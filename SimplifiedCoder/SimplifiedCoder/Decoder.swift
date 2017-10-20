//
//  Decoder.swift
//  SimplifiedCoder
//
//  Created by Brendan Henderson on 8/27/17.
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
import Swift

/// the decoder that the user calls to abstract away complexity
public protocol TopLevelDecoder {
    
    var userInfo: [CodingUserInfoKey : Any] {get set}
    
    func decode<T: Decodable>(_: T.Type, from data: Data) throws -> T
    func decode<T: Decodable>(_: T.Type, fromValue value: Any) throws -> T
}

// MARK: AnyBase

/// must be a class, so that references reference the same decoder
public protocol AnyDecoderBase: class, Decoder, SingleValueDecodingContainer {
    
    /// whether to get from container using the CodingKey's .stringValue or .intValue!
    static var usesStringValue: Bool {get}
    
    var codingPath: [CodingKey] {get set}
    var untypedOptions: Any {get}
    var userInfo: [CodingUserInfoKey : Any] {get}
    
    init(codingPath: [CodingKey], untypedOptions: Any, userInfo: [CodingUserInfoKey : Any])
    
    var storage: [Any] {get set} // = []
    
    // optional overridable methods
    
    func start<T: Decodable>(with value: Any) throws -> T
    
    var currentValue: Any {get}
    
    // MARK: decode
    
    func decodeNil() -> Bool
    func decode(_ type: Bool  .Type) throws -> Bool
    func decode(_ type: Int   .Type) throws -> Int
    func decode(_ type: Int8  .Type) throws -> Int8
    func decode(_ type: Int16 .Type) throws -> Int16
    func decode(_ type: Int32 .Type) throws -> Int32
    func decode(_ type: Int64 .Type) throws -> Int64
    func decode(_ type: UInt  .Type) throws -> UInt
    func decode(_ type: UInt8 .Type) throws -> UInt8
    func decode(_ type: UInt16.Type) throws -> UInt16
    func decode(_ type: UInt32.Type) throws -> UInt32
    func decode(_ type: UInt64.Type) throws -> UInt64
    func decode(_ type: Float .Type) throws -> Float
    func decode(_ type: Double.Type) throws -> Double
    func decode(_ type: String.Type) throws -> String
    func decode<T: Decodable>(_ type:T.Type)throws->T
    
    // MARK: unboxing
    
    /// an error to throw if unboxing fails
    func failedToUnbox(_ value: Any, to _type: Any.Type, _ typeDescription: String?, at codingPath: [CodingKey]) -> DecodingError
    func notFound(_ _type: Any.Type, _ typeDescription: String?, at codingPath: [CodingKey]) -> DecodingError
    func typeError(_ value: Any, _ _type: Any.Type, _ typeDescription: String?, at codingPath: [CodingKey]) -> DecodingError
    func corrupted(_ debugDescription: String, at codingPath: [CodingKey]) -> DecodingError
    
    //
    
    func unboxNil(_ value: Any) -> Bool
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Bool
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int8
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int16
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int32
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int64
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt8
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt16
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt32
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt64
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Float
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Double
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> String
    func unbox<T: Decodable>(_ value: Any, at codingPath: [CodingKey]) throws -> T
    
    func redecode<T: Decodable>(_ value: Any, at codingPath: [CodingKey]) throws -> T
    func redecode<T: Decodable>(_ value: Any, at codingPath: [CodingKey], closure: (Decoder)throws->T) throws -> T
    
    // MARK: containers
    
    func keyedContainerContainer(_ value: Any, at codingPath: [CodingKey], nested: Bool) throws -> DecoderKeyedContainerContainer
    func unkeyedContainerContainer(_ value: Any, at codingPath: [CodingKey], nested: Bool) throws -> DecoderUnkeyedContainerContainer
    
    func keyedContainer<Key>(decoder: AnyDecoderBase, container: DecoderKeyedContainerContainer, nestedPath: [CodingKey]) -> KeyedDecodingContainer<Key>
    func unkeyedContainer(decoder: AnyDecoderBase, container: DecoderUnkeyedContainerContainer, nestedPath: [CodingKey]) -> UnkeyedDecodingContainer
    
    //
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey
    func unkeyedContainer() throws -> UnkeyedDecodingContainer
    func singleValueContainer() throws -> SingleValueDecodingContainer
}

public extension AnyDecoderBase {
    
    public func start<T: Decodable>(with value: Any) throws -> T {
        return try self.unbox(value, at: [])
    }
    
    public var currentValue: Any {
        return self.storage.last ?? {()->Any in fatalError("Tried to decode from nothing")}
    }
    
    // MARK: decode single value
    
    public func decodeNil() -> Bool { return self.unboxNil(self.currentValue) }
    public func decode(_ type: Bool  .Type) throws -> Bool   { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Int   .Type) throws -> Int    { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Int8  .Type) throws -> Int8   { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Int16 .Type) throws -> Int16  { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Int32 .Type) throws -> Int32  { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Int64 .Type) throws -> Int64  { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: UInt  .Type) throws -> UInt   { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: UInt8 .Type) throws -> UInt8  { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: UInt16.Type) throws -> UInt16 { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: UInt32.Type) throws -> UInt32 { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: UInt64.Type) throws -> UInt64 { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Float .Type) throws -> Float  { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Double.Type) throws -> Double { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: String.Type) throws -> String { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode<T: Decodable>(_ type:T.Type)throws->T { return try self.unbox(self.currentValue, at: self.codingPath) }
    
    // MARK: unbox
    
    func unboxNil(_ value: Any) -> Bool {
        return isNil(value)
    }
    
    /// an error to throw if unboxing fails
    public func failedToUnbox(_ value: Any, to _type: Any.Type, _ typeDescription: String? = nil, at codingPath: [CodingKey]) -> DecodingError {
        
        if isNil(value) {
            return self.notFound(_type, typeDescription, at: codingPath)
        } else {
            return self.typeError(value, _type, typeDescription, at: codingPath)
        }
    }
    
    public func notFound(_ _type: Any.Type, _ typeDescription: String? = nil, at codingPath: [CodingKey]) -> DecodingError {
        
        let typeDescription = typeDescription ?? "\(_type)"
        
        return DecodingError.valueNotFound(
            _type,
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Cannot get \(typeDescription) -- found null value instead."
            )
        )
    }
    
    public func typeError(_ value: Any, _ _type: Any.Type, _ typeDescription: String? = nil, at codingPath: [CodingKey]) -> DecodingError {
        
        let typeDescription = typeDescription ?? "\(_type)"
        
        return DecodingError.typeMismatch(
            _type,
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode \(typeDescription), but found \(type(of: value)): \(value)"
            )
        )
    }
    
    public func corrupted(_ debugDescription: String, at codingPath: [CodingKey]) -> DecodingError {
        
        return DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: debugDescription
            )
        )
    }
    
    // conversions
    
    public func convert(bool value: Any, at codingPath: [CodingKey]) throws -> Bool {
        
        if (value as? NSNumber)?.isBoolean ?? false, let value = value as? Bool {
            
            return value
            
        } else if let value = value as? String, let bool = Bool(value) {
            
            return bool
        }
        
        throw failedToUnbox(value, to: Bool.self, at: codingPath)
    }
    
    public func convert<T: ConvertibleNumber>(number value: Any, at codingPath: [CodingKey]) throws -> T {
        
        if (value as? NSNumber)?.isBoolean ?? false {
            // skip
            
        } else if value is T {// value is T is more accurate than as? T
            
            return value as! T
            
        } else if value is NSNumber, let value = value as? NSNumber, let number = T(exactly: value) {
            
            if number is NSNumber {
                if number as? NSNumber == value {
                    return number
                }
            } else {
                return number
            }
            
        } else if let value = value as? String, let number = T(value) {
            
            return number
        }
        
        throw self.failedToUnbox(value, to: T.self, at: codingPath)
    }
    
    public func convert(string value: Any, at codingPath: [CodingKey]) throws -> String {
        
        if let value = value as? String {
            
            return value
        }
        
        throw self.failedToUnbox(value, to: String.self, at: codingPath)
    }
    
    // unboxing
    
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Bool  { return try convert(bool  : value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int   { return try convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int8  { return try convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int16 { return try convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int32 { return try convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int64 { return try convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt  { return try convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt8 { return try convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt16{ return try convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt32{ return try convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt64{ return try convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Float { return try convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Double{ return try convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> String{ return try convert(string: value, at: codingPath) }
    
    public func unbox<T: Decodable>(_ value: Any, at codingPath: [CodingKey]) throws -> T {
        
        return try self.unbox(default: value, at: codingPath)
            ?? self.redecode(value, at: codingPath)
    }
    
    public func unbox<T: Decodable>(default value: Any, at codingPath: [CodingKey]) throws -> T? {
        
        switch T.self {
        // FIXME: remove when SR-5206 is fixed
        case is BrokenDecode.Type: return try self.redecode(value, at: codingPath, closure: { try (T.self as! BrokenDecode.Type).init(__from: $0) as! T })
        default: return nil
        }
    }
    
    public func redecode<T: Decodable>(_ value: Any, at codingPath: [CodingKey]) throws -> T {
        
        return try self.redecode(value, at: codingPath, closure: { try T(from: $0) })
    }
    
    public func redecode<T: Decodable>(_ value: Any, at codingPath: [CodingKey], closure: (Decoder)throws->T) throws -> T {
        
        // reverts the codingPath when complete
        let previousPath = self.codingPath
        self.codingPath = codingPath
        defer { self.codingPath = previousPath }
        
        // sets the next value to decode from
        self.storage.append(value)
        defer { self.storage.removeLast() }
        
        return try closure(self)
    }
    
    // MARK: containers
    
    func keyedContainerContainer(_ value: Any, at codingPath: [CodingKey], nested: Bool) throws -> DecoderKeyedContainerContainer {
        
        if let value = value as? NSDictionary {
            
            return value
        } else {
            throw self.failedToUnbox(value, to: NSDictionary.self, (nested ? "nested " : "") + "keyed container", at: codingPath)
        }
    }
    
    func unkeyedContainerContainer(_ value: Any, at codingPath: [CodingKey], nested: Bool) throws -> DecoderUnkeyedContainerContainer {
        
        if let value = value as? NSArray {
            
            return value
        } else {
            throw self.failedToUnbox(value, to: NSArray.self, (nested ? "nested " : "") + "unkeyed container", at: codingPath)
        }
    }
    
    func keyedContainer<Key>(decoder: AnyDecoderBase, container: DecoderKeyedContainerContainer, nestedPath: [CodingKey]) -> KeyedDecodingContainer<Key> {
        
        return KeyedDecodingContainer(DecoderDefaultKeyedContainer<Key>(decoder: decoder, container: container, nestedPath: nestedPath))
    }
    
    func unkeyedContainer(decoder: AnyDecoderBase, container: DecoderUnkeyedContainerContainer, nestedPath: [CodingKey]) -> UnkeyedDecodingContainer {
        
        return DecoderDefaultUnkeyedContainer(decoder: decoder, container: container, nestedPath: nestedPath)
    }
    
    //
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        
        return try self.keyedContainer(
            decoder: self,
            container: self.keyedContainerContainer(self.currentValue, at: self.codingPath, nested: false),
            nestedPath: []
        )
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        return try self.unkeyedContainer(
            decoder: self,
            container: self.unkeyedContainerContainer(self.currentValue, at: self.codingPath, nested: false),
            nestedPath: []
        )
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

// MARK: Base

public protocol DecoderBase: AnyDecoderBase {
    
    associatedtype Options
    
    var options: Options {get}
    
    init(codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any])
}

public extension DecoderBase {
    
    var untypedOptions: Any {
        return self.options
    }
    
    init(codingPath: [CodingKey], untypedOptions: Any, userInfo: [CodingUserInfoKey : Any]) {
        
        if let options = untypedOptions as? Options {
            self.init(codingPath: codingPath, options: options, userInfo: userInfo)
        } else {
            fatalError("Failed to cast options: \(untypedOptions) to type: \(Self.Options.self)")
        }
    }
    
    public init(options: Options, userInfo: [CodingUserInfoKey: Any]) {
        self.init(codingPath: [], options: options, userInfo: userInfo)
    }
}

// JSONBase

public extension JSONDecoder {
    public typealias Options = (
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy,
        nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy
    )
}

public protocol DecoderJSONBase: DecoderBase where Self.Options == (json: JSONDecoder.Options, extra: Self.ExtraOptions) {

    associatedtype ExtraOptions
    
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Float
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Double
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Date
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Data
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> URL
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Decimal
    func unbox<T>(_ value: Any, at codingPath: [CodingKey]) throws -> T where T : Decodable
}

public extension DecoderJSONBase {
    
    typealias JSONOptions = (json: JSONDecoder.Options, extra: Self.ExtraOptions)
    
    // convert(json: means that it is specific to a JSON compatible value and a decoding strategy
    
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Float   { return try self.convert(json  : value, at: codingPath) }
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Double  { return try self.convert(json  : value, at: codingPath) }
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Date    { return try self.convert(json  : value, at: codingPath) }
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Data    { return try self.convert(json  : value, at: codingPath) }
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> URL     { return try self.convert(url   : value, at: codingPath) }
    func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Decimal { return try self.convert(number: value, at: codingPath) }
    func unbox<T>(_ value: Any, at codingPath: [CodingKey]) throws -> T where T : Decodable {
        
        return try self.unbox(json: value, at: codingPath)
            ?? self.unbox(default: value, at: codingPath)
            ?? self.redecode(value, at: codingPath)
    }
    
    func unbox<T>(json value: Any, at codingPath: [CodingKey]) throws -> T? where T : Decodable {
        switch T.self {
        case is Date.Type   , is NSDate.Type         : return try self.unbox(value, at: codingPath) as Date    as? T
        case is Data.Type   , is NSData.Type         : return try self.unbox(value, at: codingPath) as Data    as? T
        case is URL.Type    , is NSURL.Type          : return try self.unbox(value, at: codingPath) as URL     as? T
        case is Decimal.Type, is NSDecimalNumber.Type: return try self.unbox(value, at: codingPath) as Decimal as? T
        default: return nil
        }
    }
    
    func convert(json value: Any, at codingPath: [CodingKey]) throws -> Data {
        
        switch self.options.json.dataDecodingStrategy {
            
        case .deferredToData:
            return try self.redecode(value, at: codingPath)
            
        case .base64:
            guard let data = try Data(base64Encoded: self.unbox(value, at: codingPath) as String) else {
                throw self.corrupted("Encountered Data is not valid Base64.", at: codingPath)
            }
            return data
            
        case .custom(let closure):
            return try self.redecode(value, at: codingPath, closure: closure)
        }
    }
    
    func convert(json value: Any, at codingPath: [CodingKey]) throws -> Date {
        
        switch self.options.json.dateDecodingStrategy {
            
        case .deferredToDate:
            return try self.redecode(value, at: codingPath)
            
        case .secondsSince1970:
            return Date.init(timeIntervalSince1970: try self.unbox(value, at: codingPath))
            
        case .millisecondsSince1970:
            return Date.init(timeIntervalSince1970: try self.unbox(value, at: codingPath) / 1000)
            
        case .iso8601:
            if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                guard let date = ISO8601DateFormatter.shared.date(from: try self.unbox(value, at: codingPath)) else {
                    throw self.corrupted("Expected date string to be ISO8601-formatted.", at: codingPath)
                }
                return date
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }
            
        case .formatted(let formatter):
            guard let date = formatter.date(from: try self.unbox(value, at: codingPath)) else {
                throw self.corrupted("Date string does not match format expected by formatter.", at: codingPath)
            }
            return date
            
        case .custom(let closure):
            return try self.redecode(value, at: codingPath, closure: closure)
        }
    }
    
    func convert<T: FloatingPoint & ConvertibleNumber>(json value: Any, at codingPath: [CodingKey]) throws -> T {
        
        do {
            
            return try self.convert(number: value, at: codingPath)
            
        } catch {
            
            if let value = value as? String,
                case .convertFromString(let posInfString, let negInfString, let nanString) = self.options.json.nonConformingFloatDecodingStrategy {
                
                switch value {
                case posInfString: return .infinity
                case negInfString: return -.infinity
                case nanString: return .nan
                default: throw error
                }
            } else {
                throw error
            }
        }
    }
    
    func convert(url value: Any, at codingPath: [CodingKey]) throws -> URL {
        
        if let value = value as? URL {
            
            return value
            
        } else if let value = value as? String {
            
            if let value = URL(string: value) {
                
                return value
                
            } else {
                
                throw self.corrupted("Invalid url from string: \(value)", at: codingPath)
            }
        }
        
        throw self.failedToUnbox(value, to: URL.self, at: codingPath)
    }
}

// MARK: KeyedContainer

public protocol DecoderKeyedContainerContainer {
    
    func value(forStringValue key: String) -> Any?
    func value(forIntValue key: Int) -> Any?
    
    var stringValueKeys: [String] {get}
    var intValueKeys: [Int] {get}
}

extension NSDictionary: DecoderKeyedContainerContainer {
    
    public var stringValueKeys: [String] {
        return self.allKeys.flatMap { $0 as? String }
    }
    public var intValueKeys: [Int] {
        return self.allKeys.flatMap { $0 as? Int }
    }
    
    public func value(forStringValue key: String) -> Any? {
        return self[key]
    }
    
    public func value(forIntValue key: Int) -> Any? {
        return self[key]
    }
}

public protocol DecoderKeyedContainer: KeyedDecodingContainerProtocol {
    
    var decoder: AnyDecoderBase {get}
    var container: DecoderKeyedContainerContainer {get}
    var nestedPath: [CodingKey] {get}
    
    init(decoder: AnyDecoderBase, container: DecoderKeyedContainerContainer, nestedPath: [CodingKey])
    
    // overridable methods
    
    var usesStringValue: Bool {get}
    
    var codingPath: [CodingKey] {get}
    
    func currentPath(_ key: CodingKey) -> [CodingKey]
    
    var allKeys: [Key] {get}
    
    func keyNotFound(_ key: CodingKey) -> DecodingError
    
    func value(forKey key: CodingKey) throws -> Any
    
    func contains(_ key: Key) -> Bool
    
    func decodeNil(forKey key: Key) throws -> Bool
    func decode(_ type: Bool.Type  , forKey key: Key) throws -> Bool
    func decode(_ type: Int.Type   , forKey key: Key) throws -> Int
    func decode(_ type: Int8.Type  , forKey key: Key) throws -> Int8
    func decode(_ type: Int16.Type , forKey key: Key) throws -> Int16
    func decode(_ type: Int32.Type , forKey key: Key) throws -> Int32
    func decode(_ type: Int64.Type , forKey key: Key) throws -> Int64
    func decode(_ type: UInt.Type  , forKey key: Key) throws -> UInt
    func decode(_ type: UInt8.Type , forKey key: Key) throws -> UInt8
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64
    func decode(_ type: Float.Type , forKey key: Key) throws -> Float
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double
    func decode(_ type: String.Type, forKey key: Key) throws -> String
    func decode<T: Decodable>(_ type: T.Type, forKey key: Key)throws->T
    
    // containers
    
    func nestedContainer<NestedKey>(keyedBy: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey>
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer
    func superDecoder() throws -> Decoder
    func superDecoder(forKey key: Key) throws -> Decoder
}

public extension DecoderKeyedContainer {
    
    public var usesStringValue: Bool {
        return type(of: self.decoder).usesStringValue
    }
    
    public var codingPath: [CodingKey] {
        return self.decoder.codingPath + self.nestedPath
    }
    
    public func currentPath(_ key: CodingKey) -> [CodingKey] {
        
        return self.codingPath + [key]
    }
    
    public var allKeys: [Key] {
        
        return self.container.stringValueKeys.flatMap { Key(stringValue: $0) } + self.container.intValueKeys.flatMap { Key(intValue: $0) }
    }
    
    public func keyNotFound(_ key: CodingKey) -> DecodingError {
        return DecodingError.keyNotFound(
            key,
            DecodingError.Context(
                // key is not added to the path by default
                codingPath: self.codingPath,
                debugDescription: "No value found for \(type(of: key)): \(key) (stringValue: \(key.stringValue), intValue: \(key.intValue?.description ?? "nil"))"
            )
        )
    }
    
    public func value(forKey key: CodingKey) throws -> Any {
        
        if self.usesStringValue {
            
            guard let value = self.container.value(forStringValue: key.stringValue) else {
                throw self.keyNotFound(key)
            }
            
            return value
            
        } else {
            
            guard key.intValue != nil else {
                fatalError("Tried to get \(type(of: key)): \(key) .intValue, but found nil.")
            }
            
            guard let value = self.container.value(forIntValue: key.intValue!) else {
                throw self.keyNotFound(key)
            }
            
            return value
        }
    }
    
    public func contains(_ key: Key) -> Bool {
        
        return (try? self.value(forKey: key)) != nil
    }
    
    public func decodeNil(forKey key: Key) throws -> Bool {
        
        return self.decoder.unboxNil(try self.value(forKey: key))
    }
    
    public func decode(_ type: Bool.Type  , forKey key: Key) throws -> Bool   { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: Int.Type   , forKey key: Key) throws -> Int    { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: Int8.Type  , forKey key: Key) throws -> Int8   { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: Int16.Type , forKey key: Key) throws -> Int16  { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: Int32.Type , forKey key: Key) throws -> Int32  { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: Int64.Type , forKey key: Key) throws -> Int64  { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: UInt.Type  , forKey key: Key) throws -> UInt   { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: UInt8.Type , forKey key: Key) throws -> UInt8  { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: Float.Type , forKey key: Key) throws -> Float  { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode(_ type: String.Type, forKey key: Key) throws -> String { return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    public func decode<T: Decodable>(_ type: T.Type, forKey key: Key)throws->T{ return try self.decoder.unbox(self.value(forKey: key), at: self.currentPath(key)) }
    
    // containers
    
    public func nestedContainer<NestedKey>(keyedBy: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        
        return try self.decoder.keyedContainer(
            decoder: self.decoder,
            container: self.decoder.keyedContainerContainer(self.value(forKey: key), at: self.currentPath(key), nested: true),
            nestedPath: self.nestedPath + [key]
        )
    }
    
    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        
        return try self.decoder.unkeyedContainer(
            decoder: self.decoder,
            container: self.decoder.unkeyedContainerContainer(self.value(forKey: key), at: self.currentPath(key), nested: true),
            nestedPath: self.nestedPath + [key]
        )
    }
    
    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        
        let decoder = type(of: self.decoder).init(
            codingPath: self.currentPath(key),
            untypedOptions: self.decoder.untypedOptions,
            userInfo: self.decoder.userInfo
        )
        
        decoder.storage.append((try? self.value(forKey: key)) ?? NSNull())
        
        return decoder
    }
    
    public func superDecoder() throws -> Decoder {
        
        return try self._superDecoder(forKey: CodingSuperKey())
    }
    
    public func superDecoder(forKey key: Key) throws -> Decoder {
        
        return try self._superDecoder(forKey: key)
    }
}

// MARK: UnkeyedContainer

public protocol DecoderUnkeyedContainerContainer {
    
    func fromStorage(_ index: Int) -> Any
    
    /// returns the number of stored values if known
    var storageCount: Int? {get}
    
    /// returns whether fromStorage will fail to get a value at the given index
    func isAtEnd(index: Int) -> Bool
}

extension NSArray: DecoderUnkeyedContainerContainer {
    
    public var storageCount: Int? {
        return self.count
    }
    
    public func isAtEnd(index: Int) -> Bool {
        
        return index >= self.count
    }
    
    public func fromStorage(_ index: Int) -> Any {
        
        return self[index]
    }
}

public protocol DecoderUnkeyedContainer: UnkeyedDecodingContainer {
    
    // required
    
    var decoder: AnyDecoderBase {get}
    var container: DecoderUnkeyedContainerContainer {get}
    var nestedPath: [CodingKey] {get}
    
    init(decoder: AnyDecoderBase, container: DecoderUnkeyedContainerContainer, nestedPath: [CodingKey])
    
    /// currentIndex starts at 0 and increments for every call
    var currentIndex: Int {get set} // = 0
    
    // overridable
    
    var codingPath: [CodingKey] {get}
    var currentPath: [CodingKey] {get}
    var currentKey: CodingKey {get}
    var count: Int? {get}
    var isAtEnd: Bool {get}
    
    func isAtEnd(_ _type: Any.Type, _ typeDescription: String?) -> DecodingError
    
    /// gets the current value if !self.isAtEnd or throws valueNotFound found with the type
    func currentValue(_ _type: Any.Type, _ typeDescription: String?) throws -> Any
    
    /// adds 1 to .currentIndex
    mutating func increment()
    
    mutating func decodeNil() throws -> Bool
    mutating func decode(_ type: Bool.Type  ) throws -> Bool
    mutating func decode(_ type: Int.Type   ) throws -> Int
    mutating func decode(_ type: Int8.Type  ) throws -> Int8
    mutating func decode(_ type: Int16.Type ) throws -> Int16
    mutating func decode(_ type: Int32.Type ) throws -> Int32
    mutating func decode(_ type: Int64.Type ) throws -> Int64
    mutating func decode(_ type: UInt.Type  ) throws -> UInt
    mutating func decode(_ type: UInt8.Type ) throws -> UInt8
    mutating func decode(_ type: UInt16.Type) throws -> UInt16
    mutating func decode(_ type: UInt32.Type) throws -> UInt32
    mutating func decode(_ type: UInt64.Type) throws -> UInt64
    mutating func decode(_ type: Float.Type ) throws -> Float
    mutating func decode(_ type: Double.Type) throws -> Double
    mutating func decode(_ type: String.Type) throws -> String
    mutating func decode<T: Decodable>(_ type: T.Type)throws->T
    
    // containers
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer
    mutating func superDecoder() throws -> Decoder
}

public extension DecoderUnkeyedContainer {
    
    public var codingPath: [CodingKey] {
        return self.decoder.codingPath + self.nestedPath
    }
    
    public var currentPath: [CodingKey] {
        
        return self.codingPath + [self.currentKey]
    }
    
    public var currentKey: CodingKey {
        
        return CodingIndexKey(intValue: self.currentIndex)
    }
    
    public var count: Int? {
        
        return self.container.storageCount
    }
    
    public var isAtEnd: Bool {
        
        return self.container.isAtEnd(index: self.currentIndex)
    }
    
    public func isAtEnd(_ _type: Any.Type, _ typeDescription: String? = nil) -> DecodingError {
        return DecodingError.valueNotFound(
            _type,
            DecodingError.Context(
                codingPath: self.currentPath,
                debugDescription: "Cannot get \(typeDescription ?? "\(_type)") -- Unkeyed container is at end."
            )
        )
    }
    
    /// gets the current value if !self.isAtEnd or throws valueNotFound found with the type
    public func currentValue(_ _type: Any.Type, _ typeDescription: String? = nil) throws -> Any {
        
        if self.isAtEnd {
            
            throw self.isAtEnd(_type, typeDescription)
        }
        
        return self.container.fromStorage(self.currentIndex)
    }
    
    /// adds 1 to .currentIndex
    public mutating func increment() {
        self.currentIndex += 1
    }
    
    public mutating func decodeNil() throws -> Bool {
        
        //  if true, will decode nil, be sure to increment path
        if self.decoder.unboxNil(try self.currentValue(NSNull.self)) {
            self.increment()
            
            return true
        } else {
            return false
        }
    }
    
    public mutating func decode(_ type: Bool.Type  ) throws -> Bool   { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: Int.Type   ) throws -> Int    { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: Int8.Type  ) throws -> Int8   { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: Int16.Type ) throws -> Int16  { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: Int32.Type ) throws -> Int32  { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: Int64.Type ) throws -> Int64  { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: UInt.Type  ) throws -> UInt   { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: UInt8.Type ) throws -> UInt8  { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: UInt16.Type) throws -> UInt16 { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: UInt32.Type) throws -> UInt32 { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: UInt64.Type) throws -> UInt64 { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: Float.Type ) throws -> Float  { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: Double.Type) throws -> Double { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode(_ type: String.Type) throws -> String { defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    public mutating func decode<T: Decodable>(_ type: T.Type)throws->T{ defer { self.increment() } ; return try self.decoder.unbox(self.currentValue(type), at: self.currentPath) }
    
    // containers
    
    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        
        defer { self.increment() }
        
        return try self.decoder.keyedContainer(
            decoder: self.decoder,
            container: self.decoder.keyedContainerContainer(self.currentValue(KeyedDecodingContainer<NestedKey>.self, "nested keyed container"), at: self.currentPath, nested: true),
            nestedPath: self.nestedPath + [self.currentKey]
        )
    }
    
    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        defer { self.increment() }
        
        return try self.decoder.unkeyedContainer(
            decoder: self.decoder,
            container: self.decoder.unkeyedContainerContainer(self.currentValue(UnkeyedDecodingContainer.self, "nested unkeyed container"), at: self.currentPath, nested: true),
            nestedPath: self.nestedPath + [self.currentKey]
        )
    }
    
    public mutating func superDecoder() throws -> Decoder {
        
        defer { self.increment() }
        
        let decoder = type(of: self.decoder).init(
            codingPath: self.currentPath,
            untypedOptions: self.decoder.untypedOptions,
            userInfo: self.decoder.userInfo
        )
        
        decoder.storage.append(try self.currentValue(Decoder.self, "super decoder"))
        
        return decoder
    }
}

// MARK: ConvertibleNumber

public protocol ConvertibleNumber {
    
    init?(_: String)
    init?(exactly: NSNumber)
}

extension Int    : ConvertibleNumber {}
extension Int8   : ConvertibleNumber {}
extension Int16  : ConvertibleNumber {}
extension Int32  : ConvertibleNumber {}
extension Int64  : ConvertibleNumber {}
extension UInt   : ConvertibleNumber {}
extension UInt8  : ConvertibleNumber {}
extension UInt16 : ConvertibleNumber {}
extension UInt32 : ConvertibleNumber {}
extension UInt64 : ConvertibleNumber {}
extension Float  : ConvertibleNumber {}
extension Double : ConvertibleNumber {}

extension Decimal: ConvertibleNumber {
    
    public init?(_ string: String) {
        
        self.init(string: string)
    }
    
    public init?(exactly: NSNumber) {
        
        if let number = Double(exactly: exactly) { self.init(number)
        } else if let number = Int   (exactly: exactly) { self.init(number)
        } else if let number = Int8  (exactly: exactly) { self.init(number)
        } else if let number = Int16 (exactly: exactly) { self.init(number)
        } else if let number = Int32 (exactly: exactly) { self.init(number)
        } else if let number = Int64 (exactly: exactly) { self.init(number)
        } else if let number = UInt  (exactly: exactly) { self.init(number)
        } else if let number = UInt8 (exactly: exactly) { self.init(number)
        } else if let number = UInt16(exactly: exactly) { self.init(number)
        } else if let number = UInt32(exactly: exactly) { self.init(number)
        } else if let number = UInt64(exactly: exactly) { self.init(number)
        } else {
            
            let value = exactly.decimalValue
            
            if (value as NSNumber).isEqual(to: exactly) {
                
                self.init()
                
                self = value
                
            } else {
                
                return nil
            }
        }
    }
}

// MARK: Temporary decoding workarounds

// FIXME: remove when SR-5206 is fixed
func assertTypeIsDecodable(_ _type: Any.Type, in wrappingType: Any.Type) {
    guard _type is Decodable.Type else {
        if _type == Decodable.self || _type == Codable.self {
            preconditionFailure("\(wrappingType) does not conform to Decodable because Decodable does not conform to itself. You must use a concrete type to encode or decode.")
        } else {
            preconditionFailure("\(wrappingType) does not conform to Decodable because \(_type) does not conform to Decodable.")
        }
    }
}

// FIXME: Remove when conditional conformance is available.
extension Decodable {
    // Since we cannot call these __init, we'll give the parameter a '__'.
    init(__from container: SingleValueDecodingContainer)   throws { self = try container.decode(Self.self) }
    init(__from container: inout UnkeyedDecodingContainer) throws { self = try container.decode(Self.self) }
    init<Key>(__from container: KeyedDecodingContainer<Key>, forKey key: Key) throws { self = try container.decode(Self.self, forKey: key) }
}
// end remove

protocol BrokenDecode {
    
    init(__from decoder: Decoder) throws
}

extension Optional: BrokenDecode {
    
    init(__from decoder: Decoder) throws {
        assertTypeIsDecodable(Wrapped.self, in: Optional.self)
        
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .none
        } else {
            self = .some(try (Wrapped.self as! Decodable.Type).init(__from: container) as! Wrapped)
        }
    }
}

extension Array: BrokenDecode {
    
    init(__from decoder: Decoder) throws {
        assertTypeIsDecodable(Element.self, in: Array.self)
        
        self.init()
        
        var container = try decoder.unkeyedContainer()
        
        let metaType = Element.self as! Decodable.Type
        
        while !container.isAtEnd {
            
            self.append(try metaType.init(__from: &container) as! Element)
        }
    }
}

extension Set: BrokenDecode {
    
    init(__from decoder: Decoder) throws {
        assertTypeIsDecodable(Element.self, in: Set.self)
        
        self.init()
        
        var container = try decoder.unkeyedContainer()
        
        let metaType = Element.self as! Decodable.Type
        
        while !container.isAtEnd {
            self.insert(try metaType.init(__from: &container) as! Element)
        }
    }
}

extension Dictionary: BrokenDecode {
    
    init(__from decoder: Decoder) throws {
        
        assertTypeIsDecodable(Key.self, in: Dictionary.self)
        assertTypeIsDecodable(Value.self, in: Dictionary.self)
        
        let valueMetaType = Value.self as! Decodable.Type
        
        self.init()
        
        switch Key.self {
            
        case is String.Type:
            let container = try decoder.container(keyedBy: _DictionaryCodingKey.self)
            for key in container.allKeys {
                self[key.stringValue as! Key] = (try valueMetaType.init(__from: container, forKey: key) as! Value)
            }
            
        case is Int.Type:
            let container = try decoder.container(keyedBy: _DictionaryCodingKey.self)
            for key in container.allKeys {
                
                guard key.intValue != nil else {
                    throw DecodingError.typeMismatch(
                        Int.self,
                        DecodingError.Context(
                            codingPath: decoder.codingPath + [key],
                            debugDescription: "Expected Int key but found String key instead."
                        )
                    )
                }
                
                self[key.intValue as! Key] = (try valueMetaType.init(__from: container, forKey: key) as! Value)
            }
            
        default:
            let keyMetaType = Key.self as! Decodable.Type
            
            var container = try decoder.unkeyedContainer()
            
            if let count = container.count {
                guard count % 2 == 0 else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: container.codingPath,
                            debugDescription: "Expected collection of key-value pairs; encountered odd-length container instead."
                        )
                    )
                }
            }
            
            while !container.isAtEnd {
                
                let key = try keyMetaType.init(__from: &container) as! Key
                
                guard !container.isAtEnd else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "Unkeyed container reached end before value in key-value pair."
                        )
                    )
                }
                
                self[key] = (try valueMetaType.init(__from: &container) as! Value)
            }
        }
    }
}
// end remove



//fileprivate protocol UnderlyingValue {
//    func underlyingValue() -> Any
//}
//
//extension Optional: UnderlyingValue {
//
//    /// returns the underlying optional value or nil
//    func underlyingValue() -> Any {
//
//        if case .some(let wrapped) = self {
//
//            if let wrapped = wrapped as? UnderlyingValue {
//                return wrapped.underlyingValue()
//            } else {
//                return wrapped
//            }
//
//        } else {
//            return self as Any
//        }
//    }
//}
