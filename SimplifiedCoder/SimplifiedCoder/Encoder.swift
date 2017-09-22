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
    func encode(value: Encodable) throws -> Any
}

// MARK: - EncoderBase

public protocol TypedEncoderBase: EncoderBase {
    
    associatedtype Options
    
    var options: Options {get}
    
    init(codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any], reference: EncoderReference?)
}

public extension TypedEncoderBase {
    
    var untypedOptions: Any {
        return self.options
    }
    
    init(codingPath: [CodingKey], untypedOptions: Any, userInfo: [CodingUserInfoKey : Any], reference: EncoderReference?) {
        if let options = untypedOptions as? Self.Options {
            self.init(codingPath: codingPath, options: options, userInfo: userInfo, reference: reference)
        } else {
            fatalError("Failed to cast to \(Self.Options.self): \(untypedOptions)")
        }
    }
    
    public static func start(with value: Encodable, options: Options, userInfo: [CodingUserInfoKey: Any]) throws -> Any {
        return try Self.init(codingPath: [], options: options, userInfo: userInfo, reference: nil).start(with: value)
    }
}

fileprivate var null = NSNull()

public enum EncoderReference {
    case keyed(EncoderKeyedContainerContainer, key: AnyHashable)
    case unkeyed(EncoderUnkeyedContainerContainer, index: Int)
}

public protocol EncoderBase: class, Encoder, SingleValueEncodingContainer {
    
    // references
    
    static var keyedContainerContainerType: EncoderKeyedContainerContainer.Type {get}
    static var unkeyedContainerContainerType: EncoderUnkeyedContainerContainer.Type {get}
    static var unkeyedContainerType: EncoderUnkeyedContainer.Type {get}
    
    // required methods
    
    //deinit {
    //    self.willDeinit()
    //}
    
    var codingPath: [CodingKey] {get set}
    var untypedOptions: Any {get}
    var userInfo: [CodingUserInfoKey : Any] {get}
    var reference: EncoderReference? {get}
    
    init(codingPath: [CodingKey], untypedOptions: Any, userInfo: [CodingUserInfoKey : Any], reference: EncoderReference?)
    
    var storage: [Any] {get set} // = []
    var canEncodeNewValue: Bool {get set} // = true
    
    // methods
    
    func start(with value: Encodable) throws -> Any
    
    func boxNil(         at codingPath: [CodingKey]) throws -> CanBeNil
    func box(_ value: Bool  , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: Int   , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: Int8  , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: Int16 , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: Int32 , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: Int64 , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: UInt  , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: UInt8 , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: UInt16, at codingPath: [CodingKey]) throws -> Any
    func box(_ value: UInt32, at codingPath: [CodingKey]) throws -> Any
    func box(_ value: UInt64, at codingPath: [CodingKey]) throws -> Any
    func box(_ value: Float , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: Double, at codingPath: [CodingKey]) throws -> Any
    func box(_ value: String, at codingPath: [CodingKey]) throws -> Any
    func box(_ value: Encodable, at codingPath: [CodingKey]) throws -> Any
    
    // TODO: add methods
}

public extension EncoderBase {
    
    public static var keyedContainerContainerType: EncoderKeyedContainerContainer.Type {
        return NSMutableDictionary.self
    }
    
    public static var unkeyedContainerContainerType: EncoderUnkeyedContainerContainer.Type {
        return NSMutableArray.self
    }
    
    public func start(with value: Encodable) throws -> Any {
        return try self.box(value, at: [])
    }
    
    public func set(_ encoded: Any) {
        
        guard self.canEncodeNewValue else {
            
            fatalError("Tried to encode a second container when previously already encoded at path: \(self.codingPath).  encoded: \(type(of: self.storage.last ?? null)) tried to set: \(type(of: encoded))")
        }
        
        self.storage.append(encoded)
        
        self.canEncodeNewValue = false
    }
    
    public func encodeNil(            ) throws { self.set(try self.boxNil(    at: self.codingPath)) }
    public func encode(_ value: Bool  ) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: Int   ) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: Int8  ) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: Int16 ) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: Int32 ) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: Int64 ) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: UInt  ) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: UInt8 ) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: UInt16) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: UInt32) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: UInt64) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: String) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: Float ) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode(_ value: Double) throws { self.set(try self.box(value, at: self.codingPath)) }
    public func encode<T: Encodable>(_ value: T) throws { self.set(try self.box(value, at: self.codingPath)) }
    
    // MARK: encoder.box(_:)
    
    public func boxNil(         at codingPath: [CodingKey]) throws -> CanBeNil { return null  }
    public func box(_ value: Bool  , at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: Int   , at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: Int8  , at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: Int16 , at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: Int32 , at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: Int64 , at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: UInt  , at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: UInt8 , at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: UInt16, at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: UInt32, at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: UInt64, at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: Float , at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: Double, at codingPath: [CodingKey]) throws -> Any { return value }
    public func box(_ value: String, at codingPath: [CodingKey]) throws -> Any { return value }
    
    /// a routing hub to the boxing methods (nothing is encoded directly in this method)
    public func box(_ value: Encodable, at codingPath: [CodingKey]) throws -> Any {
        
        return try self.reencode(value, at: codingPath)
        
        //switch value {
        //case is Date: return try box(value as! Date, at: codingPath)
        //case is URL: return try box(value as! URL, at: codingPath)
        //default: return try reencode(value, at: codingPath)
        //}
    }
    
    public func reencode(_ value: Encodable, at codingPath: [CodingKey]) throws -> Any {
        
        return try self.reencode(type(of: value), at: codingPath, { try value.encode(to: self) })
    }
    
    public func reencode(_ type: Any.Type, at codingPath: [CodingKey], _ encodingClosure: ()throws->()) throws -> Any {
        
        let previousPath = self.codingPath
        self.codingPath = codingPath
        
        let depth = self.storage.count
        
        self.canEncodeNewValue = true
        try encodingClosure()
        
        self.codingPath = previousPath
        
        let storageCount = self.storage.count
        
        // The top container should be a new container.
        guard storageCount > depth else {
            fatalError("\(type) did not encode a container.")
        }
        
        guard storageCount == depth + 1 else {
            fatalError("\(type) encoded multiple containers (this is an encoder error, (use .canEncodeNewValue in set(Any)))")
        }
        
        return self.storage.removeLast()
    }
    
    public func createKeyedContainer<T: EncoderKeyedContainer, Key>(_: T.Type) -> KeyedEncodingContainer<Key> {
        
        // If an existing keyed container was already requested, return that one.
        let container: EncoderKeyedContainerContainer
        
        if self.canEncodeNewValue {
            
            container = Self.keyedContainerContainerType.init()
            
            self.set(container)
            
        } else {
            
            if let _container = (self.storage.last ?? null) as? EncoderKeyedContainerContainer {
                container = _container
            } else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
        }
        
        return T.initSelf(
            encoder: self,
            container: container,
            nestedPath: [],
            keyedBy: Key.self
        )
    }
    
    // public func keyedContainer<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
    //     return self.createKeyedContainer({ EncoderKeyedContainer }<Key>.self)
    // }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        
        let container: EncoderUnkeyedContainerContainer
        
        if self.canEncodeNewValue {
            
            container = Self.unkeyedContainerContainerType.init()
            
            self.set(container)
            
        } else {
            
            if let _container = (self.storage.last ?? null) as? EncoderUnkeyedContainerContainer {
                container = _container
            } else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at path: \(self.codingPath)")
            }
        }
        
        return Self.unkeyedContainerType.init(
            encoder: self,
            container: container,
            nestedPath: []
        )
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
    
    // Finalizes `self` by writing the contents of our storage to the reference's storage.
    public func willDeinit() {
        
        guard let reference = self.reference, self.storage.count > 0 else {
            return
        }
        
        precondition(self.storage.count == 1, "Referencing encoder deallocated with multiple containers on stack.")

        let encoded = self.storage.removeLast()

        switch reference {

        case .unkeyed(let container, index: let index):

            container.replaceObject(at: index, with: encoded)

        case .keyed(let container, key: let key):
            
            container.set(toStorage: encoded, forKey: key)
        }
    }
}

/// has to be a class to set to an already set object
public protocol EncoderKeyedContainerContainer: class {
    
    func set(toStorage value: Any, forKey key: AnyHashable)
    
    init()
}

extension NSMutableDictionary: EncoderKeyedContainerContainer {
    
    public func set(toStorage value: Any, forKey key: AnyHashable) {
        self[key] = value
    }
}

// MARK: - Encoding Containers
public protocol EncoderKeyedContainer: KeyedEncodingContainerProtocol {
    
    // required methods
    
    var encoder: EncoderBase {get}
    var container: EncoderKeyedContainerContainer {get}
    var nestedPath: [CodingKey] {get}
    init(encoder: EncoderBase, container: EncoderKeyedContainerContainer, nestedPath: [CodingKey])
    
    /// initSelf is longer, but it's easier than the custom nestedKeyedContainer function
    static func initSelf<Key>(encoder: EncoderBase, container: EncoderKeyedContainerContainer, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedEncodingContainer<Key>
    
    /// whether to set to .container using the CodingKey's .stringValue or .intValue!
    var usesStringValue: Bool {get} // = true/false
    
    // methods
    
    // TODO: add methods
}

public extension EncoderKeyedContainer {
    
    public var codingPath: [CodingKey] {
        return self.encoder.codingPath + self.nestedPath
    }
    
    func currentPath(_ key: CodingKey) -> [CodingKey] {
        return self.codingPath + [key]
    }
    
    public func _key(from key: CodingKey) -> AnyHashable {
        
        if self.usesStringValue {
            
            return key.stringValue
            
        } else {
            
            precondition(key.intValue != nil, "Tried to get \(key) of type: \(type(of: key)) .intValue, but found nil.")
            
            return key.intValue!
        }
    }
    
    public func set(_ encoded: Any, forKey key: CodingKey) {
        
        self.container.set(toStorage: encoded, forKey: self._key(from: key))
    }
    
    // MARK: - KeyedEncodingContainerProtocol Methods
    public mutating func encodeNil(              forKey key: Key) throws { try self.set(self.encoder.boxNil(    at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: Bool  , forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: Int   , forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: Int8  , forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: Int16 , forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: Int32 , forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: Int64 , forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: UInt  , forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: UInt8 , forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: UInt16, forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: UInt32, forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: UInt64, forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: String, forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: Float , forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode(_ value: Double, forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    public mutating func encode<T : Encodable>(_ value: T, forKey key: Key) throws { try self.set(self.encoder.box(value, at: self.currentPath(key)), forKey: key) }
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        
        let container = type(of: self.container).init()
        
        self.set(container, forKey: key)
            
        return Self.initSelf(
            encoder: self.encoder,
            container: container,
            nestedPath: self.nestedPath + [key],
            keyedBy: NestedKey.self
        )
    }
    
    public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {

        let container = type(of: self.encoder).unkeyedContainerContainerType.init()

        self.set(container, forKey: key)

        return type(of: self.encoder).unkeyedContainerType.init(
            encoder: self.encoder,
            container: container,
            nestedPath: self.nestedPath + [key]
        )
    }
    
    private func _superEncoder(forKey key: CodingKey) -> Encoder {
        
        return type(of: self.encoder).init(
            codingPath: self.codingPath + [key],
            untypedOptions: self.encoder.untypedOptions,
            userInfo: self.encoder.userInfo,
            reference: .keyed(self.container, key: self._key(from: key))
        )
    }

    public mutating func superEncoder() -> Encoder {
        return self._superEncoder(forKey: "super")
    }

    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return self._superEncoder(forKey: key)
    }
}

public protocol EncoderUnkeyedContainerContainer: class {
    
    init()
    var count: Int {get}
    func add(_ value: Any)
    func replaceObject(at index: Int, with object: Any)
}

extension NSMutableArray: EncoderUnkeyedContainerContainer {}

public protocol EncoderUnkeyedContainer : UnkeyedEncodingContainer {
    
    // required methods
    
    var encoder: EncoderBase {get}
    var container: EncoderUnkeyedContainerContainer {get}
    var nestedPath: [CodingKey] {get}
    
    init(encoder: EncoderBase, container: EncoderUnkeyedContainerContainer, nestedPath: [CodingKey])
    
    // methods
    
    // TODO: Add methods before submitting
}

public extension EncoderUnkeyedContainer {
    
    /// The path of coding keys taken to get to this point in encoding.
    public var codingPath: [CodingKey] {
        return self.encoder.codingPath + self.nestedPath
    }
    
    public var currentPath: [CodingKey] {
        return self.codingPath + [self.currentKey]
    }
    
    /// The number of elements encoded into the container.
    public var count: Int {
        return self.container.count
    }
    
    public var currentIndex: Int {
        return self.count
    }
    
    public var currentKey: CodingKey {
        return "Index \(self.currentIndex)"
    }
    
    public func set(_ encoded: Any) {
        
        self.container.add(encoded)
    }
    
    // MARK: - UnkeyedEncodingContainer Methods
    public mutating func encodeNil(            ) throws { self.set(try self.encoder.boxNil(    at: self.currentPath)) }
    public mutating func encode(_ value: Bool  ) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: Int   ) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: Int8  ) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: Int16 ) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: Int32 ) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: Int64 ) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: UInt  ) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: UInt8 ) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: UInt16) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: UInt32) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: UInt64) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: String) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: Float ) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: Double) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode<T: Encodable>(_ value: T) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    
    public func createKeyedContainer<T: EncoderKeyedContainer, NestedKey>(_: T.Type) -> KeyedEncodingContainer<NestedKey> {
        
        let container = type(of: self.encoder).keyedContainerContainerType.init()
        
        self.container.add(container)
        
        return T.initSelf(
            encoder: self.encoder,
            container: container,
            nestedPath: self.nestedPath + [self.currentKey],
            keyedBy: NestedKey.self
        )
    }
    
    //public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
    //
    //    return self.createKeyedContainer({ EncoderKeyedContainer }<NestedKey>.self)
    //}
    
    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        
        let container = type(of: self.container).init()
        
        self.container.add(container)
        
        return Self.init(
            encoder: self.encoder,
            container: container,
            nestedPath: self.nestedPath + [self.currentKey]
        )
    }

    public mutating func superEncoder() -> Encoder {

        defer { self.container.add("placeholder") }
        
        return type(of: self.encoder).init(
            codingPath: self.currentPath,
            untypedOptions: self.encoder.untypedOptions,
            userInfo: self.encoder.userInfo,
            reference: .unkeyed(self.container, index: self.currentIndex)
        )
    }
}

