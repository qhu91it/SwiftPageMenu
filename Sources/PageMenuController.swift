//
//  PageMenuController.swift
//  SwiftPageMenu
//
//  Created by Tamanyan on 3/9/17.
//  Copyright © 2017 Tamanyan. All rights reserved.
//

import UIKit

open class PageMenuController: UIViewController {

    /// SwiftPageMenu configurations
    private var _options: PageMenuOptions
    public var options: PageMenuOptions {
        get {
            return _options
        }
    }

    /// PageMenuController data source.
    open weak var dataSource: PageMenuControllerDataSource? {
        didSet {
            self.reloadPages(reloadViewControllers: true)
        }
    }

    /// PageMenuController delegate.
    open weak var delegate: PageMenuControllerDelegate?

    /// The view controllers that are displayed in the page view controller.
    open internal(set) var viewControllers = [UIViewController]()

    /// The tab menu titles that are displayed in the page view controller.
    open internal(set) var menuTitles = [SPMMenuItem]()

    /// Current page index
    open var currentIndex: Int? {
        guard let viewController = self.pageViewController.selectedViewController else {
            return nil
        }
        return self.viewControllers.firstIndex(of: viewController)
    }
    
    open var currentViewController: UIViewController? {
        if let currentIndex = currentIndex,
            viewControllers.count > currentIndex {
            return viewControllers[currentIndex]
        }
        return nil
    }

    fileprivate lazy var pageViewController: EMPageViewController = { [weak self] in
        let vc = EMPageViewController(navigationOrientation: .horizontal)
        vc.view.backgroundColor = .clear
        if let strongself = self {
            vc.dataSource = strongself
            vc.delegate = strongself
        }
        vc.scrollView.backgroundColor = .clear
        if #available(iOS 11.0, *) {
            vc.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            vc.automaticallyAdjustsScrollViewInsets = false
        }
        return vc
    }()

    /// TabView
    fileprivate(set) lazy var tabView: TabMenuView = {
        let tabView = TabMenuView(options: self.options)

        tabView.pageItemPressedBlock = { [weak self] (index: Int, direction: EMPageViewControllerNavigationDirection) in
            guard let `self` = self else { return }

            self.displayController(with: index,
                                   direction: direction,
                                   animated: true)

            self.delegate?.pageMenuController?(self,
                                               didSelectMenuItem: index,
                                               direction: direction.toPageMenuNavigationDirection)
        }

        return tabView
    }()
    
    private var tabViewHeightConstraint: NSLayoutConstraint!

    fileprivate var beforeIndex: Int?

    /// TabMenuView for custom layout
    public var tabMenuView: UIView {
        return self.tabView
    }

    /// Check options have infinite mode
    public var isInfinite: Bool {
        return self.options.isInfinite
    }

    /// Get page count
    public var pageCount: Int {
        return self.viewControllers.count
    }

    /// Page scroll enabled
    public var isScrollEnabled: Bool {
        get {
            return pageViewController.scrollView.isScrollEnabled
        }
        set {
            pageViewController.scrollView.isScrollEnabled = newValue
        }
    }
    
    /// The number of tab items
    fileprivate var tabItemCount: Int {
        return self.menuTitles.count
    }

    public init(options: PageMenuOptions? = nil) {
        _options = options ?? DefaultPageMenuOption()
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented, use init(coder: options:)")
    }

    public init?(coder: NSCoder, options: PageMenuOptions? = nil) {
        _options = options ?? DefaultPageMenuOption()
        super.init(coder: coder)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        self.setup()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let currentIndex = self.currentIndex, self.isInfinite {
            self.tabView.updateCurrentIndex(currentIndex, shouldScroll: true)
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.tabView.layouted = true
    }
    
    public func reloadOptions(_ options: PageMenuOptions) {
        _options = options
        let extraSpace = options.tabMenuPosition == .bottom ? extraBottomSpace() : 0
        tabViewHeightConstraint.constant = options.menuItemSize.height + extraSpace
        tabView.reloadOptions(options)
    }

    /**
     Reload the view controllers in the page view controller.
     This reloads the dataSource entirely, calling viewControllers(forPageMenuViewController:)
     and defaultPageIndex(forPageMenuViewController:).
     */
    public func reloadPages() {
        self.reloadPages(reloadViewControllers: true)
    }

    /**
     Transitions to the next page.

     - parameter animated: A Boolean whether or not to animate the transition
     - parameter completion: A block that's called after the transition is finished. The block parameter `transitionSuccessful` is `true` if the transition to the selected view controller was completed successfully.
     */
    public func scrollToNext(animated: Bool, completion: ((Bool) -> Void)?) {
        self.pageViewController.scrollForward(animated: animated, completion: completion)
    }

    /**
     Transitions to the previous page.

     - parameter animated: A Boolean whether or not to animate the transition
     - parameter completion: A block that's called after the transition is finished. The block parameter `transitionSuccessful` is `true` if the transition to the selected view controller was completed successfully.
     */
    public func scrollToPrevious(animated: Bool, completion: ((Bool) -> Void)?) {
        self.pageViewController.scrollReverse(animated: animated, completion: completion)
    }
    
    public func tabViewScrollToHorizontalCenter() {
        self.tabView.scrollToHorizontalCenter()
    }

    /**
     Show page controller with index

     - parameter index: Index that you want to show
     - parameter direction: The direction of the navigation and animation
     - parameter animated: A Boolean whether or not to animate the transition
     */
    fileprivate func displayController(with index: Int, direction: EMPageViewControllerNavigationDirection, animated: Bool) {
        if self.pageViewController.scrolling {
            return
        }

        if self.pageViewController.selectedViewController == viewControllers[index] {
            self.tabView.updateCollectionViewUserInteractionEnabled(true)
            return
        }

        self.beforeIndex = index
        self.pageViewController.delegate = nil
        self.tabView.updateCollectionViewUserInteractionEnabled(false)

        let completion: ((Bool) -> Void) = { [weak self] _ in
            guard let `self` = self else { return }

            self.beforeIndex = index
            self.pageViewController.delegate = self
            self.tabView.updateCollectionViewUserInteractionEnabled(true)
            self.delegate?.pageMenuController?(self,
                                               didScrollToPageAtIndex: index,
                                               direction: direction.toPageMenuNavigationDirection)
        }

        self.delegate?.pageMenuController?(self,
                                           willScrollToPageAtIndex: self.currentIndex ?? 0,
                                           direction: direction.toPageMenuNavigationDirection)

        self.pageViewController.selectViewController(viewControllers[index],
                                                     direction: direction,
                                                     animated: animated,
                                                     completion: completion)

        guard self.isViewLoaded else { return }

        self.tabView.updateCurrentIndex(index, shouldScroll: true)
    }

    /**
     Reload all pages

     - parameter reloadViewControllers: A Boolean whether or not to reload each page view controller
     */
    fileprivate func reloadPages(reloadViewControllers: Bool) {
        guard let defaultIndex = self.dataSource?.defaultPageIndex(forPageMenuController: self) else {
            self.tabView.pageTabItems = []
            return
        }

        if self.tabView.superview == nil {
            assertionFailure("TabMenuView needs to add subview before setting dataSource when you use custom menu position")
        }

        if self.beforeIndex == nil {
            self.beforeIndex = 0
        }

        guard let titles = self.dataSource?.menuTitles(forPageMenuController: self),
              let viewControllers = self.dataSource?.viewControllers(forPageMenuController: self) else {
                return
        }

        if defaultIndex < 0 || defaultIndex >= titles.count || defaultIndex >= viewControllers.count {
            // error index
            return
        }

        if reloadViewControllers || self.viewControllers.count == 0 || self.menuTitles.count == 0 {
            self.viewControllers = viewControllers
            self.menuTitles = titles
        }

        if let beforeIndex = self.beforeIndex {
            self.tabView.pageTabItems = titles
            self.tabView.updateCurrentIndex(beforeIndex, shouldScroll: false, animated: false)
        }

        guard defaultIndex < self.viewControllers.count else {
            return
        }

        self.pageViewController.selectViewController(self.viewControllers[defaultIndex],
                                                     direction: .forward,
                                                     animated: false,
                                                     completion: nil)
    }

    fileprivate func setup() {
        self.addChild(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)

        switch self.options.tabMenuPosition {
        case .top:
            // add tab view
            self.view.addSubview(self.tabView)

            // setup page view controller layout
            self.pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
            self.pageViewController.view.topAnchor.constraint(equalTo: self.tabView.bottomAnchor).isActive = true
            self.pageViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.pageViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

            // setup tab view layout
            self.tabView.translatesAutoresizingMaskIntoConstraints = false
            self.tabViewHeightConstraint = self.tabView.heightAnchor.constraint(equalToConstant: options.menuItemSize.height)
            self.tabViewHeightConstraint.priority = UILayoutPriority(999)
            self.tabViewHeightConstraint.isActive = true
            self.tabView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.tabView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

            // use layout guide or edge
            switch self.options.layout {
            case .layoutGuide:
                if #available(iOS 11.0, *) {
                    self.pageViewController.view.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.bottomAnchor).isActive = true
                    self.tabView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
                } else {
                    self.pageViewController.view.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.bottomAnchor).isActive = true
                    self.tabView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
                }
            case .edge:
                self.pageViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                self.tabView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            }
        case .bottom:
            // add tab view
            self.view.addSubview(self.tabView)

            // setup page view controller layout
            self.pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
            self.pageViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.pageViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            self.pageViewController.view.bottomAnchor.constraint(equalTo: self.tabView.topAnchor).isActive = true

            // setup tab view layout
            self.tabView.translatesAutoresizingMaskIntoConstraints = false
            let extraSpace = options.tabMenuPosition == .bottom ? extraBottomSpace() : 0
            self.tabViewHeightConstraint = self.tabView.heightAnchor.constraint(equalToConstant: options.menuItemSize.height + extraSpace)
            self.tabViewHeightConstraint.priority = UILayoutPriority(999)
            self.tabViewHeightConstraint.isActive = true
            self.tabView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.tabView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

            // use layout guide or edge
            switch self.options.layout {
            case .layoutGuide:
                if #available(iOS 11.0, *) {
                    self.pageViewController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
//                    self.tabView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                    let pageViewBottom = self.tabView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
                    pageViewBottom.priority = UILayoutPriority(999)
                    pageViewBottom.isActive = true
                } else {
                    self.pageViewController.view.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
                    self.tabView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
                }
            case .edge:
                self.pageViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                self.tabView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            }
        case .custom:

            // setup page view controller layout
            self.pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
            self.pageViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.pageViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

            // use layout guide or edge
            switch self.options.layout {
            case .layoutGuide:
                if #available(iOS 11.0, *) {
                    self.pageViewController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
//                    self.pageViewController.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
                    let pageViewBottom = self.pageViewController.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
                    pageViewBottom.priority = UILayoutPriority(999)
                    pageViewBottom.isActive = true
                } else {
                    self.pageViewController.view.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
                    self.pageViewController.view.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
                }
            case .edge:
                self.pageViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                self.pageViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            }
        }

        self.view.sendSubviewToBack(self.pageViewController.view)
        self.pageViewController.didMove(toParent: self)
    }
}

// MARK:- EMPageViewControllerDelegate

extension PageMenuController: EMPageViewControllerDelegate {
    func em_pageViewController(_ pageViewController: EMPageViewController,
                               willStartScrollingFrom startingViewController: UIViewController,
                               destinationViewController: UIViewController, direction: EMPageViewControllerNavigationDirection) {

        // Order to prevent the the hit repeatedly during animation
        self.tabView.updateCollectionViewUserInteractionEnabled(false)
        self.delegate?.pageMenuController?(self, willScrollToPageAtIndex: self.currentIndex ?? 0, direction: direction.toPageMenuNavigationDirection)
    }

    func em_pageViewController(_ pageViewController: EMPageViewController,
                               didFinishScrollingFrom startingViewController: UIViewController?,
                               destinationViewController: UIViewController,
                               direction: EMPageViewControllerNavigationDirection,
                               transitionSuccessful: Bool) {

        if let currentIndex = self.currentIndex, currentIndex < self.tabItemCount {
            self.tabView.updateCurrentIndex(currentIndex, shouldScroll: true)
            self.beforeIndex = currentIndex
            self.delegate?.pageMenuController?(self, didScrollToPageAtIndex: currentIndex, direction: direction.toPageMenuNavigationDirection)
        }

        self.tabView.updateCollectionViewUserInteractionEnabled(true)
    }

    func em_pageViewController(_ pageViewController: EMPageViewController,
                               isScrollingFrom startingViewController: UIViewController,
                               destinationViewController: UIViewController?,
                               direction: EMPageViewControllerNavigationDirection,
                               progress: CGFloat) {

        guard let beforeIndex = self.beforeIndex else { return }

        var index: Int

        if progress > 0 {
            index = beforeIndex + 1
        } else {
            index = beforeIndex - 1
        }

        if index == self.tabItemCount {
            index = 0
        } else if index < 0 {
            index = self.tabItemCount - 1
        }

        let scrollOffsetX = self.view.frame.width * progress
        self.tabView.scrollCurrentBarView(index, contentOffsetX: scrollOffsetX, progress: progress)
        self.delegate?.pageMenuController?(self, scrollingProgress: progress, direction: direction.toPageMenuNavigationDirection)
    }
}

// MARK:- EMPageViewControllerDataSource

extension PageMenuController: EMPageViewControllerDataSource {
    private func nextViewController(_ viewController: UIViewController, isAfter: Bool) -> UIViewController? {
        guard var index = viewControllers.firstIndex(of: viewController) else { return nil }

        if isAfter {
            index += 1
        } else {
            index -= 1
        }

        if self.isInfinite {
            if index < 0 {
                index = viewControllers.count - 1
            } else if index == viewControllers.count {
                index = 0
            }
        }

        if index >= 0 && index < viewControllers.count {
            return viewControllers[index]
        }
        return nil
    }

    func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return nextViewController(viewController, isAfter: true)
    }

    func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return nextViewController(viewController, isAfter: false)
    }
}

extension PageMenuController {
    func extraBottomSpace() -> CGFloat {
        guard let root = UIApplication.shared.keyWindow?.rootViewController else { return 0 }
        if root.isKind(of: UIViewController.self) {
            if #available(iOS 11.0, *) {
                return root.view.safeAreaInsets.bottom
            }
        }
        return 0
    }
}
