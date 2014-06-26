#
#  Be sure to run `pod spec lint IPSqueezableViewController.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "IPSqueezableViewController"
  s.version      = "0.0.1"
  s.summary      = "A condensing effect of navigation bar as we see in Safari.app"

  s.description  = <<-DESC
                   A condensing effect of navigation bar as we see in Safari.app. Support iOS 7.
                   DESC

  s.homepage     = "http://github.com/zetachang/IPSqueezableViewController"

  s.license      = "MIT"
  
  s.author    = "David Chang"
  s.social_media_url   = "http://twitter.com/zetachang"

  s.platform     = :ios

  s.source       = { :git => "http://github.com/zetachang/IPSqueezableViewController.git", :tag => "0.0.1" }
  
  s.source_files  = "Classes"

  s.resources = "Resources/*.png"

  s.requires_arc = true
end
