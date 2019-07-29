# Swift10-UIView UILabel UIImageView UIButton 


* ###  UIView

	UIView常用属性
	
	- frame：相对父视图的坐标和大小（x,y,w,h）
	- bounds：相对自身的坐标和大小，所以bounds的x和y永远为0（0,0,w,h）
	- center：相对父视图的中点坐标
	- transform：控制视图的放大缩小和旋转
	- superview：获取父视图
	- subviews：获取所有子视图
	- alpha：视图的透明度（0.0-1.0）
	- tag：视图标志(Int,默认0,最好不要设置1),设置后可通过viewWithTag取到该视图
	
	常用方法
	
	
	- func removeFromSuperview()：将视图从父视图中移除
	- func insertSubview(view:UIView, atIndex index:Int)：指定一个位置插入一个视图，index越小，视图越往下
	- func exchangeSubviewAtIndex(index1:Int, withSubviewAtIndex index2:Int)：将index1和index2位置的两个视图互换位置
	- func addSubview(view:UIView)：添加视图到父视图
	- func insertSubview(view:UIView,belowSubview siblingSubview:UIView)：在指定视图的下面插入视图
	- func insertSubview(view:UIVIew,aboveSubview siblingSubview:UIView)：在指定视图上面插入视图
	- func bringSubviewToFront(view:UIView)：把视图移到最顶层
	- func sendSubviewToBack(view:UIView)：把视图移到最底层
	- func viewWithTag(tag:Int)->UIView?：根据tag值获取视图


可以用Extension UIView实现

```
// MARK:- 手势
    /// 点击手势(默认代理和target相同)
    public func tapGesture(_ target: Any?,_ action: Selector,_ numberOfTapsRequired: Int = 1) {
        let tapGesture = UITapGestureRecognizer(target: target, action: action)
        tapGesture.numberOfTapsRequired = numberOfTapsRequired
        tapGesture.delegate = target as? UIGestureRecognizerDelegate
        ddyValue.isUserInteractionEnabled = true
        ddyValue.addGestureRecognizer(tapGesture)
    }

    /// 长按手势(默认代理和target相同)
    public func longGesture(_ target: Any?,_ action: Selector,_ minDuration: TimeInterval = 0.5) {
        let longGesture = UILongPressGestureRecognizer(target: target, action: action)
        longGesture.minimumPressDuration = minDuration
        longGesture.delegate = target as? UIGestureRecognizerDelegate
        ddyValue.isUserInteractionEnabled = true
        ddyValue.addGestureRecognizer(longGesture)
    }

    /// 圆角与边线
    public func borderRadius(_ radius: CGFloat,_ masksToBounds: Bool,_ borderWidth: CGFloat = 0,_ borderColor: UIColor = UIColor.clear) {
        ddyValue.layer.borderWidth = borderWidth
        ddyValue.layer.borderColor =  borderColor.cgColor
        ddyValue.layer.cornerRadius = radius
        ddyValue.layer.masksToBounds = masksToBounds
    }
    /// 部分圆角
    public func partRadius(_ corners: UIRectCorner,_ radius: CGFloat) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = ddyValue.bounds
        shapeLayer.path = UIBezierPath(roundedRect: ddyValue.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius)).cgPath
        ddyValue.layer.mask = shapeLayer
    }

    /// 移除所有子视图
    public func removeAllChildView() {
        if ddyValue.subviews.isEmpty == false {
            _ = ddyValue.subviews.map { $0.removeFromSuperview() }
        }
    }
```
	
* ### UILabel

	常用属性和方法
	
	```
	let label = UILabel(frame:CGRect(x:10, y:20, width:300, height:100))
	label.textColor = UIColor.white
	label.text = "DDY"
	label.backgroundColor = UIColor.black
	label.preferredMaxLayoutWidth = 100
	label.lineBreakMode = .byTruncatingTail  // 隐藏尾部并显示省略号
	// .byTruncatingMiddle  // 隐藏中间部分并显示省略号
	// .byTruncatingHead  // 隐藏头部并显示省略号
	// .byClipping  //截去多余部分也不显示省略号
	label.adjustsFontSizeToFitWidth = true // 当文字超出标签宽度时，自动调整文字大小，使其不被截断
	// 设置文本高亮
	label.isHighlighted = true
	// 设置文本高亮颜色
	label.highlightedTextColor = UIColor.green
	// 通过富文本来设置行间距
   let paraph = NSMutableParagraphStyle()
   //将行间距设置为28
   paraph.lineSpacing = 20
   //样式属性集合
  	let attributes = [NSFontAttributeName:UIFont.systemFont(ofSize: 15),
                          NSParagraphStyleAttributeName: paraph]
   	label.attributedText = NSAttributedString(string: str, attributes: attributes)
	view.addSubview(label)
	```


	便利构造器扩展

	```
	extension UILabel {
	    /// 便利构造器
	    convenience init(text: String, font: UIFont = UIFont.systemFont(ofSize: 12), textAlignment: NSTextAlignment = .center, numberOfLines: Int = 0) {
	        self.init()
	        self.text = text
	        self.font = font
	        self.textAlignment = textAlignment
	        self.numberOfLines = numberOfLines
	    }
	}
	```
	
	加个内边距调节
	
	```
	private var contentEdgeInsetsKey: Void?
	
	extension DDYWrapperProtocol where DDYT : UILabel {
	
	    var contentEdgeInsets: UIEdgeInsets {
	        get {
	            guard let contentEdgeInsets = objc_getAssociatedObject(ddyValue, &contentEdgeInsetsKey) as? UIEdgeInsets else {
	                return UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
	            }
	            return contentEdgeInsets
	        }
	        set {
	            objc_setAssociatedObject(ddyValue, &contentEdgeInsetsKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
	        }
	    }
	}
	
	extension UILabel {
	    public static func ddySwizzleMethod() {
	        ddySwizzle(#selector(UILabel.textRect(forBounds:limitedToNumberOfLines:)), #selector(ddyTextRect(_:_:)), swizzleClass: self)
	        ddySwizzle(#selector(UILabel.drawText(in:)), #selector(ddyDrawText(in:)), swizzleClass: self)
	    }
	
	    @objc private func ddyTextRect(_ bounds: CGRect,_ numberOfLines: Int) -> CGRect {
	        var rect = self.ddyTextRect(bounds.inset(by: self.ddy.contentEdgeInsets), numberOfLines)
	        rect.origin.x -= self.ddy.contentEdgeInsets.left;
	        rect.origin.y -= self.ddy.contentEdgeInsets.top;
	        rect.size.width += self.ddy.contentEdgeInsets.left + self.ddy.contentEdgeInsets.right;
	        rect.size.height += self.ddy.contentEdgeInsets.top + self.ddy.contentEdgeInsets.bottom;
	        return rect
	    }
	    
	    @objc private func ddyDrawText(in rect: CGRect) {
	        self.ddyDrawText(in: rect.inset(by: self.ddy.contentEdgeInsets))
	    }
	}
	```
	
* ### UIImageView 

	常用属性和方法
	
	```
	let imageView = UIImageView()
	imageView.animationImages = imagesArray
	imageView.animationRepeatCount = 0
	imageView.animationDuration = 5 * 0.5
	imageView.startAnimating()
	imageView.contentMode = .scaleAspectFit
	view.addSubview(imageView)
	```
	
	如果使用kingfisher加载网络图片
	
	```
	imageView.kf.setImage(with: url, placeholder: image)
	
	// 如果需要圆角
	let processor = RoundCornerImageProcessor(cornerRadius: 20)
	imageView.kf.setImage(with: url, placeholder: nil, options: [.processor(processor)])
	```
	
* ### UIButton

	- UIButtonType     
	.system：前面不带图标，默认文字颜色为蓝色，有触摸时的高亮效果     
	.custom：定制按钮，前面不带图标，默认文字颜色为白色，无触摸时的高亮效果    
	.contactAdd：前面带“+”图标按钮，默认文字颜色为蓝色，有触摸时的高亮效果   
	.detailDisclosure：前面带“!”图标按钮，默认文字颜色为蓝色，有触摸时的高亮效果   
	.infoDark：为感叹号“!”圆形按钮(iOS7后同detailDisclosure)   
	.infoLight：为感叹号“!”圆形按钮(iOS7后同detailDisclosure)
	
	- UIControl.State    
	highlighted: 高亮   
   	disabled: 禁用   
	selected: 选中  
	
	- UIControl.Event    
	touchDown：单点触摸按下事件，点触屏幕   
	touchDownRepeat：多点触摸按下事件，点触计数大于1，按下第2、3或第4根手指的时候   
	touchDragInside：触摸在控件内拖动时   
	touchDragOutside：触摸在控件外拖动时   
	touchDragEnter：触摸从控件之外拖动到内部时   
	touchDragExit：触摸从控件内部拖动到外部时   
	touchUpInside：在控件之内触摸并抬起事件   
	touchUpOutside：在控件之外触摸抬起事件   
	touchCancel：触摸取消事件，即一次触摸因为放上太多手指而被取消，或者电话打断     

	常用属性和方法
	
	```
	let button = UIButton(type: .custom) // 自定义按钮
	button.setTitle("普通状态", for:.normal) // 文字
	button.setTitleColor(UIColor.black, for: .normal) // 文本颜色
	button.setTitleShadowColor(UIColor.green, for:.normal) // 文本阴影颜色
	button.titleLabel?.shadowOffset = CGSize(width: -1.5, height: -1.5) // 文本阴影偏移
	button.titleLabel?.font = UIFont(name: "Zapfino", size: 13) // 字体字号
	button.adjustsImageWhenHighlighted=false // 使触摸模式下按钮也不会变暗（半透明）
	button.adjustsImageWhenDisabled=false // 使禁用模式下按钮也不会变暗（半透明）
	button.setImage(UIImage(named:"icon")?.withRenderingMode(.alwaysOriginal), for:.normal) //无渲染图片
	button.setBackgroundImage(UIImage(named:"bg1"), for:.normal) // 背景图片
	//传递触摸对象（即点击的按钮），需要在定义action参数时，方法名称后面带上冒号
	button.addTarget(self, action:#selector(tapped(_:)), for:.touchUpInside)
 
 	// 事件
	@objc func tapped(_ button:UIButton){
     	print(button.title(for: .normal))
	}
	```

	UIButton扩展
	
	```
	public enum DDYButtonStyle: Int {
	    case defaultStyle   = 0 // 默认效果(为了处理无调用状态，不可赋值)
	    case imageLeft      = 1 // 左图右文
	    case imageRight     = 2 // 右图左文
	    case imageTop       = 3 // 上图下文
	    case imageBottom    = 4 // 下图上文
	}
	
	private var styleKey: Void?
	private var paddingKey: Void?
	
	extension DDYWrapperProtocol where DDYT : UIButton {
	    /// 设置图文样式(不可逆，一旦设置不能百分百恢复系统原来样式)
	    var style: DDYButtonStyle {
	        get {
	            guard let style = objc_getAssociatedObject(ddyValue, &styleKey) as? DDYButtonStyle else {
	                return .defaultStyle
	            }
	            return style
	        }
	        set {
	            objc_setAssociatedObject(ddyValue, &styleKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	            ddyValue.layoutIfNeeded()
	        }
	    }
	
	    var padding: CGFloat {
	        get {
	            guard let padding = objc_getAssociatedObject(ddyValue, &paddingKey) as? CGFloat else {
	                return 0.5
	            }
	            return padding
	        }
	        set {
	            objc_setAssociatedObject(ddyValue, &paddingKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	            ddyValue.layoutIfNeeded()
	        }
	    }
	
	    public func setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
	        guard let color = color else {
	            return
	        }
	        func colorImage() -> UIImage? {
	            let rect = CGRect(x: 0.0, y: 0.0, width: 1, height: 1)
	            UIGraphicsBeginImageContext(rect.size)
	            let context = UIGraphicsGetCurrentContext()
	            context?.setFillColor(color.cgColor)
	            context?.fill(rect)
	            let image = UIGraphicsGetImageFromCurrentImageContext()
	            UIGraphicsEndImageContext()
	            return image ?? nil
	        }
	        ddyValue.setImage(colorImage(), for: state)
	    }
	}
	
	extension UIButton {
	    public static func ddySwizzleMethod() {
	        ddySwizzle(#selector(layoutSubviews), #selector(ddyLayoutSubviews), swizzleClass: self)
	    }
	
	    @objc private func ddyLayoutSubviews() {
	        self.ddyLayoutSubviews()
	        adjustRect(margin: (contentEdgeInsets.top, contentEdgeInsets.left, contentEdgeInsets.bottom, contentEdgeInsets.right))
	
	    }
	
	    private func adjustRect(margin:(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat)) {
	        guard let imageSize = self.imageView?.frame.size, let titleSize = self.titleLabel?.frame.size else {
	            return
	        }
	        guard imageSize != CGSize.zero && titleSize != CGSize.zero else {
	            return
	        }
	        func horizontal(_ leftView: UIView,_ rightView: UIView) {
	            let contentW = leftView.frame.width + self.ddy.padding + rightView.frame.width
	            let contentH = max(leftView.frame.height, rightView.frame.height)
	            let leftOrigin = CGPoint(x: margin.left, y: (contentH-leftView.frame.height)/2.0 + margin.top)
	            let rightOrigin = CGPoint(x: margin.left + leftView.frame.width + self.ddy.padding, y: (contentH-rightView.frame.height)/2.0 + margin.top)
	
	            self.bounds = CGRect(x: 0, y: 0, width: contentW + margin.left + margin.right, height: contentH + margin.top + margin.bottom)
	            leftView.frame = CGRect(origin: leftOrigin, size: leftView.frame.size)
	            rightView.frame = CGRect(origin: rightOrigin, size: rightView.frame.size)
	        }
	        func vertical(_ topView: UIView,_ bottomView: UIView,_ backSize: CGSize) {
	            let contentW = max(max(topView.frame.width, bottomView.frame.width), backSize.width-margin.left-margin.right)
	            let contentH = max(topView.frame.height + self.ddy.padding + bottomView.frame.height, backSize.height-margin.top-margin.bottom)
	            let topOrigin = CGPoint(x: (contentW-topView.frame.width)/2.0 + margin.left, y: margin.top)
	            let bottomOrigin = CGPoint(x: (contentW-bottomView.frame.width)/2.0 + margin.left, y: margin.top + topView.frame.height + self.ddy.padding)
	
	            self.bounds = CGRect(x: 0, y: 0, width: contentW + margin.left + margin.right, height: contentH + margin.top + margin.bottom)
	            topView.frame = CGRect(origin: topOrigin, size: topView.frame.size)
	            bottomView.frame = CGRect(origin: bottomOrigin, size: bottomView.frame.size)
	            print("layout: \(self.bounds) \(topView.frame) \(bottomView.frame)")
	        }
	
	        print("0000: \(self.bounds) \(self.imageView!.frame) \(self.titleLabel!.frame)")
	        titleLabel?.sizeToFit()
	        switch self.ddy.style {
	        case .imageLeft: horizontal(self.imageView!, self.titleLabel!)
	        case .imageRight: horizontal(self.titleLabel!, self.imageView!)
	        case .imageTop: vertical(self.imageView!, self.titleLabel!, self.frame.size)
	        case .imageBottom: vertical(self.titleLabel!, self.imageView!, self.frame.size)
	        default: return
	        }
	    }
	}      
	```