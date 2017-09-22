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
    func decode<T: Decodable>(_: T.Type, fromValue value: Any) throws -> T
}

public protocol TypedDecoderBase: DecoderBase {
    
    associatedtype Options
    
    var options: Options {get}
    
    init(codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any])
}

public extension TypedDecoderBase {
    
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
    
    public static func start<T: Decodable>(with value: Any, options: Options, userInfo: [CodingUserInfoKey: Any]) throws -> T {
        return try Self.init(codingPath: [], options: options, userInfo: userInfo).start(with: value)
    }
}

fileprivate var null = NSNull()

/// must be a class, so that references reference the same decoder
public protocol DecoderBase: class, Decoder, SingleValueDecodingContainer {
    
    // references
    func keyedContainer(from value: Any) -> DecoderKeyedContainerContainer?
    func unkeyedContainer(from value: Any) -> DecoderUnkeyedContainerContainer?
    var unkeyedContainerType: DecoderUnkeyedContainer.Type {get}
    
    // required
    var codingPath: [CodingKey] {get set}
    var untypedOptions: Any {get}
    var userInfo: [CodingUserInfoKey : Any] {get}
    
    init(codingPath: [CodingKey], untypedOptions: Any, userInfo: [CodingUserInfoKey : Any])
    
    var storage: [Any] {get set} // = []
    
    // new methods
    
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
}

public extension DecoderBase {
    
    public func start<T: Decodable>(with value: Any) throws -> T {
        return try self.unbox(value, at: [])
    }
    
    public var currentValue: Any {
        return self.storage.last ?? null
    }
    
    // MARK: decode single value
    
    public func decodeNil() -> Bool {
        return isNil(self.currentValue)
    }
    
    public func decode(_ type: Bool.Type  ) throws -> Bool   { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Int.Type   ) throws -> Int    { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Int8.Type  ) throws -> Int8   { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Int16.Type ) throws -> Int16  { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Int32.Type ) throws -> Int32  { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Int64.Type ) throws -> Int64  { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: UInt.Type  ) throws -> UInt   { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: UInt8.Type ) throws -> UInt8  { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: UInt16.Type) throws -> UInt16 { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: UInt32.Type) throws -> UInt32 { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: UInt64.Type) throws -> UInt64 { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Float.Type ) throws -> Float  { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: Double.Type) throws -> Double { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode(_ type: String.Type) throws -> String { return try self.unbox(self.currentValue, at: self.codingPath) }
    public func decode<T: Decodable>(_ type:T.Type)throws->T { return try self.unbox(self.currentValue, at: self.codingPath) }
    
    // MARK: unbox
    
    /// an error to throw if unboxing fails
    public func failedToUnbox<T>(_ value: Any, to: T.Type, _ typeDescription: String? = nil, at codingPath: [CodingKey]) -> Error {
        
        if isNil(value) {
            return self.notFound(T.self, typeDescription, at: codingPath)
        } else {
            return self.typeError(value, T.self, typeDescription, at: codingPath)
        }
    }
    
    public func notFound<T>(_ type: T.Type, _ typeDescription: String? = nil, at codingPath: [CodingKey]) -> Error {
        
        let typeDescription = typeDescription ?? "\(T.self)"
        
        return DecodingError.valueNotFound(
            type,
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Cannot get \(typeDescription) -- found null value instead."
            )
        )
    }
    
    public func typeError<T>(_ value: Any, _: T.Type, _ typeDescription: String? = nil, at codingPath: [CodingKey]) -> Error {
        
        let typeDescription = typeDescription ?? "\(T.self)"
        
        return DecodingError.typeMismatch(
            T.self,
            DecodingError.Context.init(
                codingPath: codingPath,
                debugDescription: "Expected to decode \(typeDescription), but found \(value) with metatype: \(type(of: value))"
            )
        )
    }
    
    public func corrupted(_ debugDescription: String, at codingPath: [CodingKey]) -> Error {
        
        return DecodingError.dataCorrupted(
            DecodingError.Context.init(
                codingPath: codingPath,
                debugDescription: debugDescription
            )
        )
    }
    
    public func convert<T: ConvertibleNumber>(number value: Any, at codingPath: [CodingKey]) throws -> T {
        
        if let number = value as? T {
            
            return number
            
        } else if let value = value as? NSNumber, let number = T(exactly: value) {
            
            return number
            
        } else if let value = value as? String, let number = T(value) {
            
            return number
        }
        
        throw self.failedToUnbox(value, to: T.self, at: codingPath)
    }
    
    /// start a decode with this function
    public func decode<T: Decodable>(with value: Any) throws -> T {
        return try self.unbox(value, at: [])
    }
    
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Bool   { return value as? Bool ?? isNil(value)  }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int    { return try self.convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int8   { return try self.convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int16  { return try self.convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int32  { return try self.convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int64  { return try self.convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt   { return try self.convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt8  { return try self.convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt16 { return try self.convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt32 { return try self.convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt64 { return try self.convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Float  { return try self.convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Double { return try self.convert(number: value, at: codingPath) }
    public func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> String { return value as? String ?? "\(value)"  }
    
    public func unbox<T: Decodable>(_ value: Any, at codingPath: [CodingKey]) throws -> T {
        
        return try self.redecode(value, at: codingPath)
        
        //switch T.self {
        //case is URL.Type: return try unbox(value, at: codingPath) as URL as! T
        //case is Date.Type, is NSDate.Type: return try unbox(value, with: decoder, at: codingPath) as Date as! T
        //default: return try redecode(value, with: decoder, at: codingPath)
        //}
    }
    
    public func redecode<T: Decodable>(_ value: Any, at codingPath: [CodingKey]) throws -> T {
        
        // reverts the codingPath when complete
        let previousPath = self.codingPath
        self.codingPath = codingPath
        defer { self.codingPath = previousPath }
        
        // sets the next value to decode from
        self.storage.append(value)
        defer { self.storage.removeLast() }
        
        return try T(from: self)
    }
    
    public func keyedContainer(from value: Any) -> DecoderKeyedContainerContainer? {
        return value as? NSDictionary
    }
    
    public func unkeyedContainer(from value: Any) -> DecoderUnkeyedContainerContainer? {
        return value as? NSArray
    }
    
    public func createKeyedContainer<T: DecoderKeyedContainer, Key>(_: T.Type) throws -> KeyedDecodingContainer<Key> {
        
        let value = self.currentValue
        
        guard let container = self.keyedContainer(from: value) else {
            throw self.failedToUnbox(value, to: DecoderKeyedContainerContainer.self, "keyed container", at: self.codingPath)
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

        let value = self.currentValue

        guard let container = self.unkeyedContainer(from: value) else {
            throw self.failedToUnbox(value, to: DecoderUnkeyedContainerContainer.self, "unkeyed container", at: self.codingPath)
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

public protocol DecoderKeyedContainerContainer {
    
    func value(forStringValue key: String) -> Any?
    func value(forIntValue key: Int) -> Any?
    var keys: [AnyHashable] {get}
}

extension NSDictionary: DecoderKeyedContainerContainer {
    
    public var keys: [AnyHashable] {
        return (self.allKeys as [Any]).flatMap { $0 as? AnyHashable }
    }
    
    public func value(forStringValue key: String) -> Any? {
        return self[key]
    }
    
    public func value(forIntValue key: Int) -> Any? {
        return self[key]
    }
}

public protocol DecoderKeyedContainer: KeyedDecodingContainerProtocol {
    
    // required
    
    var decoder: DecoderBase {get}
    var container: DecoderKeyedContainerContainer {get}
    var nestedPath: [CodingKey] {get}
    
    init(decoder: DecoderBase, container: DecoderKeyedContainerContainer, nestedPath: [CodingKey])
    
    static func initSelf<Key: CodingKey>(decoder: DecoderBase, container: DecoderKeyedContainerContainer, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedDecodingContainer<Key>
    
    var usesStringValue: Bool {get}
    
    // new methods
    
    func value(forKey key: CodingKey) throws -> Any
    
    func optionalValue(forKey key: CodingKey) -> Any?
    
    // TODO: fix methods and add overridden methods
}

public extension DecoderKeyedContainer {
    
    public var codingPath: [CodingKey] {
        return self.decoder.codingPath + self.nestedPath
    }
    
    public func currentPath(_ key: CodingKey) -> [CodingKey] {
        return self.codingPath + [key]
    }
    
    public var allKeys: [Key] {
        
        return self.container.keys.flatMap {
            
            if self.usesStringValue, let string = $0 as? String {
                return Key(stringValue: string)
                
            } else if let int = $0 as? Int {
                return Key(intValue: int)
                
            } else {
                return nil
            }
        }
    }
    
    private func keyNotFound(_ key: CodingKey) -> Error {
        return DecodingError.keyNotFound(
            key,
            DecodingError.Context(
                // key is not added to the path by default
                codingPath: self.codingPath,
                debugDescription: "No value found for key: \(key) of type: \(type(of: key)) (stringValue: \(key.stringValue), intValue: \(key.intValue.map { $0.description } ?? "nil"))"
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
                throw DecodingError.keyNotFound(
                    key,
                    DecodingError.Context(
                        codingPath: self.currentPath(key),
                        debugDescription: "Tried to get key: \(key) of type: \(type(of: key)) .intValue, but found nil."
                    )
                )
            }
            
            guard let value = self.container.value(forIntValue: key.intValue!) else {
                throw self.keyNotFound(key)
            }
            
            return value
        }
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
    
    public func nestedContainer<NestedKey>(keyedBy: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        
        let value = try self.value(forKey: key)
        
        guard let container = self.decoder.keyedContainer(from: value) else {
            throw self.decoder.failedToUnbox(value, to: DecoderKeyedContainerContainer.self, "nested keyed container", at: self.currentPath(key))
        }
        
        return Self.initSelf(decoder: self.decoder, container: container, nestedPath: self.nestedPath + [key], keyedBy: NestedKey.self)
    }
    
    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        
        let value = try self.value(forKey: key)

        guard let container = self.decoder.unkeyedContainer(from: value) else {
            throw self.decoder.failedToUnbox(value, to: DecoderUnkeyedContainerContainer.self, "nested unkeyed container", at: self.currentPath(key))
        }

        return self.decoder.unkeyedContainerType.init(
            decoder: self.decoder,
            container: container,
            nestedPath: self.nestedPath + [key]
        )
    }
    
    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        
        let decoder = type(of: self.decoder).init(
            codingPath: self.currentPath(key),
            untypedOptions: self.decoder.untypedOptions,
            userInfo: self.decoder.userInfo
        )
        
        decoder.storage.append(self.optionalValue(forKey: key) ?? NSNull())
        
        return decoder
    }
    
    public func superDecoder() throws -> Decoder {
        
        return try self._superDecoder(forKey: "super")
    }
    
    public func superDecoder(forKey key: Key) throws -> Decoder {
        
        return try self._superDecoder(forKey: key)
    }
}

// MARK: UnkeyedContainer

public protocol DecoderUnkeyedContainerContainer {
    
    func fromStorage(_ index: Int) -> Any
    
    var count: Int {get}
}

extension NSArray: DecoderUnkeyedContainerContainer {
    public func fromStorage(_ index: Int) -> Any {
        return self[index]
    }
}

public protocol DecoderUnkeyedContainer: UnkeyedDecodingContainer {
    
    // required
    
    var decoder: DecoderBase {get}
    var container: DecoderUnkeyedContainerContainer {get}
    var nestedPath: [CodingKey] {get}
    
    init(decoder: DecoderBase, container: DecoderUnkeyedContainerContainer, nestedPath: [CodingKey])
    
    /// currentIndex starts at 0 and increments for every call
    var currentIndex: Int {get set} // = 0
    
    // new methods
    
    // TODO: add new methods
}

public extension DecoderUnkeyedContainer {
    
    public var codingPath: [CodingKey] {
        return self.decoder.codingPath + self.nestedPath
    }
    
    public var currentPath: [CodingKey] {
        return self.codingPath + [self.currentKey]
    }
    
    /// if called before self.next, use: "index: \(self.currentIndex)" instead
    public var currentKey: CodingKey {
        
        return "Index \(self.currentIndex)"
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
        
        // note: fromStorage won't be called if self.isAtEnd == true
        return self.isAtEnd || isNil(self.container.fromStorage(self.currentIndex))
    }
    
    /// gets the next value if not at end or throws valueNotFound(type, context)
    /// increments currentIndex
    public mutating func next<T>(_: T.Type, _ typeDescription: String? = nil) throws -> Any {
        
        
        // avoid this pitfall, isAtEnd is/should be/will be called before decoding a value at all, so, isAtEnd must be correct before next is called
        if self.isAtEnd {
            
            self.currentIndex += 1
            
            let typeDescription = typeDescription ?? "\(T.self)"
            
            throw DecodingError.valueNotFound(
                T.self,
                DecodingError.Context(
                    codingPath: self.currentPath,
                    debugDescription: "Cannot get \(typeDescription) -- Unkeyed container is at end."
                )
            )
        }
        
        defer { self.currentIndex += 1 }
        
        return self.container.fromStorage(self.currentIndex)
    }
    
    public mutating func decode(_ type: Bool.Type  ) throws -> Bool   { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: Int.Type   ) throws -> Int    { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: Int8.Type  ) throws -> Int8   { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: Int16.Type ) throws -> Int16  { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: Int32.Type ) throws -> Int32  { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: Int64.Type ) throws -> Int64  { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: UInt.Type  ) throws -> UInt   { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: UInt8.Type ) throws -> UInt8  { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: UInt16.Type) throws -> UInt16 { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: UInt32.Type) throws -> UInt32 { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: UInt64.Type) throws -> UInt64 { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: Float.Type ) throws -> Float  { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: Double.Type) throws -> Double { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode(_ type: String.Type) throws -> String { return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    public mutating func decode<T: Decodable>(_ type: T.Type)throws->T{ return try self.decoder.unbox(self.next(type), at: self.currentPath) }
    
    public mutating func createKeyedContainer<T: DecoderKeyedContainer, NestedKey>(_: T.Type) throws -> KeyedDecodingContainer<NestedKey> {

        let value = try self.next(KeyedDecodingContainer<NestedKey>.self, "nested keyed container")

        guard let container = self.decoder.keyedContainer(from: value) else {
            throw self.decoder.failedToUnbox(value, to: DecoderKeyedContainerContainer.self, "nested keyed container", at: self.currentPath)
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
            throw self.decoder.failedToUnbox(value, to: DecoderUnkeyedContainerContainer.self, "nested unkeyed container", at: self.currentPath)
        }
        
        return Self.init(
            decoder: self.decoder,
            container: container,
            nestedPath: self.nestedPath + [self.currentKey]
        )
    }
    
    public mutating func superDecoder() throws -> Decoder {
        
        let decoder = type(of: self.decoder).init(
            codingPath: self.currentPath,
            untypedOptions: self.decoder.untypedOptions,
            userInfo: self.decoder.userInfo
        )
        
        let value = try? self.next(Decoder.self, "super decoder")
        
        decoder.storage.append(value ?? NSNull())
        
        return decoder
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



//fileprivate protocol UnderlyingValue {
//    func underlyingValue() -> Any
//}
//
//extension Optional: UnderlyingValue {
//
//    /// returns value or .none as Any
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





