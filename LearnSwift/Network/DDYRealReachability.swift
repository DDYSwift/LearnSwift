//
//  DDYRealReachability.swift
//  LearnSwift
//
//  Created by ddy on 2022/9/19.
//

import CoreTelephony
import SystemConfiguration

public class DDYRealReachability {
    private let reachability: SCNetworkReachability
    private var queue: DispatchQueue = DispatchQueue(label: "com.ddy.netdiag.queue.reachability")
    
    public var monitorCallback: ((Status) -> Void)?
    
    public var isReachable: Bool { return isReachableOnCellular || isReachableOnWiFi }
    public var isReachableOnCellular: Bool { return status.isCellular }
    public var isReachableOnWiFi: Bool { return status == .reachable(.wifi) }
    public var status: Status { return flags.map(Status.init) ?? .unknown }
    
    private var previousStatus: Status?
    private var flags: SCNetworkReachabilityFlags? {
        var flags = SCNetworkReachabilityFlags()
        return (SCNetworkReachabilityGetFlags(reachability, &flags)) ? flags : nil
    }
    
    public init?() {
        var zero = sockaddr()
        zero.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zero.sa_family = sa_family_t(AF_INET)
        guard let reachability = SCNetworkReachabilityCreateWithAddress(nil, &zero) else { return nil }
        self.reachability = reachability
    }
    
    public init?(host: String) {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else { return nil }
        self.reachability = reachability
    }
    
    deinit {
        stopMonitoring()
    }
    
    public func startMonitoring() -> Bool {
        var context = SCNetworkReachabilityContext(version: 0, info: Unmanaged.passRetained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        let callback: SCNetworkReachabilityCallBack = { (_, flags, info) in
            let observer = info.map { Unmanaged<DDYRealReachability>.fromOpaque($0).takeUnretainedValue() }
            observer?.reachabilityDidChange(with: flags)
        }
        
        let callbackEnabled = SCNetworkReachabilitySetCallback(reachability, callback, &context)
        let queueEnabled = SCNetworkReachabilitySetDispatchQueue(reachability, queue)
        
        // Manually call listener to give initial state, since the framework may not.
        if let currentFlags = flags {
            queue.async {
                self.reachabilityDidChange(with: currentFlags)
            }
        }
        return callbackEnabled && queueEnabled
    }
    
    public func stopMonitoring() {
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
        previousStatus = nil
    }
    
    private func reachabilityDidChange(with flags: SCNetworkReachabilityFlags) {
        let newStatus = Status(flags)
        guard previousStatus != newStatus else { return }
        previousStatus = newStatus
        
        queue.async { self.monitorCallback?(newStatus) }
    }
}

extension DDYRealReachability {
    public enum Status: CustomStringConvertible {
        public enum ConnectionType {
            case wifi
            case cellular
            case cellular2G
            case cellular3G
            case cellular4G
            //case cellular5G
        }
        case unknown
        case notReachable
        case reachable(ConnectionType)
        
        public var isCellular: Bool {
            guard case .reachable(let type) = self else { return false }
            return type == .cellular || type == .cellular2G || type == .cellular3G || type == .cellular4G
        }
        
        init(_ flags: SCNetworkReachabilityFlags) {
            guard flags.isActuallyReachable else { self = .notReachable; return }
            var networkStatus: Status
            if flags.isCellular {
                let phonyNetwork = CTTelephonyNetworkInfo()
                if let radioAccessTechnology = phonyNetwork.currentRadioAccessTechnology {
                    if radioAccessTechnology == CTRadioAccessTechnologyLTE {
                        networkStatus = .reachable(.cellular4G)
                    } else if radioAccessTechnology == CTRadioAccessTechnologyEdge || radioAccessTechnology == CTRadioAccessTechnologyGPRS {
                        networkStatus = .reachable(.cellular2G)
                    } else {
                        networkStatus = .reachable(.cellular3G)
                    }
                } else {
                    if flags.isTransientConnection {
                        if flags.isConnectionRequired {
                            networkStatus = .reachable(.cellular2G)
                        } else {
                            networkStatus = .reachable(.cellular3G)
                        }
                    } else {
                        assert(false, "Unknown cellular ???") // debug
                        networkStatus = .reachable(.cellular)
                    }
                }
            } else {
                networkStatus = .reachable(.wifi)
            }
            self = networkStatus
        }
        
        public var description: String {
            switch self {
            case .unknown:        return "unknown"
            case .notReachable:   return "notReachable"
            case .reachable(let type):
                switch type {
                case .wifi:       return "wifi"
                case .cellular:   return "cellular" // 未知蜂窝网络类型
                case .cellular2G: return "2G"
                case .cellular3G: return "3G"
                case .cellular4G: return "4G"
                }
            }
        }
    }
}

extension DDYRealReachability.Status: Equatable {}
extension SCNetworkReachabilityFlags {
    var isReachable: Bool { return contains(.reachable) }
    var isTransientConnection: Bool { return contains(.transientConnection) }
    var isConnectionRequired: Bool { return contains(.connectionRequired) }
    var canConnectAutomatically: Bool { return contains(.connectionOnDemand) || contains(.connectionOnTraffic) }
    var canConnectWithoutUserInteraction: Bool { return canConnectAutomatically && !contains(.interventionRequired) }
    var isActuallyReachable: Bool { return isReachable && (!isConnectionRequired || canConnectWithoutUserInteraction) }
    var isCellular: Bool { return contains(.isWWAN) }
}

