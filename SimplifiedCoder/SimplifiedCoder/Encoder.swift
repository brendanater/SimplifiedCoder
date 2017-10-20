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
    
    static var contentType: String {get}
    
    var userInfo: [CodingUserInfoKey : Any] {get set}
    
    func encode<T: Encodable>(_ value: T) throws -> Data
    func encode<T: Encodable>(value: T) throws -> Any
}

// MARK AnyBase

public enum EncoderReference {
    case keyed(EncoderKeyedContainerContainer, key: AnyHashable)
    case unkeyed(EncoderUnkeyedContainerContainer, index: Int)
}

public protocol AnyEncoderBase: class, Encoder, SingleValueEncodingContainer {
    
    /// whether to set to container using the CodingKey's .stringValue or .intValue!
    static var usesStringValue: Bool {get}
    
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
    
    // all methods
    
    func start<T: Encodable>(with value: T) throws -> Any
    
    func set(_ encoded: Any)
    
    // encode
    
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
    func encode<T: Encodable>(_ value: T) throws
    
    // MARK: boxing
    
    func boxNil(              at codingPath: [CodingKey]) throws -> Any
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
    func box<T: Encodable>(_ value: T, at codingPath: [CodingKey]) throws -> Any
    
    func reencode<T: Encodable>(_ value: T, at codingPath: [CodingKey]) throws -> Any
    func reencode<T: Encodable>(_ value: T, at codingPath: [CodingKey], closure: (T, Encoder)throws->Void) throws -> Any
    
    // MARK: containers
    
    func keyedContainerContainer() -> EncoderKeyedContainerContainer
    func unkeyedContainerContainer() -> EncoderUnkeyedContainerContainer
    
    func keyedContainer<Key>(encoder: AnyEncoderBase, container: EncoderKeyedContainerContainer, nestedPath: [CodingKey]) -> KeyedEncodingContainer<Key>
    func unkeyedContainer(encoder: AnyEncoderBase, container: EncoderUnkeyedContainerContainer, nestedPath: [CodingKey]) -> UnkeyedEncodingContainer
    
    //
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey
    func unkeyedContainer() -> UnkeyedEncodingContainer
    func singleValueContainer() -> SingleValueEncodingContainer
}

public extension AnyEncoderBase {
    
    public func start<T: Encodable>(with value: T) throws -> Any {
        self.canEncodeNewValue = true
        return try self.box(value, at: [])
    }
    
    public func set(_ encoded: Any) {
        
        guard self.canEncodeNewValue else {
            
            fatalError("Tried to encode a second container when previously already encoded at path: \(self.codingPath).  encoded: \(self.storage.last ?? "nothing!") tried to set: \(type(of: encoded))")
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
    public func encode<T: Encodable>(_ value: T) throws {
        guard self.canEncodeNewValue else {
            self.set(value)
            fatalError("\(self) set did not catch setting a new value when canEncodeNewValue == false")
        }
        
        let value = try self.box(value, at: self.codingPath)
        // box won't reset canEncodeNewValue, so reset here.
        self.canEncodeNewValue = true
        self.set(value)
    }
    
    // MARK: encoder.box(_:)
    
    public func boxNil(              at codingPath: [CodingKey]) throws -> Any{return NSNull()}
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
    public func box<T: Encodable>(_ value: T, at codingPath: [CodingKey]) throws -> Any {
        
        return try self.box(default: value, at: codingPath)
            ?? self.reencode(value, at: codingPath)
    }
    
    public func box<T: Encodable>(default value: T, at codingPath: [CodingKey]) throws -> Any? {
        
        switch value {
        // FIXME: remove when SR-5206 is fixed
        case is BrokenEncode: return try self.reencode(value, at: codingPath, closure: { try ($0 as! BrokenEncode).__encode(to: $1) })
        default: return nil
        }
    }
    
    public func reencode<T: Encodable>(_ value: T, at codingPath: [CodingKey]) throws -> Any {
        
        return try self.reencode(value, at: codingPath, closure: { try $0.encode(to: $1) })
    }
    
    public func reencode<T: Encodable>(_ value: T, at codingPath: [CodingKey], closure: (T, Encoder)throws->Void) throws -> Any {
        
        let previousPath = self.codingPath
        self.codingPath = codingPath
        defer { self.codingPath = previousPath }
        
        let depth = self.storage.count
        
        func getEncoded() -> Any? {
            
            switch self.storage.count {
            case depth + 1: return self.storage.removeLast()
            case depth: return nil
            default:
                if self.storage.count > depth + 1 {
                    fatalError("\(type(of: value)) encoded multiple containers to storage (this is an encoder error; use .canEncodeNewValue and remove storage after throwing). codingPath: \(codingPath)")
                } else {
                    fatalError("encoder lost values from storage while encoding \(type(of: value)).")
                }
            }
        }
        
        self.canEncodeNewValue = true
        
        do {
            try closure(value, self)
        } catch {
            _ = getEncoded()
            throw error
        }
        
        return getEncoded() ?? { ()->Any in fatalError("\(type(of: value)) did not encode a value or container at codingPath: \(codingPath).") }()
    }
    
    // MARK: containers
    
    public func keyedContainerContainer() -> EncoderKeyedContainerContainer {
        return NSMutableDictionary()
    }
    
    public func unkeyedContainerContainer() -> EncoderUnkeyedContainerContainer {
        return NSMutableArray()
    }
    
    public func keyedContainer<Key>(encoder: AnyEncoderBase, container: EncoderKeyedContainerContainer, nestedPath: [CodingKey]) -> KeyedEncodingContainer<Key> {
        
        return KeyedEncodingContainer(EncoderDefaultKeyedContainer<Key>(encoder: encoder, container: container, nestedPath: nestedPath))
    }
    
    public func unkeyedContainer(encoder: AnyEncoderBase, container: EncoderUnkeyedContainerContainer, nestedPath: [CodingKey]) -> UnkeyedEncodingContainer {
        
        return EncoderDefaultUnkeyedContainer(encoder: encoder, container: container, nestedPath: nestedPath)
    }
    
    // Encoder
    
    public func _container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        
        // If an existing keyed container was already requested, return that one.
        let container: EncoderKeyedContainerContainer
        
        if self.canEncodeNewValue {
            
            container = self.keyedContainerContainer()
            
            self.set(container)
            
        } else {
            
            if let _container = (self.storage.last ?? ()) as? EncoderKeyedContainerContainer {
                container = _container
            } else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at path: \(self.codingPath)")
            }
        }
        
        return self.keyedContainer(
            encoder: self,
            container: container,
            nestedPath: []
        )
    }
    
    public func _unkeyedContainer() -> UnkeyedEncodingContainer {
        
        let container: EncoderUnkeyedContainerContainer
        
        if self.canEncodeNewValue {
            
            container = self.unkeyedContainerContainer()
            
            self.set(container)
            
        } else {
            
            if let _container = (self.storage.last ?? ()) as? EncoderUnkeyedContainerContainer {
                container = _container
            } else {
                
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at path: \(self.codingPath)")
            }
        }
        
        return self.unkeyedContainer(
            encoder: self,
            container: container,
            nestedPath: []
        )
    }
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return self._container(keyedBy: type)
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return self._unkeyedContainer()
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
    
    // MARK: deinit
    
    // Finalizes `self` by writing the contents of our storage to the reference's storage.
    public func willDeinit() {
        
        guard let reference = self.reference, self.storage.count > 0 else {
            return
        }
        
        precondition(self.storage.count < 2, "Referencing encoder deallocated with multiple values in storage.")

        let encoded = self.storage.removeLast()

        switch reference {

        case .unkeyed(let container, index: let index):

            container.replaceObject(at: index, with: encoded)

        case .keyed(let container, key: let key):
            
            container.setToStorage(encoded, forKey: key)
        }
    }
}

// MARK: Base

public protocol EncoderBase: AnyEncoderBase {
    
    associatedtype Options
    
    var options: Options {get}
    
    init(codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any], reference: EncoderReference?)
}

public extension EncoderBase {
    
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
    
    public init(options: Options, userInfo: [CodingUserInfoKey: Any]) {
        self.init(codingPath: [], options: options, userInfo: userInfo, reference: nil)
    }
}

// MARK: JSONBase

public extension JSONEncoder {
    public typealias Options = (
        dateEncodingStrategy: JSONEncoder.DateEncodingStrategy,
        dataEncodingStrategy: JSONEncoder.DataEncodingStrategy,
        nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy
    )
}

public protocol EncoderJSONBase: EncoderBase where Self.Options == (json: JSONEncoder.Options, extra: Self.ExtraOptions) {
    
    associatedtype ExtraOptions
    
    func box(_ value: Float          , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: Double         , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: Date           , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: Data           , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: URL            , at codingPath: [CodingKey]) throws -> Any
    func box(_ value: Decimal        , at codingPath: [CodingKey]) throws -> Any
    func box<T: Encodable>(_ value: T, at codingPath: [CodingKey]) throws -> Any
}

public extension EncoderJSONBase {
    
    typealias JSONOptions = (json: JSONEncoder.Options, extra: Self.ExtraOptions)
    
    // convert(json: means that it is specific to a JSON compatible value and an encoding strategy
    
    public func box(_ value: Float          , at codingPath: [CodingKey]) throws -> Any { return try self.convert(json: value, at: codingPath) }
    public func box(_ value: Double         , at codingPath: [CodingKey]) throws -> Any { return try self.convert(json: value, at: codingPath) }
    public func box(_ value: Date           , at codingPath: [CodingKey]) throws -> Any { return try self.convert(json: value, at: codingPath) }
    public func box(_ value: Data           , at codingPath: [CodingKey]) throws -> Any { return try self.convert(json: value, at: codingPath) }
    public func box(_ value: URL            , at codingPath: [CodingKey]) throws -> Any { return self.convert(json: value) }
    public func box(_ value: Decimal        , at codingPath: [CodingKey]) throws -> Any { return value }
    public func box<T: Encodable>(_ value: T, at codingPath: [CodingKey]) throws -> Any {
        
        return try self.box(json: value, at: codingPath)
            ?? self.box(default: value, at: codingPath)
            ?? self.reencode(value, at: codingPath)
    }
    
    func box<T: Encodable>(json value: T, at codingPath: [CodingKey]) throws -> Any? {
        
        switch value {
        case is Date   , is NSDate         : return try self.box(value as! Date   , at: codingPath)
        case is Data   , is NSData         : return try self.box(value as! Data   , at: codingPath)
        case is URL    , is NSURL          : return try self.box(value as! URL    , at: codingPath)
        case is Decimal, is NSDecimalNumber: return try self.box(value as! Decimal, at: codingPath)
            
        default: return nil
        }
    }
    
    public func convert(json value: URL) -> String {
        return value.absoluteString
    }
    
    public func convert(json value: Date, at codingPath: [CodingKey]) throws -> Any {
        
        switch self.options.json.dateEncodingStrategy {
        case .deferredToDate:
            return try self.reencode(value, at: codingPath)
            
        case .secondsSince1970:
            return value.timeIntervalSince1970
            
        case .millisecondsSince1970:
            return value.timeIntervalSince1970 * 1000
            
        case .iso8601:
            if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                return ISO8601DateFormatter.shared.string(from: value)
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }
            
        case .formatted(let formatter):
            return formatter.string(from: value)
            
        case .custom(let closure):
            return try self.reencode(value, at: codingPath, closure: closure)
        }
    }
    
    public func convert(json value: Data, at codingPath: [CodingKey]) throws -> Any {
        
        switch self.options.json.dataEncodingStrategy {
        case .deferredToData:
            return try self.reencode(value, at: codingPath)
            
        case .base64:
            return value.base64EncodedString()
            
        case .custom(let closure):
            return try self.reencode(value, at: codingPath, closure: closure)
        }
    }
    
    public func convert<T: FloatingPoint>(json value: T, at codingPath: [CodingKey]) throws -> Any {
        
        if value.isInfinite || value.isNaN {
            
            guard case let .convertToString(positiveInfinity: positiveString, negativeInfinity: negitiveString, nan: nan) = self.options.json.nonConformingFloatEncodingStrategy else {
                
                throw EncodingError.invalidValue(
                    value,
                    EncodingError.Context.init(
                        codingPath: codingPath,
                        debugDescription: "Unable to encode \(T.self) (\(value)) directly. Use nonConformingFloatEncodingStrategy.convertToString to specify how the value should be encoded."
                    )
                )
            }
            
            switch value {
            case .infinity: return positiveString
            case -.infinity: return negitiveString
            default: return nan
            }
            
        } else {
            return value
        }
    }
}

// MARK: KeyedContainer

/// has to be a class to set to an already set object
public protocol EncoderKeyedContainerContainer: class {
    
    func setToStorage(_ value: Any, forKey key: AnyHashable)
}

extension NSMutableDictionary: EncoderKeyedContainerContainer {
    
    public func setToStorage(_ value: Any, forKey key: AnyHashable) {
        self[key] = value
    }
}

public protocol EncoderKeyedContainer: KeyedEncodingContainerProtocol {
    
    // required methods
    
    var encoder: AnyEncoderBase {get}
    var container: EncoderKeyedContainerContainer {get}
    var nestedPath: [CodingKey] {get}
    
    init(encoder: AnyEncoderBase, container: EncoderKeyedContainerContainer, nestedPath: [CodingKey])
    
    // methods
    
    var usesStringValue: Bool {get}
    
    var codingPath: [CodingKey] {get}
    func currentPath(_ key: CodingKey) -> [CodingKey]
    
    func _key(from key: CodingKey) -> AnyHashable
    func set(_ encoded: Any, forKey key: CodingKey)
    
    // encode
    
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
    
    // containers
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey>
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer
    mutating func superEncoder() -> Encoder
    mutating func superEncoder(forKey key: Key) -> Encoder
}

public extension EncoderKeyedContainer {
    
    public var usesStringValue: Bool {
        return type(of: self.encoder).usesStringValue
    }
    
    public var codingPath: [CodingKey] {
        return self.encoder.codingPath + self.nestedPath
    }
    
    public func currentPath(_ key: CodingKey) -> [CodingKey] {
        return self.codingPath + [key]
    }
    
    public func _key(from key: CodingKey) -> AnyHashable {
        
        if self.usesStringValue {
            
            return key.stringValue
            
        } else {
            
            guard key.intValue != nil else {
                fatalError("Tried to get \(type(of: key)): \(key) .intValue, but found nil.")
            }
            
            return key.intValue!
        }
    }
    
    public func set(_ encoded: Any, forKey key: CodingKey) {
        
        self.container.setToStorage(encoded, forKey: self._key(from: key))
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
    
    // containers
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        
        let container = self.encoder.keyedContainerContainer()
        
        self.set(container, forKey: key)
        
        return self.encoder.keyedContainer(
            encoder: self.encoder,
            container: container,
            nestedPath: self.nestedPath + [key]
        )
    }
    
    public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {

        let container = self.encoder.unkeyedContainerContainer()

        self.set(container, forKey: key)
        
        return self.encoder.unkeyedContainer(
            encoder: self.encoder,
            container: container,
            nestedPath: self.nestedPath + [key]
        )
    }
    
    private func _superEncoder(forKey key: CodingKey) -> Encoder {
        
        return type(of: self.encoder).init(
            codingPath: self.currentPath(key),
            untypedOptions: self.encoder.untypedOptions,
            userInfo: self.encoder.userInfo,
            reference: .keyed(self.container, key: self._key(from: key))
        )
    }

    public mutating func superEncoder() -> Encoder {
        return self._superEncoder(forKey: CodingSuperKey())
    }

    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return self._superEncoder(forKey: key)
    }
}

// MARK: UnkeyedContainer

public protocol EncoderUnkeyedContainerContainer: class {
    
    var count: Int {get}
    func setToStorage(_ value: Any)
    func replaceObject(at index: Int, with object: Any)
}

extension NSMutableArray: EncoderUnkeyedContainerContainer {
    public func setToStorage(_ value: Any) {
        self.add(value)
    }
}

public protocol EncoderUnkeyedContainer : UnkeyedEncodingContainer {
    
    // required methods
    
    var encoder: AnyEncoderBase {get}
    var container: EncoderUnkeyedContainerContainer {get}
    var nestedPath: [CodingKey] {get}
    
    init(encoder: AnyEncoderBase, container: EncoderUnkeyedContainerContainer, nestedPath: [CodingKey])
    
    // methods
    
    /// The path of coding keys taken to get to this point in encoding.
    var codingPath: [CodingKey] {get}
    var currentPath: [CodingKey] {get}
    
    /// The number of elements encoded into the container.
    var count: Int {get}
    var currentIndex: Int {get}
    var currentKey: CodingKey {get}
    
    func set(_ encoded: Any)
    
    // encode
    
    mutating func encodeNil(            ) throws
    mutating func encode(_ value: Bool  ) throws
    mutating func encode(_ value: Int   ) throws
    mutating func encode(_ value: Int8  ) throws
    mutating func encode(_ value: Int16 ) throws
    mutating func encode(_ value: Int32 ) throws
    mutating func encode(_ value: Int64 ) throws
    mutating func encode(_ value: UInt  ) throws
    mutating func encode(_ value: UInt8 ) throws
    mutating func encode(_ value: UInt16) throws
    mutating func encode(_ value: UInt32) throws
    mutating func encode(_ value: UInt64) throws
    mutating func encode(_ value: Float ) throws
    mutating func encode(_ value: Double) throws
    mutating func encode(_ value: String) throws
    mutating func encode<T: Encodable>(_ value: T) throws
    
    // containers
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer
    mutating func superEncoder() -> Encoder
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
        return CodingIndexKey(intValue: self.currentIndex)
    }
    
    public func set(_ encoded: Any) {
        
        self.container.setToStorage(encoded)
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
    public mutating func encode(_ value: Float ) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: Double) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode(_ value: String) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    public mutating func encode<T: Encodable>(_ value: T) throws { self.set(try self.encoder.box(value, at: self.currentPath)) }
    
    // MARK: containers
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        
        let container = self.encoder.keyedContainerContainer()
        
        self.set(container)
    
        return self.encoder.keyedContainer(
            encoder: self.encoder,
            container: container,
            nestedPath: self.nestedPath + [self.currentKey]
        )
    }
    
    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        
        let container = self.encoder.unkeyedContainerContainer()
        
        self.set(container)
        
        return Self.init(
            encoder: self.encoder,
            container: container,
            nestedPath: self.nestedPath + [self.currentKey]
        )
    }

    public mutating func superEncoder() -> Encoder {

        defer { self.set("placeholder") }
        
        return type(of: self.encoder).init(
            codingPath: self.currentPath,
            untypedOptions: self.encoder.untypedOptions,
            userInfo: self.encoder.userInfo,
            reference: .unkeyed(self.container, index: self.currentIndex)
        )
    }
}

// MARK: Temporary encoding workarounds

// FIXME: remove when SR-5206 is fixed
func assertTypeIsEncodable(_ _type: Any.Type, in wrappingType: Any.Type) {
    guard _type is Encodable.Type else {
        if _type == Encodable.self || _type == Codable.self {
            preconditionFailure("\(wrappingType) does not conform to Encodable because Encodable does not conform to itself. You must use a concrete type to encode or decode.")
        } else {
            preconditionFailure("\(wrappingType) does not conform to Encodable because \(_type) does not conform to Encodable.")
        }
    }
}

// FIXME: Remove when conditional conformance is available.
extension Encodable {
    func __encode(to container: inout SingleValueEncodingContainer) throws { try container.encode(self) }
    func __encode(to container: inout UnkeyedEncodingContainer)     throws { try container.encode(self) }
    func __encode<Key>(to container: inout KeyedEncodingContainer<Key>, forKey key: Key) throws { try container.encode(self, forKey: key) }
}
// end remove

protocol BrokenEncode {
    
    func __encode(to encoder: Encoder) throws
}

extension Optional: BrokenEncode {
    
    func __encode(to encoder: Encoder) throws {
        assertTypeIsEncodable(Wrapped.self, in: Optional.self)
        
        var container = encoder.singleValueContainer()
        switch self {
        case .none: try container.encodeNil()
        case .some(let wrapped): try (wrapped as! Encodable).__encode(to: &container)
        }
    }
}

extension BrokenEncode where Self: Sequence {
    
    func __encode(to encoder: Encoder) throws {
        assertTypeIsEncodable(Element.self, in: Self.self)
        
        var container = encoder.unkeyedContainer()
        for element in self {
            try (element as! Encodable).__encode(to: &container)
        }
    }
}

extension Array: BrokenEncode {}

extension Set: BrokenEncode {}

extension Dictionary: BrokenEncode {
    
    struct _DictionaryCodingKey : CodingKey {
        let stringValue: String
        let intValue: Int?
        
        init(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = Int(stringValue)
        }
        
        init(intValue: Int) {
            self.stringValue = intValue.description
            self.intValue = intValue
        }
    }
    
    func __encode(to encoder: Encoder) throws {
        
        assertTypeIsEncodable(Key.self, in: Dictionary.self)
        assertTypeIsEncodable(Value.self, in: Dictionary.self)
        
        switch Key.self {
            
        case is String.Type:
            var container = encoder.container(keyedBy: _DictionaryCodingKey.self)
            for (key, value) in self {
                try (value as! Encodable).__encode(to: &container, forKey: _DictionaryCodingKey(stringValue: key as! String))
            }
            
        case is Int.Type:
            var container = encoder.container(keyedBy: _DictionaryCodingKey.self)
            for (key, value) in self {
                try (value as! Encodable).__encode(to: &container, forKey: _DictionaryCodingKey(intValue: key as! Int))
            }
            
        default:
            var container = encoder.unkeyedContainer()
            for (key, value) in self {
                try (key as! Encodable).__encode(to: &container)
                try (value as! Encodable).__encode(to: &container)
            }
        }
    }
}
// end remove















