//
//  DDYUDPTraceRoute.swift
//  LearnSwift
//
//  Created by ddy on 2022/9/19.
//

import Foundation
import Darwin

/// 监测TraceRoute命令的的输出到日志变量；
public protocol DDYUDPTracerouteDelegae: AnyObject {
    func udpTraceroute(_ traceroute: DDYUDPTraceroute, output routelog: String)
    func udpTracerouteDidEnd(in traceroute: DDYUDPTraceroute)
}
/// TraceRoute网络监控
/// 主要是通过模拟shell命令traceRoute的过程，监控网络站点间的跳转
/// 默认执行20转，每转进行三次发送测速
public class DDYUDPTraceroute {
    public private(set) var isRunning: Bool = false // 检测traceroute是否在运行
    private var udpPort: UInt16         // 执行端口
    private var maxTTL: UInt32          // 执行转数
    private var maxAttempts: UInt32     // 每转的发送次数
    private weak var delegate: DDYUDPTracerouteDelegae?
    
    /// 初始化
    /// - Parameters:
    ///   - ttl: 执行转数（建议30）
    ///   - attempts: 每转的发送次数（建议3）
    ///   - port: 执行端口（默认 30001）
    public init(ttl: UInt32, attempts: UInt32, port: UInt16 = 30001, delegate: DDYUDPTracerouteDelegae?) {
        self.maxTTL = ttl
        self.udpPort = port
        self.maxAttempts = attempts
        self.delegate = delegate
    }
    
    /// 监控 tranceroute 路径
    public func startTrace(_ host: String) -> Bool {
        // 从name server获取server主机的地址
        guard let serverDNSs = DDYNetdiag.shared.netInfo.dns(host), !serverDNSs.isEmpty else {
            delegate?.udpTraceroute(self, output: "TraceRoute>>> Could not get host address")
            delegate?.udpTracerouteDidEnd(in: self)
            return false
        }
        
        let ipAddr0 = serverDNSs[0]
        // 设置server主机的套接口地址
        let addrData: Data
        let isIPV6: Bool
        if ipAddr0.range(of: ":") == nil {
            isIPV6 = false
            var nativeAddr4 = sockaddr_in()
            nativeAddr4.sin_len = UInt8(MemoryLayout.size(ofValue: nativeAddr4))
            nativeAddr4.sin_family = sa_family_t(AF_INET)
            nativeAddr4.sin_port = in_port_t(udpPort).bigEndian
            inet_pton(AF_INET, Array(ipAddr0.utf8CString), &nativeAddr4.sin_addr.s_addr)
            
            addrData = Data(bytes: &nativeAddr4, count: MemoryLayout.size(ofValue: nativeAddr4))
        } else {
            isIPV6 = true
            var nativeAddr6 = sockaddr_in6()
            nativeAddr6.sin6_len = UInt8(MemoryLayout.size(ofValue: nativeAddr6))
            nativeAddr6.sin6_family = sa_family_t(AF_INET6)
            nativeAddr6.sin6_port = in_port_t(udpPort).bigEndian
            inet_pton(AF_INET6, Array(ipAddr0.utf8CString), &nativeAddr6.sin6_addr)
            
            addrData = Data(bytes: &nativeAddr6, count: MemoryLayout.size(ofValue: nativeAddr6))
        }
        let destination = addrData.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: sockaddr.self) }
        // 初始化套接口
        var fromAddr = sockaddr()
        var error: Bool = false
        
        isRunning = true
        
        // 创建一个支持ICMP协议的UDP网络套接口（用于接收）
        let recv_sock = socket(Int32(destination.pointee.sa_family), SOCK_DGRAM, isIPV6 ? IPPROTO_ICMPV6 : IPPROTO_ICMP)
        if recv_sock < 0 {
            delegate?.udpTraceroute(self, output: "TraceRoute>>> Could not create recv socket")
            delegate?.udpTracerouteDidEnd(in: self)
            return false
        }
        
        // 创建一个UDP套接口（用于发送）
        let send_sock = socket(Int32(destination.pointee.sa_family), SOCK_DGRAM, 0)
        if send_sock < 0 {
            delegate?.udpTraceroute(self, output: "TraceRoute>>> Could not create xmit socket")
            delegate?.udpTracerouteDidEnd(in: self)
            return false
        }
        
        let cmsg = "GET / HTTP/1.1\r\n\r\n"
        var n = socklen_t(MemoryLayout.size(ofValue: fromAddr))
        var buf = [CChar](repeating: 0, count: 100)
        //var readBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: Socket.SOCKET_DEFAULT_READ_BUFFER_SIZE)
        
        var ttl: UInt32 = 1  // index sur le TTL en cours de traitement.
        var timeoutTTL: Int32 = 0
        var icmp: Bool = false  // Positionné à true lorsqu'on reçoit la trame ICMP en retour.
        var startTime: Date // Timestamp lors de l'émission du GET HTTP
        var delta: TimeInterval // Durée de l'aller-retour jusqu'au hop.
        
        // On progresse jusqu'à un nombre de TTLs max.
        while ttl <= maxTTL {
            memset(&fromAddr, 0, MemoryLayout.size(ofValue: fromAddr))
            // 设置sender 套接字的ttl
            let setResult: Int32
            if isIPV6 {
                setResult = setsockopt(send_sock,IPPROTO_IPV6, IPV6_UNICAST_HOPS, &ttl, socklen_t(MemoryLayout.size(ofValue: ttl)))
            } else {
                setResult = setsockopt(send_sock, IPPROTO_IP, IP_TTL, &ttl, socklen_t(MemoryLayout.size(ofValue: ttl)))
            }
            if (setResult < 0) {
                error = true
                delegate?.udpTraceroute(self, output: "TraceRoute>>> setsockopt failled")
            }
            
            // 每一步连续发送maxAttenpts报文
            icmp = false
            var traceTTLLog = String(repeating: "", count: 20)
            traceTTLLog.append("\(ttl)\t")
            var hostAddress = "***"
            for `try` in 0..<maxAttempts {
                startTime = Date()
                //发送成功返回值等于发送消息的长度
                let sentLen = sendto(send_sock, cmsg, cmsg.count, 0, destination, socklen_t(isIPV6 ? MemoryLayout<sockaddr_in6>.size : MemoryLayout<sockaddr_in>.size))
                if (sentLen != cmsg.count) {
                    print("Error sending to server: \(errno) \(sentLen)")
                    error = true
                    traceTTLLog.append("*\t")
                }
                
                //从（已连接）套接口上接收数据，并捕获数据发送源的地址。
                if (-1 == fcntl(recv_sock, F_SETFL, O_NONBLOCK)) {
                    print("fcntl socket error!\n")
                    return false
                }
                
                /* set recvfrom from server timeout */
                var tv = timeval()
                var readfds = fd_set()
                tv.tv_sec = 1
                tv.tv_usec = 0  //设置了1s的延迟
                readfds.ddy_zero() // FD_ZERO
                readfds.ddy_set(recv_sock) // FD_SET
                select(recv_sock + 1, &readfds, nil, nil, &tv)
                
                if readfds.ddy_isSet(recv_sock) {
                    timeoutTTL = 0
                    if recvfrom(recv_sock, &buf, 100, 0, &fromAddr, &n) < 0 {
                        error = true
                        traceTTLLog.append(String(format: "%s\t", strerror(errno)))
                    } else {
                        icmp = true
                        delta = Date().timeIntervalSince(startTime) * 1000
                        
                        //将“二进制整数” －> “点分十进制，获取hostAddress和hostName
                        if (fromAddr.sa_family == AF_INET) {
                            var display = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                            let fromAddr_in = withUnsafeBytes(of: &fromAddr) { $0.baseAddress!.assumingMemoryBound(to: sockaddr_in.self) }
                            var s_fromAddr = fromAddr_in.pointee.sin_addr.s_addr
                            inet_ntop(AF_INET, &s_fromAddr, &display, socklen_t(INET_ADDRSTRLEN))
                            hostAddress = String(utf8String: display) ?? String(format: "%s", display)
                        } else if (fromAddr.sa_family == AF_INET6) {
                            var ip = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                            let fromAddr_in6 = withUnsafeBytes(of: &fromAddr) { $0.baseAddress!.assumingMemoryBound(to: sockaddr_in6.self) }
                            var sin6_fromAddr = fromAddr_in6.pointee.sin6_addr
                            inet_ntop(AF_INET6, &sin6_fromAddr, &ip, socklen_t(INET6_ADDRSTRLEN))
                            hostAddress = String(utf8String: ip) ?? String(format: "%s", ip)
                        }
                        
                        if (`try` == 0) {
                            traceTTLLog.append("\(hostAddress)\t\t")
                        }
                        traceTTLLog.append(String(format: "%0.2fms\t", delta))
                    }
                } else {
                    timeoutTTL += 1
                    break
                }
                // On teste si l'utilisateur a demandé l'arrêt du traceroute
                if !isRunning {
                    ttl = maxTTL
                    icmp = true // On force le statut d'icmp pour ne pas générer un Hop en sortie de boucle
                    break
                }
            }
            
            // 输出报文,如果三次都无法监控接收到报文，跳转结束
            if icmp {
                delegate?.udpTraceroute(self, output: traceTTLLog)
            } else {
                // 如果连续三次接收不到icmp回显报文
                if timeoutTTL >= 4 {
                    break
                } else {
                    delegate?.udpTraceroute(self, output: "\(ttl)\t********\t")
                }
            }
            
            if hostAddress == ipAddr0 { break }
            ttl += 1
        }
        
        isRunning = false
        delegate?.udpTracerouteDidEnd(in: self) // On averti le delegate que le traceroute est terminé.
        return !error
    }
    
    /// 停止traceroute
    public func stopTrace() {
        isRunning = false
    }
}

