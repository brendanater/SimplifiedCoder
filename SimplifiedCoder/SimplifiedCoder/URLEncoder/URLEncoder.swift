//
//  URLEncoder.swift
//  URLEncoder
//
//  Created by Brendan Henderson on 8/31/17.
//  Copyright © 2017 OKAY. All rights reserved.
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

/// requires top level object to be a keyed container
struct URLEncoder: TopLevelEncoder {
    
    var serializer = URLQuerySerializer()
    var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate
    var dataEncodingStrategy: JSONEncoder.DataEncodingStrategy = .deferredToData
    var nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy = .throw
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    typealias Options = (
        dateEncodingStrategy: JSONEncoder.DateEncodingStrategy,
        dataEncodingStrategy: JSONEncoder.DataEncodingStrategy,
        nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy
    )
    
    enum URLEncoderError: Swift.Error {
        case incorrectTopLevelObject(Any)
        case cannotEncodeToData(queryString: String)
    }
    
    func encode(_ value: Encodable) throws -> Data {
        
        return try self.serializer.queryData(from: self.encode(asObject: value))
    }
    
    func encode(asQuery value: Encodable) throws -> String {
        
        return try self.serializer.query(from: self.encode(asObject: value))
    }
    
    func encode(asQueryItems value: Encodable) throws -> [URLQueryItem] {
        
        return try self.serializer.queryItems(from: self.encode(asObject: value))
    }
    
    func encode(asObject value: Encodable) throws -> [(key: String, value: Any)] {
        
        let encoder = Base(
            options: (
                self.dateEncodingStrategy,
                self.dataEncodingStrategy,
                self.nonConformingFloatEncodingStrategy
            ),
            userInfo: self.userInfo
        )
        
        let value = try encoder.box(value)
        
        if let container = (value as? _OrderedDictionary)?.baseType() {
            
            return container
            
        } else {
            
            throw URLEncoderError.incorrectTopLevelObject(value)
        }
    }
    
    private class Base: TypedEncoderBase {
        
        lazy var keyedContainerContainerType: EncoderKeyedContainerType.Type = _OrderedDictionary.self
        
        lazy var unkeyedContainerType: EncoderUnkeyedContainer.Type = UnkeyedContainer.self
        lazy var referenceType: EncoderReference.Type = Reference.self
        
        typealias Options = URLEncoder.Options
        var options: Options
        
        var userInfo: [CodingUserInfoKey : Any]
        
        required init(options: Options, userInfo: [CodingUserInfoKey : Any]) {
            self.options = options
            self.userInfo = userInfo
        }
        
        var storage: [(key: CodingKey?, value: Any)] = []
        var key: CodingKey? = nil
        
        var codingPath: [CodingKey] {
            return _codingPath
        }
        
        // boxing
        
        func box(_ value: Float) throws -> Any {
            return try self.box(floatingPoint: value)
        }
        
        func box(_ value: Double) throws -> Any {
            return try self.box(floatingPoint: value)
        }
        
        func box<T: FloatingPoint>(floatingPoint value: T) throws -> Any {
        
            if value.isInfinite || value.isNaN {
        
                guard case let .convertToString(
                    positiveInfinity: positiveString,
                    negativeInfinity: negitiveString,
                    nan: nan) = self.options.nonConformingFloatEncodingStrategy
                else {
                    throw _FloatingPointError.invalidFloatingPoint(value)
                }
        
                switch value {
                case .infinity: return positiveString
                case -.infinity: return negitiveString
                default: return nan
                }
        
            } else {
                return value
            }
        }
        
        func box(_ date: Date) throws -> Any {
            switch self.options.dateEncodingStrategy {
            case .deferredToDate:
                // Must be called with a surrounding with(pushedKey:) call.
                try date.encode(to: self)
                return self.storage.removeLast()
        
            case .secondsSince1970:
                return NSNumber(value: date.timeIntervalSince1970)
        
            case .millisecondsSince1970:
                return NSNumber(value: 1000.0 * date.timeIntervalSince1970)
        
            case .iso8601:
                if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                    return NSString(string: ISO8601DateFormatter.shared.string(from: date))
                } else {
                    fatalError("ISO8601DateFormatter is unavailable on this platform.")
                }
        
            case .formatted(let formatter):
                return NSString(string: formatter.string(from: date))
        
            case .custom(let closure):
                let depth = self.storage.count
                try closure(date, self)
        
                guard self.storage.count > depth else {
                    //return default, throw, or fatal (I picked fatal because an encoder should encodeNil() even if it is nil)
                    fatalError("Encoder did not encode any values")
                }
        
                return self.storage.removeLast()
            }
        }
        
        func box(_ data: Data) throws -> Any {
            switch self.options.dataEncodingStrategy {
            case .deferredToData:
                // data encodes a value (no need to check)
                try data.encode(to: self)
                return self.storage.removeLast()
        
            case .base64:
                return NSString(string: data.base64EncodedString())
        
            case .custom(let closure):
                let count = self.storage.count
        
                try closure(data, self)
        
                guard self.storage.count > count else {
                    //return default, throw, or fatal (I picked fatal because an encoder should encodeNil() even if it is nil)
                    fatalError("Encoder did not encode any values")
                }
        
                // We can pop because the closure encoded something.
                return self.storage.removeLast()
            }
        }
        
        func box(_ value: URL) throws -> Any { return value.absoluteString }
        
        func box(_ value: Encodable) throws -> Any {
        
            switch value {
            case is Date   , is NSDate: return try box(value as! Date   )
            case is Data   , is NSData: return try box(value as! Data   )
            case is URL    , is NSURL : return try box(value as! URL    )
            case is Decimal           : return try box(value as! Decimal)
            default: return try reencode(value)
            }
        }
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            return self.createKeyedContainer(URLEncoder.KeyedContainer<Key>.self)
        }
    }
    
    private struct KeyedContainer<K: CodingKey>: EncoderKeyedContainer {
        
        typealias Key = K
        
        var encoder: EncoderBase
        var container: EncoderKeyedContainerType
        var nestedPath: [CodingKey]
        
        init(encoder: EncoderBase, container: EncoderKeyedContainerType, nestedPath: [CodingKey]) {
            self.encoder = encoder
            self.container = container
            self.nestedPath = nestedPath
        }
        
        static func initSelf<Key>(encoder: EncoderBase, container: EncoderKeyedContainerType, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            return KeyedEncodingContainer(KeyedContainer<Key>.init(encoder: encoder, container: container, nestedPath: nestedPath))
        }
        
        var usesStringValue: Bool {
            return true
        }
    }
    
    private struct UnkeyedContainer: EncoderUnkeyedContainer {
        
        var encoder: EncoderBase
        var container: EncoderUnkeyedContainerType
        var nestedPath: [CodingKey]
        
        init(encoder: EncoderBase, container: EncoderUnkeyedContainerType, nestedPath: [CodingKey]) {
            self.encoder = encoder
            self.container = container
            self.nestedPath = nestedPath
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return self.createKeyedContainer(KeyedContainer<NestedKey>.self)
        }
    }
    
    private class Reference: Base, EncoderReference {
        
        var reference: EncoderReferenceValue = .keyed(NSMutableDictionary(), key: "")
        var previousPath: [CodingKey] = []
        
        lazy var usesStringValue: Bool = true
        
        override var codingPath: [CodingKey] {
            return _codingPath
        }
        
        deinit {
            willDeinit()
        }
    }
}

fileprivate enum _FloatingPointError<T: FloatingPoint>: Error {
    case invalidFloatingPoint(T)
}

/// needed order for query and a tupleArray was too hard to use.
/// before using value, call baseType()
fileprivate final class _OrderedDictionary: EncoderKeyedContainerType {
    
    typealias Element = (key: String, value: Any)
    typealias Elements = [Element]

    var elements: Elements

    init() {
        self.elements = []
    }
    
    func set(toStorage value: Any, forKey key: AnyHashable) {
        
        let key = key as! String
        
        if let index = self.elements.index(where: { $0.key == key }) {
            self.elements.remove(at: index)
            
            self.elements.insert((key, value), at: index)
        } else {
            self.elements.append((key, value))
        }
    }
    
    /// casts all _OrderedDictionaries to Tuple-Arrays
    func baseType() -> Elements {
        return baseType(self.elements) as! Elements
    }
    
    func baseType(_ value: Any) -> Any {
        
        if let value = value as? _OrderedDictionary {
            
            return value.baseType()
            
        } else if let value = value as? Elements {
            
            return value.map { ($0, self.baseType($1)) }
            
        } else if let value = value as? NSArray {
            
            return value.map(self.baseType(_:))
            
        } else {
            
            return value
            
        }
    }
}














