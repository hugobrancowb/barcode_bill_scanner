# barcode_bill_scanner
Scanner de código de barras para Flutter.

O **barcode_bill_scanner** foi criado devido à necessidade de leitura de códigos de barras horizontais (como em contas e boletos bancários) assim como sua conversão para o padrão brasileiro, conforme determinado pela FEBRABAN.

## Requirements

### iOS

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

Notice that the minimum `IPHONEOS_DEPLOYMENT_TARGET` is 10.0, you can set it to something newer but not older.

### Android

- minSdkVersion: 21
- targetSdkVersion: 29

## How to use
```dart
 @override
 Widget build(BuildContext context) {
   return Stack(
     alignment: Alignment.center,
     children: [
       BarcodeBillScanner(
         onCancelLabel: "You can set a message to cancel an action",
         onSuccess: (String value) async {
           setState(() => barcode = value);
         },
         onCancel: () {
           setState(() => barcode = null);
         },
       ),
       if (barcode != null)
         Text(
           barcode!,
           textAlign: TextAlign.center,
           style: const TextStyle(
             fontSize: 20.0,
             color: Colors.amber,
           ),
         ),
     ],
   );
 }
```