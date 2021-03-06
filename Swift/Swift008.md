# Swift8-琐碎知识点

* ### 三方库一处引入，处处使用
	
	```
	// 可以建立一个文件放进去，如 Const.swift
	@_exported import IQKeyboardManagerSwift
	@_exported import Alamofire
	@_exported import Moya
	@_exported import Kingfisher
	@_exported import SnapKit
	@_exported import SwiftyJSON
	@_exported import ObjectMapper
	```
	
* ### 几种定时器

1. Timer   

	```
	// 创建方式1 自动加入runloop
	timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerRun), userInfo: nil, repeats: true)
	
	// 创建方式2 手动加入runloop 
	timer = Timer.init(timeInterval: 1, target: self, selector: #selector(timerRun), userInfo: nil, repeats: true)
 	RunLoop.current.add(timer!, forMode: .default)
 	
 	// 创建方式3 自动加入runloop iOS10后block回调
 	timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer: Timer) in
  		weakSelf?.timerRun()
	})
	
 	// 创建方式4 手动加入runloop iOS10后block回调
 	timer = Timer.init(timeInterval: 1, repeats: true, block: { (timer: Timer) in
  		weakSelf?.timerRun()
	})
	RunLoop.current.add(timer!, forMode: .default)
	// 还有其他API，暂时用不到，不做太多说明
	let timerFireDate = Date.init(timeIntervalSinceNow: 79)
   let timer = Timer.init(fireAt: timerFireDate, interval: 1, target: self, selector: #selector (timerRun), userInfo: nil, repeats: true)
   RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
   timer.fire()
   	
   	@objc func timerRun() {
   		print("timerRun \(Date())")
   	}
	```
	
	方式1和方式2带来一个严重的问题--循环引用导致内存泄漏[参考苹果文档](https://developer.apple.com/documentation/foundation/timer)    
	由于内部获取传入的target对象的指针并强引用该对象，再加上runloop对timer的强引用，必然导致循环引用。    
	即使声明局部变量(runloop--target--timer三者关系并没有破坏)，即使再加上用weak形式(weak对象和原对象地址相同)，也改变不了循环引用问题的存在
	方式3和方式4由于采用了block回调的方式，变相的将target编程timer自己，从而阻断了闭环，解决了循环引用问题，但只适用于iOS10及以后系统
	要想兼容性的(主要iOS8-iOS9)解决就要另选方案  
	
	解决方案
	
	写Timer的扩展，实现类似iOS10以后的block回调形式(内部判断，版本满足iOS10则直接调用系统block形式，不满足则自己转换成block形式)
	
	```
	extension Timer {
	
		public static func ddyScheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
			if #available(iOS 10, *) {
				return scheduledTimer(withTimeInterval: interval, repeats: repeats, block: { block($0) })
			} else {
            	return scheduledTimer(timeInterval: interval, target: self, selector: #selector(ddyTimerInvoke(_:)), userInfo: block, repeats: repeats)
        	}
    	}

		public class func ddyInit(timeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void)  -> Timer {
        	if #available(iOS 10, *) {
            	return self.init(timeInterval: interval, repeats: repeats, block: { block($0) })
        	} else {
            	return self.init(timeInterval: interval, target: self, selector: #selector(ddyTimerInvoke(_:)), userInfo: block, repeats: repeats)
        	}
    	}

    	@objc static func ddyTimerInvoke(_ timer: Timer) {
        	if let block = timer.userInfo as? (Timer) -> Void {
            	block(timer)
        	}
   		}
	}
	
	```
	
	也可以仿照OC中NSProxy方案，引入中间人，进行转发
	
	异步子线程中使用Timer
	
	```
	DispatchQueue.global().async {
		// 如果timer为全局变量，需要用weak形式
		let timer = Timer.ddyInit(timeInterval: 1, repeats: true, block: { (timer: Timer) in
			weakSelf?.timerRun()
		})
 		RunLoop.current.add(timer, forMode: .default)
		// 子线程(异步情况)默认无执行的runloop
		RunLoop.current.run()
  	}
	```
	
	切后台定时器停止解决方案
	
	```
	// 后台任务标识
	var backgroundTask:UIBackgroundTaskIdentifier! = nil

	func applicationDidEnterBackground(_ application: UIApplication) {
		// 延迟程序静止的时间
     	DispatchQueue.global().async() {
			//如果已存在后台任务，先将其设为完成
         	if self.backgroundTask != nil {
				application.endBackgroundTask(self.backgroundTask)
             	self.backgroundTask = UIBackgroundTaskInvalid
         	}
     	}
        
     	//如果要后台运行
     	self.backgroundTask = application.beginBackgroundTask(expirationHandler: { () -> Void in
			//如果没有调用endBackgroundTask，时间耗尽时应用程序将被终止
        	 application.endBackgroundTask(self.backgroundTask)
         	self.backgroundTask = UIBackgroundTaskInvalid
     	})
 	}
	```
		
 
2. dispatchSourceTimer（GCD定时器）  

	```
	private class func testGCDTimer() {
		// 倒计时总次数
		var timeCount = 20
		// 自定义并发队列
		let concurrentQ = DispatchQueue(label: "com.ddy.timer", attributes: .concurrent)
		// 在自定义队列的定时器
		let timer = DispatchSource.makeTimerSource(flags: [], queue: concurrentQ)
		// 设置立即开始 0.5秒循环一次
		timer.schedule(deadline: .now(), repeating: 0.5)
		// 触发回调事件
		timer.setEventHandler {
			timeCount = timeCount - 1
			if timeCount <= 0 {
				timer.cancel()
			}
			DispatchQueue.main.async {
				print("主线程更新UI \(timeCount)")
			}
		}
		// cancel事件回调
		timer.setCancelHandler {
			DispatchQueue.main.async {
				print("已结束I \(timeCount)")
			}
		}
		// 启动定时器
		timer.resume()
	}
	```

3. CADisplayLink 

	CADisplayLink 是一种触发频率和屏幕刷新频率相同的高精度定时器。 

	```
	private func testCADisplayLink() {

		let displayLink = CADisplayLink.init(target: self, selector: #selector(handleDisplayLink(_:)))
		// 设置触发频率
		if #available(iOS 10, *) {
			// 每秒多少帧，设置0则默认60，即是一秒内有60帧执行刷新调用。
			displayLink.preferredFramesPerSecond = 30
      	} else {
    		// 每多少帧调用一次
 			displayLink.frameInterval = 2
 		}
 		displayLink.add(to: RunLoop.main, forMode: .default)
	}

	@objc func handleDisplayLink(_ displayLink:CADisplayLink) -> Void {
 		// 当前帧开始刷新的时间
 		print(displayLink.timestamp)
 		// 一帧刷新使用的时间
      	print(displayLink.duration)
      	// 下一帧开始刷新的时间
      	print(displayLink.targetTimestamp)
     	// duration  = targetTimestamp - timestamp 
     	// 暂停帧的刷新 true:停 ; false:开始
     	displayLink.isPaused = true
    	// 将定时器移除主循环
     	displayLink.remove(from: RunLoop.main, forMode: .default)
    	// 停止定时器
     	displayLink.invalidate()
 	}
	```
	
* ### 结构体(struct) 和 类(class) 的区别

	swift中     

	- class是引用类型，struct是值类型。    
		值类型在传递和赋值时将进行复制，而引用类型则只会使用引用对象的一个"指向"。所以他们两者之间的区别就是两个类型的区别。
	- class 可以继承，这样子类可以使用父类的特性和方法
	- class 可以被多次引用
	- struct 更轻量级，适用于复制操作，相比于一个class的实例被多次引用更加安全。
无须担心内存memory leak或者多线程冲突问题


	C语言中    
	
	- struct只是作为一种复杂数据类型定义，不能用于面向对象编程。
	
	C++中
	
	- 对于成员访问权限以及继承方式，class默认private的，而struct是public的。
	- class还可以用于表示模板类型，struct则不行

* ### 2B程序员 普通程序员 大神程序员

	交换数组中索引下标m和n处两个数的位置(m,n均不会越界)
	
	```
	// 2B程序员
	func swap1(_ numberArray: inout Array<Int>, _ m: Int, _ n: Int) {
		let temp = numberArray[m]
		numberArray[m] = numberArray[n]
		numberArray[n] = temp
	}
	// 普通程序员
	func swap2<T>(_ array: inout [T], _ m: Int, _ n: Int) {
		let temp = array[m]
		array[m] = array[n]
		array[n] = temp
	}
	// 大神程序员
	func swap3<T>(_ nums: inout [T], _ m: Int, _ n: Int) {
		(nums[m], nums[n]) = (nums[n], nums[m])
	}	
	
	// 调用
	var numberArray = [1, 2, 3, 4, 5]
   	swap1(&numberArray, 1, 2)
	// swap2(&numberArray, 1, 2)
	// swap3(&numberArray, 1, 2)
	```
	
	输入一个整数，输出其加10后的数字
	
	```
	// 2B程序员
	func add1(_ number: Int) -> Int {
		return number + 10
	}
	// 普通程序员
	func add2(_ number: Int, add number2: Int) -> Int {
		return number + number2
	}
	// 大神程序员
	func add3(_ number: Int) ->(Int) -> Int {
		return { number2 in
			return number + number2
		}
	}
	
	// 调用
	let num1 = add1(2)
	let num2 = add2(2, add: 10)
	let num3 = add3(2)(10)
	print("\(num1) \(num2) \(num3)")
	```

	敲黑板，划重点
	
	1. inout关键字
		swift有两种参数传递方式    
		值传递: 传递的参数是副本，调用参数过程不影响原始数据     
		指针传递: 把参数内存地址传递过去，调用过程会影响原始数据     
		
		class默认指针传递，Int,Float,Bool,Character,Array,Set,Dictionary,enum,struct默认值传递;       
		想将值传递参数变成引用方式指针传递,用inout关键字实现。
		
		注    
		函数声明中参数用inout修饰以达到函数内部改变外部传入的参数，在调用时变量前加 & 符号;          
		参数被inout修饰，就不用var和let修饰了。
	2. 范型       
		当函数只是传入参数类型不同，其他都相同，此时不用具体类型，而用范型    
	3. 元组   
		元组能简洁的交换两个变量值   
	4. Currying(柯里化)    
		通过局部套用(部分求值)实现多参变单参的函数式思想     
		其特点为:只用表达式(单纯运算过程，总是有返回值)，不用语句(执行某种操作，没有返回值)，不修改值，只返回新值。   
		  
		优点：    
		- 代码简洁    
		- 提高代码复用性    
		- 代码管理方便，相互之间不依赖，每个函数都 是一个独立的模块，很容易进行单元测试。   
		- 易于“并发编程”,因为不修改变量的值，都是返回新值。   
		- 最大的好处就是能把函数当参数用!!  
	[参考](https://www.jianshu.com/p/fc8c13ce7157) 
	
* ### 一些关键字

	let: 常量声明关键字
	
	```
	class ClassA {
    	let number: Int
    	init(num: Int) {
        	// 在 init 里对 let 声明的常量进行一次赋值(number此时还没有实例化)
        	number = num
    	}
	}
	```
	
	var: 变量声明关键字
	
	```
	var name: String?
	name = "LiLei"
	``` 
	
	class: 类声明关键字
	
	```
	class ClassB {
	
	}
	```
	struct:结构体声明关键字
	
	```
	struct StructC {
	
	}
	```
	
	enum: 枚举声明关键字
	
	```
	enum Alignment {
    	case left
    	case center
    	case right
	}
	```
	
	override:重写关键字(方法和属性)
	
	```
	class student: Person {
    	override var name: String {
      		return "LiLei"
    	}
    	override func age() -> Int {
         	return 18
    	}
	}
	```
	
	final: 防止重写(方法/属性)或继承(类)关键字
	
	```
	final class student {
		print("如果继承,报错Inheritance from a final class 'student'")
	}
	class Name {
    	final var name :String {
        	return "LiLei"
    	}
    	final func age() -> Int {
        	return 18
    	}
	}
	```
	
	super: 子类调用父类中方法或属性关键字
	
	```
	override func viewDidLoad() {
        super.viewDidLoad()
        print("super是编译器符号，代表该子类而不是父类")
    }
	```
	
	lazy:懒加载关键字
	
	```
	lazy var scanLineView: UIImageView = {
        let scanLine = UIImageView()
        return scanLine
    }()
    
    var  name = "ss"
    lazy var address = name
	```
	
	init:初始化关键字(构造器)
	
	```
	var name:String?
   init?(value:Any) { // ? 表示可以初始化失败
     	name = value as? String
   }
	```
	
	deinit:反初始化关键字(析构)
	
	```
	deinit {
      	print("反初始化")
   }
	```
	
	is: 对比关键字
	
	```
	if value is String {
    	print("我是字符串")
   	}
	```
	
	convenience: 便利构造器关键字
	
	- 指定构造方法(Designated): 没有convenience单词,必须对所有属性进行初始化
	- 便利构造方法(Convenience): 有convenience单词,不用对所有属性进行初始化，因为便利构造方法依赖于指定构造方法。
	
	便利构造函数的特点：  
  	1、便利构造函数通常都是写在extension里面  
  	2、便利函数init前面需要加载convenience   
 	3、在便利构造函数中需要明确的调用self.init() 
 	
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
 	
 	required: 必须实现关键字
 	
 	```
 	class requiredClass{
    	required init(ss:String) {
       	print("常用于修饰init，代表必须实现该init")
    	}
	}
 	```
 	
 	extension:扩展关键字
 	
 	```
 	extension String {
 	
 	}
 	```
 	
 	typealias:起别名关键字(命名空间)
 	
 	```
 	typealias MyInt = Int
 	
 	typealias DDYClosure = (_ str: String?,_ errorCode: Int) -> Void
 	```
 	
 	fallthrough:继续执行关键字(swift 中switch自带break)
 	
 	```
 	switch age {
	case 17:
	   print("17")
    	fallthrough
	case 18:
    	print("18")
    	fallthrough
	default:
    	print("1000")
	}
 	```
 	
 	与声明有关的关键字: 
 	
 	```    
 	import,class,enum,struct,extension,protocol,        
 	init,deinit,func,var,let, typealias,       
 	fileprivate,private,internal,public,open,   
 	static,operator,subscript, 
 	```    
 	
 	与语句有关的关键字:  
 	  
 	```
 	if,else,for,while,do,switch,     
 	where,in,case,    
 	break,return,fallthrough,
 	```   
 	
 	表达式和类型关键字:   
 	
 	```
 	as,dynamicType,true,false,is,nil,    
 	self,Self,super, 
 	_COLUMN_, _FILE_, _FUNCTION_, _LINE_
 	```
 	
 	在特定上下文中使用的关键字
 	
 	```
 	associativity,convenience,dynamic	didSet,final,get,
 	infix,inout,lazy,left,mutating,none,nonmutating,
 	optional,override,postfix,precedence,prefix,weak
 	Protocol,required,right,set,Type,unowned,willSet
 	```
 	
 	dynamic关键字
 	
	如果有过OC的开发经验，那一定会对OC中@dynamic关键字比较熟悉，它告诉编译器不要为属性合成getter和setter方法。    
	Swift中也有dynamic关键字，它可以用于修饰变量或函数，它的意思也与OC完全不同。它告诉编译器使用动态分发而不是静态分发。OC区别于其他语言的一个特点在于它的动态性，任何方法调用实际上都是消息分发，而Swift则尽可能做到静态分发。   
	因此，标记为dynamic的变量/函数会隐式的加上@objc关键字，它会使用OC的runtime机制。  
	虽然静态分发在效率上可能更好，不过一些app分析统计的库需要依赖动态分发的特性，动态的添加一些统计代码，这一点在Swift的静态分发机制下很难完成。这种情况下，虽然使用dynamic关键字会牺牲因为使用静态分发而获得的一些性能优化，但也依然是值得的。   
 	
* ### 单例

	```
	class SharedInstanceTest: NSObject {
		// swift显式去掉了dispatch_one函数，但是内部lazy却隐式用了
		// swift仿照OC单例写法
    	static let instance = SharedInstanceTest()
    	class func sharedInstance() -> SharedInstanceTest {
        	return instance
    	}

    	// 内部结构体写法
    	static var defaultInstance: SharedInstanceTest {
        	struct Static {
            	static let sharedInstance = SharedInstanceTest()
        	}
        	return Static.sharedInstance;
    	}

    	// 简便写法(推荐)
    	static let `default` = SharedInstanceTest()

    	// 防止外部调用init初始化
    	private override init() { }
    	// https://www.jianshu.com/p/10d6cc302366
	}
	```
 	
 	
 	
 	
* ### debugPrint	  

	如果想只在debug模式打印，而不去配置build configuration可以这么用

 
	 ```
	 func DDYPrint<M>(_ message: M) {
	    if _isDebugAssertConfiguration() {
	        print("\(message)")
	    }
	}
	 ```
	 
* ### 去除UIView(特别UILabel)上莫名其妙多出的横线

	```
	// OC	
	// CGRectIntegral(this_frame)
	// Swift
	this_frame.integral
	```
	
* ### 去除滚动可能出现的诡异动画

	```
	CATransaction.begin() 
	CATransaction.setDisableActions(true)
	// 滚动到最后一行
	scrollToRow(at: IndexPath(item: letterDetailVMArr.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
	CATransaction.commit() 
	```
	[参考](https://blog.csdn.net/Felicity294250051/article/details/84069002)
 
 
		
[上一页 Swift7-高阶函数 map flatMap compactMap filter reduce](https://github.com/DDYSwift/LearnSwift/blob/master/Swift/Swift007.md)    
[下一页 Swift9-加密](https://github.com/DDYSwift/LearnSwift/blob/master/Swift/Swift009.md)