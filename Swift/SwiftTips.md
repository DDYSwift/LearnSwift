1. 打印代码执行时间

```
let startTime = CFAbsoluteTimeGetCurrent()
// code             
let endTime = CFAbsoluteTimeGetCurrent()
debugPrint("\((endTime - startTime) * 1000) 毫秒")
```

2. UIButton Selected 按住时禁止显示normal 文字

```
let button = UIButton(type: .custom)
button.setTitle("下一步".localized, for: .normal)
button.setTitle("喂养".localized, for: .selected)
button.setTitle("喂养".localized, for: [.selected, .highlighted])
button.adjustsImageWhenHighlighted = false
```

```
post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      _plistFile = '$(SRCROOT)/Target Support Files/Pods-CommonPods-game_werewolf/Pods-CommonPods-game_werewolf-Info.plist'
      _frameworkArray = ["Adjust", "Alamofire", "AppAuth", "Base64", "CocoaLumberjack", "CodePush", "CYLTabBarController", "DateToolsSwift", "DeviceKit", "Differentiator", "DoubleConversion", "EasyTipView", "EmptyDataSet-Swift", "FBReactNativeSpec", "FBSDKCoreKit", "FBSDKLoginKit", "FBSDKShareKit", "FirebaseCore", "FirebaseCoreDiagnostics", "FirebaseInstanceID", "FirebaseMessaging", "FLAnimatedImage", "FMDB", "Folly", "FTPopOverMenu", "FXForms", "GCDWebServer", "glog", "GoogleDataTransport", "GoogleDataTransportCCTSupport", "GoogleUtilities-00567490", "GoogleUtilities-54e75ca4", "GPUImage", "GTMAppAuth", "GTMSessionFetcher", "HandyJSON", "HXPhotoPicker", "InputBarAccessoryView", "JWT", "JXCategoryView", "KeychainSwift", "KMCGeigerCounter", "LineSDKSwift", "LogUploader", "LTMorphingLabel", "MessageKit", "MJRefresh", "MLPAutoCompleteTextField", "MMKV", "MMKVCore", "nanopb", "orangeLab_iOS", "OrangelabIM", "OrgPhotoPreviewer", "PromisesObjC", "Protobuf", "QGVAPlayer", "Qiniu", "RCTTypeSafety", "React-Core", "React-CoreModules", "React-cxxreact", "React-jsi", "React-jsiexecutor", "React-jsinspector", "react-native-blur", "react-native-cameraroll", "react-native-geolocation", "react-native-image-resizer", "react-native-netinfo", "react-native-safe-area-context", "react-native-splash-screen", "react-native-view-shot", "react-native-viewpager", "react-native-webview", "React-RCTAnimation", "React-RCTBlob", "React-RCTImage", "React-RCTLinking", "React-RCTNetwork", "React-RCTSettings", "React-RCTText", "React-RCTVibration", "ReactCommon", "RealmJS", "rn-fetch-blob", "RNCAsyncStorage", "RNCClipboard", "RNCMaskedView", "RNDateTimePicker", "RNGestureHandler", "RNImageCropPicker", "RNLocalize", "RNReanimated", "RNScreens", "RNSound", "RNSVG", "RxCocoa", "RxDataSources", "RxRelay", "RxSwift", "SDWebImage", "SnapKit", "Socket.IO-Client-Swift", "Spring", "SSZipArchive", "Starscream", "SVGAPlayer", "SVProgressHUD", "SwiftyJSON", "SwiftyStoreKit", "TCAssist", "TCKit", "TextFieldEffects", "TOCropViewController", "TTGTagCollectionView", "TWMessageBarManager", "Yoga", "YTKKeyValueStore", "YYCache", "YYImage", "YYText", "YYWebImage", "ZLPhotoBrowser"]
      if _frameworkArray.include?(target.name)
        config.build_settings['INFOPLIST_FILE'] = "#{_plistFile}"
      end
      
    end
  end
end
```