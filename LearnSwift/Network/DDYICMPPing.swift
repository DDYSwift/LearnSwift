//
//  DDYICMPPing.swift
//  LearnSwift
//
//  Created by ddy on 2022/9/19.
//

import Foundation
import Darwin

// MARK: - DDYICMPPingDelegate
/// A delegate protocol for the DDYICMPPing class.
public protocol DDYICMPPingDelegate: AnyObject {
    /// A SimplePing delegate callback, called once the object has started up.
    /// - Parameters:
    ///   - pinger: The object issuing the callback.
    ///   - address: The address that's being pinged; at the time this delegate callback is made, this will have the same value as the `hostAddress` property.
    /// - Note: This is called shortly after you start the object to tell you that the object has successfully started.  On receiving this callback, you can call `-sendPingWithData:` to send pings.
    ///         If the object didn't start, `-simplePing:didFailWithError:` is called instead.
    func icmpPing(_ pinger: DDYICMPPing, didStartWith address: Data)
    /// A SimplePing delegate callback, called if the object fails to start up.
    /// - Parameters:
    ///   - pinger: The object issuing the callback.
    ///   - error: Describes the failure.
    /// - Note: This is called shortly after you start the object to tell you that the object has failed to start.  The most likely cause of failure is a problem resolving `hostName`.
    ///         By the time this callback is called, the object has stopped (that is, you don't need to call `-stop` yourself).
    func icmpPing(_ pinger: DDYICMPPing, didFailWith error: Error)
    /// A SimplePing delegate callback, called when the object has successfully sent a ping packet.
    /// - Parameters:
    ///   - pinger: The object issuing the callback.
    ///   - packet: The packet that was sent; this includes the ICMP header (`ICMPHeader`) and the data you passed to `-sendPingWithData:` but does not include any IP-level headers.
    ///   - sequenceNumber: The ICMP sequence number of that packet.
    /// - Note: Each call to `-sendPingWithData:` will result in either a
    ///         `-simplePing:didSendPacket:sequenceNumber:` delegate callback or a
    ///         `-simplePing:didFailToSendPacket:sequenceNumber:error:` delegate callback (unless you
    ///     stop the object before you get the callback).  These callbacks are currently delivered synchronously from within `-sendPingWithData:`, but this synchronous behaviour is not considered API.
    func icmpPing(_ pinger: DDYICMPPing, didSend packet: Data, sequenceNumber: UInt16)
    /// A SimplePing delegate callback, called when the object fails to send a ping packet.
    /// - Parameters:
    ///   - pinger: The object issuing the callback.
    ///   - packet: The packet that was not sent; see `-simplePing:didSendPacket:sequenceNumber:` for details.
    ///   - sequenceNumber: The ICMP sequence number of that packet.
    ///   - error: Describes the failure.
    /// - Note: Each call to `-sendPingWithData:` will result in either a
    ///         `-simplePing:didSendPacket:sequenceNumber:` delegate callback or a
    ///         `-simplePing:didFailToSendPacket:sequenceNumber:error:` delegate callback (unless you
    ///     stop the object before you get the callback).  These callbacks are currently delivered synchronously from within `-sendPingWithData:`, but this synchronous behaviour is not considered API.
    func icmpPing(_ pinger: DDYICMPPing, didFailToSend packet: Data, sequenceNumber: UInt16, error: Error)
    /// A SimplePing delegate callback, called when the object receives a ping response.
    /// - Parameters:
    ///   - pinger: The object issuing the callback.
    ///   - packet: The packet received; this includes the ICMP header (`ICMPHeader`) and any data that follows that in the ICMP message but does not include any IP-level headers.
    ///   - sequenceNumber: The ICMP sequence number of that packet.
    /// - Note: If the object receives an ping response that matches a ping request that it sent, it informs the delegate via this callback.  Matching is primarily done based on the ICMP identifier, although other criteria are used as well.
    func icmpPing(_ pinger: DDYICMPPing, didReceivePingResponse packet: Data, sequenceNumber: UInt16)
    /// A SimplePing delegate callback, called when the object receives an unmatched ICMP message.
    /// - Parameters:
    ///   - pinger: The object issuing the callback.
    ///   - packet: The packet received; this includes the ICMP header (`ICMPHeader`) and any data that follows that in the ICMP message but does not include any IP-level headers.
    /// - Note: If the object receives an ICMP message that does not match a ping request that it sent, it informs the delegate via this callback.  The nature of ICMP handling in a
    ///         BSD kernel makes this a common event because, when an ICMP message arrives, it is delivered to all ICMP sockets.
    ///     IMPORTANT: This callback is especially common when using IPv6 because IPv6 uses ICMP for important network management functions.  For example, IPv6 routers periodically
    ///     send out Router Advertisement (RA) packets via Neighbor Discovery Protocol (NDP), which is implemented on top of ICMP. For more on matching, see the discussion associated with
    ///     `-icmpPing:didReceivePingResponsePacket:sequenceNumber:`.
    func icmpPing(_ pinger: DDYICMPPing, didReceiveUnexpected packet: Data)
}

// MARK: - DDYICMPPing
/// An object wrapper around the low-level BSD Sockets ping function.
/// - Note: To use the class create an instance, set the delegate and call `-start` to start the instance on the current run loop.  If things go well you'll soon get the
///         `-icmpPing:didStartWithAddress:` delegate callback.  From there you can can call
///         `-sendPingWithData:` to send a ping and you'll receive the
///         `-icmpPing:didReceivePingResponsePacket:sequenceNumber:` and
///         `-icmpPing:didReceiveUnexpectedPacket:` delegate callbacks as ICMP packets arrive.
///     The class can be used from any thread but the use of any single instance must be confined to a specific thread and that thread must run its run loop.
public class DDYICMPPing {
    /// A copy of the value passed to `init(hostName:)`.
    public let hostName: String
    /// The identifier used by pings by this object.
    /// - Note: When you create an instance of this object it generates a random identifier that it uses to identify its own pings.
    public let identifier: UInt16 = UInt16.random(in: 0..<UInt16.max)
    /// The delegate for this object.
    /// - Note: Delegate callbacks are schedule in the default run loop mode of the run loop of the thread that calls `-start`.
    public weak var delegate: DDYICMPPingDelegate?
    /// Controls the IP address version used by the object.
    /// - Note: You should set this value before starting the object.
    public var addressStyle: DDYICMPPingAddressStyle?
    /// The address being pinged.
    /// - Note: The contents of the NSData is a (struct sockaddr) of some form.  The value is nil while the object is stopped and remains nil on start until  `icmpPing:didStartWithAddress:` is called.
    public private(set) var hostAddress: Data?
    /// The next sequence number to be used by this object.
    /// - Note: This value starts at zero and increments each time you send a ping (safely wrapping back to zero if necessary).
    ///         The sequence number is included in the ping, allowing you to match up requests and responses, and thus calculate ping times and so on.
    public private(set) var nextSequenceNumber: UInt16 = 0
    /// The address family for `hostAddress`, or `AF_UNSPEC` if that's nil.
    public var hostAddressFamily: Int32 {
        guard let hostAddress = hostAddress, hostAddress.count >= MemoryLayout<sockaddr>.size else {
            return AF_UNSPEC
        }
        return hostAddress.withUnsafeBytes { (body) -> Int32 in
            if let baseAddress = body.baseAddress {
                return Int32(baseAddress.assumingMemoryBound(to: sockaddr.self).pointee.sa_family)
            }
            return AF_UNSPEC
        }
    }
    /// true if nextSequenceNumber has wrapped from 65535 to 0.
    fileprivate var nextSequenceNumberHasWrapped: Bool = false
    /// A host object for name-to-address resolution.
    fileprivate var host: CFHost?
    /// A socket object for ICMP send and receive.
    fileprivate var socket: CFSocket?
    
    /// Initialise the object to ping the specified host.
    /// - Parameter hostName: The DNS name of the host to ping; an IPv4 or IPv6 address in string form will work here.
    public init(hostName: String) {
        self.hostName = hostName
    }
    
    deinit {
        stop()
        // Double check that -stop took care of _host and _socket.
        assert(host == nil)
        assert(socket == nil)
        #if DEBUG
        print("DDYICMPPing release memory.")
        #endif
    }
    
    /// Starts the object.
    /// - Note: You should set up the delegate and any ping parameters before calling this.
    ///     If things go well you'll soon get the `icmpPing:didStartWith:` delegate callback, at which point you can start sending pings (via `sendPing(with:)`) and
    ///     will start receiving ICMP packets (either ping responses, via the `icmpPing:didReceivePingResponse:sequenceNumber:` delegate callback, or
    ///     unsolicited ICMP packets, via the `icmpPing:didReceiveUnexpected:` delegate callback).
    ///
    ///     If the object fails to start, typically because `hostName` doesn't resolve, you'll get the `icmpPing:didFailWith:` delegate callback.
    ///     It is not correct to start an already started object.
    public func start() {
        assert(host == nil)
        assert(hostAddress == nil)
        
        var context = CFHostClientContext(version: 0, info: unsafeBitCast(self, to: UnsafeMutableRawPointer.self), retain: nil, release: nil, copyDescription: nil)
        let host = CFHostCreateWithName(nil, hostName as CFString).takeUnretainedValue()
        CFHostSetClient(host, ddy_hostResolveCallback(_:typeInfo:error:info:), &context)
        CFHostScheduleWithRunLoop(host, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        
        var streamError = CFStreamError()
        if !CFHostStartInfoResolution(host, .addresses, &streamError) {
            didFail(withHostStreamError: streamError)
        }
        self.host = host
    }
    
    /// Stops the object.
    /// - Note: You should call this when you're done pinging. It's safe to call this on an object that's stopped.
    public func stop() {
        stopHostResolution()
        stopSocket()
        // Junk the host address on stop.  If the client calls -start again, we'll re-resolve the host name.
        hostAddress = nil
    }
    
    /// Sends a ping packet containing the specified data.
    /// - Parameter data: Some data to include in the ping packet, after the ICMP header, or nil if you want the packet to include a standard 56 byte payload (resulting in a standard 64 byte ping).
    /// - Note: Sends an actual ping.
    /// The object must be started when you call this method and, on starting the object, you must wait for the `icmpPing:didStartWith:` delegate callback before calling it.
    public func sendPing(with data: Data?) {
        var err: Int32 = 0
        let payload: Data
        var packetOpt: Data?
        var bytesSent: ssize_t

        // data may be nil
        assert(self.hostAddress != nil) // gotta wait for -simplePing:didStartWithAddress:

        // Construct the ping packet.
        if let data = data {
            payload = data
        } else {
            let data = String(format: "%28zd bottles of beer on the wall", 99 - (nextSequenceNumber % 100)).data(using: .ascii)
            assert(data != nil)
            payload = data ?? Data()
            // Our dummy payload is sized so that the resulting ICMP packet, including the ICMPHeader, is
            // 64-bytes, which makes it easier to recognise our packets on the wire.
            assert(payload.count == 56)
        }

        switch hostAddressFamily {
        case AF_INET:
            packetOpt = pingPacket(withType: DDYICMPv4TypeEcho.request.rawValue, payload: payload, requiresChecksum: true)
        case AF_INET6:
            packetOpt = pingPacket(withType: DDYICMPv6TypeEcho.request.rawValue, payload: payload, requiresChecksum: false)
        default:
            assert(false)
        }
        guard let packet = packetOpt else { return assert(false) }

        // Send the packet.
        if let socket = socket {
            let hostAddr = hostAddress!.withUnsafeBytes({ $0.baseAddress!.assumingMemoryBound(to: sockaddr.self) })
            bytesSent = sendto(CFSocketGetNative(socket), Array<UInt8>(packet), packet.count, 0, hostAddr, socklen_t(hostAddress!.count))
            err = 0
            if bytesSent < 0 {
                err = errno
            }
        } else {
            bytesSent = -1
            err = EBADF
        }

        // Handle the results of the send.
        if (bytesSent > 0) && (bytesSent == packet.count) {

            // Complete success.  Tell the client.
            delegate?.icmpPing(self, didSend: packet, sequenceNumber: nextSequenceNumber)
        } else {
            // Some sort of failure.  Tell the client.
            if (err == 0) {
                err = ENOBUFS          // This is not a hugely descriptor error, alas.
            }
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(err), userInfo: nil)
            delegate?.icmpPing(self, didFailToSend: packet, sequenceNumber: nextSequenceNumber, error:error)
        }
        
        nextSequenceNumber += 1
        if nextSequenceNumber == 0 {
            nextSequenceNumberHasWrapped = true
        }
    }
    
    /// Starts the send and receive infrastructure.
    /// - Note: This is called once we've successfully resolved `hostName` in to `hostAddress`.  It's responsible for setting up the socket for sending and receiving pings.
    private func startWithHostAddress() {
        guard let hostAddr = hostAddress else { return assert(hostAddress != nil) }
        
        var err: Int32 = 0
        var fd: Int32 = -1
        
        // Open the socket.
        switch hostAddressFamily {
        case AF_INET:
            fd = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)
            if fd < 0 {
                err = errno
            }
        case AF_INET6:
            fd = Darwin.socket(AF_INET6, SOCK_DGRAM, IPPROTO_ICMPV6)
            if fd < 0 {
                err = errno
            }
        default:
            err = EPROTONOSUPPORT
        }
        
        if err != 0 {
            didFail(with: NSError(domain: NSPOSIXErrorDomain, code: Int(err), userInfo: nil))
        } else {
            var context = CFSocketContext(version: 0, info: unsafeBitCast(self, to: UnsafeMutableRawPointer.self), retain: nil, release: nil, copyDescription: nil)
                        
            // Wrap it in a CFSocket and schedule it on the runloop.
            socket = CFSocketCreateWithNative(nil, fd, CFSocketCallBackType.readCallBack.rawValue, ddy_socketReadCallback, &context)
            assert(socket != nil)
            
            // The socket will now take care of cleaning up our file descriptor.
            assert((CFSocketGetSocketFlags(socket) & kCFSocketCloseOnInvalidate) != 0)
            fd = -1
            
            let rls = CFSocketCreateRunLoopSource(nil, socket, 0)
            assert(rls != nil)
            
            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, CFRunLoopMode.defaultMode)
            
            delegate?.icmpPing(self, didStartWith: hostAddr)
        }
        assert(fd == -1)
    }
    
    /// Stops the name-to-address resolution infrastructure.
    private func stopHostResolution() {
        // Shut down the CFHost.
        guard let host = host else { return }
        CFHostSetClient(host, nil, nil)
        CFHostUnscheduleFromRunLoop(host, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        self.host = nil
    }
    
    /// Stops the send and receive infrastructure.
    private func stopSocket() {
        guard let socket = socket else { return }
        CFSocketInvalidate(socket)
        self.socket = nil
    }
    
    /// Builds a ping packet from the supplied parameters.
    /// - Parameters:
    ///   - type: The packet type, which is different for IPv4 and IPv6.
    ///   - payload: Data to place after the ICMP header.
    ///   - requiresChecksum: Determines whether a checksum is calculated (IPv4) or not (IPv6).
    /// - Returns: A ping packet suitable to be passed to the kernel.
    private func pingPacket(withType type: UInt8, payload: Data, requiresChecksum: Bool) -> Data {
        var icmpHeader = DDYICMPHeader(type: type, code: 0, checksum: 0, identifier: identifier.bigEndian, sequenceNumber: nextSequenceNumber.bigEndian)
        let icmpHeaderLen = MemoryLayout.size(ofValue: icmpHeader)
        
        var packet = Data(count: icmpHeaderLen)
        memcpy(&packet, &icmpHeader, icmpHeaderLen)
        packet.append(payload)
        
        if requiresChecksum {
            // The IP checksum routine returns a 16-bit number that's already in correct byte order
            // (due to wacky 1's complement maths), so we just put it into the packet as a 16-bit unit.
            var checksum = ddy_in_cksum(packet)
            packet.replaceSubrange(2..<4, with: Data(bytes: &checksum, count: MemoryLayout.size(ofValue: checksum)))
        }
        return packet
    }
    
    /// Processes the results of our name-to-address resolution.
    /// - Note: Called by our CFHost resolution callback (HostResolveCallback) when host resolution is complete.  We just latch the first appropriate address and kick off the send and receive infrastructure.
    fileprivate func hostResolutionDone() {
        guard let host = host else { return }
        var resolved: DarwinBoolean = false
        
        // Find the first appropriate address.
        if let addresses = CFHostGetAddressing(host, &resolved), resolved.boolValue {
            resolved = false
            if let addresses = addresses.takeUnretainedValue() as? [Data] {
                for address in addresses {
                    address.withUnsafeBytes {
                        if let baseAddress = $0.baseAddress, !$0.isEmpty {
                            let addrPtr = baseAddress.assumingMemoryBound(to: sockaddr.self)
                            switch addrPtr.pointee.sa_family {
                            case sa_family_t(AF_INET):
                                if addressStyle != .icmpv6 { hostAddress = address; resolved = true }
                            case sa_family_t(AF_INET6):
                                if addressStyle != .icmpv4 { hostAddress = address; resolved = true }
                            default:
                                break
                            }
                        }
                    }
                    if resolved.boolValue { break }
                }
            }
        }
        
        // We're done resolving, so shut that down.
        stopHostResolution()
        // If all is OK, start the send and receive infrastructure, otherwise stop.
        if resolved.boolValue {
            startWithHostAddress()
        } else {
            didFail(with: NSError(domain: String(kCFErrorDomainCFNetwork), code: Int(CFNetworkErrors.cfHostErrorHostNotFound.rawValue), userInfo: nil))
        }
    }
    
    /// Reads data from the ICMP socket.
    /// - Note: Called by the socket handling code (SocketReadCallback) to process an ICMP message waiting on the socket.
    fileprivate func readData() {
        var addr = sockaddr_storage()
        var addrLen = socklen_t(MemoryLayout.size(ofValue: addr))
        
        // 65535 is the maximum IP packet size, which seems like a reasonable bound here (plus it's what <x-man-page://8/ping> uses).
        var buffer = [CChar](repeating: 0, count: 65535)
        
        // Actually read the data.  We use recvfrom(), and thus get back the source address,
        // but we don't actually do anything with it.  It would be trivial to pass it to the delegate but we don't need it in this example.
        let bytesRead = withUnsafeMutableBytes(of: &addr) { (body) -> Int in
            if let baseAddress = body.baseAddress {
                return recvfrom(CFSocketGetNative(socket), &buffer, buffer.count, 0, baseAddress.assumingMemoryBound(to: sockaddr.self), &addrLen)
            }
            return 0
        }
        
        var err: Int32 = 0
        if bytesRead < 0 {
            err = errno
        }
        
        // Process the data we read.
        if bytesRead > 0 {
            var sequenceNumber: UInt16 = 0
            var packet = Data(bytes: &buffer, count: bytesRead)
            
            // We got some data, pass it up to our client.
            if validatePingResponsePacket(&packet, sequenceNumber: &sequenceNumber) {
                delegate?.icmpPing(self, didReceivePingResponse: packet, sequenceNumber: sequenceNumber)
            } else {
                delegate?.icmpPing(self, didReceiveUnexpected: packet)
            }
        } else {
            // We failed to read the data, so shut everything down.
            if err == 0 { err = EPIPE }
            didFail(with: NSError(domain: NSPOSIXErrorDomain, code: Int(err), userInfo: nil))
        }
        
        // Note that we don't loop back trying to read more data.  Rather, we just let CFSocket call us again.
    }
    
    /// Checks whether an incoming packet looks like a ping response.
    /// - Parameters:
    ///   - packet: The packet, as returned to us by the kernel; note that may end up modifying this data.
    ///   - sequenceNumber: A pointer to a place to start the ICMP sequence number.
    /// - Returns: YES if the packet looks like a reasonable IPv4 ping response.
    private func validatePingResponsePacket(_ packet: inout Data, sequenceNumber: inout UInt16) -> Bool {
        switch hostAddressFamily {
        case AF_INET:  return validatePing4ResponsePacket(&packet, sequenceNumber: &sequenceNumber)
        case AF_INET6: return validatePing6ResponsePacket(&packet, sequenceNumber: &sequenceNumber)
        default: assert(false);     return false
        }
    }
    
    /// Checks whether an incoming IPv4 packet looks like a ping response.
    /// - Parameters:
    ///   - packet: The IPv4 packet, as returned to us by the kernel.
    ///   - sequenceNumber: A pointer to a place to start the ICMP sequence number.
    /// - Returns: YES if the packet looks like a reasonable IPv4 ping response.
    /// - Note: This routine modifies this `packet` data!  It does this for two reasons:
    ///   * It needs to zero out the `checksum` field of the ICMPHeader in order to do its checksum calculation.
    ///   * It removes the IPv4 header from the front of the packet.
    private func validatePing4ResponsePacket(_ packet: inout Data, sequenceNumber: inout UInt16) -> Bool {
        guard let icmpHeaderOffset = DDYICMPPing.icmpHeaderOffset(inIPv4Packet: packet) else { return false }
        var icmpData = Data(packet[icmpHeaderOffset..<packet.count])
        return icmpData.withUnsafeBytes { (body) -> Bool in
            if let baseAddress = body.baseAddress {
                let icmpPtr = baseAddress.assumingMemoryBound(to: DDYICMPHeader.self)
                let receivedChecksum = icmpPtr.pointee.checksum
                var calculatedChecksum: UInt16 = 0
                icmpData.replaceSubrange(2..<4, with: Data(bytes: &calculatedChecksum, count: MemoryLayout.size(ofValue: calculatedChecksum)))
                calculatedChecksum = ddy_in_cksum(icmpData)
                //icmpPtr.pointee.checksum = receivedChecksum
                if receivedChecksum == calculatedChecksum
                    && ((icmpPtr.pointee.type == DDYICMPv4TypeEcho.reply.rawValue)
                        && (icmpPtr.pointee.code == 0)) && icmpPtr.pointee.identifier.bigEndian == identifier {
                    let sequenceNumberValue = icmpPtr.pointee.sequenceNumber.bigEndian
                    if validateSequenceNumber(sequenceNumberValue) {
                        // Remove the IPv4 header off the front of the data we received, leaving us with just the ICMP header and the ping payload.
                        packet.replaceSubrange(0..<icmpHeaderOffset, with: Data())
                        sequenceNumber = sequenceNumberValue
                        return true
                    }
                }
            }
            return false
        }
    }
    
    /// Checks whether an incoming IPv6 packet looks like a ping response.
    /// - Parameters:
    ///   - packet: The IPv6 packet, as returned to us by the kernel; note that this routine could modify this data but does not need to in the IPv6 case.
    ///   - sequenceNumber: A pointer to a place to start the ICMP sequence number.
    /// - Returns: true if the packet looks like a reasonable IPv4 ping response.
    private func validatePing6ResponsePacket(_ packet: inout Data, sequenceNumber: inout UInt16) -> Bool {
        guard packet.count >= MemoryLayout<DDYICMPHeader>.size else { return false }
        return packet.withUnsafeBytes { (body) -> Bool in
            if let baseAddress = body.baseAddress {
                let icmpPtr = baseAddress.assumingMemoryBound(to: DDYICMPHeader.self)
                // In the IPv6 case we don't check the checksum because that's hard (we need to  cook up an IPv6 pseudo header and we don't have the ingredients)
                // and unnecessary (the kernel has already done this check).
                if (icmpPtr.pointee.type == DDYICMPv6TypeEcho.reply.rawValue) && (icmpPtr.pointee.code == 0) && icmpPtr.pointee.identifier.bigEndian == identifier {
                    let sequenceNumberValue = icmpPtr.pointee.sequenceNumber.bigEndian
                    if validateSequenceNumber(sequenceNumberValue) {
                        sequenceNumber = sequenceNumberValue
                        return true
                    }
                }
            }
            return false
        }
    }
    
    /// Checks whether the specified sequence number is one we sent.
    /// - Parameter sequenceNumber: The incoming sequence number.
    /// - Returns: true if the sequence number looks like one we sent.
    private func validateSequenceNumber(_ sequenceNumber: UInt16) -> Bool {
        guard nextSequenceNumberHasWrapped else { return sequenceNumber < nextSequenceNumber }
        // If the sequence numbers have wrapped that we can't reliably check whether this is a sequence number we sent.  Rather, we check to see
        // whether the sequence number is within the last 120 sequence numbers we sent.  Note that the uint16_t subtraction here does the right
        // thing regardless of the wrapping.
        //
        // Why 120?  Well, if we send one ping per second, 120 is 2 minutes, which is the standard "max time a packet can bounce around the Internet" value.
        return (nextSequenceNumber - sequenceNumber) < 120
    }
    
    /// Calculates the offset of the ICMP header within an IPv4 packet.
    /// - Parameter packet: The IPv4 packet, as returned to us by the kernel.
    /// - Returns: The offset of the ICMP header, or nil.
    /// - Note: In the IPv4 case the kernel returns us a buffer that includes the IPv4 header.  We're not interested in that, so we have to skip over it.
    ///         This code does a rough check of the IPv4 header and, if it looks OK, returns the offset of the ICMP header.
    static private func icmpHeaderOffset(inIPv4Packet packet: Data) -> Int? {
        // Returns the offset of the ICMPv4Header within an IP packet.
        guard packet.count >= (MemoryLayout<DDYIPv4Header>.size + MemoryLayout<DDYICMPHeader>.size) else { return nil }
        return packet.withUnsafeBytes { (body) -> Int? in
            if let baseAddress = body.baseAddress {
                let ipPtr = baseAddress.assumingMemoryBound(to: DDYIPv4Header.self)
                if ((ipPtr.pointee.versionAndHeaderLength & 0xF0) == 0x40) && (ipPtr.pointee.protocol == IPPROTO_ICMP) { // IPv4
                    let ipHeaderLength = Int(ipPtr.pointee.versionAndHeaderLength & 0x0F) * MemoryLayout<UInt32>.size
                    if (packet.count >= (ipHeaderLength + MemoryLayout<DDYICMPHeader>.size)) {
                        return ipHeaderLength
                    }
                }
            }
            return nil
        }
    }
    
    /// Shuts down the pinger object and tell the delegate about the error.
    /// - Parameter error: Describes the failure.
    /// - Note: This converts the CFStreamError to an NSError and then call through to didFailWithError: to do the real work.
    fileprivate func didFail(withHostStreamError error: CFStreamError) {
        let userInfo: [String : Any]? = error.domain == kCFStreamErrorDomainNetDB ? [String(kCFGetAddrInfoFailureKey): error.error] : nil
        didFail(with: NSError(domain: String(kCFErrorDomainCFNetwork), code: Int(CFNetworkErrors.cfHostErrorUnknown.rawValue), userInfo: userInfo))
    }
    
    /// Shuts down the pinger object and tell the delegate about the error.
    /// - Parameter error: Describes the failure.
    private func didFail(with error: Error) {
        stop()
        delegate?.icmpPing(self, didFailWith: error)
    }
}

// MARK: - Static Func
/// Calculates an IP checksum.
/// - Parameter buffer: the data to checksum.
/// - Returns: The checksum value, in network byte order.
/// - Note: This is the standard BSD checksum code, modified to use modern types.
private func ddy_in_cksum(_ buffer: Data) -> UInt16 {
    return buffer.withUnsafeBytes { (body) -> UInt16 in
        if let baseAddress = body.baseAddress {
            var cursor = baseAddress.assumingMemoryBound(to: UInt16.self)
            
            var bytesLeft: Int = body.count
            var sum: Int32 = 0
            
            /// Our algorithm is simple, using a 32 bit accumulator (sum), we add sequential 16 bit words to it, and at the end, fold back all the carry bits from the top 16 bits into the lower 16 bits.
            while bytesLeft > 1 {
                sum += Int32(cursor.pointee)
                cursor = cursor.advanced(by: 1)
                bytesLeft -= 2
            }
            
            /// mop up an odd byte, if necessary
            if bytesLeft == 1 {
                sum += Int32(cursor.pointee & 0xff)
            }
            
            /// add back carry outs from top 16 bits to low 16 bits
            sum = (sum >> 16) + (sum & 0xffff)    // add hi 16 to low 16
            sum += (sum >> 16)            // add carry
            return UInt16(truncatingIfNeeded: ~sum) // truncate to 16 bits
        }
        return 0
    }
}

/// The callback for our CFHost object.
/// - Parameters:
///   - theHost: See the documentation for CFHostClientCallBack.
///   - typeInfo: See the documentation for CFHostClientCallBack.
///   - error: See the documentation for CFHostClientCallBack.
///   - info: See the documentation for CFHostClientCallBack; this is actually a pointer to the 'owning' object.
/// - Note: This simply routes the call to our `-hostResolutionDone` or `-didFailWithHostStreamError:` methods.
private func ddy_hostResolveCallback(_ theHost: CFHost, typeInfo: CFHostInfoType, error: UnsafePointer<CFStreamError>?, info: UnsafeMutableRawPointer?) -> Void {
    guard let info = info else { return }
    /// This C routine is called by CFHost when the host resolution is complete. It just redirects the call to the appropriate Objective-C method.
    let obj = unsafeBitCast(info, to: DDYICMPPing.self)
    
    assert(obj.host === theHost)
    assert(typeInfo == .addresses)
    
    if let error = error, error.pointee.domain != 0 {
        obj.didFail(withHostStreamError: error.pointee)
    } else {
        obj.hostResolutionDone()
    }
}

/// The callback for our CFSocket object.
/// - Parameters:
///   - s: See the documentation for CFSocketCallBack.
///   - type: See the documentation for CFSocketCallBack.
///   - address: See the documentation for CFSocketCallBack.
///   - data: See the documentation for CFSocketCallBack.
///   - info: See the documentation for CFSocketCallBack; this is actually a pointer to the 'owning' object.
/// - Note: This simply routes the call to our `readData()` method.
private func ddy_socketReadCallback(_ s: CFSocket?, type: CFSocketCallBackType, address: CFData?, data: UnsafeRawPointer?, info: UnsafeMutableRawPointer?) -> Void {
    guard let info = info else { return }
    // This C routine is called by CFSocket when there's data waiting on our ICMP socket.  It just redirects the call to Objective-C code.
    let obj = unsafeBitCast(info, to: DDYICMPPing.self)
    assert(obj.socket === s)
    assert(type == .readCallBack)
    assert(address == nil)
    assert(data == nil)
    obj.readData()
}

// MARK: -

/// Controls the IP address version used by SimplePing instances.
public enum DDYICMPPingAddressStyle {
    case any // Use the first IPv4 or IPv6 address found; the default.
    case icmpv4 // Use the first IPv4 address found.
    case icmpv6 // Use the first IPv6 address found.
}

private enum DDYICMPv4TypeEcho: UInt8 {
    case request = 8   // The ICMP `type` for a ping request in this case `code` is always 0.
    case reply   = 0   // The ICMP `type` for a ping response in this case `code` is always 0.
}
private enum DDYICMPv6TypeEcho: UInt8 {
    case request = 128 // The ICMP `type` for a ping request in this case `code` is always 0.
    case reply   = 129 // The ICMP `type` for a ping response in this case `code` is always 0.
}

// MARK: - IPv4 and ICMPv4 On-The-Wire Format

/// Describes the on-the-wire header format for an IPv4 packet.
/// - Note: This defines the header structure of IPv4 packets on the wire.  We need this in order to skip this header in the IPv4 case, where the kernel passes it to us for no obvious reason.
private struct DDYIPv4Header {
    let versionAndHeaderLength: UInt8
    let differentiatedServices: UInt8
    let totalLength: UInt16
    let identification: UInt16
    let flagsAndFragmentOffset: UInt16
    let timeToLive: UInt8
    let `protocol`: UInt8
    let headerChecksum: UInt16
    let sourceAddress: (UInt8, UInt8, UInt8, UInt8)
    let destinationAddress: (UInt8, UInt8, UInt8, UInt8)
    // options...
    // data...
}

// MARK: - ICMP On-The-Wire Format
/// Describes the on-the-wire header format for an ICMP ping.
/// - Note: This defines the header structure of ping packets on the wire.  Both IPv4 and IPv6 use the same basic structure.
///         This is declared in the header because clients of SimplePing might want to use it parse received ping packets.
private struct DDYICMPHeader {
    let type: UInt8
    let code: UInt8
    let checksum: UInt16
    let identifier: UInt16
    let sequenceNumber: UInt16
    // data...
}

