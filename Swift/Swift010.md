# Swift10-UIView UILabel UIButton 


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