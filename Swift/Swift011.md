# Swift10-QRCode BarCode 


* ###  生成

	条形码要求生成的原始字符串需要为ASCII码0-127内字符(Code128,最好不超过30个字符)    
	二维码字数也不宜过多，防止生成的二维码密度过大影响识别   

	```
	import UIKit
	import CoreImage
	import CoreGraphics
	
	/// errorCode意义 0:成功 -1:字符串非法 -2:size非法 -3:前景色非法 -4:背景色非法 -5:未知错误
	typealias DDYQRCodeCreatorClosure = (_ image: UIImage?,_ errorCode: Int,_ errorMessage: String) -> Void
	
	// 创建配置结构体
	public struct DDYQRCodeConfig {
	    // 大小(更改大小以 let scale = min(size.width/img.extent.integral.width, size.height/img.extent.integral.height) 等比例缩放)
	    var size: CGSize? = CGSize(width: 600, height: 600)
	    // 前景色，默认黑色
	    var color: UIColor? = UIColor.black
	    // 背景色，默认白色 前景色背景色如果自定义最好有差异
	    var bgColor: UIColor? = UIColor.white
	    // 二维码中间logo(条形码时设置无效)
	    var logo: UIImage?
	}
	
	final class DDYQRCodeCreator: NSObject {
	    
	    /// 生成条形码(可以配置指定大小指定颜色) DDYQRCodeCreator.ddyBarCode("987654321123456789", DDYQRCodeConfig()) { (image, code, message) in }
	    ///
	    /// - Parameters:
	    ///   - inputStr: 要转换成条形码的字符串(128码只允许ASCII中0-127的128个字符,长度最好20个字符内)
	    ///   - config: 配置
	    ///   - closure: 闭包回掉(逃逸闭包)
	    public static func ddyBarCode(_ inputStr: String?,_ config: DDYQRCodeConfig?,_ closure: @escaping DDYQRCodeCreatorClosure) {
	
	        guard let strData = inputStr?.data(using: String.Encoding.utf8), strData.count>0 else {
	            closure(nil, -1, "字符串非法")
	            return
	        }
	        for asciiByte in [UInt8](strData) {
	            if asciiByte > 127 {
	                closure(nil, -1, "字符串非法")
	                return
	            }
	        }
	        guard let size = config?.size else {
	            closure(nil, -2, "size非法")
	            return
	        }
	        guard let color = config?.color else {
	            closure(nil, -3, "前景色非法")
	            return
	        }
	        guard let bgColor = config?.bgColor else {
	            closure(nil, -4, "背景色非法")
	            return
	        }
	        DispatchQueue.global().async {
	            guard let barImg = generateOriginalBarCode(strData) else {
	                closure(nil, -5, "未知错误")
	                return
	            }
	            let colorImg = changeColor(barImg, color, bgColor)
	            let sizeImg = changeSize(colorImg, size)
	            DispatchQueue.main.async {
	                closure(sizeImg, 0, "条形码创建成功")
	            }
	        }
	    }
	
	    /// 生成二维码(可以配置指定大小指定颜色) DDYQRCodeCreator.ddyQRCode("987654321123456789", DDYQRCodeConfig()) { (image, code, message) in }
	    ///
	    /// - Parameters:
	    ///   - inputStr: 要转换成二维码的字符串(长度最好200个字符内, 太多字符导致二维码密度上升，不容易识别)
	    ///   - config: 配置
	    ///   - closure: 闭包回掉(逃逸闭包)
	    public static func ddyQRCode(_ inputStr: String?,_ config: DDYQRCodeConfig?,_ closure: @escaping DDYQRCodeCreatorClosure) {
	
	        guard let strData = inputStr?.data(using: String.Encoding.utf8), strData.count>0 else {
	            closure(nil, -1, "字符串非法")
	            return
	        }
	        guard let size = config?.size else {
	            closure(nil, -2, "size非法")
	            return
	        }
	        guard let color = config?.color else {
	            closure(nil, -3, "前景色非法")
	            return
	        }
	        guard let bgColor = config?.bgColor else {
	            closure(nil, -4, "背景色非法")
	            return
	        }
	        DispatchQueue.global().async {
	            guard let barImg = generateOriginalQRCode(strData) else {
	                closure(nil, -5, "未知错误")
	                return
	            }
	            let colorImg = changeColor(barImg, color, bgColor)
	            let sizeImg = changeSize(colorImg, size)
	            if let logo = config?.logo {
	                let logoImg = addLogo(logo, sizeImg, 0.25)
	                DispatchQueue.main.async {
	                    closure(logoImg, 0, "二维码创建成功")
	                }
	            } else {
	                DispatchQueue.main.async {
	                    closure(sizeImg, 0, "二维码创建成功")
	                }
	            }
	        }
	    }
	}
	
	// MARK:- 生成与处理 私有函数
	extension DDYQRCodeCreator {
	    // MARK: 生成原始条形码
	    private class func generateOriginalBarCode(_ strData: Data!) -> CIImage! {
	        let filter = CIFilter(name: "CICode128BarcodeGenerator")!
	        filter.setDefaults()
	        filter.setValue(strData, forKey: "inputMessage")
	        filter.setValue(NSNumber(floatLiteral: 0), forKey: "inputQuietSpace")
	        return filter.outputImage
	    }
	
	    // MARK: 生成原始二维码
	    private class func generateOriginalQRCode(_ strData: Data!) -> CIImage! {
	        let filter = CIFilter(name: "CIQRCodeGenerator")!
	        filter.setDefaults()
	        filter.setValue(strData, forKey: "inputMessage")
	        filter.setValue("H", forKey: "inputCorrectionLevel")
	        return filter.outputImage
	    }
	
	    // MARK: 改变前景和背景色
	    private class func changeColor(_ img: CIImage!,_ color: UIColor!,_ bgColor: UIColor!) -> CIImage! {
	        let filter = CIFilter(name: "CIFalseColor")!
	        filter.setDefaults()
	        filter.setValue(img, forKey: "inputImage")
	        filter.setValue(CIColor(cgColor: bgColor.cgColor), forKey: "inputColor0")
	        filter.setValue(CIColor(cgColor: color.cgColor), forKey: "inputColor1")
	        return filter.outputImage
	    }
	
	    // MARK: 改变宽高
	    private class func changeSize(_ img: CIImage!,_ size: CGSize!) -> UIImage! {
	
	        let extent = img.extent.integral
	        let scale = min(size.width/extent.width, size.height/extent.height)
	        let width = extent.width * scale
	        let height = extent.height * scale
	        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
	        let contentRef = CGContext.init(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpaceRef, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue | CGImageByteOrderInfo.order32Little.rawValue)!
	        let context = CIContext(options: nil)
	        let imageRef = context.createCGImage(img, from: extent)!
	        contentRef.interpolationQuality = CGInterpolationQuality.none
	        contentRef.scaleBy(x: scale, y: scale)
	        contentRef.draw(imageRef, in: extent)
	        let imageRefResized = contentRef.makeImage()
	        return UIImage(cgImage: imageRefResized!)
	    }
	    /** 灰度图
	     let colorSpaceRef = CGColorSpaceCreateDeviceGray()
	     let contentRef = CGContext.init(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpaceRef, bitmapInfo: 0)!
	     */
	
	    // MARK: 二维码添加logo
	    private class func addLogo(_ logo: UIImage!,_ img: UIImage!,_ scale: CGFloat) -> UIImage! {
	        let newScale = max(min(scale, 0.5), 0)
	        let logoW = img.size.width * newScale
	        let logoX = (img.size.width-logoW) / 2.0
	        UIGraphicsBeginImageContext(img.size)
	        img .draw(in: CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height))
	        logo.draw(in: CGRect(x: logoX, y: logoX, width: logoW, height: logoW))
	        let resultImg = UIGraphicsGetImageFromCurrentImageContext()
	        UIGraphicsEndImageContext()
	        return resultImg
	    }
	}
	
	```	
	
* ### 识别

	分为相机识别和图片(相册)识别，由于编码和容错问题，并不能保证识别所有二维码(条形码)
	
	```
	import UIKit
	import Photos
	import AVFoundation
	import AudioToolbox
	
	@objc protocol DDYQRCodeScannerDelegate: NSObjectProtocol {
	    /// 扫描结果代理方法 errorCode意义 0:成功 -1:相机扫描未发现二维码 -2:图片扫描未发现二维码 -3:未知错误
	    @objc optional func ddyQRCodeScanResult(_ resultStr: String?,_ errorCode: Int,_ errorMessage: String)
	    /// 光强检测代理方法
	    @objc optional func ddyQRCodeBrightnessValue(_ brightnessValue: Double)
	}
	/// errorCode意义 0:成功 -1:相机扫描未发现二维码 -2:图片扫描未发现二维码 -3:未知错误
	typealias DDYQRScanResultClosure = (_ resultStr: String?,_ errorCode: Int,_ errorMessage: String) -> Void
	/// 光强检测闭包起别名
	typealias DDYQRBrightnessClosure = (_ brightnessValue: Double) -> Void
	
	final class DDYQRCodeScanner: NSObject {
	    // 扫描结果代理回掉(优先代理)
	    weak var qrCodeDelegate: DDYQRCodeScannerDelegate?
	    // 扫描结果闭包回掉(优先代理)
	    public var scanResultClosure: DDYQRScanResultClosure?
	    // 光强检测数据闭包回调
	    public var brightnessClosure: DDYQRBrightnessClosure?
	    // 会话(输入输出中间桥梁)
	    fileprivate lazy var captureSession: AVCaptureSession = AVCaptureSession()
	
	    /// 相机扫描二维码
	    ///
	    /// - Parameters:
	    ///   - preview: 预览视图
	    ///   - effectiveRect: 有效识别范围
	    public func ddyQRCode(_ preview: UIView,_ effectiveRect: CGRect) {
	        // 会话指定质量
	        if captureSession.canSetSessionPreset(.high) {
	            captureSession.sessionPreset = .high
	        }
	        // 视频输入
	        guard let device = AVCaptureDevice.default(for: .video) else {
	            return
	        }
	        guard let videoInput = try? AVCaptureDeviceInput(device: device) else {
	            return
	        }
	        if captureSession.canAddInput(videoInput) {
	            captureSession.addInput(videoInput)
	        }
	        // 自动对焦
	        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
	            try? videoInput.device.lockForConfiguration()
	            videoInput.device.focusMode = .autoFocus
	            videoInput.device.unlockForConfiguration()
	        }
	        let ddyQRCodeQueue = DispatchQueue(label: "ddy.QRCode.serialQueue")
	        // 元数据输出
	        let metadataOutput = AVCaptureMetadataOutput()
	        metadataOutput.setMetadataObjectsDelegate(self, queue: ddyQRCodeQueue)
	        metadataOutput.rectOfInterest = effectiveRect // 有效识别范围
	        if captureSession.canAddOutput(metadataOutput) {
	            captureSession.addOutput(metadataOutput)
	        }
	        // 设置识别类型 必须先加addOutput 并且有权限
	        metadataOutput.metadataObjectTypes = [.upce, .code39, .code39Mod43, .ean13, .ean8, .code93, .code128, .pdf417, .qr, .aztec, .interleaved2of5, .itf14, .dataMatrix]
	        // 光强检测
	        let lightOutput = AVCaptureVideoDataOutput()
	        lightOutput.setSampleBufferDelegate(self, queue: ddyQRCodeQueue)
	        if captureSession.canAddOutput(lightOutput) {
	            captureSession.addOutput(lightOutput)
	        }
	        // 预览层
	        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
	        previewLayer.videoGravity = .resizeAspectFill
	        previewLayer.frame = preview.bounds
	        preview.layer.insertSublayer(previewLayer, at: 0)
	        // 如果需要旋转屏幕则需要改变视频方向
	        // previewLayer.connection?.videoOrientation = .portrait
	        // 开始会话
	        ddyStartRunningSession()
	    }
	
	    public func ddyStartRunningSession() {
	        if captureSession.isRunning == false {
	            captureSession.startRunning()
	        }
	        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(scanTimeout), object: nil)
	        self.perform(#selector(scanTimeout), with: nil, afterDelay: 12)
	    }
	
	    public func ddyStopRunningSession() {
	        if captureSession.isRunning == true {
	            captureSession.stopRunning()
	        }
	        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(scanTimeout), object: nil)
	    }
	
	    @objc fileprivate func scanTimeout() {
	        handleScanResult(nil, -1, "相机扫描未发现二维码")
	    }
	
	    fileprivate func handleScanResult(_ resultStr: String?,_ errorCode: Int,_ errorMessage: String) {
	        if qrCodeDelegate?.responds(to: #selector(DDYQRCodeScannerDelegate.ddyQRCodeScanResult(_:_:_:))) != nil {
	            qrCodeDelegate?.ddyQRCodeScanResult?(resultStr, errorCode, errorMessage)
	        } else if scanResultClosure != nil {
	            scanResultClosure!(resultStr, errorCode, errorMessage)
	        }
	    }
	}
	
	// MARK:- 相机代理
	extension DDYQRCodeScanner: AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
	    // MARK: 扫描结果元数据输出代理实现
	    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
	        if metadataObjects.count > 0 {
	            let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
	            if let resultStr = metadataObject.stringValue {
	                ddyStopRunningSession()
	                handleScanResult(resultStr, 0, "相机扫描二维码成功")
	            }
	        }
	    }
	    // MARK: 光强检测代理实现
	    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
	        // 这里因为只添加了视频输出，没添加音频输出 所以可以不判断 captureOutput 类型
	        let metadataDict = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
	        guard let metadata = metadataDict as? [AnyHashable : Any] else { return }
	        guard let exifMetadata = (metadata[kCGImagePropertyExifDictionary]) as? [AnyHashable : Any] else { return }
	        guard let brightnessValue = exifMetadata[kCGImagePropertyExifBrightnessValue] as? Double else { return }
	        DispatchQueue.main.async {
	            if self.qrCodeDelegate?.responds(to: #selector(DDYQRCodeScannerDelegate.ddyQRCodeBrightnessValue(_:))) != nil {
	                self.qrCodeDelegate?.ddyQRCodeBrightnessValue?(brightnessValue)
	            } else if self.brightnessClosure != nil {
	                self.brightnessClosure!(brightnessValue)
	            }
	        }
	    }
	}
	
	// MARK:- 图片二维码识别
	extension DDYQRCodeScanner: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	    /// 传入图片二维码识别
	    ///
	    /// - Parameter image: 要识别的带有二维码的图片
	    public func ddyQRCode(_ image: UIImage) {
	        DispatchQueue.global().async {
	            if let ciImage: CIImage = CIImage(image: image) {
	                let context = CIContext(options: nil)
	                let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
	                if let featuresArray = detector?.features(in: ciImage) as? [CIQRCodeFeature] {
	                    if featuresArray.count > 0 {
	                        if let resultStr = featuresArray[0].messageString {
	                            DispatchQueue.main.async {
	                                self.handleScanResult(resultStr, 0, "图片扫描二维码成功")
	                                return
	                            }
	                        }
	                    }
	                }
	            }
	            self.handleScanResult(nil, -2, "图片扫描未发现二维码")
	        }
	    }
	
	    /// 相册图片二维码识别
	    ///
	    /// - Parameter currentViewController: 传入当前控制器weak对象用于弹出 imagePicker
	    public func ddyQRCodeWithImagePicker(_ currentViewController: UIViewController?) {
	        if currentViewController != nil {
	            self.performSelector(onMainThread: #selector(presentImagePicker(_:)), with: currentViewController, waitUntilDone: false)
	        }
	    }
	    @objc private func presentImagePicker(_ currentVC: UIViewController) {
	        DispatchQueue.main.async {
	            let imagePicker = UIImagePickerController()
	            imagePicker.sourceType = .photoLibrary
	            imagePicker.delegate = self
	            currentVC.present(imagePicker, animated: true, completion: nil)
	        }
	    }
	
	    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
	        ddyQRCode(info[.originalImage] as! UIImage)
	        picker.dismiss(animated: true, completion: nil)
	    }
	
	    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
	        picker.dismiss(animated: true, completion: nil)
	    }
	}
	
	// MARK:- 权限鉴定与申请
	extension DDYQRCodeScanner {
	
	    /// 相机权限
	    ///
	    /// - Parameter closure: 闭包回调
	    public static func cameraAuth(_ closure: @escaping (Bool) -> Void) -> Void {
	        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
	        switch authStatus {
	        case .notDetermined:
	            AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted: Bool) in
	                DispatchQueue.main.async {
	                    closure(granted)
	                }
	            }
	            break
	        case .authorized:
	            DispatchQueue.main.async {
	                closure(true)
	            }
	            break
	        default: // case .restricted // case .denied
	            DispatchQueue.main.async {
	                closure(false)
	            }
	            break
	        }
	    }
	
	    /// 相册权限
	    ///
	    /// - Parameter closure: 闭包回调
	    public static func albumAuth(_ closure: @escaping (Bool) -> Void) -> Void {
	        let authStatus = PHPhotoLibrary.authorizationStatus()
	        switch authStatus {
	        case .notDetermined:
	            PHPhotoLibrary.requestAuthorization { (newStatus) in
	                closure((newStatus == PHAuthorizationStatus.authorized))
	            }
	            break
	        case .authorized:
	            DispatchQueue.main.async {
	                closure(true)
	            }
	            break
	        default:
	            DispatchQueue.main.async {
	                closure(false)
	            }
	            break
	        }
	    }
	}
	
	// MARK:- 工具
	extension DDYQRCodeScanner {
	    // MARK:- 绘制扫描边框工具
	    public static func scanRectImage(_ color: UIColor) -> UIImage {
	        let rect = CGRect(x: 0, y: 0, width: 300, height: 300)
	        UIGraphicsBeginImageContext(rect.size)
	        let context = UIGraphicsGetCurrentContext()!
	
	        context.setStrokeColor(color.cgColor) // 设置描边颜色
	        context.setLineWidth(6.0) //线的宽度
	        context.setLineCap(.square)  //顶端为方形
	        context.setLineJoin(.miter) //拐角为尖角
	
	        // 左上
	        context.move(to: CGPoint(x: 20, y: 0))
	        context.addLine(to: CGPoint(x: 0, y: 0))
	        context.addLine(to: CGPoint(x: 0, y: 20))
	
	        // 右上
	        context.move(to: CGPoint(x: 300 - 20, y: 0))
	        context.addLine(to: CGPoint(x: 300, y: 0))
	        context.addLine(to: CGPoint(x: 300, y: 20))
	
	        // 左下
	        context.move(to: CGPoint(x: 0, y: 300 - 20))
	        context.addLine(to: CGPoint(x: 0, y: 300))
	        context.addLine(to: CGPoint(x: 20, y: 300))
	
	        // 右下
	        context.move(to: CGPoint(x: 300 - 20, y: 300))
	        context.addLine(to: CGPoint(x: 300, y: 300))
	        context.addLine(to: CGPoint(x: 300, y: 300-20))
	
	        context.drawPath(using: .stroke)
	        let img = UIGraphicsGetImageFromCurrentImageContext()!
	        UIGraphicsEndImageContext()
	        return img
	    }
	    // MARK:- 播放成功提示音工具
	    public static func playSound(withResource resource: String) {
	        var soundID: SystemSoundID = 0
	        let soundFile = Bundle.main.path(forResource: resource, ofType: nil)
	        //生成系统声音
	        AudioServicesCreateSystemSoundID(NSURL.fileURL(withPath: soundFile!) as  CFURL, &soundID)
	        //播放提示音 带有震动
	        //      AudioServicesPlayAlertSound(soundID)
	        //播放系统提示
	        AudioServicesPlaySystemSound(soundID)
	    }
	    // MARK: 打开关闭闪光灯--持续亮灯(非拍照闪灯)
	    public static func turnOnTorchLight(_ turnOn: Bool) {
	        guard let device = AVCaptureDevice.default(for: .video) else {
	            return
	        }
	        if device.hasTorch && device.hasFlash {
	            try? device.lockForConfiguration()
	            device.torchMode = turnOn ? AVCaptureDevice.TorchMode.on : AVCaptureDevice.TorchMode.off
	            device.unlockForConfiguration()
	        }
	    }
	}
	
	```	
	