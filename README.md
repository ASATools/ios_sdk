# ASAAttribution

Library that allows you to get information about apple search ads install keyword, campaign, adgroup and other info. Here is how it looks:
```swift
ASAAttribution.sharedInstance.attribute(apiToken: "your_token_here") { response, error in
  print(response.analyticsValues())
}
```

Output:
```javascript
{
  "asa_campaign_name": "MyAppName US Woman 18-35",
  "asa_ad_group_name": "Branded Keywords Campaign",
  "asa_keyword_name": "my app name",
  "asa_conversion_type": "download"
}
```

For all response values please check [ASAAttributionResponse](https://github.com/vdugnist/asaattribution_lib/blob/main/ASAAttribution/Classes/ASAAttributionResponse.swift) class.


[![Version](https://img.shields.io/cocoapods/v/ASAAttribution.svg?style=flat)](https://cocoapods.org/pods/ASAAttribution)
[![License](https://img.shields.io/cocoapods/l/ASAAttribution.svg?style=flat)](https://cocoapods.org/pods/ASAAttribution)
[![Platform](https://img.shields.io/cocoapods/p/ASAAttribution.svg?style=flat)](https://cocoapods.org/pods/ASAAttribution)

## Installation

Add the following line to your Podfile and run pod install:

```ruby
pod 'ASAAttribution'
```

From applicationDidFinishLaunching method call:
```swift
ASAAttribution.sharedInstance.attribute(apiToken: "your_token_here") { response, error in
  if let error = error {
    // handle error response
    return
  }

  // handle success response using response!.analyticsValues() or your custom format
}
```

Note, that completion block will only be called **once** if there is a success response. To get your API token please visit [asaattribution.com](https://asaattribution.com).

## Author

vdugnist, vdugnist@gmail.com

## License

ASAAttribution is available under the MIT license. See the LICENSE file for more info.


