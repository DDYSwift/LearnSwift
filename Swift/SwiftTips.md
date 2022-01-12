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

3. 字符串转字符数组

```
let charArray = Array("String")
```

4. 更改图片缩放和方向

```
// 可用在绘制的图片或网络图片设置@2x @3x
let img = UIImage()
let a = UIImage(cgImage: img.cgImage, scale: img.scale, orientation: .up)
```

5. 找视图

```
// viewWithTag

设置多个视图相同tag，层级为下面关系

.view1
..view11
...view111

.view2
..view21

https://blog.csdn.net/lingduhuoyan245/article/details/46849943
https://blog.csdn.net/qq_19411159/article/details/70141913
```

6. DispatchTime

```
DispatchTime.now() + .seconds(value)
```

7. 等执行完执行下一步

```
@objc func prepareForShare() {

        let allLooker = [firstLooker, secondLooker, thirdLooker, forthLooker, fifthLooker, sexthLooker, seventhLooker, eighthLooker]
        // 截图隐藏空位 隐藏戒指
        let hideOperation = BlockOperation {
            DispatchQueue.main.async { [self] in
                allLooker.forEach {  $0.isHidden = ($0.json == nil) ? true : false }
                boyRingAnimateImgView.isHidden = true
                girlRingAnimateImgView.isHidden = true
            }
        }
        // 截图分享
        let shareOperation = BlockOperation { [self] in
            DispatchQueue.main.async {
                self.shareAction()
            }
        }
        // 恢复显示空位 显示戒指
        let showOperation = BlockOperation {
            DispatchQueue.main.async { [self] in
                allLooker.forEach {  $0.isHidden = false }
                boyRingAnimateImgView.isHidden = false
                girlRingAnimateImgView.isHidden = false
            }
        }
        shareOperation.addDependency(hideOperation)
        showOperation.addDependency(shareOperation)
    
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.addOperations([hideOperation, shareOperation, showOperation], waitUntilFinished: true)
    }
```

8. 自定义比较相等

```
extension Animal: Equatable {
    static func ==(left: Animal, right: Animal) -> Bool {
        return (left.height == right.height && left.weight == right.weight)
    }
}
```

9. 循环

```
// for..in..
for item in items { }

// 

```

```
/// 通过Cell类自动获取类名注册cell
    @discardableResult
    func tc_register<T: UITableViewCell>(cellClass: T.Type) -> UITableView {
        register(cellClass, forCellReuseIdentifier: String(describing: T.self))
        return self
    }
    
    /// 批量通过Cell类自动获取类名注册cell
    @discardableResult
    func tc_register(cellClasses: UITableViewCell.Type...) -> UITableView {
        for cellCls in cellClasses {
            register(cellCls, forCellReuseIdentifier: String(describing: cellCls.self))
        }
        return self
    }
    
    /// 通过Cell类获取复用cell
    func tc_dequeueReusableCell<T: UITableViewCell>(_ cellClass: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: String(describing: T.self), for: indexPath) as? T else {
            fatalError("未能通过 \(String(describing: T.self)) 取出 \(String(describing: cellClass))，请检查注册的实际情况")
        }
        return cell
    }
```

10. 使用ISO 8601和RFC 3339的格式标准生成日期时间戳

```
// "2015-01-01T00:00:00.000Z"
var now = NSDate()
var formatter = NSDateFormatter()
formatter.dateFormat ="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
println(formatter.stringFromDate(now))
// https://www.codenong.com/28016578/
```

11. build setting -> User-defined

```
// 不每次重复全量编译
user-defined HEADERMAP_USES_VFS YES

// Command PhaseScriptExecution failed with a nonzero exit code
SWIFT_ENABLE_BATCH_MODE NO
```

12. webp

```
https://github.com/tattn/AnimatedWebP
```

13. 日历

```
https://github.com/tattn/TTEventKit
```

14. swift版本

```
#if swift(>=5.3)
if #available(iOS 14.0, *) {
    return PHPhotoLibrary.authorizationStatus(for: accessLevel)
} else {
    return PHPhotoLibrary.authorizationStatus()
}
#else
return PHPhotoLibrary.authorizationStatus()
#endif
```

15. 扬声器播放

```
do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } catch {
            DDLogError("666666 RocketFox audio overrideOutputAudioPort \(error)")
        }
```

```
post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
      config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
      config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
      
      _plistFile = '$(SRCROOT)/Target Support Files/Pods-CommonPods-game_werewolf/Pods-CommonPods-game_werewolf-Info.plist'
      _frameworkArray = ["Adjust", "FirebaseInstallations", "Alamofire", "AppAuth", "Base64", "CocoaLumberjack", "CodePush", "CYLTabBarController", "DateToolsSwift", "DeviceKit", "Differentiator", "DoubleConversion", "EasyTipView", "EmptyDataSet-Swift", "FBReactNativeSpec", "FBSDKCoreKit", "FBSDKLoginKit", "FBSDKShareKit", "FirebaseCore", "FirebaseCoreDiagnostics", "FirebaseInstanceID", "FirebaseMessaging", "FLAnimatedImage", "FMDB", "Folly", "FTPopOverMenu", "FXForms", "GCDWebServer", "glog", "GoogleDataTransport", "GoogleDataTransportCCTSupport", "GoogleUtilities", "GPUImage", "GTMAppAuth", "GTMSessionFetcher", "HandyJSON", "HXPhotoPicker", "InputBarAccessoryView", "JWT", "JXCategoryView", "KeychainSwift", "KMCGeigerCounter", "LineSDKSwift", "LogUploader", "LTMorphingLabel", "MessageKit", "MJRefresh", "MLPAutoCompleteTextField", "MMKV", "MMKVCore", "nanopb", "orangeLab_iOS", "OrangelabIM", "OrgPhotoPreviewer", "PromisesObjC", "Protobuf", "QGVAPlayer", "Qiniu", "RCTTypeSafety", "React-Core", "React-CoreModules", "React-cxxreact", "React-jsi", "React-jsiexecutor", "React-jsinspector", "react-native-blur", "react-native-cameraroll", "react-native-geolocation", "react-native-image-resizer", "react-native-netinfo", "react-native-safe-area-context", "react-native-splash-screen", "react-native-view-shot", "react-native-viewpager", "react-native-webview", "React-RCTAnimation", "React-RCTBlob", "React-RCTImage", "React-RCTLinking", "React-RCTNetwork", "React-RCTSettings", "React-RCTText", "React-RCTVibration", "ReactCommon", "RealmJS", "rn-fetch-blob", "RNCAsyncStorage", "RNCClipboard", "RNCMaskedView", "RNDateTimePicker", "RNGestureHandler", "RNImageCropPicker", "RNLocalize", "RNReanimated", "RNScreens", "RNSound", "RNSVG", "RxCocoa", "RxDataSources", "RxRelay", "RxSwift", "SDWebImage", "SnapKit", "Socket.IO-Client-Swift", "Spring", "SSZipArchive", "Starscream", "SVGAPlayer", "SVProgressHUD", "SwiftyJSON", "SwiftyStoreKit", "TCAssist", "TCKit", "TextFieldEffects", "TOCropViewController", "TTGTagCollectionView", "TWMessageBarManager", "Yoga", "YTKKeyValueStore", "YYCache", "YYImage", "YYText", "YYWebImage", "ZLPhotoBrowser"]
      if _frameworkArray.include?(target.name)
        config.build_settings['INFOPLIST_FILE'] = "#{_plistFile}"
      end
      
    end
  end
end
```





```
post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
      config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
      config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
      
      _plistFile = '$(SRCROOT)/Target Support Files/Pods-en_dev/Pods-en_dev-Info.plist'
      _frameworkArray = ["Adjust", "FirebaseInstallations", "Alamofire", "AppAuth", "Base64", "CocoaLumberjack", "CodePush", "CYLTabBarController", "DateToolsSwift", "DeviceKit", "Differentiator", "DoubleConversion", "EasyTipView", "EmptyDataSet-Swift", "FBReactNativeSpec", "FBSDKCoreKit", "FBSDKLoginKit", "FBSDKShareKit", "FirebaseCore", "FirebaseCoreDiagnostics", "FirebaseInstanceID", "FirebaseMessaging", "FLAnimatedImage", "FMDB", "Folly", "FTPopOverMenu", "FXForms", "FSPagerView", "GCDWebServer", "glog", "GoogleDataTransport", "GoogleDataTransportCCTSupport", "GoogleUtilities", "GPUImage", "GTMAppAuth", "GTMSessionFetcher", "HandyJSON", "HXPhotoPicker", "InputBarAccessoryView", "IQKeyboardManagerSwift", "JWT", "JXCategoryView", "KeychainSwift", "KMCGeigerCounter", "LineSDKSwift", "LogUploader", "LTMorphingLabel", "MessageKit", "MJRefresh", "MLPAutoCompleteTextField", "MMKV", "MMKVCore", "nanopb", "orangeLab_iOS", "OrangelabIM", "OrgPhotoPreviewer", "PromisesObjC", "Protobuf", "QGVAPlayer", "Qiniu", "RCTTypeSafety", "React-Core", "React-CoreModules", "React-cxxreact", "React-jsi", "React-jsiexecutor", "React-jsinspector", "react-native-blur", "react-native-cameraroll", "react-native-geolocation", "react-native-image-resizer", "react-native-netinfo", "react-native-safe-area-context", "react-native-splash-screen", "react-native-view-shot", "react-native-viewpager", "react-native-webview", "React-RCTAnimation", "React-RCTBlob", "React-RCTImage", "React-RCTLinking", "React-RCTNetwork", "React-RCTSettings", "React-RCTText", "React-RCTVibration", "ReactCommon", "RealmJS", "rn-fetch-blob", "RNCAsyncStorage", "RNCClipboard", "RNCMaskedView", "RNDateTimePicker", "RNGestureHandler", "RNImageCropPicker", "RNLocalize", "RNReanimated", "RNScreens", "RNSound", "RNSVG", "RxCocoa", "RxDataSources", "RxRelay", "RxSwift", "SDWebImage", "SnapKit", "Socket.IO-Client-Swift", "Spring", "SSZipArchive", "Starscream", "SVGAPlayer", "SVProgressHUD", "SwiftyJSON", "SwiftyStoreKit", "TCAssist", "TCKit", "TextFieldEffects", "TOCropViewController", "TTGTagCollectionView", "TWMessageBarManager", "Yoga", "YTKKeyValueStore", "YYCache", "YYImage", "YYText", "YYWebImage", "ZLPhotoBrowser"]
      if _frameworkArray.include?(target.name)
        config.build_settings['INFOPLIST_FILE'] = "#{_plistFile}"
      end
      
    end
  end
end
```


```
["eu", "hr_BA", "en_CM", "en_BI", "en_AE", "rw_RW", "ast", "en_SZ", "he_IL", "ar", "uz_Arab", "en_PN", "as", "en_NF", "ks_IN", "es_KY", "rwk_TZ", "zh_Hant_TW", "en_CN", "gsw_LI", "ta_IN", "th_TH", "es_EA", "fr_GF", "nso", "ar_001", "en_RW", "tr_TR", "de_CH", "ee_TG", "en_NG", "byn", "fr_TG", "fr_SC", "az", "es_HN", "en_CO", "pa_Aran_PK", "en_AG", "ccp_IN", "gsw", "ru_KZ", "ks_Aran", "dyo", "so_ET", "ff_Latn", "zh_Hant_MO", "de_BE", "km_KH", "nus_SS", "my_MM", "mgh_MZ", "ee_GH", "es_EC", "kw_GB", "rm_CH", "en_ME", "nyn", "mk_MK", "bs_Cyrl_BA", "ar_MR", "es_GL", "en_BM", "ms_Arab", "en_AI", "gl_ES", "en_PR", "trv_TW", "ne_IN", "or_IN", "byn_ER", "khq_ML", "ia_001", "en_MG", "iu_CA", "en_LC", "pt_TL", "ta_SG", "tn_ZA", "myv", "syr", "jmc_TZ", "ceb_PH", "om_ET", "lv_LV", "ps_PK", "es_US", "ceb", "en_PT", "vai_Latn_LR", "en_NL", "to_TO", "cgg_UG", "en_MH", "ta", "ur_Arab_PK", "xh", "zu_ZA", "shi_Latn_MA", "es_FK", "ar_KM", "en_AL", "brx_IN", "te", "chr_US", "yo_BJ", "fr_VU", "pa", "ks_Arab", "sat_Olck", "kea", "ksh_DE", "sw_CD", "te_IN", "fr_RE", "tg", "th", "ur_IN", "ti", "yo_NG", "es_HT", "es_GP", "nqo_GN", "guz_KE", "tk", "kl_GL", "ksf_CM", "mua_CM", "lag_TZ", "lb", "fr_TN", "tn", "es_PA", "pl_PL", "to", "hi_IN", "dje_NE", "es_GQ", "en_BR", "kok_IN", "ss_ZA", "fr_GN", "pl", "bem", "ha", "ckb", "es_CA", "lg", "tr", "en_PW", "ts", "tt", "en_NO", "nyn_UG", "nr_ZA", "oc_FR", "sr_Latn_RS", "jbo", "gsw_FR", "he", "pa_Guru", "ps_AF", "lu_CD", "mgo_CM", "qu_BO", "en_BS", "sn_ZW", "da", "ps", "ss_SZ", "ln", "pt", "hi", "lo", "ebu", "de", "gu_IN", "wo_SN", "seh", "en_CX", "en_ZM", "mni_Mtei", "fr_HT", "fr_GP", "pt_GQ", "lt", "lu", "es_TT", "ln_CD", "vai_Latn", "el_GR", "lv", "en_MM", "io_001", "en_KE", "sbp", "ff_Latn_GW", "hr", "ur_Aran_PK", "en_CY", "es_GT", "twq_NE", "zh_Hant_HK", "kln_KE", "fr_GQ", "chr", "hu", "es_UY", "fr_CA", "ms_BN", "en_NR", "mer", "fr_SN", "es_PE", "shi", "bez", "sw_TZ", "wae_CH", "kkj", "hy", "dz_BT", "en_CZ", "teo_KE", "teo", "en_AR", "ar_JO", "yue_Hans_CN", "mer_KE", "dv", "khq", "ln_CF", "nn_NO", "es_SR", "en_MO", "ve_ZA", "gez", "ar_TD", "dz", "ses", "en_BW", "en_AS", "ar_IL", "es_BB", "bo_CN", "nnh", "mni", "ff_Latn_GM", "hy_AM", "ln_CG", "sr_Latn_BA", "teo_UG", "en_MP", "ksb_TZ", "ar_SA", "smn_FI", "ar_LY", "en_AT", "so_KE", "fr_CD", "af_NA", "en_NU", "es_PH", "en_KI", "ba_RU", "en_JE", "ff_Latn_GH", "lkt", "dv_MV", "en_AU", "fa_IR", "pt_FR", "uz_Latn_UZ", "zh_Hans_CN", "ewo_CM", "jv_ID", "fr_PF", "ca_IT", "es_GY", "en_BZ", "ar_KW", "am_ET", "fr_FR", "ff_Latn_SL", "en_VC", "es_DM", "fr_DJ", "pt_GW", "fr_CF", "es_SV", "en_MS", "nqo", "pt_ST", "ar_SD", "luy_KE", "gd_GB", "de_LI", "it_VA", "fr_CG", "pt_CH", "ckb_IQ", "zh_Hans_SG", "en_MT", "sc_IT", "ha_NE", "en_ID", "ewo", "af_ZA", "om_KE", "os_GE", "wa", "nl_SR", "es_ES", "es_DO", "ar_IQ", "sat_Olck_IN", "en_UA", "tig_ER", "fr_CH", "nnh_CM", "es_SX", "es_419", "en_MU", "en_US_POSIX", "yav_CM", "luo_KE", "dua_CM", "et_EE", "en_IE", "ak_GH", "sa", "rwk", "sc", "es_CL", "kea_CV", "sd", "fr_CI", "ckb_IR", "fr_BE", "se", "en_NZ", "syr_IQ", "en_MV", "en_LR", "es_PM", "en_KN", "nb_SJ", "ha_NG", "sg", "tn_BW", "sr_Cyrl_RS", "ru_RU", "en_ZW", "oc", "ga_IE", "si", "sv_AX", "wo", "en_VG", "ky_KG", "agq_CM", "mzn", "fr_BF", "naq_NA", "mr_IN", "en_MW", "de_AT", "az_Latn", "en_LS", "ka", "sk", "sl", "sat_Deva_IN", "sn", "sr_Latn_ME", "wa_BE", "fr_NC", "so", "is_IS", "kpe_LR", "twq", "ig_NG", "sq", "fo_FO", "sd_Deva", "sr", "ga", "eo_001", "en_MX", "om", "en_LT", "bas_CM", "se_NO", "ss", "st", "tzm", "ki", "nl_BE", "ar_QA", "gd", "sv", "kk", "pa_Aran", "rn_BI", "es_CO", "az_Latn_AZ", "kl", "en_VI", "es_AG", "ca", "or", "km", "os", "sw", "en_MY", "kn", "en_LU", "fr_SY", "ar_TN", "en_JM", "fr_PM", "ko", "st_ZA", "fr_NE", "ce", "fr_MA", "co_FR", "nso_ZA", "gl", "ru_MD", "kaj_NG", "es_BL", "ks", "fr_CM", "lb_LU", "gv_IM", "fr_BI", "gn", "saq_KE", "en_LV", "ku", "en_KR", "ks_Arab_IN", "es_NI", "en_GB", "kw", "nl_SX", "dav_KE", "tr_CY", "ky", "en_UG", "es_BM", "en_TC", "es_AI", "ar_EG", "fr_BJ", "co", "gu", "es_PR", "fr_RW", "gv", "lrc_IQ", "kcg", "sr_Cyrl_BA", "es_MF", "fr_MC", "cs", "bez_TZ", "es_CR", "asa_TZ", "ar_EH", "fo_DK", "ms_Arab_BN", "cv", "ccp", "en_JP", "sbp_TZ", "en_IL", "lt_LT", "mfe", "en_GD", "moh_CA", "cy", "es_LC", "ca_FR", "ts_ZA", "ff_Latn_SN", "ug_CN", "es_BO", "en_SA", "fr_BL", "bn_IN", "uz_Cyrl_UZ", "lrc_IR", "az_Cyrl", "en_IM", "sw_KE", "en_SB", "pa_Arab", "ur_PK", "haw_US", "ar_SO", "en_IN", "cv_RU", "fil", "fr_MF", "scn", "en_WS", "es_CU", "es_BQ", "ja_JP", "fy_NL", "en_SC", "yue_Hant_HK", "en_IO", "pt_PT", "en_HK", "ks_Aran_IN", "en_GG", "fr_MG", "ff_Latn_MR", "de_LU", "tig", "zh_Hant_CN", "tzm_MA", "es_BR", "en_TH", "en_SD", "nds_DE", "ln_AO", "ny_MW", "shi_Tfng", "as_IN", "en_GH", "ms_MY", "ro_RO", "jgo_CM", "es_CW", "dua", "en_UM", "es_BS", "en_SE", "kn_IN", "en_KY", "vun_TZ", "kln", "lrc", "en_GI", "moh", "ca_ES", "mni_Mtei_IN", "rof", "pt_CV", "kok", "pt_BR", "ar_DJ", "yi_001", "fi_FI", "zh", "es_PY", "ar_SS", "arn", "ve", "mua", "sr_Cyrl_ME", "hi_Latn", "vai_Vaii_LR", "en_001", "nl_NL", "en_TK", "ca_AD", "en_SG", "fr_DZ", "si_LK", "sv_SE", "pt_AO", "mni_Beng", "vi", "xog_UG", "xog", "en_IS", "syr_SY", "nb", "seh_MZ", "es_AR", "sk_SK", "en_SH", "ti_ER", "nd", "az_Cyrl_AZ", "zu", "ne", "nd_ZW", "kcg_NG", "el_CY", "en_IT", "nl_BQ", "da_GL", "ja", "wal_ET", "rm", "fr_ML", "gaa_GH", "rn", "en_VU", "ff_Latn_BF", "ro", "ebu_KE", "rof_TZ", "ru_KG", "en_SI", "sa_IN", "sg_CF", "mfe_MU", "nl", "brx", "bs_Latn", "fa", "zgh_MA", "ff_Latn_LR", "en_GM", "shi_Latn", "en_FI", "nn", "en_EE", "ru", "yue", "kam_KE", "fur", "vai_Vaii", "ar_ER", "rw", "ti_ET", "ff", "luo", "nr", "ur_Arab_IN", "ba", "fa_AF", "nl_CW", "es_MQ", "en_HR", "en_FJ", "fi", "pt_MO", "be", "en_US", "en_TO", "en_SK", "bg", "mi_NZ", "arn_CL", "ny", "ru_BY", "it_IT", "ml_IN", "gsw_CH", "qu_EC", "fo", "ff_Latn_CM", "sv_FI", "en_FK", "nus", "ff_Latn_NE", "jv", "ta_LK", "vun", "sr_Latn", "es_BZ", "fr", "en_SL", "bm", "es_VC", "trv", "ar_BH", "guz", "bn", "bo", "ar_SY", "es_MS", "lo_LA", "ne_NP", "uz_Latn", "be_BY", "es_IC", "sr_Latn_XK", "ar_MA", "pa_Guru_IN", "br", "luy", "kde_TZ", "es_AW", "bs", "fy", "fur_IT", "gez_ER", "hu_HU", "ar_AE", "gaa", "en_HU", "sah_RU", "zh_Hans", "en_FM", "fr_MQ", "ko_KP", "en_150", "en_DE", "ce_RU", "en_CA", "hsb_DE", "sq_AL", "wuu", "en_TR", "ro_MD", "es_VE", "tg_TJ", "fr_WF", "mt_MT", "kab", "nmg_CM", "ms_SG", "en_GR", "ru_UA", "fr_MR", "xh_ZA", "zh_Hans_MO", "de_IT", "ku_TR", "ccp_BD", "kpe_GN", "ur_Aran_IN", "myv_RU", "bs_Cyrl", "nds_NL", "es_KN", "sw_UG", "tt_RU", "ko_KR", "yue_Hans", "en_DG", "bo_IN", "en_CC", "shi_Tfng_MA", "lag", "it_SM", "en_TT", "ms_Arab_MY", "os_RU", "sq_MK", "es_VG", "kaj", "bem_ZM", "kde", "ur_Aran", "ar_OM", "kk_KZ", "cgg", "gez_ET", "bas", "kam", "scn_IT", "es_MX", "sah", "wae", "en_GU", "zh_Hant", "fr_MU", "fr_KM", "ar_LB", "en_BA", "sat_Deva", "en_TV", "sr_Cyrl", "mzn_IR", "es_VI", "dje", "kab_DZ", "fil_PH", "se_SE", "vai", "hr_HR", "bs_Latn_BA", "nl_AW", "dav", "so_SO", "ar_PS", "en_FR", "uz_Cyrl", "jbo_001", "en_BB", "ki_KE", "en_TW", "naq", "en_SS", "mg_MG", "mas_KE", "ff_Latn_GN", "en_RO", "en_PG", "mgh", "dyo_SN", "wal", "mas", "agq", "bn_BD", "haw", "yi", "nb_NO", "da_DK", "en_DK", "saq", "st_LS", "ug", "cy_GB", "fr_YT", "jmc", "ses_ML", "en_PH", "de_DE", "ar_YE", "es_TC", "bm_ML", "yo", "lkt_US", "uz_Arab_AF", "jgo", "sl_SI", "gn_PY", "pt_LU", "sat", "en_CH", "asa", "en_BD", "uk", "lg_UG", "nds", "qu_PE", "mgo", "id_ID", "en_NA", "en_GY", "ff_Latn_NG", "zgh", "dsb", "fr_LU", "pt_MZ", "mas_TZ", "en_DM", "ia", "es_GD", "en_BE", "mg", "sd_PK", "ta_MY", "fr_GA", "ka_GE", "nmg", "en_TZ", "ur", "eu_ES", "ar_DZ", "mi", "ur_Arab", "id", "so_DJ", "kpe", "hsb", "yav", "mk", "ml", "pa_Arab_PK", "en_ER", "ig", "se_FI", "mn", "ksb", "uz", "vi_VN", "ii", "qu", "en_RS", "en_PK", "ee", "ast_ES", "yue_Hant", "mr", "ms", "en_ES", "ha_GH", "it_CH", "sq_XK", "mt", "en_CK", "br_FR", "en_BG", "io", "es_GF", "sr_Cyrl_XK", "ksf", "en_SX", "bg_BG", "tk_TM", "en_PL", "af", "el", "cs_CZ", "fr_TD", "ks_Deva", "zh_Hans_HK", "is", "ksh", "my", "mn_MN", "en", "it", "dsb_DE", "ii_CN", "eo", "iu", "en_CL", "en_ZA", "en_AD", "smn", "mni_Beng_IN", "ak", "en_RU", "kkj_CM", "am", "es", "et", "uk_UA"]



        UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        DDLogInfo("666666Language NSLocale.preferredLanguages \(NSLocale.preferredLanguages)")
        DDLogInfo("666666Language UserDefault \(String(describing: UserDefaults.standard.array(forKey: "AppleLanguages")))")
        DDLogInfo("666666Language languageCode \(NSLocale.current.languageCode ?? "code blank")")
        DDLogInfo("666666Language regionCode \(NSLocale.current.regionCode ?? "regionCode blank")")
        DDLogInfo("666666Language currencyCode \(NSLocale.current.currencyCode ?? "currencyCode blank")")
        DDLogInfo("666666Language default \(NSLocalizedString(self, comment: ""))")
        
        DDLogInfo("666666Language Bundle \(Bundle.main.preferredLocalizations)")
        DDLogInfo("666666Language special \(NSLocale.availableLocaleIdentifiers)")
```

[UITextView 设置不允许选中，允许链接跳转](https://www.jianshu.com/p/6d941e81cfd7)