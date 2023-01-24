# ASATools

This library is part of the service [ASATools](https://asa.tools)

[![Version](https://img.shields.io/cocoapods/v/ASATools.svg?style=flat)](https://cocoapods.org/pods/ASATools) [![License](https://img.shields.io/cocoapods/l/ASATools.svg?style=flat)](https://cocoapods.org/pods/ASATools)

## Installation

You can integrate ASATools using Cocoapods or Swift PM.

---

### Cocoapods

Add the following line to your Podfile:

```ruby
target '<Your Target Name>' do
  pod 'ASATools', '~> 1.4.0'
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
    .package(url: "https://github.com/ASATools/ios_sdk.git", .upToNextMajor(from: "1.4.0"))
]
```

## Integration

Open AppDelegate and at the top of the file add
```swift
import ASATools
```

From applicationDidFinishLaunching method call:
```swift
ASATools.instance.attribute(apiToken: "your_token_here")
```
To get your API token please visit [ASATools dashboard](https://asa.tools/client/settings).

![API Key location](http://asa.tools/images/sdk_integration/sdk_api_key.png)

## Handle attribution data (optional)

If you want store attribution data or pass it to your product analytics, you can use AttributionResponse from completion block. 

```swift
ASATools.instance.attribute(apiToken: "your_token_here") { response, error in
  if let response = response {
    // pass response.analyticsValues() to your product analytics
    Amplitude.instance.setUserProperties(response.analyticsValues())
    Amplitude.instance.logEvent("did_receive_asa_attribution", withEventProperties: response.analyticsValues())
  }
}
```

Note, that completion block will only be called **once** if there is a success response.

## Author

vdugnist, vdugnist@gmail.com

## License

ASATools is available under the MIT license. See the LICENSE file for more info.


