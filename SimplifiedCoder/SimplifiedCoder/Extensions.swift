//
//  Extensions.swift
//  SimplifiedCoder
//
//  Created by Brendan Henderson on 8/31/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import Foundation


extension String: CodingKey {
    
    public var stringValue: String {
        return self
    }
    
    public init(stringValue: String) {
        self = stringValue
    }
    
    public var intValue: Int? {
        return Int(self)
    }
    
    public init?(intValue: Int) {
        self = "\(intValue)"
    }
}
