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
fileprivate class EncoderBase : Encoder {
    // MARK: Properties
    /// The encoder's storage.
    fileprivate var storage: [(key: CodingKey?, value: Any)] = []
    
    fileprivate typealias Options = JSONEncoder._Options
    
    /// Options set on the top-level encoder.
    fileprivate let options: Options
    
    /// The path to the current point in encoding.
    public var codingPath: [CodingKey] {
        return storage.flatMap { $0.key }
    }
    
    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any]
    
    // MARK: - Initialization
    /// Initializes `self` with the given top-level encoder options.
    fileprivate init(options: Options, userInfo: [CodingUserInfoKey : Any]) {
        self.options = options
        self.userInfo = userInfo
    }
    
    var key: CodingKey? = nil
    
    /// Returns whether a new element can be encoded at this coding path.
    ///
    /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
    fileprivate var canEncodeNewValue: Bool {
        // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
        // At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
        // If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
        //
        // This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
        // Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
        return self.storage.count == self.codingPath.count
    }
    
    // MARK: - Encoder Methods
    public func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        // If an existing keyed container was already requested, return that one.
        let topContainer: NSMutableDictionary
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = NSMutableDictionary()
            
            self.storage.append((key, topContainer))
        } else {
            guard let container = self.storage.last?.value as? NSMutableDictionary else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
            
            topContainer = container
        }
        
        let container = EncoderKeyedContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer, nestedPath: [])
        return KeyedEncodingContainer(container)
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        // If an existing unkeyed container was already requested, return that one.
        let topContainer: NSMutableArray
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            
            topContainer = NSMutableArray()
            
            self.storage.append((key, topContainer))
        } else {
            guard let container = self.storage.last?.value as? NSMutableArray else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }
            
            topContainer = container
        }
        
        return EncoderUnkeyedContainer(encoder: self, container: topContainer, nestedPath: [])
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
}

// MARK: - Encoding Containers
fileprivate struct EncoderKeyedContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    typealias Key = K
    
    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: EncoderBase
    
    /// A reference to the container we're writing to.
    private let container: NSMutableDictionary
    
    /// The path of coding keys taken to get to this point in encoding.
    public var codingPath: [CodingKey] {
        return encoder.codingPath + nestedPath
    }
    
    var nestedPath: [CodingKey]
    
    static var usesStringValue: Bool {
        return true
    }
    
    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: EncoderBase, codingPath: [CodingKey], wrapping container: NSMutableDictionary, nestedPath: [CodingKey]) {
        
        self.nestedPath = nestedPath
        self.encoder = encoder
        self.container = container
    }
    
    func _key(from key: CodingKey) -> Any {
        
        if EncoderKeyedContainer.usesStringValue {
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
    public mutating func encodeNil(forKey key: Key)               throws { try encode(()   , with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Bool, forKey key: Key)   throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int, forKey key: Key)    throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int8, forKey key: Key)   throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int16, forKey key: Key)  throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int32, forKey key: Key)  throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Int64, forKey key: Key)  throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt, forKey key: Key)   throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt8, forKey key: Key)  throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt16, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt32, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: UInt64, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: String, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Float, forKey key: Key)  throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode(_ value: Double, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    public mutating func encode<T : Encodable>(_ value: T, forKey key: Key) throws { try encode(value as Encodable, with: encoder.box(_:), forKey: key) }
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let dictionary = NSMutableDictionary()
        self.container[key.stringValue] = dictionary
        
        let container = EncoderKeyedContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary, nestedPath: self.nestedPath + [key])
        return KeyedEncodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let array = NSMutableArray()
        self.container[key.stringValue] = array
        
        return EncoderUnkeyedContainer(encoder: self.encoder, container: array, nestedPath: self.nestedPath + [key])
    }
    
    public mutating func superEncoder() -> Encoder {
        return EncoderReference(encoder: self.encoder, reference: .keyed(self.container, key: "super"))
    }
    
    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return EncoderReference(encoder: self.encoder, reference: .keyed(self.container, key: key))
    }
}

fileprivate struct EncoderUnkeyedContainer : UnkeyedEncodingContainer {
    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: EncoderBase
    
    /// A reference to the container we're writing to.
    private let container: NSMutableArray
    
    /// The path of coding keys taken to get to this point in encoding.
    public var codingPath: [CodingKey] {
        return encoder.codingPath + nestedPath
    }
    
    /// The number of elements encoded into the container.
    public var count: Int {
        return self.container.count
    }
    
    var nestedPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(encoder: EncoderBase, container: NSMutableArray, nestedPath: [CodingKey]) {
        
        self.nestedPath = nestedPath
        self.encoder = encoder
        self.container = container
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
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        
        let dictionary = NSMutableDictionary()
        self.container.add(dictionary)
        
        let container = EncoderKeyedContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary, nestedPath: self.nestedPath + ["index \(count)"])
        return KeyedEncodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        
        let array = NSMutableArray()
        self.container.add(array)
        
        return EncoderUnkeyedContainer(encoder: self.encoder, container: array, nestedPath: self.nestedPath + ["index \(count)"])
    }
    
    public mutating func superEncoder() -> Encoder {
        defer { container.add("placeholder") }
        return EncoderReference(encoder: self.encoder, reference: .unkeyed(self.container, index: container.count))
    }
}

extension EncoderBase : SingleValueEncodingContainer {
    
    func removeKey() -> CodingKey? {
        defer { self.key = nil }
        return self.key
    }
    
    func encode<T>(_ value: T, with box: (T)throws->Any) throws {
        
        do {
            let key = self.removeKey()
            
            guard key != nil || self.storage.count > 0 else {
                
                let v = storage.last!.value
                let first = "\(v) of type: \(type(of: v))"
                let second = "\(value) of type: \(T.self)"
                
                fatalError("Tried to encode a second value when previously already encoded at path: \(codingPath).  First: \(first) Second: \(second)")
            }
            
            try self.storage.append((key, box(value)))
            
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
}

// MARK: - Concrete Value Representations
extension EncoderBase {
    
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
}

enum EncoderReferenceValue {
    case keyed(NSMutableDictionary, key: CodingKey)
    case unkeyed(NSMutableArray, index: Int)
}

// MARK: - EncoderReference
/// EncoderReference is a special subclass of EncoderBase which has its own storage, but references the contents of a different encoder.
/// It's used in superEncoder(), which returns a new encoder for encoding a superclass -- the lifetime of the encoder should not escape the scope it's created in, but it doesn't necessarily know when it's done being used (to write to the original container).
fileprivate class EncoderReference : EncoderBase {
    // MARK: Reference types.
    
    /// The container reference itself.
    private let reference: EncoderReferenceValue
    
    override var codingPath: [CodingKey] {
        return previousPath + storage.flatMap { $0.key }
    }
    
    var previousPath: [CodingKey]
    
    var superKey: CodingKey {
        switch reference {
        case .keyed(_, key: let key): return key
        case .unkeyed(_, index: let index): return "index \(index)"
        }
    }
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given array container in the given encoder.
    fileprivate init(encoder: EncoderBase, reference: EncoderReferenceValue, previousPath: [CodingKey] = []) {
        
        self.previousPath = previousPath
        self.reference = reference
        
        super.init(options: encoder.options, userInfo: encoder.userInfo)
        
        self.key = superKey
    }
    
    typealias KeyedContainer = EncoderKeyedContainer<String>
    
    func _key(from key: CodingKey) -> Any {
        
        if KeyedContainer.usesStringValue {
            return key.stringValue
        } else {
            guard key.intValue != nil else { fatalError("Tried to get \(key).intValue, but found nil.") }
            return key.intValue!
        }
    }
    
    func willDeinit() {
        
        precondition(storage.count != 0, "Referencing encoder deallocated without encoding any values")
        precondition(storage.count <= 1, "Referencing encoder deallocated with multiple containers on stack.")
        
        let value = self.storage.removeLast()
        
        switch self.reference {
        case .unkeyed(let array, index: let index):
            array.replaceObject(at: index, with: value)
            
        case .keyed(let dictionary, key: let key):
            dictionary[_key(from: key)] = dictionary[_key(from: key)] ?? value
        }
    }
    
    // MARK: - Deinitialization
    // Finalizes `self` by writing the contents of our storage to the referenced encoder's storage.
    deinit {
        willDeinit()
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

