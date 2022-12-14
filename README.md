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


[![Version](https://img.shields.io/cocoapods/v/ASATools.svg?style=flat)](https://cocoapods.org/pods/ASATools)
[![License](https://img.shields.io/cocoapods/l/ASATools.svg?style=flat)](https://cocoapods.org/pods/ASATools)

## Installation

### Cocoapods

Add the following line to your Podfile:

```ruby
target '<Your Target Name>' do
  pod 'ASATools', '~> 1.3.1'
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
    .package(url: "https://github.com/ASATools/ios_sdk.git", .upToNextMajor(from: "1.3.1"))
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

Note, that completion block will only be called **once** if there is a success response. To get your API token please visit [ASATools dashboard](https://asa.tools/client/settings).

![API Key location](http://asa.tools/images/sdk_integration/sdk_api_key.png)

## Author

vdugnist, vdugnist@gmail.com

## License

ASATools is available under the MIT license. See the LICENSE file for more info.


