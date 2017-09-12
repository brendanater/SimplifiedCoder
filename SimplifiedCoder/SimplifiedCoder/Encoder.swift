//
//  Encoder2.swift
//  SimplifiedCoder
//
//  Created by Brendan Henderson on 8/23/17.
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

/// the encoder that the user calls to abstract away complexity
public protocol TopLevelEncoder {
    
    func encode(_ value: Encodable) throws -> Data
}

// MARK: - EncoderBase

public protocol TypedEncoderBase: EncoderBase {
    associatedtype Options
    var options: Options {get}
    init(options: Options, userInfo: [CodingUserInfoKey: Any])
}

extension TypedEncoderBase {
    
    var untypedOptions: Any {
        get {
            return options
        }
    }
    
    public init(untypedOptions: Any, userInfo: [CodingUserInfoKey : Any]) {
        if let options = untypedOptions as? Options {
            self.init(options: options, userInfo: userInfo)
        } else {
            fatalError("Failed to cast to \(Options.self): \(untypedOptions)")
        }
    }
}

public protocol EncoderBase: class, Encoder, SingleValueEncodingContainer {
    
    // references
    
    var unkeyedContainerType: EncoderUnkeyedContainer.Type {get}
    
    var referenceType: EncoderReference.Type {get}
    
    // required methods
    
    /// Options set on the top-level encoder.
    var untypedOptions: Any {get}
    var userInfo: [CodingUserInfoKey : Any] {get}
    init(untypedOptions: Any, userInfo: [CodingUserInfoKey : Any])
    
    // storage and key were zipped together to better guarantee a single path to any resource
    var storage: [(key: CodingKey?, value: Any)] {get set}
    // a temporary storage for a new key
    var key: CodingKey? {get set}
    
    // methods
    
    var keyedContainerContainerType: EncoderKeyedContainerType.Type {get}
    var unkeyedContainerContainerType: EncoderUnkeyedContainerType.Type {get}
    
    // remember to override codingPath in subclasses (EncoderReference) if custom implementing codingPath
    // default return self._codingPath
    /// The path to the current point in encoding.
    var codingPath: [CodingKey] {get}
    
    var canEncodeNewValue: Bool {get}
    
    func removeKey() -> CodingKey?
    
    func set(_ encoded: Any)
    
    func encode<T>(_ value: T, with box: (T)throws->Any) throws
    
    func encodeNil(            ) throws
    func encode(_ value: Bool  ) throws
    func encode(_ value: Int   ) throws
    func encode(_ value: Int8  ) throws
    func encode(_ value: Int16 ) throws
    func encode(_ value: Int32 ) throws
    func encode(_ value: Int64 ) throws
    func encode(_ value: UInt  ) throws
    func encode(_ value: UInt8 ) throws
    func encode(_ value: UInt16) throws
    func encode(_ value: UInt32) throws
    func encode(_ value: UInt64) throws
    func encode(_ value: String) throws
    func encode(_ value: Float ) throws
    func encode(_ value: Double) throws
    
    func encode<T : Encodable>(_ value: T) throws
    
    // MARK: encoder.box(_:)
    
    
    
    func box(_ value: Void  ) throws -> Any
    func box(_ value: Bool  ) throws -> Any
    func box(_ value: Int   ) throws -> Any
    func box(_ value: Int8  ) throws -> Any
    func box(_ value: Int16 ) throws -> Any
    func box(_ value: Int32 ) throws -> Any
    func box(_ value: Int64 ) throws -> Any
    func box(_ value: UInt  ) throws -> Any
    func box(_ value: UInt8 ) throws -> Any
    func box(_ value: UInt16) throws -> Any
    func box(_ value: UInt32) throws -> Any
    func box(_ value: UInt64) throws -> Any
    func box(_ value: Float ) throws -> Any
    func box(_ value: Double) throws -> Any
    func box(_ value: String) throws -> Any
    
    func box(_ value: Encodable) throws -> Any
    
    func reencode(_ value: Encodable) throws -> Any
    
    func createKeyedContainer<T: EncoderKeyedContainer, Key>(_: T.Type) -> KeyedEncodingContainer<Key> where T.Key == Key
    
    // public func keyedContainer<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
    //     return self.createKeyedContainer({ EncoderKeyedContainer }<Key>.self)
    // }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer
    
    func singleValueContainer() -> SingleValueEncodingContainer
}

public extension EncoderBase {
    
    public var keyedContainerContainerType: EncoderKeyedContainerType.Type {
        return NSMutableDictionary.self
    }
    
    public var unkeyedContainerContainerType: EncoderUnkeyedContainerType.Type {
        return NSMutableArray.self
    }
    
    public var _codingPath: [CodingKey] {
        return self.storage.flatMap { $0.key }
    }
    
    public var canEncodeNewValue: Bool {
        return self.key != nil || self.storage.count == 0
    }
    
    public func removeKey() -> CodingKey? {
        defer { self.key = nil }
        return self.key
    }
    
    public func set(_ encoded: Any) {
        
        guard self.canEncodeNewValue else {
            
            let v = self.storage.last!.value
            let first = "\(v) of type: \(type(of: v))"
            let second = "\(encoded) of type: \(type(of: encoded))"
            
            fatalError("Tried to set a second value when previously already encoded at path: \(self.codingPath).  encoded: \(first) tried to set: \(second)")
        }
        
        self.storage.append((self.removeKey(), encoded))
    }
    
    /// casts the error to the right type and associates the error with the right codingPath
    public func error(_ error: Error, with value: Any, atPath codingPath: [CodingKey]) -> Error {
        
        if case EncodingError.invalidValue(let value, let context) = error {
            if codingPath.count > context.codingPath.count {
                return EncodingError.invalidValue(
                    value,
                    EncodingError.Context.init(
                        codingPath: codingPath,
                        debugDescription: context.debugDescription,
                        underlyingError: context.underlyingError
                    )
                )
            } else {
                return error
            }
        } else {
            return EncodingError.invalidValue(
                value,
                EncodingError.Context.init(
                    codingPath: codingPath,
                    debugDescription: "Failed to encode value",
                    underlyingError: error
                )
            )
        }
    }
    
    public func encode<T>(_ value: T, with box: (T)throws->Any) throws {
        
        do {
            
            try self.set(box(value))
            
        } catch {
            throw self.error(error, with: value, atPath: self.codingPath)
        }
    }
    
    public func encodeNil(            ) throws { try encode(()   , with: self.box(_:)) }
    public func encode(_ value: Bool  ) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: Int   ) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: Int8  ) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: Int16 ) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: Int32 ) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: Int64 ) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: UInt  ) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: UInt8 ) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: UInt16) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: UInt32) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: UInt64) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: String) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: Float ) throws { try encode(value, with: self.box(_:)) }
    public func encode(_ value: Double) throws { try encode(value, with: self.box(_:)) }
    
    public func encode<T : Encodable>(_ value: T) throws { try encode(value as Encodable, with: self.box(_:)) }
    
    // MARK: encoder.box(_:)
    
    public func box(_ value: Void  ) throws -> Any{return NSNull()}
    public func box(_ value: Bool  ) throws -> Any { return value }
    public func box(_ value: Int   ) throws -> Any { return value }
    public func box(_ value: Int8  ) throws -> Any { return value }
    public func box(_ value: Int16 ) throws -> Any { return value }
    public func box(_ value: Int32 ) throws -> Any { return value }
    public func box(_ value: Int64 ) throws -> Any { return value }
    public func box(_ value: UInt  ) throws -> Any { return value }
    public func box(_ value: UInt8 ) throws -> Any { return value }
    public func box(_ value: UInt16) throws -> Any { return value }
    public func box(_ value: UInt32) throws -> Any { return value }
    public func box(_ value: UInt64) throws -> Any { return value }
    public func box(_ value: Float ) throws -> Any { return value }
    public func box(_ value: Double) throws -> Any { return value }
    public func box(_ value: String) throws -> Any { return value }
    
    public func box(_ value: Encodable) throws -> Any {
        
        return try reencode(value)
        
        //switch value {
        //case is Date: return try box(value as Date)
        //case is URL: return try box(value as URL)
        //default: return try reencode(value)
        //}
    }
    
    public func reencode(_ value: Encodable) throws -> Any {
        
        let count = self.storage.count
        
        try value.encode(to: self)
        
        // The top container should be a new container.
        guard self.storage.count > count else {
            fatalError("\(type(of: value)) did not encode a value.")
        }
        
        return self.storage.removeLast().value
    }
    
    public func createKeyedContainer<T: EncoderKeyedContainer, Key>(_: T.Type) -> KeyedEncodingContainer<Key> where T.Key == Key {
        
        // If an existing keyed container was already requested, return that one.
        let container: EncoderKeyedContainerType
        
        if self.canEncodeNewValue {
            
            container = self.keyedContainerContainerType.init()
            
            self.set(container)
            
        } else {
            // could just crash here, but checks if the last encoded container is the same type and returns that.
            
            if let _container = self.storage.last!.value as? EncoderKeyedContainerType {
                container = _container
            } else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
        }
        
        return KeyedEncodingContainer(T.init(encoder: self, container: container, nestedPath: []))
    }
    
    // public func keyedContainer<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
    //     return self.createKeyedContainer({ EncoderKeyedContainer }<Key>.self)
    // }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        
        let container: EncoderUnkeyedContainerType
        
        if self.canEncodeNewValue {
            
            container = self.unkeyedContainerContainerType.init()
            
            self.set(container)
            
        } else {
            // could just crash here, but checks if the last encoded container is the same type and returns that.
            
            if let _container = self.storage.last?.value as? EncoderUnkeyedContainerType {
                container = _container
            } else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }
        }
        
        return self.unkeyedContainerType.init(encoder: self, container: container, nestedPath: [])
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
}

/// has to be a class to set to an already set object
public protocol EncoderKeyedContainerType: class {
    
    subscript(key: Any) -> Any? {get set}
    
    init()
}

extension NSMutableDictionary: EncoderKeyedContainerType {}

// MARK: - Encoding Containers
public protocol EncoderKeyedContainer: KeyedEncodingContainerProtocol {
    
    // required methods
    
    var encoder: EncoderBase {get}
    var container: EncoderKeyedContainerType {get}
    var nestedPath: [CodingKey] {get}
    init(encoder: EncoderBase, container: EncoderKeyedContainerType, nestedPath: [CodingKey])
    
    /// initSelf is longer, but it's easier than the custom nestedKeyedContainer function
    static func initSelf<Key>(encoder: EncoderBase, container: EncoderKeyedContainerType, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedEncodingContainer<Key>
    
    var usesStringValue: Bool {get}
    
    // methods
    
    var codingPath: [CodingKey] {get}
    
    func set(_ encoded: Any, forKey key: CodingKey)
    
    func encode<T>(_ value: T, with box: (T)throws->Any, forKey key: Key) throws
    
    // MARK: - KeyedEncodingContainerProtocol Methods
    mutating func encodeNil(              forKey key: Key) throws
    mutating func encode(_ value: Bool  , forKey key: Key) throws
    mutating func encode(_ value: Int   , forKey key: Key) throws
    mutating func encode(_ value: Int8  , forKey key: Key) throws
    mutating func encode(_ value: Int16 , forKey key: Key) throws
    mutating func encode(_ value: Int32 , forKey key: Key) throws
    mutating func encode(_ value: Int64 , forKey key: Key) throws
    mutating func encode(_ value: UInt  , forKey key: Key) throws
    mutating func encode(_ value: UInt8 , forKey key: Key) throws
    mutating func encode(_ value: UInt16, forKey key: Key) throws
    mutating func encode(_ value: UInt32, forKey key: Key) throws
    mutating func encode(_ value: UInt64, forKey key: Key) throws
    mutating func encode(_ value: String, forKey key: Key) throws
    mutating func encode(_ value: Float , forKey key: Key) throws
    mutating func encode(_ value: Double, forKey key: Key) throws
    
    mutating func encode<T : Encodable>(_ value: T, forKey key: Key) throws
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey>
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer
    
    mutating func superEncoder() -> Encoder
    mutating func superEncoder(forKey key: Key) -> Encoder
}

public extension EncoderKeyedContainer {
    
    public var codingPath: [CodingKey] {
        return self.encoder.codingPath + self.nestedPath
    }
    
    public func set(_ encoded: Any, forKey key: CodingKey) {
        
        if self.usesStringValue {

            self.container[key.stringValue] = encoded

        } else {

            precondition(key.intValue != nil, "Tried to get \(key).intValue, but found nil.")

            self.container[key.intValue!] = encoded
        }
    }
    
    public func encode<T>(_ value: T, with box: (T)throws->Any, forKey key: Key) throws {
        
        do {
            try self.set(box(value), forKey: key)
            
        } catch {
            throw self.encoder.error(error, with: value, atPath: self.codingPath + [key])
        }
    }
    
    // MARK: - KeyedEncodingContainerProtocol Methods
    public mutating func encodeNil(              forKey key: Key) throws { try self.encode(()   , with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Bool  , forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int   , forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int8  , forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int16 , forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int32 , forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int64 , forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt  , forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt8 , forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt16, forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt32, forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt64, forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: String, forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Float , forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Double, forKey key: Key) throws { try self.encode(value, with: self.encoder.box(_:), forKey: key) }
    
    // remember to set key to encoder.key before calling encoder.reencode(Encodable) after the initial container was added, or the encoder won't know that a value has been added with a codingPath.
    public mutating func encode<T : Encodable>(_ value: T, forKey key: Key) throws {
        
        // how to have self.codingPath available
        
        self.encoder.key = key
        
        try encode(value as Encodable, with: self.encoder.box(_:), forKey: key)
    }
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        
        let container = type(of: self.container).init()
        
        self.set(container, forKey: key)
        
        return Self.initSelf(encoder: self.encoder, container: container, nestedPath: self.nestedPath + [key], keyedBy: NestedKey.self)
    }
    
    public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {

        let container = self.encoder.unkeyedContainerContainerType.init()

        self.set(container, forKey: key)

        return self.encoder.unkeyedContainerType.init(encoder: self.encoder, container: container, nestedPath: self.nestedPath + [key])
    }

    public mutating func superEncoder() -> Encoder {
        return self.encoder.referenceType.init(encoder: self.encoder, reference: .keyed(self.container, key: "super"), previousPath: self.codingPath + ["super"])
    }

    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return self.encoder.referenceType.init(encoder: self.encoder, reference: .keyed(self.container, key: key), previousPath: self.codingPath + [key])
    }
}

public protocol EncoderUnkeyedContainerType: class {
    
    init()
    var count: Int {get}
    func add(_ value: Any)
    func replaceObject(at index: Int, with object: Any)
}

extension NSMutableArray: EncoderUnkeyedContainerType {}

public protocol EncoderUnkeyedContainer : UnkeyedEncodingContainer {
    
    // required methods
    
    var encoder: EncoderBase {get}
    var container: EncoderUnkeyedContainerType {get}
    var nestedPath: [CodingKey] {get}
    init(encoder: EncoderBase, container: EncoderUnkeyedContainerType, nestedPath: [CodingKey])
    
    // methods
    
    /// The path of coding keys taken to get to this point in encoding.
    var codingPath: [CodingKey] {get}
    
    /// The number of elements encoded into the container.
    var count: Int {get}
    
    var currentKey: CodingKey {get}
    
    func encode<T>(_ value: T, with box: (T)throws->Any) throws
    
    // MARK: - UnkeyedEncodingContainer Methods
    mutating func encodeNil()             throws
    mutating func encode(_ value: Bool)   throws
    mutating func encode(_ value: Int)    throws
    mutating func encode(_ value: Int8)   throws
    mutating func encode(_ value: Int16)  throws
    mutating func encode(_ value: Int32)  throws
    mutating func encode(_ value: Int64)  throws
    mutating func encode(_ value: UInt)   throws
    mutating func encode(_ value: UInt8)  throws
    mutating func encode(_ value: UInt16) throws
    mutating func encode(_ value: UInt32) throws
    mutating func encode(_ value: UInt64) throws
    mutating func encode(_ value: String) throws
    mutating func encode(_ value: Float)  throws
    mutating func encode(_ value: Double) throws
    
    mutating func encode<T : Encodable>(_ value: T) throws
    
    func createKeyedContainer<T: EncoderKeyedContainer, NestedKey>(_: T.Type) -> KeyedEncodingContainer<NestedKey> where T.Key == NestedKey
    
    //public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
    //
    //    return self.createKeyedContainer({ EncoderKeyedContainer }<NestedKey>.self)
    //}
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer
    
    mutating func superEncoder() -> Encoder
}

public extension EncoderUnkeyedContainer {
    
    /// The path of coding keys taken to get to this point in encoding.
    public var codingPath: [CodingKey] {
        return self.encoder.codingPath + self.nestedPath
    }
    
    /// The number of elements encoded into the container.
    public var count: Int {
        return self.container.count
    }
    
    public var currentKey: CodingKey {
        return "index: \(self.count)"
    }
    
    public func encode<T>(_ value: T, with box: (T)throws->Any) throws {
        
        do {
            try self.container.add(box(value))
            
        } catch {
            throw self.encoder.error(error, with: value, atPath: self.codingPath + [self.currentKey])
        }
    }
    
    // MARK: - UnkeyedEncodingContainer Methods
    public mutating func encodeNil()             throws { try self.encode(()   , with: self.encoder.box(_:)) }
    public mutating func encode(_ value: Bool)   throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: Int)    throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: Int8)   throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: Int16)  throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: Int32)  throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: Int64)  throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: UInt)   throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: UInt8)  throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: UInt16) throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: UInt32) throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: UInt64) throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: String) throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: Float)  throws { try self.encode(value, with: self.encoder.box(_:)) }
    public mutating func encode(_ value: Double) throws { try self.encode(value, with: self.encoder.box(_:)) }
    
    // remember to set key to encoder.key before calling encoder.reencode(Encodable) after the initial container was added, or the encoder won't know that a value has been added with a codingPath.
    public mutating func encode<T : Encodable>(_ value: T) throws { self.encoder.key = self.currentKey ; try encode(value as Encodable, with: encoder.box(_:)) }
    
    public func createKeyedContainer<T: EncoderKeyedContainer, NestedKey>(_: T.Type) -> KeyedEncodingContainer<NestedKey> where T.Key == NestedKey {
        
        let container = self.encoder.keyedContainerContainerType.init()
        self.container.add(container)
        
        return KeyedEncodingContainer(T.init(encoder: self.encoder, container: container, nestedPath: self.nestedPath + [self.currentKey]))
    }
    
    //public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
    //
    //    return self.createKeyedContainer({ EncoderKeyedContainer }<NestedKey>.self)
    //}
    
    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        
        let container = self.encoder.unkeyedContainerContainerType.init()
        self.container.add(container)
        
        return Self.init(encoder: self.encoder, container: container, nestedPath: self.nestedPath + [self.currentKey])
    }

    public mutating func superEncoder() -> Encoder {

        defer { self.container.add("placeholder") }

        return self.encoder.referenceType.init(encoder: self.encoder, reference: .unkeyed(self.container, index: self.count), previousPath: self.codingPath + ["super (\(self.currentKey))"])
    }
}

public enum EncoderReferenceValue {
    case keyed(EncoderKeyedContainerType, key: CodingKey)
    case unkeyed(EncoderUnkeyedContainerType, index: Int)
}

public protocol EncoderReference : EncoderBase {
    
    // required methods
    
    var reference: EncoderReferenceValue {get set}
    var previousPath: [CodingKey] {get set}
    
    var usesStringValue: Bool {get}
    
    // previousPath will not be appended if codingPath is not overridden when subclassed
    var codingPath: [CodingKey] {get}
    
    // var codingPath: [CodingKey] {
    //     return _codingPath
    // }
    
    // super will not be returned if willDeinit() is not called or implemented
    //deinit {
    //    willDeinit()
    //}
    
    // new methods
    
    init(encoder: EncoderBase, reference: EncoderReferenceValue, previousPath: [CodingKey])
    
    /// Finalizes `self` by writing the contents of our storage to the reference's storage.
    func willDeinit()
    
}

extension EncoderReference {
    
    public init(encoder: EncoderBase, reference: EncoderReferenceValue, previousPath: [CodingKey]) {
        
        self.init(untypedOptions: encoder.untypedOptions, userInfo: encoder.userInfo)
        
        self.previousPath = previousPath
        self.reference = reference
    }
    
    public var _codingPath: [CodingKey] {
        return self.previousPath + self.storage.flatMap { $0.key }
    }
    
    // Finalizes `self` by writing the contents of our storage to the reference's storage.
    public func willDeinit() {
        
        guard self.storage.count > 0 else { return }
        precondition(self.storage.count < 2, "Referencing encoder deallocated with multiple containers on stack.")
        
        let encoded = self.storage.removeLast().value
        
        switch self.reference {
            
        case .unkeyed(let container, index: let index):
            
            container.replaceObject(at: index, with: encoded)
            
        case .keyed(let container, key: let key):
            
            if self.usesStringValue {

                container[key.stringValue] = encoded
                
            } else {
                
                precondition(key.intValue != nil, "Tried to get \(key).intValue, but found nil.")

                container[key.intValue!] = encoded
            }
        }
    }
}
