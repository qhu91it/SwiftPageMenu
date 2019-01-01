Pod::Spec.new do |s|
	s.name         = "SwiftPageMenu"
	s.version      = "1.3.1"
	s.summary      = "Customizable Page Menu ViewController in Swift"
	s.homepage     = "https://github.com/tamanyan/SwiftPageMenu"
	s.license      = "MIT"
	s.author       = { "tamanyan" => "tamanyan.ttt@gmail.com" }
	s.screenshots 	= [ "https://raw.githubusercontent.com/tamanyan/SwiftPageMenu/master/screen_captures/1.gif", "https://raw.githubusercontent.com/tamanyan/SwiftPageMenu/master/screen_captures/2.gif", "https://raw.githubusercontent.com/tamanyan/SwiftPageMenu/master/screen_captures/3.gif", "https://raw.githubusercontent.com/tamanyan/SwiftPageMenu/master/screen_captures/4.gif"]
	s.ios.deployment_target = "10.0"
	s.source       = { :git => "https://github.com/qhu91it/SwiftPageMenu.git", :tag => s.version.to_s }
	s.source_files = "Sources/**/*.swift"
end
