#
# Be sure to run `pod lib lint SwiftTickerView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftTickerView'
  s.version          = '1.2.2'
  s.summary          = 'A simple news ticker view'
  s.swift_version    = '4.0'

  s.description      = <<-DESC
A swift ticker, written in swift. The one, with those '+++' separators ;)
                       DESC

  s.homepage         = 'https://github.com/EMart86/SwiftTickerView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Martin Eberl' => 'eberl_ma@gmx.at' }
  s.source           = { :git => 'https://github.com/EMart86/SwiftTickerView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'SwiftTickerView/Classes/**/*'
end
