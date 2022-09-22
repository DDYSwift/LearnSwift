//
//  DDYTCPPing.swift
//  LearnSwift
//
//  Created by ddy on 2022/9/19.
//

import Foundation

enum DDYNetdiagError: Error {
    case accessingDNSFailed // Problem accessing the DNS
    case ipResolutionFailed
}
public protocol DDYTCPPingDelegate: AnyObject {
    func tcpPing(_ pinger: DDYTCPPing, output line: String)
    func tcpPing(_ pinger: DDYTCPPing, didFailWith error: Error)
}

public class DDYTCPPing {
    static private let kRequestStoped: Int32 = -2 // 中途取消的状态码
    
    public struct Result: CustomStringConvertible {
        public let code: Int32
        public let ip: String?
        public let maxTime: TimeInterval
        public let minTime: TimeInterval
        public let avgTime: TimeInterval
        public let loss: UInt32
        public let count: UInt32
        public let totalTime: TimeInterval
        public let stddev: TimeInterval

        public var description: String {
            if code == 0 || code == DDYTCPPing.kRequestStoped {
                return String(format: "tcp connect min/avg/max = %.3f/%.3f/%.3fms", minTime, avgTime, maxTime)
            }
            return "tcp connect failed \(code)"
        }
    }
    
    private let host: String
    private let port: UInt16
    private let count: UInt32
    private var stopped: Bool = false
    private weak var delegate: DDYTCPPingDelegate?
    private let completion: ((Result) -> Void)?
    
    deinit {
        #if DEBUG
        print("DDYTCPPing release memory.")
        #endif
    }
    
    public init(host: String, port: UInt16 = 80, count: UInt32, delegate: DDYTCPPingDelegate?, completion: ((Result) -> Void)?) {
        self.host = host
        self.port = port
        self.count = count
        self.delegate = delegate
        self.completion = completion
    }
    
    public func start() {
        DispatchQueue.global().async { self.run() }
    }
    
    public func stop() {
        stopped = true
    }
    
    private func run() {
        let begin = Date()
        delegate?.tcpPing(self, output: "connect to host \(host):\(port) ...\n")
        
        let hostaddr = Array(host.utf8CString)
        
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(port).bigEndian
        addr.sin_addr.s_addr = inet_addr(hostaddr)
        
        if addr.sin_addr.s_addr == INADDR_NONE {
            guard let host = gethostbyname(hostaddr), let h_addr = host.pointee.h_addr_list?[0] else {
                delegate?.tcpPing(self, didFailWith: DDYNetdiagError.accessingDNSFailed)
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion(self.buildResult(-1006, ip: nil, durations: nil, loss: 0, count: 0, total: 0))
                    }
                }
                return
            }
            addr.sin_addr = h_addr.withMemoryRebound(to: in_addr.self, capacity: 1) { $0.pointee }
        }
        
        guard let ipAddr = inet_ntoa(addr.sin_addr), let ip = String(utf8String: ipAddr) else {
            delegate?.tcpPing(self, didFailWith: DDYNetdiagError.ipResolutionFailed)
            return
        }
        delegate?.tcpPing(self, output: "connect to ip \(ip):\(port) ...\n")

        var intervals = [TimeInterval](repeating: 0, count: Int(count))
        var r: Int32 = 0
        var loss: UInt32 = 0
        var connectCount: UInt32 = 0
        for index in 0..<Int(count) where !stopped && r == 0 {
            let t1 = Date()
            r = conn(&addr)
            let duration = NSDate().timeIntervalSince(t1) * 1000
            intervals[index] = duration
            if r == 0 {
                delegate?.tcpPing(self, output: String(format: "connected to %s:%lu, %f ms\n", inet_ntoa(addr.sin_addr), port, duration))
            } else {
                delegate?.tcpPing(self, output: String(format: "connect failed to %s:%lu, %f ms, error %d\n", inet_ntoa(addr.sin_addr), port, duration, r))
                loss += 1
            }

            if index < count && !stopped && r == 0 {
                Thread.sleep(forTimeInterval: 0.1)
            }

            connectCount += 1
        }
        
        if let completion = completion {
            let code = stopped ? DDYTCPPing.kRequestStoped : r
            DispatchQueue.main.async {
                completion(self.buildResult(code, ip: ip, durations: intervals, loss: loss, count: connectCount, total: Date().timeIntervalSince(begin) * 1000))
            }
        }
    }

    private func buildResult(_ code: Int32, ip: String?, durations: [TimeInterval]?, loss: UInt32, count: UInt32, total time: TimeInterval) -> Result {
        if code != 0 && code != DDYTCPPing.kRequestStoped {
            return Result(code: code, ip: ip, maxTime: 0, minTime: 0, avgTime: 0, loss: 1, count: 1, totalTime: time, stddev: 0)
        }
        var max: TimeInterval = 0
        var min: TimeInterval = 10000000
        var sum: TimeInterval = 0
        var sum2: TimeInterval = 0
        durations?.forEach({
            if $0 > max { max = $0 }
            if $0 < min { min = $0 }
            sum += $0
            sum2 += $0 * $0
        })

        let avg = sum / TimeInterval(count)
        let avg2 = sum2 / TimeInterval(count)
        let stddev = sqrt(avg2 - avg * avg)
        return Result(code: code, ip: ip, maxTime: max, minTime: min, avgTime: avg, loss: loss, count: count, totalTime: time, stddev: stddev)
    }
    
    private func conn(_ addr_in: UnsafePointer<sockaddr_in>) -> Int32 {
        let sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
        if sock == -1 {
            return errno
        }
        
        var on: Int32 = 1
        assert(setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout.size(ofValue: on))) == 0)
        assert(setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, &on, socklen_t(MemoryLayout.size(ofValue: on))) == 0)
        
        var timeout = timeval(tv_sec: 10, tv_usec: 0)
        assert(setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout.size(ofValue: timeout))) == 0)
        assert(setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout.size(ofValue: timeout))) == 0)
        
        let addr = addr_in.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size) { $0 }
        if connect(sock, addr, socklen_t(MemoryLayout<sockaddr>.size)) < 0 {
            let err = errno
            close(sock)
            return err
        }
        close(sock)
        return 0
    }
}

