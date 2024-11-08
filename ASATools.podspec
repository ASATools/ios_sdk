#
# Be sure to run `pod lib lint ASATools.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ASATools'
  s.version          = '1.5.0'
  s.summary          = 'iOS library for Apple Search Ads attribution and ROAS measurement'

  s.description      = <<-DESC
This library is a part of a SAAS. Please check out asa.tools for futher details.
DESC

  s.homepage         = 'https://github.com/ASATools/ios_sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'vdugnist' => 'vdugnist@gmail.com' }
  s.source           = { :git => 'https://github.com/ASATools/ios_sdk', :tag => s.version.to_s }
  s.swift_version    = '5.0'

  s.ios.deployment_target = '9.0'
  s.macos.deployment_target = '10.14'
  s.source_files = 'ASATools/Classes/**/*'
  s.resource_bundles = {'ASATools' => ['ASATools/PrivacyInfo.xcprivacy']}
  s.weak_framework = 'AdServices'
end
