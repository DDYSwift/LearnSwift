//
//  DDYLog.swift
//  LearnSwift
//
//  Created by ddy on 2022/9/19.
//

import Foundation
import os

/// subsystem for current project.
///  - setup it when start a new project.
private let subsystem = "com.ddy.log"

/// Custom log system.
final public class DDYLog {
    
    public struct Output: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let info = Output(rawValue: 1 << 0)
        public static let debug = Output(rawValue: 1 << 1)
        public static let warning = Output(rawValue: 1 << 2)
        public static let error = Output(rawValue: 1 << 3)

        public static let all: Output = [.info, .debug, .warning, .error]
    }
    
    /// setup log level and when does the log work.
    public static var output: Output = [.debug, .warning, .error]
    
    @available(iOS 10.0, *)
    /// level info
    static let infoLog = OSLog(subsystem: subsystem, category: "INFO")
    /// info level
    ///
    /// - Parameters:
    ///   - string: log info description
    ///   - fileName: file name
    ///   - methodName: method name
    ///   - lineNumber: line number
    public static func info(_ string: String, fileName: String = #file, methodName: String = #function, lineNumber: Int = #line) {
        #if DEBUG
        let log = "\(fileName):line \(lineNumber) method:\(methodName):\(string)"
        if output.contains(.info) {
            if #available(iOS 10.0, *) {
                os_log("%@", log: infoLog, type: .info, log)
            } else {
                print("<INFO>: %@", log)
            }
        }
        #endif
    }

    @available(iOS 10.0, *)
    /// level debug
    static let debugLog = OSLog(subsystem: subsystem, category: "DEBUG")
    /// debug level
    ///
    /// - Parameters:
    ///   - string: log info description
    ///   - fileName: file name
    ///   - methodName: method name
    ///   - lineNumber: line number
    public static func debug(_ string: String, fileName: String = #file, methodName: String = #function, lineNumber: Int = #line) {
        #if DEBUG
            let log = "\(fileName):line \(lineNumber) method:\(methodName):\(string)"
            if output.contains(.debug) {
                if #available(iOS 10.0, *) {
                    os_log("%@", log: debugLog, type: .debug, log)
                } else {
                    print("<DEBUG>: %@", log)
                }
            }
        #endif
    }

    @available(iOS 10.0, *)
    /// level warning
    static let warningLog = OSLog(subsystem: subsystem, category: "WARNING")
    public static func warning(_ string: String, fileName: String = #file, methodName: String = #function, lineNumber: Int = #line) {
        if output.contains(.warning) {
            let log = "\(fileName):line \(lineNumber) method:\(methodName):\(string)"
            if #available(iOS 10.0, *) {
                os_log("%@", log: warningLog, type: .fault, log)
            } else {
                print("<WARNING>: %@", string)
            }
        }
    }

    @available(iOS 10.0, *)
    /// level error
    static let errorLog = OSLog(subsystem: subsystem, category: "ERROR")
    public static func error(_ string: String, fileName: String = #file, methodName: String = #function, lineNumber: Int = #line) {
        if output.contains(.error) {
            let log = "\(fileName):line \(lineNumber) method:\(methodName):\n\(string)"
            if #available(iOS 10.0, *) {
                os_log("%@", log: errorLog, type: .error, log)
            } else {
                print("<ERROR>: %@", string)
            }
        }
    }
    
    /// just output in console.
    ///
    /// - Parameters:
    ///   - message: output message.
    ///   - fileName: file name.
    ///   - methodName: method name.
    ///   - lineNumber: line number.
    static func out<N>(message: N, fileName: String = #file, methodName: String = #function, lineNumber: Int = #line){
        #if DEBUG
            print("\(fileName):\(lineNumber) \(methodName):\(message)");
        #endif
    }
}
// [swift 自定义Log，提升调试效率](https://www.jianshu.com/p/5946b4859e10)
// [探索 Swift 中的日志系统](https://www.136.la/jingpin/show-13384.html)
