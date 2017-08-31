//
//  Encoder2.swift
//  SimplifiedCoder
//
//  Created by Brendan Henderson on 8/23/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import Foundation

/// a TopLevelEncoder calls an encoder and verifies the encoded data before serializing
/// this is the API that the user calls
/// a TopLevelEncoder is not an encoder.
protocol TopLevelEncoder {
    
    func encode(_ value: Encodable) throws -> Data
    
    func encode(asValue value: Encodable) throws -> Any
}


extension JSONEncoder {
    fileprivate typealias _Options = (
        dateEncodingStrategy: DateEncodingStrategy,
        dataEncodingStrategy: DataEncodingStrategy,
        nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy,
        userInfo: [CodingUserInfoKey : Any]
    )
}

// MARK: - EncoderBase
protocol EncoderBase: class, Encoder, SingleValueEncodingContainer {
    // MARK: Properties
    /// The encoder's storage.
    var storage: [(key: CodingKey?, value: Any)] {get set}
    
    associatedtype KeyedContainer: EncoderKeyedContainer
    associatedtype UnkeyedContainer: EncoderUnkeyedContainer
    associatedtype Options
    
    /// Options set on the top-level encoder.
    var options: Options {get}
    
    /// Contextual user-provided information for use during encoding.
    var userInfo: [CodingUserInfoKey : Any] {get}
    
    // MARK: - Initialization
    /// Initializes `self` with the given top-level encoder options.
    init(options: Options, userInfo: [CodingUserInfoKey : Any])
    
    var key: CodingKey? {get set}
}

extension EncoderBase {
    
    /// The path to the current point in encoding.
    public var codingPath: [CodingKey] {
        return storage.flatMap { $0.key }
    }
    
    var canEncodeNewValue: Bool {
        return key != nil || self.storage.count == 0
    }
    
    func removeKey() -> CodingKey? {
        defer { self.key = nil }
        return self.key
    }
    
    func set(_ encoded: Any) {
        
        let key = self.removeKey()
        
        guard self.canEncodeNewValue else {
            
            let v = storage.last!.value
            let first = "\(v) of type: \(type(of: v))"
            let second = "\(encoded) of type: \(type(of: encoded))"
            
            fatalError("Tried to set a second value when previously already encoded at path: \(codingPath).  encoded: \(first) tried to set: \(second)")
        }
        
        self.storage.append((key, encoded))
    }
    
    func encode<T>(_ value: T, with box: (T)throws->Any) throws {
        
        do {
            try set(box(value))
            
        } catch let error as EncodeError {
            throw error
        } catch {
            throw EncodeError.encodeError(error, atPath: self.codingPath)
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
    
    func box(_ value: Void  ) throws -> Any{return NSNull()}
    func box(_ value: Bool  ) throws -> Any { return value }
    func box(_ value: Int   ) throws -> Any { return value }
    func box(_ value: Int8  ) throws -> Any { return value }
    func box(_ value: Int16 ) throws -> Any { return value }
    func box(_ value: Int32 ) throws -> Any { return value }
    func box(_ value: Int64 ) throws -> Any { return value }
    func box(_ value: UInt  ) throws -> Any { return value }
    func box(_ value: UInt8 ) throws -> Any { return value }
    func box(_ value: UInt16) throws -> Any { return value }
    func box(_ value: UInt32) throws -> Any { return value }
    func box(_ value: UInt64) throws -> Any { return value }
    func box(_ value: Float ) throws -> Any { return value }
    func box(_ value: Double) throws -> Any { return value }
    func box(_ value: String) throws -> Any { return value }
    
    func box(_ value: Encodable) throws -> Any {
        
        return try reencode(value)
        
        //        switch value {
        //        case is Date: return try box(value as Date)
        //        case is URL: return try box(value as URL)
        //        default: return try reencode(value)
        //        }
    }
    
    func reencode(_ value: Encodable) throws -> Any {
        
        let count = self.storage.count
        
        try value.encode(to: self)
        
        // The top container should be a new container.
        guard self.storage.count > count else {
            fatalError("\(type(of: value)) did not encode any values.")
        }
        
        return self.storage.removeLast().value
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
}

extension EncoderBase where Self.KeyedContainer.Base == Self {
    // MARK: - Encoder Methods
    func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        // If an existing keyed container was already requested, return that one.
        let container: NSMutableDictionary

        if self.canEncodeNewValue {

            container = NSMutableDictionary()

            set(container)

        } else {
            // could just crash here, but checks if the last encoded container is the same type and returns that.

            if let _container = self.storage.last!.value as? NSMutableDictionary {
                container = _container
            } else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
        }
        
        return KeyedContainer.initSelf(encoder: self, container: container, nestedPath: [], keyedBy: Key.self)
    }
}

extension EncoderBase where Self.UnkeyedContainer.Base == Self {
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        
        let container: NSMutableArray

        if self.canEncodeNewValue {

            container = NSMutableArray()

            set(container)

        } else {
            // could just crash here, but checks if the last encoded container is the same type and returns that.
            
            if let _container = self.storage.last!.value as? NSMutableArray {
                container = _container
            } else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }
        }

        return UnkeyedContainer(encoder: self, container: container, nestedPath: [])
    }

}

// MARK: - Encoding Containers
protocol EncoderKeyedContainer: KeyedEncodingContainerProtocol {
    
    associatedtype UnkeyedContainer: EncoderUnkeyedContainer
    associatedtype Reference: EncoderReference
    associatedtype Base: EncoderBase
    
    // MARK: Properties
    var encoder: Base {get}
    var container: NSMutableDictionary {get}
    var nestedPath: [CodingKey] {get}
    
    static var usesStringValue: Bool {get}
    
    // MARK: - Initialization
    /// Initializes `self` with the given references.
    init(encoder: Base, container: NSMutableDictionary, nestedPath: [CodingKey])
    
    static func initSelf<Key>(encoder: Base, container: NSMutableDictionary, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedEncodingContainer<Key>
}

extension EncoderKeyedContainer {
    
    public var codingPath: [CodingKey] {
        return encoder.codingPath + nestedPath
    }
    
    func _key(from key: CodingKey) -> Any {
        
        if Self.usesStringValue {
            return key.stringValue
        } else {
            guard key.intValue != nil else { fatalError("Tried to get \(key).intValue, but found nil.") }
            return key.intValue!
        }
    }
    
    func encode<T>(_ value: T, with box: (T)throws->Any, forKey key: Key) throws {
        
        do {
            try self.container[_key(from: key)] = box(value)
            
        } catch let error as EncodeError {
            throw error
        } catch {
            throw EncodeError.encodeError(error, atPath: self.codingPath + [key])
        }
    }
    
    // MARK: - KeyedEncodingContainerProtocol Methods
    public mutating func encodeNil(              forKey key: Key) throws { try encode(()   , with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Bool  , forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int   , forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int8  , forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int16 , forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int32 , forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int64 , forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt  , forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt8 , forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt16, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt32, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt64, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: String, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Float , forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Double, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    
    public mutating func encode<T : Encodable>(_ value: T, forKey key: Key) throws { try encode(value as Encodable, with: encoder.box(_:), forKey: key) }
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        
        let container = NSMutableDictionary()
        self.container[_key(from: key)] = container
        
        return Self.initSelf(encoder: self.encoder, container: container, nestedPath: self.nestedPath + [key], keyedBy: NestedKey.self)
    }
}

extension EncoderKeyedContainer where Self.UnkeyedContainer.Base == Self.Base {
    

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {

        let container = NSMutableArray()
        self.container[_key(from: key)] = container

        return UnkeyedContainer(encoder: self.encoder, container: container, nestedPath: self.nestedPath + [key])
    }
}

extension EncoderKeyedContainer where Self.Reference.Super == Self.Base {

    mutating func superEncoder() -> Encoder {
        return Reference(encoder: self.encoder, reference: .keyed(self.container, key: "super"), previousPath: self.codingPath) // [key] is added from reference
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        return Reference(encoder: self.encoder, reference: .keyed(self.container, key: key), previousPath: self.codingPath)
    }
}

protocol EncoderUnkeyedContainer : UnkeyedEncodingContainer {
    // MARK: Properties
    associatedtype KeyedContainer: EncoderKeyedContainer
    associatedtype Reference: EncoderReference
    associatedtype Base: EncoderBase
    
    var encoder: Base {get}
    var container: NSMutableArray {get}
    var nestedPath: [CodingKey] {get}
    
    // MARK: - Initialization
    /// Initializes `self` with the given references.
    init(encoder: Base, container: NSMutableArray, nestedPath: [CodingKey])
}

extension EncoderUnkeyedContainer {
    
    /// The path of coding keys taken to get to this point in encoding.
    public var codingPath: [CodingKey] {
        return encoder.codingPath + nestedPath
    }
    
    /// The number of elements encoded into the container.
    public var count: Int {
        return self.container.count
    }
    
    func encode<T>(_ value: T, with box: (T)throws->Any) throws {
        
        do {
            try self.container.add(box(value))
            
        } catch let error as EncodeError {
            throw error
        } catch {
            throw EncodeError.encodeError(error, atPath: self.codingPath + ["index \(count)"])
        }
    }
    
    // MARK: - UnkeyedEncodingContainer Methods
    public mutating func encodeNil()             throws { try encode(()   , with: encoder.box(_:)) }
    public mutating func encode(_ value: Bool)   throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: Int)    throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: Int8)   throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: Int16)  throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: Int32)  throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: Int64)  throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: UInt)   throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: UInt8)  throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: UInt16) throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: UInt32) throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: UInt64) throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: String) throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: Float)  throws { try encode(value, with: encoder.box(_:)) }
    public mutating func encode(_ value: Double) throws { try encode(value, with: encoder.box(_:)) }
    
    public mutating func encode<T : Encodable>(_ value: T) throws { try encode(value as Encodable, with: encoder.box(_:)) }
    
    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        
        let container = NSMutableArray()
        self.container.add(container)
        
        return Self(encoder: self.encoder, container: container, nestedPath: self.nestedPath + ["index \(count)"])
    }
}

extension EncoderUnkeyedContainer where Self.KeyedContainer.Base == Self.Base {
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {

        let container = NSMutableDictionary()
        self.container.add(container)
        
        return KeyedContainer.initSelf(encoder: self.encoder, container: container, nestedPath: self.nestedPath + ["index \(count)"], keyedBy: NestedKey.self)
    }
}

extension EncoderUnkeyedContainer where Self.Reference.Super == Self.Base {
    
    mutating func superEncoder() -> Encoder {
        
        defer { container.add("placeholder") }
        
        return Reference(encoder: self.encoder, reference: .unkeyed(self.container, index: container.count), previousPath: self.codingPath) // ["index \(count)"] is added from reference
    }
}

enum EncoderReferenceValue {
    case keyed(NSMutableDictionary, key: CodingKey)
    case unkeyed(NSMutableArray, index: Int)
}

// MARK: - EncoderReference
/// EncoderReference is a special subclass of EncoderBase which has its own storage, but references the contents of a different encoder.
/// It's used in superEncoder(), which returns a new encoder for encoding a superclass -- the lifetime of the encoder should not escape the scope it's created in, but it doesn't necessarily know when it's done being used (to write to the original container).
protocol EncoderReference : EncoderBase {
    // MARK: Reference types.
    
    var reference: EncoderReferenceValue {get set}
    var previousPath: [CodingKey] {get set}
    
    associatedtype Super: EncoderBase
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given array container in the given encoder.
    init(encoder: Super, reference: EncoderReferenceValue, previousPath: [CodingKey])
    
    
    // MARK: - Deinitialization
//    deinit {
//        willDeinit()
//    }
}

extension EncoderReference {
    
    var codingPath: [CodingKey] {
        return previousPath + storage.flatMap { $0.key }
    }
    
    var superKey: CodingKey {
        switch reference {
        case .keyed(_, key: let key): return key
        case .unkeyed(_, index: let index): return "index \(index)"
        }
    }
    
    func _key(from key: CodingKey) -> Any {
        
        if Self.KeyedContainer.usesStringValue {
            return key.stringValue
        } else {
            guard key.intValue != nil else { fatalError("Tried to get \(key).intValue, but found nil.") }
            return key.intValue!
        }
    }
    
    // not supported (would change expected behaviour), but it would be nice.
    //    override func set(_ encoded: Any) {
    //
    //        if self.storage.count > 0 {
    //
    //            guard let key = self.removeKey() else {
    //                super.set(encoded)
    //                return
    //            }
    //
    //            switch self.reference {
    //            case .keyed(let container, key: _): container[_key(from: key)] = encoded
    //            case .unkeyed(let container, index: _): container.add(encoded)
    //            }
    //
    //            super.set(encoded)
    //
    //        } else {
    //            super.set(encoded)
    //        }
    //    }
    
    // Finalizes `self` by writing the contents of our storage to the reference's storage.
    func willDeinit() {
        
        precondition(storage.count > 0, "Referencing encoder deallocated without encoding any values")
        precondition(storage.count < 2, "Referencing encoder deallocated with multiple containers on stack.")
        
        let value = self.storage.removeLast()
        
        switch self.reference {
        case .unkeyed(let array, index: let index):
            array.replaceObject(at: index, with: value)
            
        case .keyed(let dictionary, key: let key):
            dictionary[_key(from: key)] = dictionary[_key(from: key)] ?? value
        }
    }
}

extension EncoderReference where Super.Options == Self.Options {
    
    init(encoder: Super, reference: EncoderReferenceValue, previousPath: [CodingKey]) {
        
        self.init(options: encoder.options, userInfo: encoder.userInfo)
        
        self.previousPath = previousPath
        self.reference = reference
        self.key = superKey
    }
}

/// a wrapping error to associate an unknown error on encode with a codingPath
enum EncodeError: Error {
    
    case encodeError(Error, atPath: [CodingKey])
    
    var error: Error {
        switch self {
        case .encodeError(let error, atPath: _): return error
        }
    }
    
    var codingPath: [CodingKey] {
        switch self {
        case .encodeError(_, atPath: let codingPath): return codingPath
        }
    }
}

