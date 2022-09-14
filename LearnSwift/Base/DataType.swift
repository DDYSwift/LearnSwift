import Foundation
import os

class DataType {
    public class func test() {
        self.testCreateDictSomeMethod()
    }
    
    // Swift 包含了 Objective-C 上所有基本数据类型，另外还增加了高阶数据类型，如元组(Tuple)，还增加了可选类型(Optional)
    // MARK: - 常量&变量
    private func test1() {
        // 常量用let声明
        let dataTypeLet = "let" // 类型推断，根据所赋值得到类型String，等同于 let dataTypeLet: String = "let"
        // 变量用var声明
        var dataTypeVar = "var"
        dataTypeVar = "changed"
        print("\(dataTypeLet) \(dataTypeVar)")
    }

    // MARK: - 整型
    private func test2() {
        // MARK: 有符号整型: Int，Int8，Int16，Int32，Int64
        // MARK: 无符号整型: UInt，UInt8，UInt16，UInt32，UInt64
        // MARK: 兼容NS框架: NSInteger
        let age: UInt = 18 // 如果不显式声明数据类型为UInt则类型推导得到类型为Int
        var count: Int = 10086 // Int在64位平台上和Int64等同，在32位平台和Int32等同
        count = 1008611
        // MARK: arc4random() 这个全局顶级函数会生成10位数的随机整数（UInt32）。其生成的最大值是4294967295（2^32 - 1），最小值为0
        // 生成一个 1~100 的随机数(包括1和100)
        let random1 = Int(arc4random() % 100) + 1
        let random2 = Int(arc4random_uniform(100)) + 1
        print("\(age) \(count) \(random1) \(random2)")
    }
    
    // MARK: - 浮点型
    private func test3() {
        // MARK: Double/Float64: 64位浮点数。存储很大或精度很高的浮点数时使用
        // MARK: Float/Float32: 32位浮点数。精度要求不高时使用
        let score: Float = 99.5
        let velocity: Double  = 10.33333
        // MARK: 为增强大数可读性，Swift增加了下划线来分隔数字(整数、浮点数)
        let num1 = 10_000_000_000
        let num2 = 1_000_000.000_000_1
        let num3: Int = 1_0_0_0_1
        print("\(score) \(velocity) \(num1) \(num2) \(num3)")
    }
    
    // MARK: - 布尔型
    private func test4() {
        // MARK: Bool: 用来表示逻辑上真(true)与假(false)，但不能用0和非0表示
        var isSelected: Bool = false
        isSelected = true
        print(isSelected)
    }
    
    // MARK: - 字符型
    private func test5() {
        // MARK: Character: 一般指单个字符
        let firstChar: Character = "C"
        // MARK: 字符串 String: 是字符的序列集合  NSString: 兼容NS框架字符串
        var city = "BeiJing"
        // 用\(str) 方式包裹变量常量
        let message = "Welcome to \(city)"
        // 更改city为"ShangHai"但message中仍为"BeiJing"
        city = "ShangHai"
        // MARK: String和NSString比较
        // String 是一个结构体，性能更高
        // NSString 是一个OC类，性能略差
        // String 支持直接遍历
        print("\(firstChar) \(city) \(message)")
        // 大写
        let changeStr1 = city.uppercased()
        // 小写
        let changeStr2 = city.lowercased()
        // 首字母大写
        let changeStr3 = city.capitalized
        // 判断是否空字符串
        if message.isEmpty == false {
            // message.count得到字符数量
            print("\(message.count)") // 18
            print("\(city)") // ShangHai
            print(message) // Welcome to BeiJing
            print(changeStr1) // SHANGHAI
            print(changeStr2) // shanghai
            print(changeStr3) // Shanghai
        }
        
        // MARK: String截取字符串
        let originalStr = "Welcome to BeiJing"
        // 取前三个字符
        let prefixStr = originalStr.prefix(3) // Wel
        // 取后三个字符
        let suffixStr = originalStr.suffix(3) // ing
        // 取限定范围[3..<6]内字符
        let indexStart = originalStr.index(originalStr.startIndex, offsetBy: 3)
        let indexEnd = originalStr.index(originalStr.startIndex, offsetBy: 6)
        let midStr = originalStr[indexStart..<indexEnd] // com
        // Wel ing com
        print("\(prefixStr) \(suffixStr) \(midStr)")
    }
    
    // MARK: - 数组
    private func testArray() {
        // MARK: Array: 是有序数据的集,分配常量得到不可变数组，分配变量得到可变数组
        // 数组使用有序列表存储同一类型的多个值。相同的值可以多次出现在一个数组的不同位置中
        let arrayM1 = [String]()
        var arrayM2: [String]
        arrayM2 = Array()
        let arrayM3: Array<String> = []
        let arrayM4: [String?] = []
        print("\(arrayM1) \(arrayM2) \(arrayM3) \(arrayM4)")
        // 一个数组的完成类型为：Array<ElementType>。ElementType表示数组中元素的类型
        let array1 = Array<Int>()
        // 一种精简的表示法：Array[ElementType]
        let array2 = [Int]()
        // 声明一个Double类型常量数组，创建10个元素，每个元素都是2.0
        let array3 = [Double](repeating: 2.0, count: 10)
        // 字面量方式声明一个有4个元素的Int类型数组常量
        let array4 = [1, 2, 3, 4]
        // 声明一个有2个元素的 Any 类型数组常量
        let array5 = [1, "two", true, 1.1] as [Any]
        print("\(array1) \(array2) \(array3) \(array4) \(array5)")
        // MARK: Array和NSArray比较
        // Array是一个Swift结构体，性能较高
        // NSArray是一个OC类，性能略差
        // Array可以放普通类型
    }
    
    public class func testHandle() {
        // 声明一个空数组变量（let声明为常量, var声明变量，即可变数组）
        var testArray = [String]()
        // 追加元素 姿势1
        testArray.append("six")
        // 追加元素 姿势2
        testArray += ["seven"]
        // 指定位置添加元素
        testArray.insert("one", at:0)
        // 通过下标修改数组中的数据
        testArray[0] = "message"
        // 通过小标区间替换数据（前3个数据），没有则追加
        testArray[0...2] = ["message","Apple","com"]
        // 交换元素位置
        testArray.swapAt(1, 2)
        // 删除下标为2的数组
        testArray.remove(at: 2)
        // 删除最后一个元素
        testArray.removeLast()
        // 删除数组中所有元素 keepingCapacity：保持最大容量
        testArray.removeAll(keepingCapacity: true)
        // 数组组合
        let addStringArr = testArray + ["1", "2"]
        // 使用for in 实现数组遍历
        for value in addStringArr {
            print("\(value)");
        }
        // 通过enumerate函数同时遍历数组的所有索引与数据
        for (index, value) in addStringArr.enumerated() {
            print("index：\(index) data：\(value)");
        }
        // 过滤数组元素(元素长度小于6)
        let newTypes = addStringArr.filter { $0.count < 6 }
        // 创建包含100个元素的数组 ["条目0", "条目1" ... "条目5"]
        let intArray1 = Array(0..<6).map{ "条目\($0)"}
        // 创建1-10连续整数数组 姿势1 闭区间
        let intArray2 = [Int](1...10)
        // 创建1-10连续整数数组 姿势2 半闭半开区间
        let intArray3 = [Int](1..<11)
        // 获取数组元素个数
        let testArrayCount = testArray.count
        // 判断数组是否为空
        if testArray.isEmpty == false {
            print("\(testArray)")
            print("\(testArrayCount)")
            print("\(addStringArr)")
            print("\(newTypes)")
            print("\(intArray1)")
            print("\(intArray2)")
            print("\(intArray3)")
        }
    }
    
    // MARK: - 字典
    private func testDict() {
        // MARK: Dictionary: 是无序的键值对的集,分配常量得到不可变字典，分配变量得到可变字典
        //    字典是由键值 key:value 对组成的集合
        //    字典中的元素之间是无序的
        //    字典是由两部分集合构成的，一个是键集合，一个是值集合
        //    字典是通过访问键间接访问值的
        //    键集合是不能有重复元素的，而值集合是可以重复的
        //    Swift中的字典类型是Dictionary，也是一个泛型集合
        //    使用let修饰的字典是不可变字典
        //    使用var修饰的字典是可变字典
        // 建立个空字典变量（let声明为常量, var声明变量，即可变字典）
        var fruitPriceDict = [String: Int]() // Dictionary<String, Int>()
        fruitPriceDict = ["apple":10, "pear":9, "banana":8, "peach":11, "strawberry":30, "lemon":1]
        print(fruitPriceDict)
        // 声明一个字典变量，其key为String类型 value为Any类型
        var personDict = ["name":"LiLei", "age":18, "nickName":"XiaoLi", "score":100] as [String : Any]
        // 修改key对应value值（不存在则添加）姿势1
        personDict.updateValue("city", forKey: "BeiJing China")
        // 修改key对应value值（不存在则添加）姿势2
        personDict["city"] = "BeiJing"
        // 删除key值及对应value值 姿势1
        personDict.removeValue(forKey: "score")
        // 删除key值及对应value值 姿势2
        personDict["nickName"] = nil
        // 访问字典的key集合
        let keysSet = personDict.keys
        // 访问字典的values数组
        let valueArray = personDict.values
        print("\(keysSet)  \(valueArray)")
    }
    
    // MARK: - 遍历字典
    public class func testDictEnumerated() {
        let personDict = ["name":"LiLei", "age":18, "nickName":"XiaoLi", "score":100] as [String : Any]
        // 遍历字典 姿势1
        for (key, value) in personDict {
            print("\(key):\(value)");
        }
        // 遍历字典 姿势2
        for keyAndValue in personDict {
            print("keyAndValue: \(keyAndValue)")
        }
        // 只遍历字典的键（key）
        for key in personDict.keys {
            print("\(key)");
        }
        // 只遍历字典的值（value）
        for value in personDict.values {
            print("\(value)");
        }
    }
    
    // MARK: - 字典过滤和合并
    public class func testDictFilterAndMerge() {
        // 建立个空字典变量（let声明为常量, var声明变量，即可变字典）
        let fruitPriceDict = ["apple":10, "pear":9, "banana":8, "peach":11, "strawberry":30, "lemon":1]
        // 过滤字典元素
        let fruitPriceDict2 = fruitPriceDict.filter { $0.value < 10 }
        print("\(fruitPriceDict2)")
        // 合并 姿势1
        var dict1 = ["name":"000","age":18,"title":"888"] as [String : Any]
        let dict2 = ["name":"da","hegiht":190] as [String : Any]
        
        for e in dict2 {
            dict1[e.key] = dict2[e.key]
        }
        // 如果key存在会修改，key不存在会新增
        print(dict1)
        var dic = ["one": 10, "two": 20]
        // merge方法合并
        let tuples = [("one", 5),  ("three", 30)]
        dic.merge(tuples, uniquingKeysWith: min)
        print("dic：\(dic)")
        // merging方法合并
        let dic2 = ["one": 0, "four": 40]
        let dic3 = dic.merging(dic2, uniquingKeysWith: min)
        print("dic3：\(dic3)")
        // merge(_: uniquingKeysWith:)：这种方法会修改原始Dictionary
        // merging(_: uniquingKeysWith:)：这种方法会创建并返回一个全新的Dictionary
    }
    
    // MARK: - 字典另类创建方式
    public class func testCreateDictSomeMethod() {
        // 通过元组创建字典
        let tupleKeyValueArray = [("Monday", 30),  ("Tuesday", 25),  ("Wednesday", 27)]
        let dictFromTuple = Dictionary(uniqueKeysWithValues: tupleKeyValueArray)
        print(dictFromTuple) // ["Monday": 30, "Tuesday": 25, "Wednesday": 27]
        // 通过键值序列创建字典
        let keyArrayToDict = ["Apple", "Pear"]
        let valueArrayToDict = [7, 6]
        let keyValueArrayToDict = Dictionary(uniqueKeysWithValues: zip(keyArrayToDict, valueArrayToDict))
        print(keyValueArrayToDict)
        // 用键序列/值序列创建字典
        let arrayKeyOrValue = ["Monday", "Tuesday", "Wednesday"]
        let indexKeyDict = Dictionary(uniqueKeysWithValues: zip(1..., arrayKeyOrValue))
        let indexValueDict = Dictionary(uniqueKeysWithValues: zip(arrayKeyOrValue, 1...))
        print("\(indexKeyDict) \(indexValueDict)") // [1: "Monday", 2: "Tuesday", 3: "Wednesday"] ["Wednesday": 3, "Tuesday": 2, "Monday": 1]
        // 数组分组成字典（比如下面生成一个以首字母分组的字典）
        let nameGroupArray = ["LiLei", "LiXiaolong", "LiuDehua", "HanMeimei", "HanLei", "SunWukong", "ErLangshen"]
        let dictFromNameGroup = Dictionary(grouping: nameGroupArray) { $0.first! }
        print(dictFromNameGroup) // ["S": ["SunWukong"], "L": ["LiLei", "LiXiaolong", "LiuDehua"], "E": ["ErLangshen"], "H": ["HanMeimei", "HanLei"]]
        
        let parsedType = OSLogType.debug
        let log = OSLog(subsystem: "my.subsystem.domain", category: "myCategory")
        os_log("%{private}@", log: log, type: parsedType, "os_log_test")
    }
    
    // MARK: - 获取对象占用内存
    // https://www.jianshu.com/p/36234c1ee24a
    private func getMemory() {
        let a1 = MemoryLayout<DataType>.size
        let a2 = MemoryLayout<DataType>.stride
        let a3 = MemoryLayout<DataType>.alignment
        let a4 = class_getInstanceSize(DataType.self)
        print("\(a1) \(a2) \(a3) \(a4)")
    }
}
