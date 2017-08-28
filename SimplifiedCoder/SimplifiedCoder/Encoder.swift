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
            return "Unable to encode value. underlying error: \(error) at path: \(path)"
        }
    }
    
    case encoderError(Error, atPath: [CodingKey])
}

/// a strategy identifier for Reference.willDeinit() to return encoded to the reference
struct EncoderReferenceReturnStrategy: OptionSet {
    
    let rawValue: Int
    
    static let set = EncoderReferenceReturnStrategy(rawValue: 1)
    static let merge = EncoderReferenceReturnStrategy(rawValue: 2)
}

protocol Base: class, Encoder, SingleValueEncodingContainer {
    
    associatedtype KeyedContainerType: KeyedContainer
    associatedtype UnkeyedContainerType: UnkeyedContainer
    
    associatedtype Options
    
    var options: Options {get}
    
    init(options: Options, userInfo: [CodingUserInfoKey : Any])
    
    // only the first key may be nil
    var storage: [(key: CodingKey?, value: Any)] {get set}
    
    var key: CodingKey? {get set}
    
    static var usesStringValue: Bool {get}
    
    var superKeyedReturnStrategy: EncoderReferenceReturnStrategy {get}
}

extension Base {
    
    var superKeyedReturnStrategy: EncoderReferenceReturnStrategy {
        return .merge
    }
    
    var codingPath: [CodingKey] {
        
        return storage.flatMap {$0.key}
    }
    
    func set(_ key: CodingKey) -> Self {
        self.key = key
        return self
    }
    
    /// the current encoded value ?? try! Self.box(Void) if no value was encoded
    var encoded: Any? {
        
        return storage.first?.value
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
    
    func encode<T>(_ value: T, with box: (T)throws->Any) throws {
        
        do {
            try set(box(value))
            
        } catch EncoderError.encoderError(let error, atPath: let path) {
            throw EncoderError.encoderError(error, atPath: path)
        } catch {
            throw EncoderError.encoderError(error, atPath: codingPath)
        }
    }
    
    func box(_ value: Void  ) throws -> Any { return NSNull() }
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
    
    /// tries to box the value into a encoder specific box. If it can't, reencodes the value then removes the last encoded value
    func box(_ value: Encodable) throws -> Any { return try reencode(value) }
    
    func reencode(_ value: Encodable) throws -> Any {
        let count = storage.count
        
        try value.encode(to: self)
        
        if storage.count == count {
            fatalError("\(value) did not encode a value")
            // TODO: find out if this matters: "return default container"
            // return NSMutableDictionary()
            
        } else {
            
            return storage.removeLast().value
        }
    }
    
    func encodeNil()             throws { try encode(()   , with: box(_:)) }
    func encode(_ value: Bool  ) throws { try encode(value, with: box(_:)) }
    func encode(_ value: Int   ) throws { try encode(value, with: box(_:)) }
    func encode(_ value: Int8  ) throws { try encode(value, with: box(_:)) }
    func encode(_ value: Int16 ) throws { try encode(value, with: box(_:)) }
    func encode(_ value: Int32 ) throws { try encode(value, with: box(_:)) }
    func encode(_ value: Int64 ) throws { try encode(value, with: box(_:)) }
    func encode(_ value: UInt  ) throws { try encode(value, with: box(_:)) }
    func encode(_ value: UInt8 ) throws { try encode(value, with: box(_:)) }
    func encode(_ value: UInt16) throws { try encode(value, with: box(_:)) }
    func encode(_ value: UInt32) throws { try encode(value, with: box(_:)) }
    func encode(_ value: UInt64) throws { try encode(value, with: box(_:)) }
    func encode(_ value: Float ) throws { try encode(value, with: box(_:)) }
    func encode(_ value: Double) throws { try encode(value, with: box(_:)) }
    func encode(_ value: String) throws { try encode(value, with: box(_:)) }
    
    func encode<T: Encodable>(_ value: T) throws { try encode(value as Encodable) }
    
    func encode(_ value: Encodable) throws { try encode(value, with: box(_:)) }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        
        return self
    }
}

extension Base where Self.KeyedContainerType.BaseEncoder == Self {
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        
        let container: NSMutableDictionary
        
        if key != nil || storage.count == 0 {
            container = NSMutableDictionary()
            set(container)
            
        } else {
            // already encoded a value, at least try to get the last encoded value as the value before causing a fatal error
            if let value = storage.last?.value as? NSMutableDictionary {
                container = value
            } else {
                fatalError("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
        }
        
        return KeyedContainerType.initSelf(encoder: self, container: container, nestedPath: [], keyedBy: Key.self)
    }
}

extension Base where Self.UnkeyedContainerType.BaseEncoder == Self {
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        
        let container: NSMutableArray
        
        if key != nil || storage.count == 0 {
            container = NSMutableArray()
            set(container)
            
        } else {
            
            if let value = storage.last!.value as? NSMutableArray {
                container = value
            } else {
                fatalError("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
        }
        
        return UnkeyedContainerType.init(encoder: self, container: container, nestedPath: [])
    }
}

fileprivate func _rawValue_<_Self>(from key: CodingKey, _ useStringValue: Bool, _: _Self.Type) -> Any {
    
    if useStringValue {
        return key.stringValue
        
    } else {
        
        precondition(key.intValue != nil, "Tried to get key: \(key).intValue, because \(_Self.self).usesStringValue is false, but found nil.")
        
        return key.intValue!
    }
}

enum ReferenceObject {
    case unkeyed(NSMutableArray, index: Int)
    case keyed(NSMutableDictionary, key: CodingKey)
}

protocol Reference: Base {
    
    associatedtype BaseEncoder: Base
    
    var reference: ReferenceObject {get set}
    var previousPath: [CodingKey] {get set}
    var returnStrategy: EncoderReferenceReturnStrategy {get set}
    
    init(_ _super: BaseEncoder, reference: ReferenceObject, nestedPath: [CodingKey])
    
    static var usesStringValue: Bool {get}
    
    // remember: deinit { willDeinit() }
}

extension Reference {
    
    var superKey: CodingKey {
        switch reference {
        case .keyed(_, key: let key): return key
        case .unkeyed(_, index: let index): return "index \(index)"
        }
    }
    
    var codingPath: [CodingKey] {
        // superKey will be added, but won't increase the codingPath size, because, instead of nil, the first key is the superKey
        return self.previousPath + storage.flatMap { $0.key }
    }
    
    func willDeinit() {
        
        precondition(encoded != nil, "super encoder did not encode a value")
        
        func set(_ encoded: Any) {
            switch reference {
            case .keyed(let container, key: let key): container[_rawValue_(from: key, Self.usesStringValue, Self.self)] = encoded
            case .unkeyed(let container, index: let index): container.replaceObject(at: index, with: encoded)
            }
        }
        
        switch returnStrategy {
        case .set: set(encoded!)
        case .merge:
            if case .keyed(let container, key: _) = reference, let container2 = encoded as? NSDictionary {
                for (key, value) in container2 {
                    container[key] = container[key] ?? value
                }
            } else {
                set(encoded!)
            }
        default: fatalError("Unrecognized EncoderReferenceReturnStrategy in \(Self.self).willDeinit(), create a custom willDeinit.")
        }
    }
}

extension Reference where BaseEncoder.Options == Self.Options {
    
    init(_ _super: BaseEncoder, reference: ReferenceObject, nestedPath: [CodingKey]) {
        
        self.init(options: _super.options, userInfo: _super.userInfo)
        
        self.reference = reference
        self.previousPath = _super.codingPath + nestedPath
        self.returnStrategy = _super.superKeyedReturnStrategy
        self.key = superKey
    }
}

protocol UnkeyedContainer: UnkeyedEncodingContainer {
    
    associatedtype KeyedContainerType: KeyedContainer
    associatedtype ReferenceType: Reference
    associatedtype BaseEncoder: Base
    
    var encoder: BaseEncoder {get}
    var container: NSMutableArray {get}
    var nestedPath: [CodingKey] {get}
    
    init(encoder: BaseEncoder, container: NSMutableArray, nestedPath: [CodingKey])
}

extension UnkeyedContainer {
    
    var count: Int {
        return container.count
    }
    
    var codingPath: [CodingKey] {
        return encoder.codingPath + nestedPath
    }
    
    func encode<T>(_ value: T, with box: (T)throws->Any) throws {
        do {
            try container.add(box(value))
        } catch EncoderError.encoderError(let error, atPath: let path) {
            throw EncoderError.encoderError(error, atPath: path)
        } catch {
            throw EncoderError.encoderError(error, atPath: codingPath + ["index \(count)"])
        }
    }
    
    func encodeNil()             throws { try encode(()   , with: encoder.box(_:)) }
    func encode(_ value: Bool  ) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: Int   ) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: Int8  ) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: Int16 ) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: Int32 ) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: Int64 ) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: UInt  ) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: UInt8 ) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: UInt16) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: UInt32) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: UInt64) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: Float ) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: Double) throws { try encode(value, with: encoder.box(_:)) }
    func encode(_ value: String) throws { try encode(value, with: encoder.box(_:)) }
    
    func encode<T: Encodable>(_ value: T) throws { try encode(value as Encodable) }
    
    func encode(_ value: Encodable) throws { try encode(value, with: encoder.box(_:)) }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        
        let container = NSMutableArray()
        
        self.container.add(container)
        
        return Self.init(encoder: encoder, container: container, nestedPath: nestedPath + ["index \(count)"])
    }
}

extension UnkeyedContainer where Self.KeyedContainerType.BaseEncoder == Self.BaseEncoder {
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        
        let container = NSMutableDictionary()
        
        self.container.add(container)
        
        return KeyedContainerType.initSelf(encoder: encoder, container: container, nestedPath: nestedPath + ["index \(count)"], keyedBy: NestedKey.self)
    }
}

extension UnkeyedContainer where Self.ReferenceType.BaseEncoder == Self.BaseEncoder {
    
    func superEncoder() -> Encoder {
        
        // placeholder.
        container.add("∆")
        
        return ReferenceType(encoder, reference: .unkeyed(container, index: count), nestedPath: nestedPath)
    }
}

protocol KeyedContainer: KeyedEncodingContainerProtocol {
    
    associatedtype UnkeyedContainerType: UnkeyedContainer
    associatedtype ReferenceType: Reference
    associatedtype BaseEncoder: Base
    
    var encoder: BaseEncoder {get}
    var container: NSMutableDictionary {get}
    var nestedPath: [CodingKey] {get}
    
    // nestedPath is seperate from encoder because a nestedContainer must have a path, but, the value is set directly to the container, instead of the encoder.
    
    init(encoder: BaseEncoder, container: NSMutableDictionary, nestedPath: [CodingKey], keyedBy: Key.Type)
    
    static func initSelf<Key>(encoder: BaseEncoder, container: NSMutableDictionary, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedEncodingContainer<Key>
    
    var usesStringValue: Bool {get}
}

extension KeyedContainer {
    
    var codingPath: [CodingKey] {
        return encoder.codingPath + nestedPath
    }
    
    fileprivate func _rawValue(_ key: CodingKey) -> Any {
        return _rawValue_(from: key, usesStringValue, Self.self)
    }
    
    func encode<T>(_ value: T, with box: (T)throws->Any, forKey key: Key) throws {
        do {
            try container[_rawValue(key)] = box(value)
        } catch EncoderError.encoderError(let error, atPath: let path) {
            throw EncoderError.encoderError(error, atPath: path)
        } catch {
            throw EncoderError.encoderError(error, atPath: codingPath + [key])
        }
    }
    
    func encodeNil(forKey key: Key)               throws { try encode(()   , with: encoder.box(_:), forKey: key) }
    func encode(_ value: Bool,   forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: Int,    forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: Int8,   forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: Int16,  forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: Int32,  forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: Int64,  forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: UInt,   forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: UInt8,  forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: UInt16, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: UInt32, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: UInt64, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: Float,  forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: Double, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    func encode(_ value: String, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    
    func encode<T: Encodable>(_ value: T, forKey key: Key) throws { try encode(value as Encodable, forKey: key) }
    
    func encode(_ value: Encodable, forKey key: Key) throws { try encode(value, with: encoder.box(_:), forKey: key) }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        
        let container = NSMutableDictionary()
        
        self.container[_rawValue(key)] = container
        
        return Self.initSelf(encoder: encoder, container: container, nestedPath: nestedPath + [key], keyedBy: NestedKey.self)
    }
}

extension KeyedContainer where Self.UnkeyedContainerType.BaseEncoder == Self.BaseEncoder {
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        
        let container = NSMutableArray()
        
        self.container[_rawValue(key)] = container
        
        return UnkeyedContainerType(encoder: encoder, container: container, nestedPath: nestedPath + [key])
    }
}

extension KeyedContainer where Self.ReferenceType.BaseEncoder == Self.BaseEncoder {
    
    func superEncoder() -> Encoder {
        
        return ReferenceType(encoder, reference: .keyed(container, key: "super"), nestedPath: nestedPath)
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        
        return ReferenceType(encoder, reference: .keyed(container, key: key), nestedPath: nestedPath)
    }
}