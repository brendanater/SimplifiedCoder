//
//  Extensions.swift
//  SimplifiedCoder
//
//  Created by Brendan Henderson on 8/31/17.
//  Copyright © 2017 OKAY.
//
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

// CodingKey

/// a codingKey where the intValue is never nil and the stringValue is always "Index " + self.intValue!.description
public struct CodingIndexKey: CodingKey {
    
    public var stringValue: String {
        return "Index " + self.intValue!.description
    }
    
    public var intValue: Int?
    
    public init?(stringValue: String) {
        
        if let index = Int(stringValue) {
            
            self.intValue = index
            
        } else if stringValue.hasPrefix("Index ") {
            
            self.intValue = Int(stringValue[stringValue.index(stringValue.startIndex, offsetBy: 6)..<stringValue.endIndex].description)
            
        } else {
            
            return nil
        }
    }
    
    public init(intValue: Int) {
        self.intValue = intValue
    }
}

/// a coding key where the stringValue is always "super" and the intValue is always nil
public struct CodingSuperKey: CodingKey {
    
    public var stringValue: String = "super"
    
    public init() {}
    
    public init?(stringValue: String) {
        if stringValue != "super" {
            return nil
        }
    }
    
    public var intValue: Int? = nil
    
    public init?(intValue: Int) {
        return nil
    }
}

func ==(lhs: CodingKey, rhs: CodingKey) -> Bool {
    return lhs.stringValue == rhs.stringValue && lhs.intValue == rhs.intValue
}

public func equalPaths(_ path1: [CodingKey], _ path2: [CodingKey]) -> Bool {
    
    guard path1.count == path2.count else {
        return false
    }
    
    for (key1, key2) in zip(path1, path2) {
        
        guard key1 == key2 else {
            
            return false
        }
    }
    
    return true
}

// errors

public extension DecodingError {
    public var context: Context {
        switch self {
        case let .dataCorrupted(context): return context
        case let .keyNotFound(_, context): return context
        case let .typeMismatch(_, context): return context
        case let .valueNotFound(_, context): return context
        }
    }
}

public extension EncodingError {
    public var context: Context {
        switch self {
        case let .invalidValue(_, context): return context
        }
    }
    
    public var value: Any {
        switch self {
        case let .invalidValue(value, _): return value
        }
    }
    
    public var values: (value: Any, context: Context) {
        switch self {
        case let .invalidValue(value, context): return (value, context)
        }
    }
}

// user info

extension CodingUserInfoKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        
        if let _self = CodingUserInfoKey._init_(rawValue: value) {
            
            self = _self
            
        } else {
            fatalError("Failed to init \(CodingUserInfoKey.self) with stringLiteral: \(value)")
        }
    }
    
    private static func _init_(rawValue: String) -> CodingUserInfoKey? {
        return self.init(rawValue: rawValue)
    }
}

// can be nil

public protocol CanBeNil {
    var isNil: Bool {get}
}

extension NSNull: CanBeNil { public var isNil: Bool { return true } }
extension Optional: CanBeNil {
    public var isNil: Bool {
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

public func isNil(_ value: Any?) -> Bool {
    return value.isNil
}

// optional

fileprivate protocol _OptionalWrapping {
    var _wrapped: Any? {get}
}

extension Optional: _OptionalWrapping {
    var _wrapped: Any? {
        return self
    }
}

/// returns the value as? an Optional without nesting the value
public func asOptional<T>(_: T.Type, _ value: Any) -> T?? {
    
    if value is _OptionalWrapping {
        return (value as! _OptionalWrapping)._wrapped as? T?
    } else {
        return nil
    }
}

// shared

public extension NumberFormatter {
    public static var shared = NumberFormatter()
}

public extension ISO8601DateFormatter {
    public static let shared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        return formatter
    }()
}

// NSNumber

public extension NSNumber {
    var isBoolean: Bool {
        return self === kCFBooleanTrue || self === kCFBooleanFalse
    }
}

// ObjectIdentifier

public typealias TypeID = ObjectIdentifier

// array

public extension Array {
    
    /**
     gets an ArraySlice or returns nil using subscript range:
     index * count ..< min((index * count) + count, self.endIndex)
     
     example:
     
     let array = [0,1,2,3,4,5,6,7]
     
     [0,1,2]
     let firstSlice = arraySlice(at: 0, count: 3)
     
     [3,4,5]
     let secondSlice = arraySlice(at: 1, count: 3)
     
     [6,7]
     let thirdSlice = arraySlice(at: 2, count: 3)
     
     nil
     let fourthSlice = arraySlice(at: 3, count: 3)
     
     */
    public func slice(at index: Int, count: Int) -> ArraySlice<Element>? {
        
        let index = index * count
        
        if index < self.endIndex {
            return self[index..<Swift.min(index + count, self.endIndex)]
        } else {
            return nil
        }
    }
}

// dictionary

public extension Dictionary {
    init(_ elements: [Element]) {
        self.init()
        for (key, value) in elements {
            self[key] = value
        }
    }
}


