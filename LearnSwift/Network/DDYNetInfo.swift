import CoreTelephony

public class DDYNetInfo: CustomStringConvertible {
    
    /// 网络连接状态改变通知
    public static let reachabilityChangedNotification = Notification.Name(rawValue: "com.ddy.netdiag.notification.reachabilityChanged")
    private(set) var reachability: DDYRealReachability?
    /// 获取运营商信息
    var cellulars: [CTCarrier]? {
        let info = CTTelephonyNetworkInfo()
        if #available(iOS 12.0, *) {
            return info.serviceSubscriberCellularProviders?.map({ $0.value })
        } else if let carrier = info.subscriberCellularProvider {
            return [carrier]
        }
        return nil
    }
    
    public var description: String {
        var externalNetworkIP: String?
        let semaphore = DispatchSemaphore(value: 0) // 创建信号量
        fetchExternalNetworkIP { (ip) in
            externalNetworkIP = ip
            semaphore.signal() // 在网络请求结束后发送通知信号
        }
        _ = semaphore.wait(timeout: .distantFuture) // 发送等待信号
        
        return """
        status：\(reachability?.status.description ?? "unknown")
        cellulars：\(cellulars?.description ?? "unknown")
        外网IP：\(externalNetworkIP ?? "unknown")
        """
    }
}

// MARK: - Network Reachability monitor
extension DDYNetInfo {
    /// 开始监听网络连接
    public func startMonitoring(_ host: String?) {
        guard reachability == nil else { return assert(false, "reachability started Monitoring") }
        
        if let host = host, let reachability = DDYRealReachability(host: host) {
            return startMonitoring(reachability)
        }
        
        if let reachability = DDYRealReachability() {
            return startMonitoring(reachability)
        }
        return assert(false, "reachability start Monitoring fail")
    }
    
    private func startMonitoring(_ reachability: DDYRealReachability) {
        reachability.monitorCallback = { (state) in
            DDYNetInfo.externalNetworkIP = nil // 当网络状态发生改变后将此属性置为nil
            
            #if DEBUG
            print("⚠️⚠️⚠️ ----------------------------------------- ⚠️⚠️⚠️")
            print("net state：-> \(state.description)")
            print("⚠️⚠️⚠️ ----------------------------------------- ⚠️⚠️⚠️")
            #endif
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: DDYNetInfo.reachabilityChangedNotification, object: nil)
            }
        }
        
        if !reachability.startMonitoring() {
            assert(false, "reachability start Monitoring fail")
        }
        
        self.reachability = reachability
    }
    
    /// 停止监控网络变化
    public func stopMonitoring() {
        reachability?.stopMonitoring()
    }
}

// MARK: - External Network IP
extension DDYNetInfo {
    /// 外网IP
    public private(set) static var externalNetworkIP: String?
    /// 查询外网IP
    public func fetchExternalNetworkIP(_ completion: @escaping (String?) -> Void) {
        if let ip = DDYNetInfo.externalNetworkIP {
            return completion(ip)
        }
        
        httpReq("https://ifconfig.me/ip") { (data, error) in
            if let data = data, let ip = String(data: data, encoding: .utf8) {
                DDYNetInfo.externalNetworkIP = ip
                return completion(ip)
            }
            self.httpReq("https://httpbin.org/ip") { (data, error) in
                if let data = data {
                    do {
                        let obj = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                        if let ip = (obj as? [String: Any])?["origin"] as? String {
                            DDYNetInfo.externalNetworkIP = ip
                            return completion(ip)
                        }
                    } catch {
                        assert(false, "error: \(error), data: \(data)")
                    }
                }
                completion(nil)
            }
        }
    }
    
    private func httpReq(_ urlString: String, completion: @escaping (Data?, Error?) -> Void) {
        guard let url = URL(string: urlString) else { return assert(false, "url invalid.") }
        let req = URLRequest(url: url, timeoutInterval: 10.0)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: req) { (data, _, error) in
            completion(data, error)
        }
        task.resume()
    }
}

// MARK: - 域名解析
extension DDYNetInfo {
    /// 通过域名获取服务器DNS地址（IPv4 and IPv6）
    public func dns(_ hostName: String) -> [String]? {
        var ipv4DNSs = ipv4DNS(hostName)
        if let ipv6DNSs = ipv6DNS(hostName), !ipv6DNSs.isEmpty {
            if ipv4DNSs == nil {
                return ipv6DNSs
            } else {
                ipv4DNSs?.append(contentsOf: ipv6DNSs)
            }
        }
        return ipv4DNSs
    }
    
    /// 通过域名获取服务器DNS地址（Only IPv4 or IPv6）
    public func dnsIPv4OrIPv6(_ hostName: String) -> [String]? {
        let ipv4DNSs = ipv4DNS(hostName)
        // 由于在IPV6环境下不能用IPV4的地址进行连接监测，所以只返回IPV6的服务器DNS地址
        if let ipv6DNSs = ipv6DNS(hostName), !ipv6DNSs.isEmpty {
            return ipv6DNSs
        }
        return ipv4DNSs
    }
    
    public func ipv4DNS(_ hostName: String) -> [String]? {
        let hostN = Array(hostName.utf8CString)
        guard let phot = gethostbyname(hostN), let addr_list = phot.pointee.h_addr_list else { return nil }
        
        var result: [String] = []
        var j = 0
        while let addr = addr_list[j] {
            var ip_addr = in_addr()
            memcpy(&ip_addr, addr, MemoryLayout<in_addr>.size)
            var ip = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            inet_ntop(AF_INET, &ip_addr, &ip, socklen_t(INET_ADDRSTRLEN))
            if let ipAddress = String(utf8String: ip) {
                result.append(ipAddress)
            }
            j += 1
        }
        return result
    }
    
    public func ipv6DNS(_ hostName: String) -> [String]? {
        let hostN = Array(hostName.utf8CString)
        // 只有在IPV6的网络下才会有返回值
        guard let phot = gethostbyname2(hostN, AF_INET6), let addr_list = phot.pointee.h_addr_list else { return nil }
        
        var result: [String] = []
        var j = 0
        while let addr = addr_list[j] {
            var ip6_addr = in6_addr()
            memcpy(&ip6_addr, addr, MemoryLayout<in6_addr>.size)
            var ip = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            inet_ntop(AF_INET6, &ip6_addr, &ip, socklen_t(INET6_ADDRSTRLEN))
            if let ipAddress = String(utf8String: ip) {
                result.append(ipAddress)
            }
            j += 1
        }
        return result
    }
}
