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
protocol TopLevelEncoder {
    
    func encode(_ value: Encodable) throws -> Data
}

// MARK: - EncoderBase
protocol EncoderBase: class, Encoder, SingleValueEncodingContainer {
    
    // references
    
    // warning: references to KeyedContainer<Key> types will compiler crash (Command failed due to signal: Abort trap: 6) if the generic value is left out
    // default with <String>
    associatedtype KeyedContainer: EncoderKeyedContainer
    associatedtype UnkeyedContainer: EncoderUnkeyedContainer
    associatedtype Options
    
    // required methods
    
    /// Options set on the top-level encoder.
    var options: Options {get}
    var userInfo: [CodingUserInfoKey : Any] {get}
    init(options: Options, userInfo: [CodingUserInfoKey : Any])
    
    // storage and key were zipped together to guarantee a single path to any resource
    // starts with []
    var storage: [(key: CodingKey?, value: Any)] {get set}
    var key: CodingKey? {get set}
    
    // new methods
    
    var canEncodeNewValue: Bool {get}
    
    func removeKey() -> CodingKey?
    
    func set(_ encoded: Any)
    
    func encode<T>(_ value: T, with box: (T)throws->Any) throws
    
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
        
        typealias C = KeyedContainer.Container
        
        // If an existing keyed container was already requested, return that one.
        let container: C
        
        if self.canEncodeNewValue {
            
            container = C()
            
            set(container)
            
        } else {
            // could just crash here, but checks if the last encoded container is the same type and returns that.
            
            if let _container = self.storage.last!.value as? C {
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
        
        typealias C = UnkeyedContainer.Container
        
        let container: C
        
        if self.canEncodeNewValue {
            
            container = C()
            
            set(container)
            
        } else {
            // could just crash here, but checks if the last encoded container is the same type and returns that.
            
            if let _container = self.storage.last!.value as? C {
                container = _container
            } else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }
        }
        
        return UnkeyedContainer(encoder: self, container: container, nestedPath: [])
    }
    
}

/// has to be a class to set the value to a central object
protocol EncoderKeyedContainerType: class {
    subscript(key: String) -> Any? {get set}
    subscript(key: Int) -> Any? {get set}
    init()
}

extension NSMutableDictionary: EncoderKeyedContainerType {}

// MARK: - Encoding Containers
protocol EncoderKeyedContainer: KeyedEncodingContainerProtocol {
    
    // references
    
    associatedtype UnkeyedContainer: EncoderUnkeyedContainer
    associatedtype Reference: EncoderReference
    associatedtype Base: EncoderBase
    associatedtype Container: EncoderKeyedContainerType = NSMutableDictionary
    
    // required methods
    
    var encoder: Base {get}
    var container: Container {get}
    var nestedPath: [CodingKey] {get}
    init(encoder: Base, container: Container, nestedPath: [CodingKey])
    
    static func initSelf<Key>(encoder: Base, container: Container, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedEncodingContainer<Key>
    
    static var usesStringValue: Bool {get}
    
    // new methods
    
    func set(_ encoded: Any, forKey key: CodingKey)
    
    func encode<T>(_ value: T, with box: (T)throws->Any, forKey key: Key) throws
}

extension EncoderKeyedContainer {
    
    public var codingPath: [CodingKey] {
        return encoder.codingPath + nestedPath
    }
    
    func set(_ encoded: Any, forKey key: CodingKey) {
        
        if Self.usesStringValue {
            
            self.container[key.stringValue] = encoded
            
        } else {
            
            precondition(key.intValue != nil, "Tried to get \(key).intValue, but found nil.")
            
            self.container[key.intValue!] = encoded
        }
    }
    
    func encode<T>(_ value: T, with box: (T)throws->Any, forKey key: Key) throws {
        
        do {
            
            try set(box(value), forKey: key)
            
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
        
        let container = Container()
        
        set(container, forKey: key)
        
        return Self.initSelf(encoder: self.encoder, container: container, nestedPath: self.nestedPath + [key], keyedBy: NestedKey.self)
    }
}

extension EncoderKeyedContainer where Self.UnkeyedContainer.Base == Self.Base {
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        
        let container = UnkeyedContainer.Container()
        
        set(container, forKey: key)
        
        return UnkeyedContainer(encoder: self.encoder, container: container, nestedPath: self.nestedPath + [key])
    }
}

extension EncoderKeyedContainer where Self.Reference.Super == Self.Base {
    
    mutating func superEncoder() -> Encoder {
        return Reference(encoder: self.encoder, reference: .keyed(self.container, key: "super"), previousPath: self.codingPath + ["super"])
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        return Reference(encoder: self.encoder, reference: .keyed(self.container, key: key), previousPath: self.codingPath + [key])
    }
}

protocol EncoderUnkeyedContainerType: class {
    var count: Int {get}
    func add(_ value: Any)
    init()
    func replaceObject(at index: Int, with object: Any)
}

extension NSMutableArray: EncoderUnkeyedContainerType {}

protocol EncoderUnkeyedContainer : UnkeyedEncodingContainer {
    
    // references
    
    // warning: references to KeyedContainer<Key> types will compiler crash (Command failed due to signal: Abort trap: 6) if the generic value is left out
    // default with <String>
    associatedtype KeyedContainer: EncoderKeyedContainer
    associatedtype Reference: EncoderReference
    associatedtype Base: EncoderBase
    associatedtype Container: EncoderUnkeyedContainerType = NSMutableArray
    
    // required methods
    
    var encoder: Base {get}
    var container: Container {get}
    var nestedPath: [CodingKey] {get}
    init(encoder: Base, container: Container, nestedPath: [CodingKey])
    
    // new methods
    
    func encode<T>(_ value: T, with box: (T)throws->Any) throws
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
        
        let container = Container()
        self.container.add(container)
        
        return Self(encoder: self.encoder, container: container, nestedPath: self.nestedPath + ["index \(count)"])
    }
}

extension EncoderUnkeyedContainer where Self.KeyedContainer.Base == Self.Base {
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        
        let container = KeyedContainer.Container()
        self.container.add(container)
        
        return KeyedContainer.initSelf(encoder: self.encoder, container: container, nestedPath: self.nestedPath + ["index \(count)"], keyedBy: NestedKey.self)
    }
}

extension EncoderUnkeyedContainer where Self.Reference.Super == Self.Base {
    
    mutating func superEncoder() -> Encoder {
        
        defer { container.add("placeholder") }
        
        return Reference(encoder: self.encoder, reference: .unkeyed(self.container, index: container.count), previousPath: self.codingPath + ["super \(count)"])
    }
}

enum EncoderReferenceValue {
    case keyed(EncoderKeyedContainerType, key: CodingKey)
    case unkeyed(EncoderUnkeyedContainerType, index: Int)
}

protocol EncoderReference : EncoderBase {
    
    // references
    
    associatedtype Super: EncoderBase
    
    // required methods
    
    var reference: EncoderReferenceValue {get set}
    var previousPath: [CodingKey] {get set}
    
    // super will not be encoded if willDeinit() is not called
    //    deinit {
    //        willDeinit()
    //    }
    
    // new methods
    
    // not required if Super.Options == Self.Options
    init(encoder: Super, reference: EncoderReferenceValue, previousPath: [CodingKey])
    
    var codingPath: [CodingKey] {get}
    
    /// Finalizes `self` by writing the contents of our storage to the reference's storage.
    func willDeinit()
    
}

extension EncoderReference {
    
    var codingPath: [CodingKey] {
        return previousPath + storage.flatMap { $0.key }
    }
    
    // not supported (would change expected behaviour), but it would be nice. (incomplete)
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
        
        let value = self.storage.removeLast().value
        
        switch self.reference {
        case .unkeyed(let container, index: let index):
            container.replaceObject(at: index, with: value)
            
        case .keyed(let container, key: let key):
            
            if Self.KeyedContainer.usesStringValue {
                container[key.stringValue] = container[key.stringValue] ?? value
            } else {
                precondition(key.intValue != nil, "Tried to get \(key).intValue, but found nil.")
                
                container[key.intValue!] = container[key.intValue!] ?? value
            }
            
        }
    }
}

extension EncoderReference where Super.Options == Self.Options {
    
    init(encoder: Super, reference: EncoderReferenceValue, previousPath: [CodingKey]) {
        
        self.init(options: encoder.options, userInfo: encoder.userInfo)
        
        self.previousPath = previousPath
        self.reference = reference
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
