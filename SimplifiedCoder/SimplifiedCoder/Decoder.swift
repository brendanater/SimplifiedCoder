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
public protocol TopLevelDecoder {
    
    func decode<T: Decodable>(_: T.Type, from data: Data) throws -> T
}

public protocol TypedDecoderBase: DecoderBase {
    
    associatedtype Options
    
    var options: Options {get}
    
    init(options: Options, userInfo: [CodingUserInfoKey : Any])
}

extension TypedDecoderBase {
    
    var untypedOptions: Any {
        return self.options
    }
    
    public init(untypedOptions: Any, userInfo: [CodingUserInfoKey : Any]) {
        
        if let options = untypedOptions as? Options {
            self.init(options: options, userInfo: userInfo)
        } else {
            fatalError("Failed to cast options: \(untypedOptions) to type: \(Self.Options.self)")
        }
    }
}

fileprivate var null: NSNull {
    return NSNull()
}

/// must be a class, so that references reference the same decoder
public protocol DecoderBase: class, Decoder, SingleValueDecodingContainer {
    
    // references
    
    var unkeyedContainerType: DecoderUnkeyedContainer.Type {get}
    
    // required
    
    var untypedOptions: Any {get}
    var userInfo: [CodingUserInfoKey : Any] {get}
    
    init(untypedOptions: Any, userInfo: [CodingUserInfoKey : Any])
    
    // only the first key is nil
    var storage: [(key: CodingKey?, value: Any)] {get set} // = []
    var tempKey: CodingKey? {get set} // = nil
    var previousPath: [CodingKey] {get set} // lazy? = []
    
    // new methods
    
    func decodeNil() -> Bool
    
    // decides which unbox error to throw based on the value
    func failedToUnbox<T>(_ value: Any, to: T.Type, _ typeDescription: String?) -> Error
    
    func notFound<T>(_ type: T.Type, _ typeDescription: String?) -> Error
    func typeError<T>(_ value: Any, _ type: T.Type, _ typeDescription: String?) -> Error
    func corrupted(_ debugDescription: String) -> Error
    
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
    
    // TODO: add overridden methods
}

public extension DecoderBase {
    
    var codingPath: [CodingKey] {
        
        return self.previousPath + self.storage.flatMap { $0.key }
    }
    
    func new(previousPath: [CodingKey]) -> Self {
        
        let new = Self.init(untypedOptions: self.untypedOptions, userInfo: self.userInfo)
        
        new.previousPath = previousPath
        
        return new
    }
    
    // MARK: decode single value
    
    public func decodeNil() -> Bool {
        return isNil(self.storage.last)
    }
    
    public func decode(_: Bool.Type  ) throws -> Bool   { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: Int.Type   ) throws -> Int    { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: Int8.Type  ) throws -> Int8   { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: Int16.Type ) throws -> Int16  { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: Int32.Type ) throws -> Int32  { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: Int64.Type ) throws -> Int64  { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: UInt.Type  ) throws -> UInt   { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: UInt8.Type ) throws -> UInt8  { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: UInt16.Type) throws -> UInt16 { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: UInt32.Type) throws -> UInt32 { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: UInt64.Type) throws -> UInt64 { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: Float.Type ) throws -> Float  { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: Double.Type) throws -> Double { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode(_: String.Type) throws -> String { return try self.unbox(self.storage.last?.value ?? null) }
    public func decode<T: Decodable>(_:T.Type)throws->T { return try self.unbox(self.storage.last?.value ?? null) }
    
    // MARK: unbox
    
    /// an error to throw if unboxing fails
    public func failedToUnbox<T>(_ value: Any, to: T.Type, _ typeDescription: String? = nil) -> Error {
        
        if isNil(value) {
            return self.notFound(T.self, typeDescription)
        } else {
            return self.typeError(value, T.self, typeDescription)
        }
    }
    
    public func notFound<T>(_ type: T.Type, _ typeDescription: String? = nil) -> Error {
        
        let typeDescription = typeDescription ?? "\(T.self)"
        
        return DecodingError.valueNotFound(
            type,
            DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Cannot get \(typeDescription) -- found null value instead."
            )
        )
    }
    
    public func typeError<T>(_ value: Any, _: T.Type, _ typeDescription: String? = nil) -> Error {
        
        let typeDescription = typeDescription ?? "\(T.self)"
        
        return DecodingError.typeMismatch(
            T.self,
            DecodingError.Context.init(
                codingPath: self.codingPath,
                debugDescription: "Expected to decode \(typeDescription), but found \(value) with type: \(type(of: value))"
            )
        )
    }
    
    public func corrupted(_ debugDescription: String) -> Error {
        
        return DecodingError.dataCorrupted(
            DecodingError.Context.init(
                codingPath: self.codingPath,
                debugDescription: debugDescription
            )
        )
    }
    
    public func convert<T: ConvertibleNumber>(number value: Any) throws -> T {
        
        if let number = value as? T {
            
            return number
            
        } else if let value = value as? NSNumber, let number = T(exactly: value) {
            
            return number
            
        } else if let value = value as? String, let number = T(value) {
            
            return number
        }
        
        throw self.failedToUnbox(value, to: T.self)
    }
    
    public func unbox(_ value: Any) throws -> Bool   { return value as? Bool ?? isNil(value)  }
    public func unbox(_ value: Any) throws -> Int    { return try self.convert(number: value) }
    public func unbox(_ value: Any) throws -> Int8   { return try self.convert(number: value) }
    public func unbox(_ value: Any) throws -> Int16  { return try self.convert(number: value) }
    public func unbox(_ value: Any) throws -> Int32  { return try self.convert(number: value) }
    public func unbox(_ value: Any) throws -> Int64  { return try self.convert(number: value) }
    public func unbox(_ value: Any) throws -> UInt   { return try self.convert(number: value) }
    public func unbox(_ value: Any) throws -> UInt8  { return try self.convert(number: value) }
    public func unbox(_ value: Any) throws -> UInt16 { return try self.convert(number: value) }
    public func unbox(_ value: Any) throws -> UInt32 { return try self.convert(number: value) }
    public func unbox(_ value: Any) throws -> UInt64 { return try self.convert(number: value) }
    public func unbox(_ value: Any) throws -> Float  { return try self.convert(number: value) }
    public func unbox(_ value: Any) throws -> Double { return try self.convert(number: value) }
    public func unbox(_ value: Any) throws -> String { return value as? String ?? "\(value)"  }
    public func unbox<T: Decodable>(_ value: Any) throws -> T {
        return try self.redecode(value)
        //        switch T.self {
        //        case is Date: return try unbox(value) as Date
        //        default: return try redecode(value)
        //        }
    }
    
    public func redecode<T: Decodable>(_ value: Any) throws -> T {
        
        // decoder now uses this value to decode from (same as creating a new decoder)
        self.storage.append(value)
        let decoded = try T(from: self)
        // not decoding with this value anymore (same as manually deinitializing the new decoder)
        self.storage.removeLast()
        return decoded
    }
    
    public func keyedContainer(from value: Any) -> DecoderKeyedContainerType? {
        return value as? NSDictionary
    }
    
    public func unkeyedContainer(from value: Any) -> DecoderUnkeyedContainerType? {
        return value as? NSArray
    }
    
    public func createKeyedContainer<T: DecoderKeyedContainer, Key>(_: T.Type) throws -> KeyedDecodingContainer<Key> {

        let value = self.storage.last ?? NSNull()
        
        guard let container = self.keyedContainer(from: value) else {
            throw self.failedToUnbox(value, to: KeyedDecodingContainer<Key>.self, "keyed container")
        }

        return T.initSelf(
            decoder: self,
            container: container,
            nestedPath: [],
            keyedBy: Key.self
        )
    }
    
    //    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
    //        return createKeyedContainer({ DecoderKeyedContainer }.self)
    //    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {

        let value = self.storage.last ?? NSNull()

        guard let container = self.unkeyedContainer(from: value) else {
            throw self.failedToUnbox(value, to: UnkeyedDecodingContainer.self, "unkeyed container")
        }

        return self.unkeyedContainerType.init(
            decoder: self,
            container: container,
            nestedPath: []
        )
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

// MARK: KeyedContainer

public protocol DecoderKeyedContainerType {
    subscript(key: AnyHashable) -> Any? {get}
    var allKeys: [Any] {get}
}

extension NSDictionary: DecoderKeyedContainerType {
    public subscript(key: AnyHashable) -> Any? {
        get {
            return self[key as Any]
        }
    }
}

public protocol DecoderKeyedContainer: KeyedDecodingContainerProtocol {
    
    // required
    
    var decoder: DecoderBase {get}
    var container: DecoderKeyedContainerType {get}
    var nestedPath: [CodingKey] {get}
    
    init(decoder: DecoderBase, container: DecoderKeyedContainerType, nestedPath: [CodingKey])
    
    static func initSelf<Key: CodingKey>(decoder: DecoderBase, container: DecoderKeyedContainerType, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedDecodingContainer<Key>
    
    var usesStringValue: Bool {get}
    
    // new methods
    
    func value(forKey key: CodingKey) throws -> Any
    
    func optionalValue(forKey key: CodingKey) -> Any?
    
    func decode<T>(with unbox: (Any)throws->T, forKey key: Key) throws -> T
    
    // TODO: fix methods and add overridden methods
}

public extension DecoderKeyedContainer {
    
    public var codingPath: [CodingKey] {
        return self.decoder.codingPath
    }
    
    public var allKeys: [Key] {
        return self.container.allKeys.flatMap {
            
            if self.usesStringValue, let string = $0 as? String {
                return Key(stringValue: string)
                
            } else if let int = $0 as? Int {
                return Key(intValue: int)
                
            } else {
                return nil
            }
        }
    }
    
    public func _key(from key: CodingKey) -> AnyHashable {
        
        if self.usesStringValue {
            
            return key.stringValue
            
        } else {
            
            guard key.intValue != nil else {
                fatalError("Tried to get \(key).intValue but found nil")
            }
            
            return key.intValue!
        }
    }
    
    public func value(forKey key: CodingKey) throws -> Any {
        
        guard let value = self.container[self._key(from: key)] else {
            throw DecodingError.keyNotFound(
                key,
                DecodingError.Context(
                    codingPath: self.codingPath + [key],
                    // starts(with: "_ ") to override withNestedPath(_:)
                    debugDescription: "_ No value found for key: \(self._key(from: key)) (\(key))"
                )
            )
        }
        
        return value
    }
    
    public func optionalValue(forKey key: CodingKey) -> Any? {
        
        return try? self.value(forKey: key)
    }
    
    public func contains(_ key: Key) -> Bool {
        
        return isNil(self.optionalValue(forKey: key))
    }
    
    public func decodeNil(forKey key: Key) throws -> Bool {
        
        // throw if key not found
        return try isNil(self.value(forKey: key))
    }
    
    public func decode<T>(with unbox: (Any)throws->T, forKey key: Key) throws -> T {
        
        do {
            return try unbox(self.value(forKey: key))
            
        } catch {
            
            if let error = error as? HasCodingPath & Error {
                
                let codingPath = error.
                
                if self.codingPath.count > codingPath.count {
                    
                }
                
                throw error.withNestedPath(self.nestedPath + [key])
            } else {
                throw error
            }
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
        
        guard let container = self.decoder.keyedContainer(from: value) else {
            throw self.decoder.failedToUnbox(value, to: KeyedDecodingContainer<NestedKey>.self, "nested keyed container")
        }
        
        return Self.initSelf(decoder: self.decoder, container: container, nestedPath: self.nestedPath + [key], keyedBy: NestedKey.self)
    }
    
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        let value = try self.value(forKey: key)

        guard let container = self.decoder.unkeyedContainer(from: value) else {
            throw self.decoder.failedToUnbox(value, to: UnkeyedDecodingContainer.self, "nested unkeyed container")
        }

        return self.decoder.unkeyedContainerType.init(
            decoder: self.decoder,
            container: container,
            nestedPath: self.nestedPath + [key]
        )
    }
    
    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        
        return type(of: self.decoder).init(
            value: self.optionalValue(forKey: key) ?? NSNull(),
            codingPath: self.codingPath + [key],
            untypedOptions: self.decoder.untypedOptions,
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

// MARK: UnkeyedContainer

public protocol DecoderUnkeyedContainerType {
    subscript(index: Int) -> Any {get}
    var count: Int {get}
}

extension NSArray: DecoderUnkeyedContainerType {}

public protocol DecoderUnkeyedContainer: UnkeyedDecodingContainer {
    
    // required
    
    var decoder: DecoderBase {get}
    var container: DecoderUnkeyedContainerType {get}
    var nestedPath: [CodingKey] {get}
    
    init(decoder: DecoderBase, container: DecoderUnkeyedContainerType, nestedPath: [CodingKey])
    
    var currentIndex: Int {get set}
    
    // new methods
    
    // TODO: add new methods
}

public extension DecoderUnkeyedContainer {
    
    public var codingPath: [CodingKey] {
        
        return self.decoder.codingPath
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
    
    public var currentKey: CodingKey {
        
        return "index: \(self.currentIndex)"
    }
    
    /// gets the next value if not at end or throws valueNotFound(type, context)
    /// increments currentIndex
    public mutating func next<T>(_: T.Type, _ typeDescription: String? = nil) throws -> Any {
        
        if self.isAtEnd {
            
            let typeDescription = typeDescription ?? "\(T.self)"
            
            throw DecodingError.valueNotFound(
                T.self,
                DecodingError.Context(
                    codingPath: self.codingPath + [self.currentKey],
                    debugDescription: "_ Cannot get \(typeDescription) -- Unkeyed container is at end."
                )
            )
        }
        
        // avoid this pitfall, isAtEnd is/should be/will be called before decoding a value, so, isAtEnd must be correct before calling next
        
        defer { self.currentIndex += 1 }
        
        return self.container[self.currentIndex]
    }
    
    public mutating func decode<T>(with unbox: (Any)throws->T) throws -> T {
        do {
            return try unbox(self.next(T.self))
            
        } catch {
            if let error = error as? HasCodingPath & Error {
                throw error.withNestedPath(self.nestedPath + [self.currentKey])
            } else {
                throw error
            }
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
    
    public mutating func createKeyedContainer<T: DecoderKeyedContainer, NestedKey>(_: T.Type) throws -> KeyedDecodingContainer<NestedKey> {

        let value = try self.next(KeyedDecodingContainer<NestedKey>.self, "nested keyed container")

        guard let container = self.decoder.keyedContainer(from: value) else {
            throw self.decoder.failedToUnbox(value, to: KeyedDecodingContainer<NestedKey>.self, "nested keyed container")
        }

        return T.initSelf(
            decoder: self.decoder,
            container: container,
            nestedPath: self.nestedPath + [self.currentKey],
            keyedBy: NestedKey.self
        )
    }
    
//    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
//        return self.createKeyedContainer({ DecoderKeyedContainer }.self)
//    }
    
    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        let value = try self.next(UnkeyedDecodingContainer.self, "nested unkeyed container")
        
        guard let container = self.decoder.unkeyedContainer(from: value) else {
            throw self.decoder.failedToUnbox(value, to: UnkeyedDecodingContainer.self, "nested unkeyed container")
        }
        
        return Self.init(
            decoder: self.decoder,
            container: container,
            nestedPath: self.nestedPath + [self.currentKey]
        )
    }
    
    public mutating func superDecoder() throws -> Decoder {
        
        return type(of: self.decoder).init(
            value: try self.next(Decoder.self, "super"),
            codingPath: self.codingPath + [self.currentKey],
            untypedOptions: self.decoder.untypedOptions,
            userInfo: self.decoder.userInfo
        )
    }
}

public protocol ConvertibleNumber {
    
    init?(_: String)
    init?(exactly: NSNumber)
}

extension Int   : ConvertibleNumber {}
extension Int8  : ConvertibleNumber {}
extension Int16 : ConvertibleNumber {}
extension Int32 : ConvertibleNumber {}
extension Int64 : ConvertibleNumber {}
extension UInt  : ConvertibleNumber {}
extension UInt8 : ConvertibleNumber {}
extension UInt16: ConvertibleNumber {}
extension UInt32: ConvertibleNumber {}
extension UInt64: ConvertibleNumber {}
extension Float : ConvertibleNumber {}
extension Double: ConvertibleNumber {}

fileprivate protocol UnderlyingValue {
    func underlyingValue() -> Any
}

extension Optional: UnderlyingValue {
    
    /// returns value or .none as Any
    func underlyingValue() -> Any {
        
        if case .some(let wrapped) = self {
            
            if let wrapped = wrapped as? UnderlyingValue {
                return wrapped.underlyingValue()
            } else {
                return wrapped
            }
            
        } else {
            return self as Any
        }
    }
}

/// returns the wrapped value or .none as Any
func underlyingValue(_ value: Any?) -> Any {
    return value.underlyingValue()
}





