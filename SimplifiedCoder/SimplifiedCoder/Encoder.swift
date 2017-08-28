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
    func encode(  value: Encodable) throws -> Any
}

/// a type that can convert "box" values from an encoder
//protocol EncodeBoxing {
//
//    static func box(_ value: Void)   throws -> Any
//    static func box(_ value: Bool)   throws -> Any
//    static func box(_ value: Int)    throws -> Any
//    static func box(_ value: Int8)   throws -> Any
//    static func box(_ value: Int16)  throws -> Any
//    static func box(_ value: Int32)  throws -> Any
//    static func box(_ value: Int64)  throws -> Any
//    static func box(_ value: UInt)   throws -> Any
//    static func box(_ value: UInt8)  throws -> Any
//    static func box(_ value: UInt16) throws -> Any
//    static func box(_ value: UInt32) throws -> Any
//    static func box(_ value: UInt64) throws -> Any
//    static func box(_ value: Float)  throws -> Any
//    static func box(_ value: Double) throws -> Any
//    static func box(_ value: String) throws -> Any
//
//    // if the value cannot be boxed and needs to be encoded further, return Void
//    static func box(_ value: Encodable) throws -> Any
//}
//
//extension EncodeBoxing {
//}

extension String: CodingKey {
    
    public var stringValue: String {
        return self
    }
    
    public init(stringValue: String) {
        self = stringValue
    }
    
    public var intValue: Int? {
        return Int(self)
    }
    
    public init?(intValue: Int) {
        self = "\(intValue)"
    }
}

enum EncoderError: Error, CustomStringConvertible {
    
    var description: String {
        switch self {
        case .encoderError(let error, atPath: let path):
            return "Unable to encode value. Error: \(error) at path: \(path)"
        }
    }
    
    case encoderError(Error, atPath: [CodingKey])
}

protocol Base: class, Encoder, SingleValueEncodingContainer {
    
    associatedtype Options
    
    var options: Options {get}
    
    init(_ options: Options, userInfo: [CodingUserInfoKey : Any])
    
    // only the first key may be nil
    var storage: [(key: CodingKey?, value: Any)] {get set}
    
    var key: CodingKey? {get set}
    
    static var usesStringValue: Bool {get}
    
    associatedtype KeyedContainer
    associatedtype UnkeyedContainer
}

extension Base {
    
    var codingPath: [CodingKey] {
        
        return storage.flatMap {$0.key}
    }
    
    func set(_ key: CodingKey) -> Self {
        self.key = key
        return self
    }
    
    /// the current encoded value ?? try! Self.box(Void) if no value was encoded
    var encoded: Any? {
        
        return storage.first
    }
    
    func removeKey() -> CodingKey? {
        let key = self.key
        self.key = nil
        return key
    }
    
    func set(_ encoded: Any) {
        
        if let key = removeKey() {
            storage.append((key, encoded))
        } else if storage.count == 0 {
            // append self.key to allow Reference to add superKey instead
            storage.append((key, encoded))
        } else {
            fatalError("Tried to encode a second value when previously already encoded at path: \(codingPath).  First: \(storage.last!.value) Second: \(encoded)")
        }
    }

    func encodeAndSet<T>(_ value: T, with box: (T)throws->Any) throws {
        
        do {
            try set(box(value))
        } catch {
            throw EncoderError.encoderError(error, atPath: codingPath)
        }
    }
    
    static func box(_ value: Void  ) throws -> Any { return NSNull() }
    static func box(_ value: Bool  ) throws -> Any { return value }
    static func box(_ value: Int   ) throws -> Any { return value }
    static func box(_ value: Int8  ) throws -> Any { return value }
    static func box(_ value: Int16 ) throws -> Any { return value }
    static func box(_ value: Int32 ) throws -> Any { return value }
    static func box(_ value: Int64 ) throws -> Any { return value }
    static func box(_ value: UInt  ) throws -> Any { return value }
    static func box(_ value: UInt8 ) throws -> Any { return value }
    static func box(_ value: UInt16) throws -> Any { return value }
    static func box(_ value: UInt32) throws -> Any { return value }
    static func box(_ value: UInt64) throws -> Any { return value }
    static func box(_ value: Float ) throws -> Any { return value }
    static func box(_ value: Double) throws -> Any { return value }
    static func box(_ value: String) throws -> Any { return value }
    static func box(_ value: Encodable) throws -> Any { return () }
    
    func encodeNil()             throws { try encodeAndSet(()   , with: Self.box(_:)) }
    func encode(_ value: Bool  ) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: Int   ) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: Int8  ) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: Int16 ) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: Int32 ) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: Int64 ) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: UInt  ) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: UInt8 ) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: UInt16) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: UInt32) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: UInt64) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: Float ) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: Double) throws { try encodeAndSet(value, with: Self.box(_:)) }
    func encode(_ value: String) throws { try encodeAndSet(value, with: Self.box(_:)) }
    
    func encode<T: Encodable>(_ value: T) throws { try encode(value as Encodable) }
    
    func encode(_ value: Encodable) throws { try set(box(value)) }
    
    // because box Encodable may need to encode further, it is the only box that can't be on the type
    func box(_ value: Encodable) throws -> Any {
        
        do {
            
            let encoded = try box(value)
            
            if encoded is Void {
                
                let count = storage.count
                
                try value.encode(to: self)
                
                if storage.count == count {
                    fatalError("\(value) did not encode a value")
                    // TODO: find out if this matters: "return default container"
                    // return NSMutableDictionary()
                    
                } else {
                    
                    return storage.removeLast().value
                }
                
            } else {
                
                return encoded
            }
        
            // delegates EncoderError and catches others
        } catch EncoderError.encoderError(let error, atPath: let path) {
            throw EncoderError.encoderError(error, atPath: path)
        } catch {
            throw EncoderError.encoderError(error, atPath: codingPath)
        }
    }
    
    /// encodes a new keyed container or tries to unwrap encoded as a keyed container, then returns a new KeyedEncodingContainer encoding to the container
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {

        let container: NSMutableDictionary
        
        if key != nil || storage.count > 0 {
            container = NSMutableDictionary()
            set(container)
            
        } else {
            // already encoded a value, at least try to get the last encoded value as the value before causing a fatal error
            if let value = storage.last!.value as? NSMutableDictionary {
                container = value
            } else {
                fatalError("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
        }

        return 1 as! KeyedEncodingContainer<Key> // new keyed encoder referencing dictionary
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {

        let container: NSMutableArray
        
        if key != nil || storage.count > 0 {
            container = NSMutableArray()
            set(container)
            
        } else {
            
            if let value = storage.last!.value as? NSMutableArray {
                container = value
            } else {
                fatalError("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
        }

        return 1 as! UnkeyedEncodingContainer // new unkeyed encoder referencing array
    }

    func singleValueContainer() -> SingleValueEncodingContainer {

        return self
    }
}

enum ReferenceObject {
    case unkeyed(NSMutableArray, index: Int)
    case keyed(NSMutableDictionary, key: CodingKey)
}

protocol Reference: Base {
    
    var reference: ReferenceObject {get set}
    
    var previousPath: [CodingKey] {get set}
    
    static var usesStringValue: Bool {get set}
    
    associatedtype Super: Base
    
    // deinit {willDeinit()}
}

extension Reference {
    
    var superKey: CodingKey {
        switch reference {
        case .keyed(_, key: let key): return key
        case .unkeyed(_, index: let index): return "index \(index)"
        }
    }
    
    var codingPath: [CodingKey] {
        // super key will be added because the first key is not nil, but will not change the size of the storage
        return self.previousPath + storage.flatMap { $0.key }
    }
    
    func willDeinit() {
        
        precondition(encoded != nil, "SuperEncoder did not encode a value")
        
        switch reference {
        case .keyed(let container, key: let key):
            if Self.usesStringValue {
                container[key.stringValue] = encoded
            } else {
                
                precondition(key.intValue != nil, "Tried to get key: \(key).intValue, because \(Self.self).usesStringValue is false, but found nil.")
                
                container[key.intValue!] = encoded
            }
        case .unkeyed(let array, index: let index): array.replaceObject(at: index, with: encoded!)
        }
    }
}

extension Reference where Super.Options == Self.Options {
    
    init(_ _super: Super, reference: ReferenceObject) {
        
        self.init(_super.options, userInfo: _super.userInfo)
        
        self.reference = reference
        self.previousPath = _super.codingPath
        self.key = superKey
    }
}

protocol UnkeyedContainer: UnkeyedEncodingContainer {
    
    associatedtype BaseEncoder: Base
    var encoder: BaseEncoder {get}
    
    init(encoder: BaseEncoder, container: NSMutableArray)
}

protocol KeyedEncoder: KeyedEncodingContainerProtocol {
    
}


//
//protocol Encoder2: Encoder, SingleValueEncodingContainer, UnkeyedEncodingContainer, KeyedEncodingContainerProtocol {
//
//    associatedtype _Self = Self
//
//    /// by binding _Self to an associatedtype, it allows the subclass to control what Self is
//    /// get: as? Self, set: self as Self? as! _Self?
//    weak var subEncoder: AnyObject? {get set}
//
//    /// activated on access, calls a function on deinit
//    var lazyLifetime: Lifetime {get}
//
//
//    /// defines whether to use (CodingKey) .stringValue or .intValue! to set from Key,
//    /// defaults to true
//    static var setsKeyFromStringValue: Bool {get}
//
//    var single: Any {get set}
//    // unkeyed and keyed should be lazy
//    var unkeyed: NSMutableArray {get set}
//    var keyed: NSMutableDictionary {get set}
//
//    var encoderType: EncoderType {get set}
//
//    var codingPath: [CodingKey] {get set}
//
//    func set(_ encoded: Any, forKey key: Key?)
//
//    func encode(_ value: Encodable) throws
//
//    func encode(_ value: Encodable, forKey key: Key) throws
//
//    init(forNormalEncoder codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any])
//
//    /// pass result to KeyedEncodingContainer<NewKey>
//    static func initForKeyed<T: Encoder2>(takeValuesFrom _self: T, writeTo dictionary: NSMutableDictionary) -> Self
//
//    init(forUnkeyedTakeValuesFrom _self: Self, writeTo array: NSMutableArray)
//
//    // no init for single (uses init(forNormalEncoder)
//
//    // superEncoder():
//
//    // .single does not need it because it can only encode one value
//    // can only be called from a .single Encoder2
//    // case .single
//    // singleValueContainer() returns self
//    // don't add "super", because only base encodable values use this
//    // subclasses of singleValueContainers should not call this unless overriding the full implementation
//
//    // case .unkeyed
//    // superEncoder() returns Self.init
//    // adds to path: "index 0"
//    // set to subEncoder?.unkeyed on deinit
//    // should add to path: "super (called at index 0)"
//
//    // case .keyed
//    // superEncoder() returns Self.init
//    // adds to path: "super"
//    // set to subEncoder?.keyed on deinit
//
//    // superEncoder(forKey:)
//    // prints warning "unknown what this is for" and returns superEncoder()
//
//    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any])
//
//    /** Equivalent code is needed to return the value:
//     let new = Self<NewKey>.init(codingPath: _self.codingPath, userInfo: _self.userInfo);
//     new.keyed = _self.keyed;
//     new.encoderType = .keyed;
//     return KeyedEncodingContainer<NewKey>(new)
//     */
//    static func keyedContainer<NewKey>(with _self: Self, keyedBy: NewKey.Type) -> KeyedEncodingContainer<NewKey>
//
//    /// initialize a new encoder with default values
//    /// defaults to init(codingPath: userInfo: encoderType: )
//    func new() -> Self
//
//    func box(_ value: NSNull) throws -> Any
//    func box(_ value: Bool)   throws -> Any
//    func box(_ value: Int)    throws -> Any
//    func box(_ value: Int8)   throws -> Any
//    func box(_ value: Int16)  throws -> Any
//    func box(_ value: Int32)  throws -> Any
//    func box(_ value: Int64)  throws -> Any
//    func box(_ value: UInt)   throws -> Any
//    func box(_ value: UInt8)  throws -> Any
//    func box(_ value: UInt16) throws -> Any
//    func box(_ value: UInt32) throws -> Any
//    func box(_ value: UInt64) throws -> Any
//    func box(_ value: Float)  throws -> Any
//    func box(_ value: Double) throws -> Any
//    func box(_ value: String) throws -> Any
//    func box(_ value:Encodable)throws-> Any
//
//    func execute<T>(_ box: (T)throws->Any, with value: T, forKey key: Key?) throws
//}
//
//// found out how to create a new class, but not how to pass the result back.
//
//extension Encoder2 {
//
//    static var setsKeyFromStringValue: Bool {
//        return true
//    }
//
//    var count: Int {
//
//        switch encoderType {
//        case .single:  return (single is Void ? 0 : 1)
//        case .unkeyed: return unkeyed.count
//        case .keyed:   return keyed.count
//        }
//    }
//
//    // should I throw, crash or skip, if a value tries to encode two values for the same key?
//    // shouldn't throw, or they won't know what happend exactly
//    // shouldn't skip, or they won't know which value it will use.
//    // crash.
//
//    func set(_ encoded: Any, forKey key: Key? = nil) {
//
//        switch encoderType {
//        case .single:
//            precondition(single is Void, "Tried to set two values to a SingleValueContainer.")
//            single = encoded
//
//        case .unkeyed:
//            unkeyed.add(encoded)
//
//        case .keyed:
//
//            let _key: Any = Self.setsKeyFromStringValue
//                ? key!.stringValue
//                : key?.intValue ?? fatalError("Tried to get \(Key.self).\(key!).intValue, because \(Self.self).setsKeyFromStringValue is false, but found nil.")
//
//            precondition((keyed[_key] ?? ()) is Void, "\(Self.self): Tried to set two values for the same key (\(_key) from \(Key.self).\(key!)).")
//
//            keyed[_key] = encoded
//        }
//    }
//
//    func box(_ value: NSNull) throws -> Any { return value }
//    func box(_ value: Bool  ) throws -> Any { return value }
//    func box(_ value: Int   ) throws -> Any { return value }
//    func box(_ value: Int8  ) throws -> Any { return value }
//    func box(_ value: Int16 ) throws -> Any { return value }
//    func box(_ value: Int32 ) throws -> Any { return value }
//    func box(_ value: Int64 ) throws -> Any { return value }
//    func box(_ value: UInt  ) throws -> Any { return value }
//    func box(_ value: UInt8 ) throws -> Any { return value }
//    func box(_ value: UInt16) throws -> Any { return value }
//    func box(_ value: UInt32) throws -> Any { return value }
//    func box(_ value: UInt64) throws -> Any { return value }
//    func box(_ value: Float ) throws -> Any { return value }
//    func box(_ value: Double) throws -> Any { return value }
//    func box(_ value: String) throws -> Any { return value }
//    func box(_ value:Encodable)throws-> Any { return try value.encode(to: self) }
//
//    // [["":User]]
//
//
//    // when to increment path
//
//    // path should look like: ["index 0", address, "super", zipCode]
//
//    // increment for box value that throws, if !(encoderType == .single && subEncoder == nil)
//
//    // box(Encodable) needs to increment sometimes?
//
//    func encodeNil()           throws {try execute(box(_:), with: NSNull()) }
//    func encode(_ value: Bool  ) throws { try execute(box(_:), with: value) }
//    func encode(_ value: Int   ) throws { try execute(box(_:), with: value) }
//    func encode(_ value: Int8  ) throws { try execute(box(_:), with: value) }
//    func encode(_ value: Int16 ) throws { try execute(box(_:), with: value) }
//    func encode(_ value: Int32 ) throws { try execute(box(_:), with: value) }
//    func encode(_ value: Int64 ) throws { try execute(box(_:), with: value) }
//    func encode(_ value: UInt  ) throws { try execute(box(_:), with: value) }
//    func encode(_ value: UInt8 ) throws { try execute(box(_:), with: value) }
//    func encode(_ value: UInt16) throws { try execute(box(_:), with: value) }
//    func encode(_ value: UInt32) throws { try execute(box(_:), with: value) }
//    func encode(_ value: UInt64) throws { try execute(box(_:), with: value) }
//    func encode(_ value: Float ) throws { try execute(box(_:), with: value) }
//    func encode(_ value: Double) throws { try execute(box(_:), with: value) }
//    func encode(_ value: String) throws { try execute(box(_:), with: value) }
//
//    func encode<T: Encodable>(_ value: T) throws { try encode(value as Encodable) }
//
//    func encode(_ value: Encodable) throws {
//
//        try value.encode(to: self)
//    }
//
//    func encodeNil(forKey key: Key)               throws { try encodeNil()   ; set(key) }
//    func encode(_ value: Bool,   forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: Int,    forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: Int8,   forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: Int16,  forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: Int32,  forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: Int64,  forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: UInt,   forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: UInt8,  forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: UInt16, forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: UInt32, forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: UInt64, forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: Float,  forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: Double, forKey key: Key) throws { try encode(value) ; set(key) }
//    func encode(_ value: String, forKey key: Key) throws { try encode(value) ; set(key) }
//
//    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable { try encode(value as Encodable, forKey: key) }
//
//    func encode(_ value: Encodable, forKey key: Key) throws { codingPath.append(key) ; try encode(value) ; set(key) ; codingPath.removeLast() }
//
//    // how do they pass the values back through an Encoder
//
//    // how to init with a new keyed container
//
//    // Encoder
//    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
//
//        let dictionary = NSMutableDictionary()
//
//        self.keyed = dictionary
//        self.encoderType = .keyed
//
//        return Self.keyedContainer(with: self, keyedBy: Key.self)
//    }
//
//    func unkeyedContainer() -> UnkeyedEncodingContainer {
//
//        self.encoderType = .unkeyed
//
//        let array = NSMutableArray()
//
//
//
//        let new = self.new()
//
//        new.unkeyed = array
//
//        new.encoderType = .unkeyed
//
//        return new
//    }
//
//    func singleValueContainer() -> SingleValueEncodingContainer {
//
//        self.encoderType = .single
//
//        return self
//    }
//    //
//
//    // KeyedContainer
//
//    /// adds a dictionary for key and returns an encoder referencing it.
//    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
//
//        // + dict, set(dict, forKey), + keyedContainer<NestedKey>(self, dictionary, path + key)
//
//
//        assert(encoderType == .keyed)
//
//        let dictionary = NSMutableDictionary()
//
//        let new = 1 as! Self// Self.init()
//
//        new.encoderType = .keyed
//
//        new.keyed = dictionary
//
//        let container = Self.keyedContainer(with: new, keyedBy: NestedKey.self)
//
//
//        return container
//    }
//
//    /// adds an array for key and returns an encoder referencing it
//    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
//
//        // + array, set(array, forKey), + unkeyedContainer(self, array, path + index)
//
//        assert(encoderType == .keyed)
//
//        return unkeyedContainer()
//    }
//
//    func superEncoder() -> Encoder {
//
//        let new = //Self.init( (forEncoder) self.path, self.userInfo)
//
//            new.codingPath.append("super")
//
//        new.subEncoder = self as Self? as! _Self?
//
//        return new
//    }
//
//    func superEncoder(forKey key: Key) -> Encoder {
//
//        print("Warning: superEncoder(forKey: \(key) called but only returns superEncoder()")
//
//        return superEncoder()
//    }
//    //
//
//    // unkeyed container
//
//    // nested containers need to return a new instance that encodes to self
//    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
//
//        let dictionary = NSMutableDictionary()
//
//        let new = Self.init(forKeyed)
//
//        new.encoderType = .keyed
//
//        return self.asKeyedContainer(keyedBy: NestedKey.self)
//    }
//
//    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
//
//        let new = self.new()
//
//        new.encoderType = .unkeyed
//
//        return new
//    }
//    //
//
//    func willDeinit() {
//
//        guard count > 0 else {
//
//            if encoderType == .single && single == nil {
//
//                fatalError("\(Self.self) at path: \(codingPath) did not encode any values")
//            } else {
//                return
//            }
//        }
//
//        guard let subEncoder = subEncoder as? Self else { return }
//
//        switch encoderType {
//        case .single: if subEncoder.single == nil { subEncoder.single = single }
//
//        case .unkeyed: subEncoder.unkeyed.append(contentsOf: unkeyed)
//
//        case .keyed: for (k, v) in keyed { subEncoder.keyed[k] = subEncoder.keyed[k] ?? v }
//        }
//    }
//}
//
//enum CodingKeyTest: String, CodingKey {
//    case one
//}
//
//struct JSONEncoder2: TopLevelEncoder {
//
//    init() {}
//
//    func encode(_ value: Encodable) throws -> Data {
//
//        return try JSONSerialization.data(withJSONObject: try encode(value: value), options: [])
//    }
//
//    func encode(value: Encodable) throws -> Any {
//
//        let encoder = _PrivateJSONEncoder2<String>()
//
//        try value.encode(to: encoder)
//
//        return encoder.result.value
//    }
//}


//class _PrivateJSONEncoder2<K: CodingKey>: Encoder2 {
//
//    typealias Key = K
//    typealias OutboundKey = String
//    typealias Encoded = NSObject
//
//    var codingPath: [CodingKey]
//    var encoderType: EncoderType
//    var userInfo: [CodingUserInfoKey : Any]
//
//    weak var subEncoder: _PrivateJSONEncoder2?
//
//    var single: Any!
//    lazy var unkeyed: NSArray = []
//    lazy var keyed: NSDictionary = [:]
//
//    required init(codingPath: [CodingKey] = [], encoderType: EncoderType = .single, userInfo: [CodingUserInfoKey : Any] = [:]) {
//
//        self.codingPath = codingPath
//        self.encoderType = encoderType
//        self.userInfo = userInfo
//    }
//
//    static func keyedContainer<NewKey>(with _self: _PrivateJSONEncoder2, keyedBy: NewKey.Type) -> KeyedEncodingContainer<NewKey> {
//
//        return KeyedEncodingContainer<NewKey>(_PrivateJSONEncoder2<NewKey>(codingPath: _self.codingPath, encoderType: _self.encoderType, userInfo: _self.userInfo))
//    }
//
//    deinit {
//        willDeinit()
//    }
//}


//protocol SingleValueEncoder: UnsetEncoder, Encoder, SingleValueEncodingContainer {
//
//    var value: Boxer.Encoded! {get set}
//}
//
//extension SingleValueEncoder {
//
//    func assertWillSet(_ encoded: Boxer.Encoded) {
//
//        precondition(value == nil, "\(Self.self): Tried to encode two values to a single value container.  First: \(value), Second: \(encoded)")
//    }
//
//    mutating func set(_ encoded: Boxer.Encoded) {
//
//        assertWillSet(encoded)
//
//        self.value = encoded
//    }
//
//    mutating func encode(_ value: Encodable) throws {
//
//        try value.encode(to: self)
//    }
//}
//
//protocol UnkeyedContainer: UnsetEncoder, UnkeyedEncodingContainer {
//
//    var codingPath: [CodingKey] { get set }
//
//    var values: [Encoded] { get set }
//}
//
//extension UnkeyedContainer {
//
//    mutating func set(_ encoded: Encoded) {
//
//        self.values.append(encoded)
//    }
//
//    mutating func encode(_ value: Encodable) throws {
//        // a UnkeyedContainer cannot encode to self.
//        // TODO: find a way to add a value to self without overriding
//
//        set(try Boxer.box(value))
//    }
//}
//
//protocol Container: Encoder, SingleValueEncodingContainer {
//
//    // Encoder
//    var codingPath: [CodingKey] { get } // + SingleValueEncodingContainer
//    var userInfo: [CodingUserInfoKey : Any] { get }
//
//    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey
//    func unkeyedContainer() -> UnkeyedEncodingContainer
//    func singleValueContainer() -> SingleValueEncodingContainer
//    //
//    // SingleValueEncodingContainer
//    mutating func encodeNil() throws
//
//    mutating func encode(_ value: Bool) throws
//    mutating func encode(_ value: Int) throws
//    mutating func encode(_ value: Int8) throws
//    mutating func encode(_ value: Int16) throws
//    mutating func encode(_ value: Int32) throws
//    mutating func encode(_ value: Int64) throws
//    mutating func encode(_ value: UInt) throws
//    mutating func encode(_ value: UInt8) throws
//    mutating func encode(_ value: UInt16) throws
//    mutating func encode(_ value: UInt32) throws
//    mutating func encode(_ value: UInt64) throws
//    mutating func encode(_ value: Float) throws
//    mutating func encode(_ value: Double) throws
//    mutating func encode(_ value: String) throws
//
//    mutating func encode<T>(_ value: T) throws where T : Encodable
//    //
//}
//
//protocol UnkeyedContainer_: Encoder, UnkeyedEncodingContainer {
//
//    associatedtype Boxer: EncodeBoxer
//
//    // encoder
//    var codingPath: [CodingKey] { get } // + UnkeyedEncodingContainer
//    var userInfo: [CodingUserInfoKey : Any] { get }
//
//    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey
//    func unkeyedContainer() -> UnkeyedEncodingContainer
//    func singleValueContainer() -> SingleValueEncodingContainer
//    //
//    // UnkeyedEncodingContainer
//    mutating func encodeNil() throws
//
//    mutating func encode(_ value: Bool) throws
//    mutating func encode(_ value: Int) throws
//    mutating func encode(_ value: Int8) throws
//    mutating func encode(_ value: Int16) throws
//    mutating func encode(_ value: Int32) throws
//    mutating func encode(_ value: Int64) throws
//    mutating func encode(_ value: UInt) throws
//    mutating func encode(_ value: UInt8) throws
//    mutating func encode(_ value: UInt16) throws
//    mutating func encode(_ value: UInt32) throws
//    mutating func encode(_ value: UInt64) throws
//    mutating func encode(_ value: Float) throws
//    mutating func encode(_ value: Double) throws
//    mutating func encode(_ value: String) throws
//
//    mutating func encode<T>(_ value: T) throws where T : Encodable
//
//    var count: Int { get }
//
//    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey
//
//    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer
//
//    mutating func superEncoder() -> Encoder
//    //
//}
//
//extension UnkeyedContainer_ {
//    mutating func superEncoder() -> Encoder { return self }
//}


//    mutating func encode(_ value: Bool)   throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: Int)    throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: Int8)   throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: Int16)  throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: Int32)  throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: Int64)  throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: UInt)   throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: UInt8)  throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: UInt16) throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: UInt32) throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: UInt64) throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: Float)  throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: Double) throws { set(Boxer.box(value)) }
//    mutating func encode(_ value: String) throws { set(Boxer.box(value)) }

//public protocol Encoder {
//    public var codingPath: [CodingKey] { get }
//    public var userInfo: [CodingUserInfoKey : Any] { get }

//    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey
//    public func unkeyedContainer() -> UnkeyedEncodingContainer
//    public func singleValueContainer() -> SingleValueEncodingContainer
//}

//struct U: SingleValueEncodingContainer {
//
//    var codingPath: [CodingKey]
//
//    mutating func encodeNil() throws
//
//    mutating func encode(_ value: Bool) throws
//    mutating func encode(_ value: Int) throws
//    mutating func encode(_ value: Int8) throws
//    mutating func encode(_ value: Int16) throws
//    mutating func encode(_ value: Int32) throws
//    mutating func encode(_ value: Int64) throws
//    mutating func encode(_ value: UInt) throws
//    mutating func encode(_ value: UInt8) throws
//    mutating func encode(_ value: UInt16) throws
//    mutating func encode(_ value: UInt32) throws
//    mutating func encode(_ value: UInt64) throws
//    mutating func encode(_ value: Float) throws
//    mutating func encode(_ value: Double) throws
//    mutating func encode(_ value: String) throws
//
//    mutating func encode<T>(_ value: T) throws where T : Encodable
//}

// SingleValueEncodingContainer has the same signature (mostly) with UnkeyedEncodingContainer

//struct U: UnkeyedEncodingContainer {
//
//    mutating func encodeNil() throws
//
//    mutating func encode(_ value: Bool) throws
//    mutating func encode(_ value: Int) throws
//    mutating func encode(_ value: Int8) throws
//    mutating func encode(_ value: Int16) throws
//    mutating func encode(_ value: Int32) throws
//    mutating func encode(_ value: Int64) throws
//    mutating func encode(_ value: UInt) throws
//    mutating func encode(_ value: UInt8) throws
//    mutating func encode(_ value: UInt16) throws
//    mutating func encode(_ value: UInt32) throws
//    mutating func encode(_ value: UInt64) throws
//    mutating func encode(_ value: Float) throws
//    mutating func encode(_ value: Double) throws
//    mutating func encode(_ value: String) throws
//
//    mutating func encode<T>(_ value: T) throws where T : Encodable
//
//    var codingPath: [CodingKey]
//
//    var count: Int
//
/*
 var rangeContainer = indexesContainer.nestedContainer(keyedBy: RangeCodingKeys.self)
 try rangeContainer.encode(range.startIndex, forKey: .location)
 try rangeContainer.encode(range.count, forKey: .length)
 */
//    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey
//
//    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer
//
/*
 Does nothing. (they create a class and then pass the values back to the same class on deinit)
 
 My implementation will let the value know not to throw if a value is encoded twice, uhh... but, how.
 A super will encode it's values into the container, but how will it know if it's encoding the same values twice?
 This doesn't make sense.
 
 superEncoder() on an UnkeyedEncodingContainer is not needed.
 */
//    mutating func superEncoder() -> Encoder
//}

// struct Str<K: CodingKey> {
// typealias Key = K
//
//
//}

// enum C: String, CodingKey {case one}
// KeyedEncodingContainerProtocol {

//    typealias Key = C

//    var codingPath: [CodingKey]
//
//    mutating func encodeNil(forKey key: C) throws

//    mutating func encode(_ value: Bool,   forKey key: C) throws
//    mutating func encode(_ value: Int,    forKey key: C) throws
//    mutating func encode(_ value: Int8,   forKey key: C) throws
//    mutating func encode(_ value: Int16,  forKey key: C) throws
//    mutating func encode(_ value: Int32,  forKey key: C) throws
//    mutating func encode(_ value: Int64,  forKey key: C) throws
//    mutating func encode(_ value: UInt,   forKey key: C) throws
//    mutating func encode(_ value: UInt8,  forKey key: C) throws
//    mutating func encode(_ value: UInt16, forKey key: C) throws
//    mutating func encode(_ value: UInt32, forKey key: C) throws
//    mutating func encode(_ value: UInt64, forKey key: C) throws
//    mutating func encode(_ value: Float,  forKey key: C) throws
//    mutating func encode(_ value: Double, forKey key: C) throws
//    mutating func encode(_ value: String, forKey key: C) throws
//
//    mutating func encode<T>(_ value: T, forKey key: C) throws where T : Encodable
//
//    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: C) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey
//
/*
 from: "{"indexes": [{"location": 0, "length": 100}, {"location": 100, "length": 100}]}"
 
 let container = try decoder.container(keyedBy: CodingKeys.self)
 var indexesContainer = container.nestedUnkeyedContainer(forKey: .indexes)
 
 for range in self.rangeView {
 var rangeContainer = indexesContainer.nestedContainer(keyedBy: RangeCodingKeys.self)
 try rangeContainer.encode(range.startIndex, forKey: .location)
 try rangeContainer.encode(range.count, forKey: .length)
 }
 */
//    mutating func nestedUnkeyedContainer(forKey key: C) -> UnkeyedEncodingContainer
//
//    mutating func superEncoder() -> Encoder
//
//    mutating func superEncoder(forKey key: C) -> Encoder
//
//}
