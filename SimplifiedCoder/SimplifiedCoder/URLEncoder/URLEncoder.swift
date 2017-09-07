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
    
    enum Error: Swift.Error {
        case incorrectTopLevelObject(Any, ofType: Any.Type)
        case cannotEncodeToData(queryString: String)
    }
    
    func encode(_ value: Encodable) throws -> Data {
        
        let string = try encode(asQueryString: value)
        
        guard let data = string.data(using: .utf8, allowLossyConversion: false) else {
            throw Error.cannotEncodeToData(queryString: string)
        }
        
        return data
    }
    
    func encode(asQueryString value: Encodable) throws -> String {
        
        var components: URLComponents = URLComponents(url: URL(string: "notAURL.com/")!, resolvingAgainstBaseURL: false)!
        
        components.queryItems = try encode(asQuery: value)
        
        return components.query!
    }
    
    func encode(asQuery value: Encodable) throws -> [URLQueryItem] {
        
        let encoder = Base(
            options: (
                dateEncodingStrategy,
                dataEncodingStrategy,
                nonConformingFloatEncodingStrategy
            ),
            userInfo: userInfo
        )
        
        let value = try encoder.box(value)
        
        if let container = (value as? _OrderedDictionary)?.elements as? [(key: String, value: Any)] {
            
            return try serializer.serialize(container)
            
        } else {
            
            throw Error.incorrectTopLevelObject(value, ofType: type(of: value))
        }
    }
    
    private class Base: EncoderBase {
        
        typealias KeyedContainer = URLEncoder.KeyedContainer<String>
        typealias UnkeyedContainer = URLEncoder.UnkeyedContainer
        typealias Options = URLEncoder.Options
        
        var options: Options
        var userInfo: [CodingUserInfoKey : Any]
        
        required init(options: Options, userInfo: [CodingUserInfoKey : Any]) {
            self.options = options
            self.userInfo = userInfo
        }
        
        var storage: [(key: CodingKey?, value: Any)] = []
        var key: CodingKey? = nil
        
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
    }
    
    private struct KeyedContainer<K: CodingKey>: EncoderKeyedContainer {
        
        typealias UnkeyedContainer = URLEncoder.UnkeyedContainer
        typealias Reference = URLEncoder.Reference
        typealias Base = URLEncoder.Base
        typealias Key = K
        typealias Container = _OrderedDictionary
        
        var encoder: URLEncoder.Base
        var container: Container
        var nestedPath: [CodingKey]
        
        init(encoder: URLEncoder.Base, container: Container, nestedPath: [CodingKey]) {
            self.encoder = encoder
            self.container = container
            self.nestedPath = nestedPath
        }
        
        static func initSelf<Key>(encoder: URLEncoder.Base, container: Container, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            return KeyedEncodingContainer(KeyedContainer<Key>(encoder: encoder, container: container, nestedPath: nestedPath))
        }
        
        static var usesStringValue: Bool {
            return true
        }
    }
    
    private struct UnkeyedContainer: EncoderUnkeyedContainer {
        
        typealias KeyedContainer = URLEncoder.KeyedContainer<String>
        typealias Reference = URLEncoder.Reference
        typealias Base = URLEncoder.Base
        
        var encoder: URLEncoder.Base
        var container: NSMutableArray
        var nestedPath: [CodingKey]
        
        init(encoder: URLEncoder.Base, container: NSMutableArray, nestedPath: [CodingKey]) {
            self.encoder = encoder
            self.container = container
            self.nestedPath = nestedPath
        }
    }
    
    private class Reference: Base, EncoderReference {
        
        typealias Super = URLEncoder.Base
        
        var reference: EncoderReferenceValue = .unkeyed(NSMutableArray(), index: 0)
        var previousPath: [CodingKey] = []
    }
}

fileprivate enum _FloatingPointError<T: FloatingPoint>: Error {
    case invalidFloatingPoint(T)
}

fileprivate final class _OrderedDictionary: OrderedDictionaryProtocol, EncoderKeyedContainerType {
    
    typealias Key = AnyHashable
    typealias Value = Any

    typealias Element = (key: Key, value: Value)

    var elements: [Element]

    init() {
        self.elements = []
    }

    init(_ elements: [Element]) {
        self.elements = elements
    }
    
    subscript(key: Any) -> Any? {
        get {
            return self[key as! AnyHashable]
        }
        set {
            self[key as! AnyHashable] = newValue
        }
    }
}


//fileprivate class <K: Hashable, V>: OrderedDictionaryProtocol, EncoderKeyedContainerType {
//
//
//    typealias Key = K
//    typealias Value = V
//
//    typealias Element = (key: Key, value: Value)
//
//    var elements: [Element]
//
//    required init() {
//        self.elements = []
//    }
//
//    required init(_ elements: [Element]) {
//        self.elements = elements
//    }
//
//    subscript(key: Any) -> Any? {
//
//        get {
//            return self[key as! Key]
//        }
//        set {
//            self[key as! Key] = newValue as! Value?
//        }
//    }
//}

//fileprivate protocol _K: EncoderKeyedContainerType {
//
//}
//
//extension OrderedDictionary: _K {
//
//    subscript(key: Any) -> Any? {
//        get {
//            return self[key as! Key]
//        }
//        set {
//            self[key as! Key] = newValue as! Value?
//        }
//    }
//}














