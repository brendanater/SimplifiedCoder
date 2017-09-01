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

protocol CanBeNil {
    var isNil: Bool {get}
}

extension NSNull: CanBeNil { var isNil: Bool { return true } }
extension Optional: CanBeNil {
    var isNil: Bool {
        if case .some(let wrapped) = self {
            if let canBeNil = wrapped as? CanBeNil {
                return canBeNil.isNil
            } else {
                return false
            }
        } else {
            return true
        }
    }
}

func isNil(_ value: Any?) -> Bool {
    return value.isNil
}

extension NumberFormatter {
    static var shared = NumberFormatter()
}

extension ISO8601DateFormatter {
    static let shared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        return formatter
    }()
}
