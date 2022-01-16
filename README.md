<h1 align="center">Barcode Bill Scanner</h1>

Barcode scanner build for Flutter.

**Barcode Bill Scanner** aims to be used by brazilian apps willing to get a readable code from a horizontal barcode, mainly from bills.
Brazilian's pattern for barcode is defined by [FEBRABAN](https://febraban.org.br), which has a couple of rules for transforming a regular 44-length code into 47~48 character long.

Our package converts the barcode by default to FEBRABAN's format but can easily be turned off if necessary.

<p align="center">
  <img src="https://user-images.githubusercontent.com/11953552/148662123-32c06f35-3dd0-4faf-94cb-8ed56a54e20c.gif">
</p>

## How to use
```dart
  @override
  Widget build(BuildContext context) {
    return BarcodeBillScanner(
      onCancelLabel: "You can set a message to cancel an action",
      onSuccess: (String value) async {
        setState(() => barcode = value);
      },
      onCancel: () {
        setState(() => barcode = null);
      },
    );
  }
```

## Requirements
<details>
<summary>iOS</summary>

- Minimum iOS Deployment Target: 10.0
- Xcode 12 or newer
- Swift 5
- ML Kit only supports 64-bit architectures (x86_64 and arm64). Check this [list](https://developer.apple.com/support/required-device-capabilities/) to see if your device has the required device capabilities.

Since ML Kit does not support 32-bit architectures (i386 and armv7) ([Read mode](https://developers.google.com/ml-kit/migration/ios)), you need to exclude amrv7 architectures in Xcode in order to run `flutter build ios` or `flutter build ipa`.

Go to Project > Runner > Building Settings > Excluded Architectures > Any SDK > armv7

![](https://github.com/bharat-biradar/Google-Ml-Kit-plugin/blob/master/ima/build_settings_01.png)

Then your Podfile should look like this:

```
# add this line:
$iOSVersion = '10.0'

post_install do |installer|
  # add these lines:
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=*]"] = "armv7"
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = $iOSVersion
  end
  
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # add these lines:
    target.build_configurations.each do |config|
      if Gem::Version.new($iOSVersion) > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = $iOSVersion
      end
    end
    
  end
end
```
</details>

<details>
<summary>Android</summary>
  
- minSdkVersion: 21
- targetSdkVersion: 29
</details>
