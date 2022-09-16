##### p
```
print 打印变量、常量、表达式 【不可以打印宏】
```

##### po
```
print objcet ，打印变量、常量、表达式返回的对象等 【不可以打印宏】
```


##### expression
```
能动态执行赋值表达式，同时打印出结果【例如执行某个else 情况时的调试】

(lldb) po i
5
(lldb) expression i = 10
(int) $5 = 10
(lldb) po i
10

// 还可以格式化打印字典，防止横杠模式
expression print(json.dictionaryValue)
```

##### call
```
动态调用函数，例如在不重新编译情况下修改视图

(lldb) po cell.contentView.subviews
<__NSArrayM 0x60800005f5f0>(
<UILabel: 0x7f91f4f18c90; frame = (5 5; 300 25); text = '2 - Drawing index is top ...'; userInteractionEnabled = NO; tag = 1; layer = <_UILabelLayer: 0x60800009ff40>>,
<UIImageView: 0x7f91f4d20050; frame = (105 20; 85 85); opaque = NO; userInteractionEnabled = NO; tag = 2; layer = <CALayer: 0x60000003ff60>>,
<UIImageView: 0x7f91f4f18f10; frame = (200 20; 85 85); opaque = NO; userInteractionEnabled = NO; tag = 3; layer = <CALayer: 0x608000039860>>
)
 
(lldb) call [label removeFromSuperview]
(lldb) po cell.contentView.subviews
<__NSArrayM 0x600000246de0>(
<UIImageView: 0x7f91f4d20050; frame = (105 20; 85 85); opaque = NO; userInteractionEnabled = NO; tag = 2; layer = <CALayer: 0x60000003ff60>>,
<UIImageView: 0x7f91f4f18f10; frame = (200 20; 85 85); opaque = NO; userInteractionEnabled = NO; tag = 3; layer = <CALayer: 0x608000039860>>
)
```

##### bt
```
打印当前线程的堆栈信息，比左侧Debug Navigator更详细

(lldb) bt 
* thread #1: tid = 0x27363, 0x000000010d204125 TestDemo`-[FifthViewController tableView:cellForRowAtIndexPath:](self=0x00007f91f4e153c0, _cmd="tableView:cellForRowAtIndexPath:", tableView=0x00007f91f5889600, indexPath=0xc000000000400016) + 2757 at FifthViewController.m:91, queue = 'com.apple.main-thread', stop reason = breakpoint 6.1
 * frame #0: 0x000000010d204125 TestDemo`-[FifthViewController tableView:cellForRowAtIndexPath:](self=0x00007f91f4e153c0, _cmd="tableView:cellForRowAtIndexPath:", tableView=0x00007f91f5889600, indexPath=0xc000000000400016) + 2757 at FifthViewController.m:91
  frame #1: 0x0000000111d0a7b5 UIKit`-[UITableView _createPreparedCellForGlobalRow:withIndexPath:willDisplay:] + 757
  frame #2: 0x0000000111d0aa13 UIKit`-[UITableView _createPreparedCellForGlobalRow:willDisplay:] + 74
…
…
(lldb)
```

##### image
```
image list 命令可以列出当前App中的所有module（这个module 在后面符号断点时有用到），可以查看某一个地址对应的代码位置。 除了 image list 还有 image add、image lookup等命令，可以自行查看。
当遇到crash 时，查看线程栈，只能看到栈帧的地址，使用 image lookup –address 地址 可以方便的定位到这个地址对应的代码行
```

##### 进模拟器沙盒
在启动函数打断点，运行到断点后， po NSHomeDirectory()，拷贝地址，终端open path


* [https://lldb.llvm.org/](https://lldb.llvm.org/)
* [LLDB命令速查手册](https://easeapi.com/blog/blog/156-lldb.html)