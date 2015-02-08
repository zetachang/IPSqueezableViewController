Pod::Spec.new do |s|
  s.name         = "IPSqueezableViewController"
  s.version      = "0.0.2"
  s.summary      = "Condensing effect of navigation bar as the one in Safari.app "

  s.description  = <<-DESC
                   A condensing effect of navigation bar as we see in Safari.app. Support iOS 7.
                   DESC

  s.homepage     = "http://github.com/zetachang/IPSqueezableViewController"

  s.license      = "MIT"
  
  s.author    = "David Chang"
  s.social_media_url   = "http://twitter.com/zetachang"

  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/zetachang/IPSqueezableViewController.git", :tag => "#{s.version}" }
  
  s.source_files  = "Classes"

  s.resources = "Resources/*.png"

  s.requires_arc = true
end
