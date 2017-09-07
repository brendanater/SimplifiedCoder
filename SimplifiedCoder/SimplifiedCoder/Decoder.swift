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

/// the decoder that the user calls to abstract away complexity
protocol TopLevelDecoder {
    
    func decode<T: Decodable>(_: T.Type, from data: Data) throws -> T
}

/// must be a class, so that references reference the same decoder
protocol DecoderBase: class, Decoder, SingleValueDecodingContainer {
    
    // references
    
    // warning: references to KeyedContainer<Key> types will compiler crash (Command failed due to signal: Abort trap: 6) if the generic value is left out
    // default with <String>
    associatedtype KeyedContainer: DecoderKeyedContainer
    associatedtype UnkeyedContainer: DecoderUnkeyedContainer
    associatedtype Options
    
    // required
    
    var storage: [Any] {get set}
    var options: Options {get}
    var codingPath: [CodingKey] {get set}
    var userInfo: [CodingUserInfoKey : Any] {get}
    
    /// self.storage = [value]
    init(value: Any, codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any])
    
    // new methods
    
    func decodeNil() -> Bool
    
    func error(_ error: Error, at codingPath: [CodingKey]) -> Error
    
    // decides which unbox error to throw based on the value
    func failedToUnbox<T>(_ value: Any, to type: T.Type, _ typeDescription: String?) -> UnboxError
    
    func notFound<T>(_ type: T.Type, _ typeDescription: String?) -> UnboxError
    func typeError<T>(_ value: Any, _ type: T.Type, _ typeDescription: String?) -> UnboxError
    func corrupted(_ debugDescription: String) -> UnboxError
    
    func decode<T>(with unbox: (Any)throws->T) throws -> T
    
    func convert<T: ConvertibleNumber>(number value: Any) throws -> T
    
    func unbox(_ value: Any) throws -> Bool
    func unbox(_ value: Any) throws -> Int
    func unbox(_ value: Any) throws -> Int8
    func unbox(_ value: Any) throws -> Int16
    func unbox(_ value: Any) throws -> Int32
    func unbox(_ value: Any) throws -> Int64
    func unbox(_ value: Any) throws -> UInt
    func unbox(_ value: Any) throws -> UInt8
    func unbox(_ value: Any) throws -> UInt16
    func unbox(_ value: Any) throws -> UInt32
    func unbox(_ value: Any) throws -> UInt64
    func unbox(_ value: Any) throws -> Float
    func unbox(_ value: Any) throws -> Double
    func unbox(_ value: Any) throws -> String
    func unbox<T: Decodable>(_ value: Any) throws -> T
    
    func redecode<T: Decodable>(_ value: Any) throws -> T
}

extension DecoderBase {
    
    // MARK: decode single value
    
    func decodeNil() -> Bool {
        return isNil(self.storage.last)
    }
    
    /// casts an error to the right codingPath and type
    func error(_ error: Error, at codingPath: [CodingKey]) -> Error {
        
        if let error = error as? UnboxError {
            return error.asDecodingError(with: codingPath)
        } else if error is DecodingError {
            return error
        } else if error is DecodeError {
            return error
        } else {
            return DecodeError.decodeError(error, atPath: codingPath)
        }
    }
    
    func decode<T>(with unbox: (Any)throws->T) throws -> T {
        
        do {
            return try unbox(self.storage.last!)
            
        } catch {
            throw self.error(error, at: self.codingPath)
        }
    }
    
    public func decode(_: Bool.Type  ) throws -> Bool   { return try self.decode(with: unbox(_:)) }
    public func decode(_: Int.Type   ) throws -> Int    { return try self.decode(with: unbox(_:)) }
    public func decode(_: Int8.Type  ) throws -> Int8   { return try self.decode(with: unbox(_:)) }
    public func decode(_: Int16.Type ) throws -> Int16  { return try self.decode(with: unbox(_:)) }
    public func decode(_: Int32.Type ) throws -> Int32  { return try self.decode(with: unbox(_:)) }
    public func decode(_: Int64.Type ) throws -> Int64  { return try self.decode(with: unbox(_:)) }
    public func decode(_: UInt.Type  ) throws -> UInt   { return try self.decode(with: unbox(_:)) }
    public func decode(_: UInt8.Type ) throws -> UInt8  { return try self.decode(with: unbox(_:)) }
    public func decode(_: UInt16.Type) throws -> UInt16 { return try self.decode(with: unbox(_:)) }
    public func decode(_: UInt32.Type) throws -> UInt32 { return try self.decode(with: unbox(_:)) }
    public func decode(_: UInt64.Type) throws -> UInt64 { return try self.decode(with: unbox(_:)) }
    public func decode(_: Float.Type ) throws -> Float  { return try self.decode(with: unbox(_:)) }
    public func decode(_: Double.Type) throws -> Double { return try self.decode(with: unbox(_:)) }
    public func decode(_: String.Type) throws -> String { return try self.decode(with: unbox(_:)) }
    public func decode<T: Decodable>(_: T.Type)throws->T{ return try self.decode(with: unbox(_:)) }
    
    // MARK: unbox
    
    /// an error to throw if unboxing fails
    func failedToUnbox<T>(_ value: Any, to type: T.Type, _ typeDescription: String? = nil) -> UnboxError {
        
        if isNil(value) {
            return self.notFound(type, typeDescription)
        } else {
            return self.typeError(value, type, typeDescription)
        }
    }
    
    func notFound<T>(_ type: T.Type, _ typeDescription: String? = nil) -> UnboxError {
        
        let typeDescription = typeDescription ?? "\(T.self)"
        
        return UnboxError.valueNotFound(
            type,
            UnboxError.Context(
                debugDescription: "Cannot get \(typeDescription) -- found null value instead."
            )
        )
    }
    
    func typeError<T>(_ value: Any, _ type: T.Type, _ typeDescription: String? = nil) -> UnboxError {
        
        let typeDescription = typeDescription ?? "\(T.self)"
        
        return UnboxError.typeMismatch(
            type,
            UnboxError.Context(
                debugDescription: "Expected to decode \(typeDescription), but found \(value)"
            )
        )
    }
    
    func corrupted(_ debugDescription: String) -> UnboxError {
        
        return UnboxError.dataCorrupted(
            UnboxError.Context(
                debugDescription: debugDescription
            )
        )
    }
    
    func convert<T: ConvertibleNumber>(number value: Any) throws -> T {
        
        if let number = value as? T {
            return number
            
        } else if let number = value as? NSNumber ?? NumberFormatter.shared.number(from: value as? String ?? "˜∆åƒ˚")  {
            
            if let number = T(exactly: number) {
                return number
            }
        }
        
        throw self.failedToUnbox(value, to: T.self)
    }
    
    func unbox(_ value: Any) throws -> Bool { return value as? Bool ?? isNil(value) }
    
    func unbox(_ value: Any) throws -> Int    { return try self.convert(number: value) }
    func unbox(_ value: Any) throws -> Int8   { return try self.convert(number: value) }
    func unbox(_ value: Any) throws -> Int16  { return try self.convert(number: value) }
    func unbox(_ value: Any) throws -> Int32  { return try self.convert(number: value) }
    func unbox(_ value: Any) throws -> Int64  { return try self.convert(number: value) }
    func unbox(_ value: Any) throws -> UInt   { return try self.convert(number: value) }
    func unbox(_ value: Any) throws -> UInt8  { return try self.convert(number: value) }
    func unbox(_ value: Any) throws -> UInt16 { return try self.convert(number: value) }
    func unbox(_ value: Any) throws -> UInt32 { return try self.convert(number: value) }
    func unbox(_ value: Any) throws -> UInt64 { return try self.convert(number: value) }
    func unbox(_ value: Any) throws -> Float  { return try self.convert(number: value) }
    func unbox(_ value: Any) throws -> Double { return try self.convert(number: value) }
    
    func unbox(_ value: Any) throws -> String {
        
        if let string = value as? String {
            return string
            
        } else {
            return "\(value)"
        }
    }
    
    func unbox<T: Decodable>(_ value: Any) throws -> T {
        return try self.redecode(value)
        //        switch T.self {
        //        case is Date: return try unbox(value) as Date
        //        default: return try redecode(value)
        //        }
    }
    
    func redecode<T: Decodable>(_ value: Any) throws -> T {
        
        // decoder now uses this value to decode from (same as creating a new decoder)
        self.storage.append(value)
        let decoded = try T(from: self)
        // not decoding with this value anymore (same as manually deinitializing the new decoder)
        self.storage.removeLast()
        return decoded
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
    
}

extension DecoderBase where KeyedContainer.Base == Self {
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        
        let value = self.storage.last as Any
        
        guard let container = value as? NSDictionary else {
            throw self.failedToUnbox(value, to: KeyedDecodingContainer<Key>.self, "keyed container")
                .asDecodingError(with: self.codingPath)
        }
        
        return Self.KeyedContainer.initSelf(
            decoder: self,
            container: container,
            nestedPath: [],
            keyedBy: Key.self
        )
    }
}

extension DecoderBase where UnkeyedContainer.Base == Self {
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        let value = self.storage.last as Any
        
        guard let container = value as? NSArray else {
            throw self.failedToUnbox(value, to: UnkeyedDecodingContainer.self, "unkeyed container")
                .asDecodingError(with: self.codingPath)
        }
        
        return UnkeyedContainer(
            decoder: self,
            container: container,
            nestedPath: []
        )
    }
}

// MARK: KeyedContainer

protocol DecoderKeyedContainer: KeyedDecodingContainerProtocol {
    
    // references
    
    associatedtype UnkeyedContainer: DecoderUnkeyedContainer
    associatedtype Base: DecoderBase
    
    // required
    
    var decoder: Base {get}
    var container: NSDictionary {get}
    var nestedPath: [CodingKey] {get}
    
    init(decoder: Base, container: NSDictionary, nestedPath: [CodingKey])
    
    static func initSelf<Key: CodingKey>(decoder: Base, container: NSDictionary, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedDecodingContainer<Key>
    
    static var usesStringValue: Bool {get}
    
    // new methods
    
    func value(forKey key: CodingKey) throws -> Any
    
    func optionalValue(forKey key: CodingKey) -> Any
    
    func decode<T>(with unbox: (Any)throws->T, forKey key: Key) throws -> T
}

extension DecoderKeyedContainer {
    
    public var codingPath: [CodingKey] {
        return self.decoder.codingPath + self.nestedPath
    }
    
    public var allKeys: [Key] {
        return self.container.allKeys.flatMap {
            
            if Self.usesStringValue, let string = $0 as? String {
                return Key(stringValue: string)
                
            } else if let int = $0 as? Int {
                return Key(intValue: int)
                
            } else {
                return nil
            }
        }
    }
    
    func _key(from key: CodingKey) -> Any {
        
        if Self.usesStringValue {
            return key.stringValue
            
        } else {
            
            guard key.intValue != nil else {
                fatalError("Tried to get \(key as? String == "super" ? "" : "\(type(of: key)).")\(key).intValue but found nil")
            }
            
            return key.intValue!
        }
    }
    
    func value(forKey key: CodingKey) throws -> Any {
        
        guard let value = self.container[self._key(from: key)] else {
            throw DecodingError.keyNotFound(
                key,
                DecodingError.Context(
                    codingPath: self.codingPath + [key],
                    debugDescription: "No value found for key: \(self._key(from: key)) (\(key))"
                )
            )
        }
        
        return value
    }
    
    func optionalValue(forKey key: CodingKey) -> Any {
        
        let value = try? self.value(forKey: key)
        
        return value as Any
    }
    
    public func contains(_ key: Key) -> Bool {
        
        return isNil(self.optionalValue(forKey: key))
    }
    
    public func decodeNil(forKey key: Key) throws -> Bool {
        
        // throw if key not found
        return try isNil(self.value(forKey: key))
    }
    
    func decode<T>(with unbox: (Any)throws->T, forKey key: Key) throws -> T {
        
        do {
            return try unbox(self.value(forKey: key))
        } catch {
            throw self.decoder.error(error, at: codingPath + [key])
        }
    }
    
    public func decode(_ type: Bool.Type  , forKey key: Key) throws -> Bool   { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Int.Type   , forKey key: Key) throws -> Int    { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Int8.Type  , forKey key: Key) throws -> Int8   { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Int16.Type , forKey key: Key) throws -> Int16  { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Int32.Type , forKey key: Key) throws -> Int32  { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Int64.Type , forKey key: Key) throws -> Int64  { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: UInt.Type  , forKey key: Key) throws -> UInt   { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: UInt8.Type , forKey key: Key) throws -> UInt8  { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Float.Type , forKey key: Key) throws -> Float  { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode(_ type: String.Type, forKey key: Key) throws -> String { return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    public func decode<T: Decodable>(_ type: T.Type, forKey key: Key)throws->T{ return try self.decode(with: self.decoder.unbox(_:), forKey: key) }
    
    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        
        let value = try self.value(forKey: key)
        
        guard let container = value as? NSDictionary else {
            throw self.decoder.failedToUnbox(value, to: KeyedDecodingContainer<NestedKey>.self, "nested keyed container")
                .asDecodingError(with: self.codingPath + [key])
        }
        
        return Self.initSelf(decoder: self.decoder, container: container, nestedPath: self.nestedPath + [key], keyedBy: NestedKey.self)
    }
    
    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        
        return Self.Base(
            value: self.optionalValue(forKey: key),
            codingPath: self.codingPath + [key],
            options: self.decoder.options,
            userInfo: self.decoder.userInfo
        )
    }
    
    public func superDecoder() throws -> Decoder {
        
        return try self._superDecoder(forKey: "super")
    }
    
    public func superDecoder(forKey key: Key) throws -> Decoder {
        return try self._superDecoder(forKey: key)
    }
}

extension DecoderKeyedContainer where UnkeyedContainer.Base == Self.Base {
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        
        let value = try self.value(forKey: key)
        
        guard let container = value as? NSArray else {
            throw self.decoder.failedToUnbox(value, to: UnkeyedDecodingContainer.self, "nested unkeyed container")
                .asDecodingError(with: self.codingPath + [key])
        }
        
        return Self.UnkeyedContainer(
            decoder: self.decoder,
            container: container,
            nestedPath: self.nestedPath + [key]
        )
    }
}

// MARK: UnkeyedContainer

protocol DecoderUnkeyedContainer: UnkeyedDecodingContainer {
    
    // references
    
    // warning: references to KeyedContainer<Key> types will compiler crash (Command failed due to signal: Abort trap: 6) if the generic value is left out
    // default with <CodingKey> (<String>)
    associatedtype KeyedContainer: DecoderKeyedContainer
    associatedtype Base: DecoderBase
    
    // required
    
    var decoder: Base {get}
    var container: NSArray {get}
    var nestedPath: [CodingKey] {get}
    
    init(decoder: Base, container: NSArray, nestedPath: [CodingKey])
    
    var currentIndex: Int {get set}
    
    // new overridable functions and variables
    
    var currentKey: CodingKey {get}
    
    mutating func next<T>(_ type: T.Type, _ typeDescription: String?) throws -> Any
    
    mutating func decode<T>(with unbox: (Any)throws->T) throws -> T
}

extension DecoderUnkeyedContainer {
    
    public var codingPath: [CodingKey] {
        
        return self.decoder.codingPath + self.nestedPath
    }
    
    public var count: Int? {
        
        return self.container.count
    }
    
    public var isAtEnd: Bool {
        
        return self.currentIndex >= self.container.count
    }
    
    public mutating func decodeNil() throws -> Bool {
        
        // will decode a null value, be sure to increment path.
        defer { self.currentIndex += 1 }
        
        return self.isAtEnd || isNil(self.container[self.currentIndex])
    }
    
    var currentKey: CodingKey {
        
        return "index \(self.currentIndex)"
    }
    
    /// gets the next value if not at end or throws valueNotFound(type, context)
    /// increments currentIndex
    mutating func next<T>(_ type: T.Type, _ typeDescription: String? = nil) throws -> Any {
        
        if isAtEnd {
            
            let typeDescription = typeDescription ?? "\(type)"
            
            throw DecodingError.valueNotFound(
                type,
                DecodingError.Context(
                    codingPath: self.codingPath + [self.currentKey],
                    debugDescription: "Cannot get \(typeDescription) -- Unkeyed container is at end."
                )
            )
        }
        
        // avoid this pitfall, isAtEnd is/should be/will be called before decoding a value, so, isAtEnd must be correct before calling next
        
        defer { self.currentIndex += 1 }
        
        return self.container[self.currentIndex]
    }
    
    mutating func decode<T>(with unbox: (Any)throws->T) throws -> T {
        
        do {
            return try unbox(self.next(T.self))
        } catch {
            throw self.decoder.error(error, at: self.codingPath + [self.currentKey])
        }
    }
    
    public mutating func decode(_ type: Bool.Type  ) throws -> Bool   { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: Int.Type   ) throws -> Int    { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: Int8.Type  ) throws -> Int8   { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: Int16.Type ) throws -> Int16  { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: Int32.Type ) throws -> Int32  { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: Int64.Type ) throws -> Int64  { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: UInt.Type  ) throws -> UInt   { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: UInt8.Type ) throws -> UInt8  { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: UInt16.Type) throws -> UInt16 { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: UInt32.Type) throws -> UInt32 { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: UInt64.Type) throws -> UInt64 { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: Float.Type ) throws -> Float  { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: Double.Type) throws -> Double { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode(_ type: String.Type) throws -> String { return try self.decode(with: self.decoder.unbox(_:)) }
    public mutating func decode<T: Decodable>(_ type: T.Type)throws->T{ return try self.decode(with: self.decoder.unbox(_:)) }
    
    
    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        let value = try self.next(UnkeyedDecodingContainer.self, "nested unkeyed container")
        
        guard let container = value as? NSArray else {
            throw self.decoder.failedToUnbox(value, to: UnkeyedDecodingContainer.self, "nested unkeyed container")
                .asDecodingError(with: self.codingPath + [self.currentKey])
        }
        
        return Self.init(
            decoder: self.decoder,
            container: container,
            nestedPath: self.nestedPath + [self.currentKey]
        )
    }
    
    mutating func superDecoder() throws -> Decoder {
        
        return try Base(
            value: self.next(Decoder.self, "value for super decoder"),
            codingPath: self.codingPath + ["super: \(self.currentKey)"],
            options: self.decoder.options,
            userInfo: self.decoder.userInfo
        )
    }
}

extension DecoderUnkeyedContainer where KeyedContainer.Base == Self.Base {
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        
        let value = try self.next(KeyedDecodingContainer<NestedKey>.self, "nested keyed container")
        
        guard let container = value as? NSDictionary else {
            throw self.decoder.failedToUnbox(value, to: KeyedDecodingContainer<NestedKey>.self, "nested keyed container")
                .asDecodingError(with: self.codingPath + [self.currentKey])
        }
        
        return KeyedContainer.initSelf(
            decoder: self.decoder,
            container: container,
            nestedPath: self.nestedPath + [self.currentKey],
            keyedBy: NestedKey.self
        )
    }
}

/// a wrapping error to associate a path with an unknown unbox error
enum DecodeError: Error {
    case decodeError(Error, atPath: [CodingKey])
    var error: Error {
        switch self {
        case .decodeError(let error, atPath: _): return error
        }
    }
    var codingPath: [CodingKey] {
        switch self {
        case .decodeError(_, atPath: let codingPath): return codingPath
        }
    }
}

/// a type that can be converted to the associated DecodingError later with a codingPath
enum UnboxError: Error {
    
    struct Context {
        var debugDescription: String
        var underlyingError: Error?
        
        init(debugDescription: String, underlyingError: Error? = nil) {
            
            self.debugDescription = debugDescription
            self.underlyingError = underlyingError
        }
        
        func asDecodingErrorContext(with codingPath: [CodingKey]) -> DecodingError.Context {
            return DecodingError.Context(codingPath: codingPath, debugDescription: debugDescription, underlyingError: underlyingError)
        }
    }
    
    case valueNotFound(Any.Type, Context)
    case typeMismatch(Any.Type, Context)
    case dataCorrupted(Context)
    
    func asDecodingError(with codingPath: [CodingKey]) -> DecodingError {
        switch self {
        case .valueNotFound(let type, let context):
            return DecodingError.valueNotFound(type, context.asDecodingErrorContext(with: codingPath))
        case .typeMismatch(let type, let context):
            return DecodingError.typeMismatch(type, context.asDecodingErrorContext(with: codingPath))
        case .dataCorrupted(let context):
            return DecodingError.dataCorrupted(context.asDecodingErrorContext(with: codingPath))
        }
    }
}

protocol ConvertibleNumber {
    init?(exactly: NSNumber)
    init(truncating: NSNumber)
    init(_ value: NSNumber)
}

protocol ConvertibleInteger: ConvertibleNumber {
    init(clamping: Int)
    init(clamping: UInt)
}

extension Int   : ConvertibleInteger {}
extension Int8  : ConvertibleInteger {}
extension Int16 : ConvertibleInteger {}
extension Int32 : ConvertibleInteger {}
extension Int64 : ConvertibleInteger {}
extension UInt  : ConvertibleInteger {}
extension UInt8 : ConvertibleInteger {}
extension UInt16: ConvertibleInteger {}
extension UInt32: ConvertibleInteger {}
extension UInt64: ConvertibleInteger {}
extension Float : ConvertibleNumber {}
extension Double: ConvertibleNumber {}
