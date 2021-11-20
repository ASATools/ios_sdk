# ASAAttribution

Library that allows you to get information about apple search ads install keyword, campaign, adgroup and other info. Here is how it looks:
```
ASAAttribution.sharedInstance.attribute(apiToken: "your_token_here") { response, error in
// 	{
// 		"attribution_status": "attributed", (attributed, organic)
// 		"organization_id": 40669820,
// 		"campaign_id": 542370539,
// 		"ad_group_id": 542317095,
// 		"keyword_id": 87675432,
// 		"creative_set_id": 542317136,
// 		"conversion_type": "Download", (download, redownload)
// 		"region": "US",
// 		"campaign_name": "MyAppName US Woman 18-35",
// 		"ad_group_name": "Branded Keywords Campaign",
// 		"keyword_name": "my app name"
// 	}
}
```


[![Version](https://img.shields.io/cocoapods/v/ASAAttribution.svg?style=flat)](https://cocoapods.org/pods/ASAAttribution)
[![License](https://img.shields.io/cocoapods/l/ASAAttribution.svg?style=flat)](https://cocoapods.org/pods/ASAAttribution)
[![Platform](https://img.shields.io/cocoapods/p/ASAAttribution.svg?style=flat)](https://cocoapods.org/pods/ASAAttribution)

## Installation

Add the following line to your Podfile:

```ruby
pod 'ASAAttribution'
```

To get your API token please visit [asaattribution.com](https://asaattribution.com).

## Author

vdugnist, vdugnist@gmail.com

## License

ASAAttribution is available under the MIT license. See the LICENSE file for more info.


