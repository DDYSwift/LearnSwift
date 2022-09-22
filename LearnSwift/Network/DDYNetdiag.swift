//
//  DDYNetdiag.swift
//  LearnSwift
//
//  Created by ddy on 2022/9/19.
//

import Foundation

public class DDYNetdiag {
    
    public static let shared = { return DDYNetdiag() }()
    
    public private(set) lazy var netInfo = DDYNetInfo()
    
    
    
}
