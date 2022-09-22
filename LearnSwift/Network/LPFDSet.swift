//
//  DDYFDSet.swift
//  DDYNetdiagDemo
//
//  Created by pengli on 2019/11/28.
//  Copyright © 2019 pengli. All rights reserved.
//

import Darwin

private let ddy_fd_set_count = Int(__DARWIN_FD_SETSIZE) / 32
extension fd_set {
    @inline(__always)
    mutating func ddy_withCArrayAccess<T>(block: (UnsafeMutablePointer<Int32>) throws -> T) rethrows -> T {
        return try withUnsafeMutablePointer(to: &fds_bits) {
            try block(UnsafeMutableRawPointer($0).assumingMemoryBound(to: Int32.self))
        }
    }
    
    @inline(__always)
    private static func ddy_address(for fd: Int32) -> (Int, Int32) {
        var intOffset = Int(fd) / ddy_fd_set_count
        #if _endian(big)
        if intOffset % 2 == 0 {
            intOffset += 1
        } else {
            intOffset -= 1
        }
        #endif
        let bitOffset = Int(fd) % ddy_fd_set_count
        let mask = Int32(bitPattern: UInt32(1 << bitOffset))
        return (intOffset, mask)
    }
    
    /// 将fd_set归零（替换FD_ZERO宏）
    public mutating func ddy_zero() {
        ddy_withCArrayAccess { $0.initialize(repeating: 0, count: ddy_fd_set_count) }
    }
    
    /// 在fd_set中设置一个fd（替换FD_SET宏）
    /// - Parameter fd:    要添加到fd_set的fd
    public mutating func ddy_set(_ fd: Int32) {
        let (index, mask) = fd_set.ddy_address(for: fd)
        ddy_withCArrayAccess { $0[index] |= mask }
    }
    
    /// 从fd_set清除fd（替换FD_CLR宏）
    /// - Parameter fd:    从fd_set清除的fd
    public mutating func ddy_clear(_ fd: Int32) {
        let (index, mask) = fd_set.ddy_address(for: fd)
        ddy_withCArrayAccess { $0[index] &= ~mask }
    }
    
    /// 检查fd_set中是否存在fd（替换FD_ISSET宏）
    public mutating func ddy_isSet(_ fd: Int32) -> Bool {
        let (index, mask) = fd_set.ddy_address(for: fd)
        return ddy_withCArrayAccess { $0[index] & mask != 0 }
    }
}
