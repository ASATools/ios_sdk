#
# Be sure to run `pod lib lint ASAAttribution.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ASAAttribution'
  s.version          = '0.2.1'
  s.summary          = 'iOS library for detecting apple search ads install keyword and other info'

  s.description      = <<-DESC
This library is a part of a SAAS. Please check out asaattribution.com for futher details.
DESC

  s.homepage         = 'https://github.com/vdugnist/asaattribution_lib'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'vdugnist' => 'vdugnist@gmail.com' }
  s.source           = { :git => 'https://github.com/vdugnist/asaattribution_lib', :tag => s.version.to_s }
  s.swift_version    = '5.0'

  s.ios.deployment_target = '9.0'
  s.source_files = 'ASAAttribution/Classes/**/*'
  s.frameworks = 'AdServices'
end
