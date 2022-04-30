# ASATools

Library that allows you to get information about apple search ads install campaign, ad group, keyword and other info. Here is how it looks:
```swift
ASATools.instance.attribute(apiToken: "your_token_here") { response, error in
  print(response?.analyticsValues())
}
```

Output:
```javascript
{
  "asa_campaign_name": "MyAppName US",
  "asa_ad_group_name": "Branded Keywords",
  "asa_keyword_name": "my app name",
  "asa_store_country": "US"
}
```

For all response values please check [ASAToolsAttributionResponse](https://github.com/vdugnist/asatools_lib/blob/main/ASATools/Classes/ASAToolsAttributionResponse.swift) class.


[![Version](https://img.shields.io/cocoapods/v/ASAAttribution.svg?style=flat)](https://cocoapods.org/pods/ASAAttribution)
[![License](https://img.shields.io/cocoapods/l/ASAAttribution.svg?style=flat)](https://cocoapods.org/pods/ASAAttribution)
[![Platform](https://img.shields.io/cocoapods/p/ASAAttribution.svg?style=flat)](https://cocoapods.org/pods/ASAAttribution)

## Installation

### Cocoapods

Add the following line to your Podfile:

```ruby
target '<Your Target Name>' do
  pod 'ASATools', '~> 1.2.0'
end
```

Then, run the following command:
```bash
pod install
```

### Swift Package Manager

To integrate ASATools into your Xcode project using Swift Package Manager, add it to the dependencies value of your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/vdugnist/asatools_lib.git", .upToNextMajor(from: "1.2.0"))
]
```

## Integration

From applicationDidFinishLaunching method call:
```swift
ASATools.instance.attribute(apiToken: "your_token_here") { response, error in
  if let response = response {
    // store response.analyticsValues() in your product analytics
    Amplitude.instance.setUserProperties(response.analyticsValues())
    Amplitude.instance.logEvent("did_receive_asa_attribution", withEventProperties: response.analyticsValues())
  }
}
```

Note, that completion block will only be called **once** if there is a success response. To get your API token please visit [asa.tools](https://asa.tools).

## Author

vdugnist, vdugnist@gmail.com

## License

ASATools is available under the MIT license. See the LICENSE file for more info.


