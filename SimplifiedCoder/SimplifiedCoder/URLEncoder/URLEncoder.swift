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
    
    // MARK: options
    
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
    
    // MARK: TopLevelEncoder
    
    func encode(_ value: Encodable) throws -> Data {
        
        do {
            return try self.serializer.queryData(from: self.encode(value: value))
            
        } catch {
            
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context.init(
                    codingPath: [],
                    debugDescription: "Unable to encode the given top-level value to a query",
                    underlyingError: error
                )
            )
        }
    }
    
    /// returns the value just before passing to serializer
    func encode(value: Encodable) throws -> Any {
        
        let value = try Base.start(
            with: value,
            options: (
                self.dateEncodingStrategy,
                self.dataEncodingStrategy,
                self.nonConformingFloatEncodingStrategy
            ),
            userInfo: self.userInfo
        )
        
        do {
            try URLQuerySerializer.assertValidObject(value)
            
            return value
            
        } catch {
            
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context.init(
                    codingPath: [],
                    debugDescription: "Incorrect URLQuery object encoded",
                    underlyingError: error
                )
            )
        }
    }
    
    // MARK: other encode types
    
    func encode(asQuery value: Encodable) throws -> String {
        
        return try self.serializer.query(from: self.encode(value: value))
    }
    
    func encode(asQueryItems value: Encodable) throws -> [URLQueryItem] {
        
        return try self.serializer.queryItems(from: self.encode(value: value))
    }
    
    // MARK: Base
    
    private class Base: TypedEncoderBase {
        
        static var keyedContainerContainerType: EncoderKeyedContainerContainer.Type = _OrderedDictionary.self
        static var unkeyedContainerType: EncoderUnkeyedContainer.Type = UnkeyedContainer.self
        
        typealias Options = URLEncoder.Options
        
        var codingPath: [CodingKey]
        var options: Options
        var userInfo: [CodingUserInfoKey : Any]
        var reference: EncoderReference?
        
        required init(codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any], reference: EncoderReference?) {
            self.codingPath = codingPath
            self.options = options
            self.userInfo = userInfo
            self.reference = reference
        }
        
        var storage: [Any] = []
        var canEncodeNewValue: Bool = true
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            return self.createKeyedContainer(URLEncoder.KeyedContainer<Key>.self)
        }
        
        deinit {
            self.willDeinit()
        }
        
        // MARK: start
        
        func start(with value: Encodable) throws -> Any {
            
            let value = try self.box(value, at: [])
            
            if let value = value as? _OrderedDictionary {
                return value.baseType()
            } else {
                return value
            }
        }
        
        // MARK: Boxing
        
        func box(_ value: Float, at codingPath: [CodingKey]) throws -> Any {
            return try self.box(floatingPoint: value, at: codingPath)
        }
        
        func box(_ value: Double, at codingPath: [CodingKey]) throws -> Any {
            return try self.box(floatingPoint: value, at: codingPath)
        }
        
        func box<T: FloatingPoint>(floatingPoint value: T, at codingPath: [CodingKey]) throws -> Any {
        
            if value.isInfinite || value.isNaN {
        
                guard case let .convertToString(
                    positiveInfinity: positiveString,
                    negativeInfinity: negitiveString,
                    nan: nan) = self.options.nonConformingFloatEncodingStrategy
                else {
                    throw EncodingError._invalidFloatingPointValue(value, at: codingPath)
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
        
        func box(_ value: Date, at codingPath: [CodingKey]) throws -> Any {
            
            switch self.options.dateEncodingStrategy {
                
            case .deferredToDate:
                return try self.reencode(value, at: codingPath)
        
            case .secondsSince1970:
                return NSNumber(value: value.timeIntervalSince1970)
        
            case .millisecondsSince1970:
                return NSNumber(value: 1000.0 * value.timeIntervalSince1970)
        
            case .iso8601:
                if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                    return ISO8601DateFormatter.shared.string(from: value)
                } else {
                    fatalError("ISO8601DateFormatter is unavailable on this platform.")
                }
        
            case .formatted(let formatter):
                return formatter.string(from: value)
        
            case .custom(let closure):
                
                return try self.reencode(type(of: value), at: codingPath, { try closure(value, self) })
            }
        }
        
        func box(_ value: Data, at codingPath: [CodingKey]) throws -> Any {
            
            switch self.options.dataEncodingStrategy {
                
            case .deferredToData:
                return try self.reencode(value, at: codingPath)
        
            case .base64:
                return value.base64EncodedString()
        
            case .custom(let closure):
                return try self.reencode(type(of: value), at: codingPath, { try closure(value, self) })
            }
        }
        
        func box(_ value: URL, at codingPath: [CodingKey]) throws -> Any {
            
            return value.absoluteString
        }
        
        func box(_ value: Encodable, at codingPath: [CodingKey]) throws -> Any {
        
            switch value {
            case is Date, is NSDate: return try box(value as! Date   , at: codingPath)
            case is Data, is NSData: return try box(value as! Data   , at: codingPath)
            case is URL , is NSURL : return try box(value as! URL    , at: codingPath)
            case is Decimal        : return try box(value as! Decimal, at: codingPath)
            default: return try reencode(value, at: codingPath)
            }
        }
    }
    
    // MARK: KeyedContainer
    
    private struct KeyedContainer<K: CodingKey>: EncoderKeyedContainer {
        
        typealias Key = K
        
        var encoder: EncoderBase
        var container: EncoderKeyedContainerContainer
        var nestedPath: [CodingKey]
        
        init(encoder: EncoderBase, container: EncoderKeyedContainerContainer, nestedPath: [CodingKey]) {
            self.encoder = encoder
            self.container = container
            self.nestedPath = nestedPath
        }
        
        static func initSelf<Key>(encoder: EncoderBase, container: EncoderKeyedContainerContainer, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            return KeyedEncodingContainer(KeyedContainer<Key>(encoder: encoder, container: container, nestedPath: nestedPath))
        }
        
        var usesStringValue: Bool = true
    }
    
    // MARK: UnkeyedContainer
    
    private struct UnkeyedContainer: EncoderUnkeyedContainer {
        
        var encoder: EncoderBase
        var container: EncoderUnkeyedContainerContainer
        var nestedPath: [CodingKey]
        
        init(encoder: EncoderBase, container: EncoderUnkeyedContainerContainer, nestedPath: [CodingKey]) {
            self.encoder = encoder
            self.container = container
            self.nestedPath = nestedPath
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return self.createKeyedContainer(KeyedContainer<NestedKey>.self)
        }
    }
}

fileprivate extension EncodingError {
    /// Returns a `.invalidValue` error describing the given invalid floating-point value.
    ///
    ///
    /// - parameter value: The value that was invalid to encode.
    /// - parameter path: The path of `CodingKey`s taken to encode this value.
    /// - returns: An `EncodingError` with the appropriate path and debug description.
    fileprivate static func _invalidFloatingPointValue<T : FloatingPoint>(_ value: T, at codingPath: [CodingKey]) -> EncodingError {
        let valueDescription: String
        if value == T.infinity {
            valueDescription = "\(T.self).infinity"
        } else if value == -T.infinity {
            valueDescription = "-\(T.self).infinity"
        } else {
            valueDescription = "\(T.self).nan"
        }
        
        let debugDescription = "Unable to encode \(valueDescription) directly in JSON. Use JSONEncoder.NonConformingFloatEncodingStrategy.convertToString to specify how the value should be encoded."
        return .invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: debugDescription))
    }
}

/// needed order for query and a tupleArray was too hard to use.
/// before using value, call baseType()
fileprivate final class _OrderedDictionary: EncoderKeyedContainerContainer {
    
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














