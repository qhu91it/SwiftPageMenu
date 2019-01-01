//
//  PageMenuControllerDataSource.swift
//  SwiftPageMenu
//
//  Created by Tamanyan on 3/9/17.
//  Copyright © 2017 Tamanyan. All rights reserved.
//

import Foundation

public class SPMMenuItem: NSObject {
    public var title: String
    public var icon: UIImage?
    
    public init(title: String = "", icon: UIImage? = nil) {
        self.title = title
        self.icon = icon
    }
}

@objc public protocol PageMenuControllerDataSource: class {

    /// The view controllers to display in the page menu view controller.
    func viewControllers(forPageMenuController pageMenuController: PageMenuController) -> [UIViewController]

    /// The view controllers to display in the page menu view controller.
    func menuTitles(forPageMenuController pageMenuController: PageMenuController) -> [SPMMenuItem]

    /// The default page index to display in the page menu view controller.
    func defaultPageIndex(forPageMenuController pageMenuController: PageMenuController) -> Int
}
