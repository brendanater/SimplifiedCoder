//
//  Decoder.swift
//  SimplifiedCoder
//
//  Created by Christopher Bryan Henderson on 8/27/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import Foundation

protocol TopLevelDecoder {
    
    func decode<T: Decodable>(_: T.Type, from data: Data) throws -> T
    func decode<T: Decodable>(_: T.Type, from value: Any) throws -> T
}

struct NumberLossyConversionStrategy: OptionSet {
    
    let rawValue: Int
    
    static let dontAllow = NumberLossyConversionStrategy(rawValue: 0)
    /// use Number.init(NSNumber)
    static let initNSNumber = NumberLossyConversionStrategy(rawValue: 1)
    /// use Number.init(clamping: Int or UInt)
    /// float and double default to init(NSNumber)
    static let clampingIntegers = NumberLossyConversionStrategy(rawValue: 2)
    /// use Number.init(truncating: NSNumber)
    static let truncating = NumberLossyConversionStrategy(rawValue: 3)

}

//extension JSONDecoder {
//    typealias _Options2 = (
//        dateDecodingStrategy: DateDecodingStrategy,
//        dataDecodingStrategy: DataDecodingStrategy,
//        nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy,
//        numberLossyConversionStrategy: NumberLossyConversionStrategy,
//        stringDefaultsToDescription: Bool
//    )
//}


/// must be a class, so that references reference the same decoder
protocol DecoderBase: class, Decoder, SingleValueDecodingContainer {
    
    associatedtype KeyedContainer: DecoderKeyedContainer
    associatedtype UnkeyedContainer: DecoderUnkeyedContainer
    associatedtype Options
    
    var storage: [Any] {get set}
    var options: Options {get}
    var codingPath: [CodingKey] {get set}
    var userInfo: [CodingUserInfoKey : Any] {get}
    
    // storage = [value] at start
    init(value: Any, codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any])
}

extension DecoderBase {
    
    // MARK: decode single value
    
    var stringDefaultsToDescription: Bool {
        return true
    }
    
    func decodeNil() -> Bool {
        return isNil(storage.last)
    }
    
    /// casts an error to the right codingPath and type
    func error(_ error: Error, at codingPath: [CodingKey]) -> Error {
        
        if let error = error as? UnboxError {
            return error.asDecodingError(with: codingPath)
        } else if error is DecodingError {
            return error
        } else if error is DecodeError {
            return error
        } else {
            return DecodeError.decodeError(error, atPath: codingPath)
        }
    }
    
    func decode<T>(with unbox: (Any)throws->T) throws -> T {
        
        do {
            return try unbox(storage.last!)
            
        } catch {
            throw self.error(error, at: codingPath)
        }
    }
    
    public func decode(_: Bool.Type  ) throws -> Bool   { return try decode(with: unbox(_:)) }
    public func decode(_: Int.Type   ) throws -> Int    { return try decode(with: unbox(_:)) }
    public func decode(_: Int8.Type  ) throws -> Int8   { return try decode(with: unbox(_:)) }
    public func decode(_: Int16.Type ) throws -> Int16  { return try decode(with: unbox(_:)) }
    public func decode(_: Int32.Type ) throws -> Int32  { return try decode(with: unbox(_:)) }
    public func decode(_: Int64.Type ) throws -> Int64  { return try decode(with: unbox(_:)) }
    public func decode(_: UInt.Type  ) throws -> UInt   { return try decode(with: unbox(_:)) }
    public func decode(_: UInt8.Type ) throws -> UInt8  { return try decode(with: unbox(_:)) }
    public func decode(_: UInt16.Type) throws -> UInt16 { return try decode(with: unbox(_:)) }
    public func decode(_: UInt32.Type) throws -> UInt32 { return try decode(with: unbox(_:)) }
    public func decode(_: UInt64.Type) throws -> UInt64 { return try decode(with: unbox(_:)) }
    public func decode(_: Float.Type ) throws -> Float  { return try decode(with: unbox(_:)) }
    public func decode(_: Double.Type) throws -> Double { return try decode(with: unbox(_:)) }
    public func decode(_: String.Type) throws -> String { return try decode(with: unbox(_:)) }
    public func decode<T: Decodable>(_: T.Type)throws->T{ return try decode(with: unbox(_:)) }
    
    // MARK: unbox
    
    func notFound<T>(_ type: T.Type, _ typeDescription: String? = nil) -> UnboxError {
        
        let typeDescription = typeDescription ?? "\(T.self)"
        
        return UnboxError.valueNotFound(
            type,
            UnboxError.Context(
                debugDescription: "Cannot get \(typeDescription) -- found null value instead."
            )
        )
    }
    
    func typeError<T>(_ value: Any, _ type: T.Type, _ typeDescription: String? = nil) -> UnboxError {
        
        let typeDescription = typeDescription ?? "\(T.self)"
        
        return UnboxError.typeMismatch(
            type,
            UnboxError.Context(
                debugDescription: "Expected to decode \(typeDescription), but found \(value)"
            )
        )
    }
    
    /// an error to throw if unboxing fails
    func failedToUnbox<T>(_ value: Any, to type: T.Type, _ typeDescription: String? = nil) -> UnboxError {
        
        if isNil(value) {
            return notFound(type, typeDescription)
        } else {
            return typeError(value, type, typeDescription)
        }
    }
    
    func corrupted(_ debugDescription: String) -> UnboxError {
        
        return UnboxError.dataCorrupted(
            UnboxError.Context(
                debugDescription: debugDescription
            )
        )
    }
    
    func convert<T: ConvertibleNumber>(number value: Any) throws -> T {
        
        if let number = value as? T {
            return number
            
        } else if let number = value as? NSNumber ?? NumberFormatter.shared.number(from: value as? String ?? "˜∆åƒ˚")  {
            
            if let number = T(exactly: number) {
                return number
            }
        }
        
        throw failedToUnbox(value, to: T.self)
    }
    
    func unbox(_ value: Any) throws -> Bool { return value as? Bool ?? isNil(value) }
    
    func unbox(_ value: Any) throws -> Int    { return try convert(number: value) }
    func unbox(_ value: Any) throws -> Int8   { return try convert(number: value) }
    func unbox(_ value: Any) throws -> Int16  { return try convert(number: value) }
    func unbox(_ value: Any) throws -> Int32  { return try convert(number: value) }
    func unbox(_ value: Any) throws -> Int64  { return try convert(number: value) }
    func unbox(_ value: Any) throws -> UInt   { return try convert(number: value) }
    func unbox(_ value: Any) throws -> UInt8  { return try convert(number: value) }
    func unbox(_ value: Any) throws -> UInt16 { return try convert(number: value) }
    func unbox(_ value: Any) throws -> UInt32 { return try convert(number: value) }
    func unbox(_ value: Any) throws -> UInt64 { return try convert(number: value) }
    func unbox(_ value: Any) throws -> Float  { return try convert(number: value) }
    func unbox(_ value: Any) throws -> Double { return try convert(number: value) }
    
    func unbox(_ value: Any) throws -> String {
        
        if let string = value as? String {
            return string
            
        } else if stringDefaultsToDescription {
            return "\(value)"
        }
        
        throw failedToUnbox(value, to: String.self)
    }
    
    func unbox<T : Decodable>(_ value: Any) throws -> T {
        return try redecode(value)
//        switch T.self {
//        default: return try redecode(value)
//        }
    }
    
    func redecode<T: Decodable>(_ value: Any) throws -> T {
        
        // use this value to decode from (same as creating a new decoder)
        self.storage.append(value)
        let decoded = try T(from: self)
        // not decoding with this value anymore (same as manually deinitializing the new decoder)
        self.storage.removeLast()
        return decoded
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
    
}

extension DecoderBase where KeyedContainer.Base == Self {

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {

        let value = storage.last as Any

        guard let container = value as? NSDictionary else {
            throw failedToUnbox(value, to: KeyedDecodingContainer<Key>.self, "keyed container")
                .asDecodingError(with: codingPath)
        }
        
        return KeyedContainer.initSelf(
            decoder: self,
            container: container,
            nestedPath: [],
            keyedBy: Key.self
        )
    }
}

extension DecoderBase where UnkeyedContainer.Base == Self {

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {

        let value = storage.last as Any

        guard let container = value as? NSArray else {
            throw failedToUnbox(value, to: UnkeyedDecodingContainer.self, "unkeyed container")
                .asDecodingError(with: codingPath)
        }

        return UnkeyedContainer(
            decoder: self,
            container: container,
            nestedPath: []
        )
    }
}

// MARK: KeyedContainer

protocol DecoderKeyedContainer: KeyedDecodingContainerProtocol {
    
    associatedtype UnkeyedContainer: DecoderUnkeyedContainer
    associatedtype Base: DecoderBase
    
    var decoder: Base {get}
    var container: NSDictionary {get}
    var nestedPath: [CodingKey] {get}
    
    init(decoder: Base, container: NSDictionary, nestedPath: [CodingKey])
    
    static func initSelf<Key: CodingKey>(decoder: Base, container: NSDictionary, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedDecodingContainer<Key>
    
    static var usesStringValue: Bool {get}
    
}

extension DecoderKeyedContainer {
    
    public var codingPath: [CodingKey] {
        return decoder.codingPath + nestedPath
    }
    
    public var allKeys: [Key] {
        return self.container.allKeys.flatMap {
            
            if Self.usesStringValue, let string = $0 as? String {
                return Key(stringValue: string)
                
            } else if let int = $0 as? Int {
                return Key(intValue: int)
                
            } else {
                return nil
            }
        }
    }
    
    func _key(from key: CodingKey) -> Any {
        
        if Self.usesStringValue {
            return key.stringValue
            
        } else {
            precondition(key.intValue != nil, "Tried to get intValue for key: \(key) in KeyedDecodingContainer<\(Key.self)>, but found nil.")
            return key.intValue!
        }
    }
    
    func value(forKey key: CodingKey) throws -> Any {
        
        let _key = self._key(from: key)
        
        guard let value = self.container[_key] else {
            throw DecodingError.keyNotFound(
                key,
                DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "No value found for key \(key) (\(_key))."
                )
            )
        }
        
        return value
    }
    
    public func contains(_ key: Key) -> Bool {
        
        return container[_key(from: key)] != nil
    }
    
    public func decodeNil(forKey key: Key) throws -> Bool {
        
        return try isNil(value(forKey: key))
    }
    
    func decode<T>(with unbox: (Any)throws->T, forKey key: Key) throws -> T {
        
        do {
            return try unbox(value(forKey: key))
        } catch {
            throw decoder.error(error, at: codingPath + [key])
        }
    }
    
    public func decode(_ type: Bool.Type  , forKey key: Key) throws -> Bool   { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Int.Type   , forKey key: Key) throws -> Int    { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Int8.Type  , forKey key: Key) throws -> Int8   { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Int16.Type , forKey key: Key) throws -> Int16  { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Int32.Type , forKey key: Key) throws -> Int32  { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Int64.Type , forKey key: Key) throws -> Int64  { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: UInt.Type  , forKey key: Key) throws -> UInt   { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: UInt8.Type , forKey key: Key) throws -> UInt8  { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Float.Type , forKey key: Key) throws -> Float  { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode(_ type: String.Type, forKey key: Key) throws -> String { return try decode(with: decoder.unbox(_:), forKey: key) }
    public func decode<T: Decodable>(_ type: T.Type, forKey key: Key)throws->T{ return try decode(with: decoder.unbox(_:), forKey: key) }
    
    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {

        let value = try self.value(forKey: key)

        guard let container = value as? NSDictionary else {
            throw decoder.failedToUnbox(value, to: KeyedDecodingContainer<NestedKey>.self, "nested keyed container")
                .asDecodingError(with: codingPath + [key])
        }
        
        return Self.initSelf(decoder: decoder, container: container, nestedPath: nestedPath + [key], keyedBy: NestedKey.self)
    }
    
    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {

        let value = try? self.value(forKey: key)

        return Base(
            value: value ?? NSNull(),
            codingPath: codingPath + [key],
            options: decoder.options,
            userInfo: decoder.userInfo
        )
    }

    public func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: "super")
    }

    public func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}

extension DecoderKeyedContainer where UnkeyedContainer.Base == Self.Base {
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {

        let value = try self.value(forKey: key)

        guard let container = value as? NSArray else {
            throw decoder.failedToUnbox(value, to: UnkeyedDecodingContainer.self, "nested unkeyed container")
                .asDecodingError(with: codingPath + [key])
        }

        return UnkeyedContainer(
            decoder: decoder,
            container: container,
            nestedPath: nestedPath + [key]
        )
    }
}

// MARK: UnkeyedContainer

protocol DecoderUnkeyedContainer: UnkeyedDecodingContainer {
    
    associatedtype KeyedContainer: DecoderKeyedContainer
    associatedtype Base: DecoderBase
    
    var decoder: Base {get}
    var container: NSArray {get}
    var nestedPath: [CodingKey] {get}
    
    init(decoder: Base, container: NSArray, nestedPath: [CodingKey])
    
    var currentIndex: Int {get set}
}

extension DecoderUnkeyedContainer {
    
    public var codingPath: [CodingKey] {
        
        return decoder.codingPath + nestedPath
    }
    
    public var count: Int? {
        
        return self.container.count
    }
    
    public var isAtEnd: Bool {
        
        return currentIndex >= container.count
    }
    
    public mutating func decodeNil() throws -> Bool {
        
        // will decode a null value, be sure to increment path.
        // it shouldn't matter to add to currentIndex greater than count
        defer { self.currentIndex += 1 }
        
        return self.isAtEnd || isNil(container[currentIndex])
    }
    
    var currentKey: CodingKey {
        
        return "index \(currentIndex)"
    }
    
    /// gets the next value if not at end or throws valueNotFound(type, context)
    /// increments currentIndex
    mutating func next<T>(_ type: T.Type, _ typeDescription: String? = nil) throws -> Any {
        
        if isAtEnd {
            
            let typeDescription = typeDescription ?? "\(type)"
            
            throw DecodingError.valueNotFound(
                type,
                DecodingError.Context(
                    codingPath: codingPath + [currentKey],
                    debugDescription: "Cannot get \(typeDescription) -- Unkeyed container is at end."
                )
            )
        }
        
        // avoid this pitfall, isAtEnd is/should be/will be called before decoding a value, so, isAtEnd must be correct before calling next
        
        defer { currentIndex += 1 }
        
        return container[currentIndex]
    }
    
    mutating func decode<T>(with unbox: (Any)throws->T) throws -> T {
        
        do {
            return try unbox(next(T.self))
        } catch {
            throw decoder.error(error, at: codingPath + [currentKey])
        }
    }
    
    public mutating func decode(_ type: Bool.Type  ) throws -> Bool   { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: Int.Type   ) throws -> Int    { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: Int8.Type  ) throws -> Int8   { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: Int16.Type ) throws -> Int16  { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: Int32.Type ) throws -> Int32  { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: Int64.Type ) throws -> Int64  { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: UInt.Type  ) throws -> UInt   { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: UInt8.Type ) throws -> UInt8  { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: UInt16.Type) throws -> UInt16 { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: UInt32.Type) throws -> UInt32 { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: UInt64.Type) throws -> UInt64 { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: Float.Type ) throws -> Float  { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: Double.Type) throws -> Double { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode(_ type: String.Type) throws -> String { return try decode(with: decoder.unbox(_:)) }
    public mutating func decode<T: Decodable>(_ type: T.Type)throws->T{ return try decode(with: decoder.unbox(_:)) }
    
    
    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {

        let value = try next(UnkeyedDecodingContainer.self, "nested unkeyed container")

        guard let container = value as? NSArray else {
            throw decoder.failedToUnbox(value, to: UnkeyedDecodingContainer.self, "nested unkeyed container")
                .asDecodingError(with: codingPath + [currentKey])
        }

        return Self.init(
            decoder: decoder,
            container: container,
            nestedPath: nestedPath + [currentKey]
        )
    }
    
    mutating func superDecoder() throws -> Decoder {
        
        return try Base(
            value: next(Decoder.self, "value for super decoder"),
            codingPath: codingPath + ["super: \(currentKey)"],
            options: decoder.options,
            userInfo: decoder.userInfo
        )
    }
}

extension DecoderUnkeyedContainer where KeyedContainer.Base == Self.Base {
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {

        let value = try next(KeyedDecodingContainer<NestedKey>.self, "nested keyed container")

        guard let container = value as? NSDictionary else {
            throw decoder.failedToUnbox(value, to: KeyedDecodingContainer<NestedKey>.self, "nested keyed container")
                .asDecodingError(with: codingPath + [currentKey])
        }

        return KeyedContainer.initSelf(
            decoder: decoder,
            container: container,
            nestedPath: nestedPath + [currentKey],
            keyedBy: NestedKey.self
        )
    }
}

/// a wrapping error to associate a path with an unknown unbox error
enum DecodeError: Error {
    case decodeError(Error, atPath: [CodingKey])
    var error: Error {
        switch self {
        case .decodeError(let error, atPath: _): return error
        }
    }
    var codingPath: [CodingKey] {
        switch self {
        case .decodeError(_, atPath: let codingPath): return codingPath
        }
    }
}

/// a type that can be converted to the associated DecodingError later with a codingPath
enum UnboxError: Error {
    
    struct Context {
        var debugDescription: String
        var underlyingError: Error?
        
        init(debugDescription: String, underlyingError: Error? = nil) {
            
            self.debugDescription = debugDescription
            self.underlyingError = underlyingError
        }
        
        func asDecodingErrorContext(with codingPath: [CodingKey]) -> DecodingError.Context {
            return DecodingError.Context(codingPath: codingPath, debugDescription: debugDescription, underlyingError: underlyingError)
        }
    }
    
    case valueNotFound(Any.Type, Context)
    case typeMismatch(Any.Type, Context)
    case dataCorrupted(Context)
    
    func asDecodingError(with codingPath: [CodingKey]) -> DecodingError {
        switch self {
        case .valueNotFound(let type, let context):
            return DecodingError.valueNotFound(type, context.asDecodingErrorContext(with: codingPath))
        case .typeMismatch(let type, let context):
            return DecodingError.typeMismatch(type, context.asDecodingErrorContext(with: codingPath))
        case .dataCorrupted(let context):
            return DecodingError.dataCorrupted(context.asDecodingErrorContext(with: codingPath))
        }
    }
}

protocol ConvertibleNumber {
    init?(exactly: NSNumber)
    init(truncating: NSNumber)
    init(_ value: NSNumber)
}

protocol ConvertibleInteger: ConvertibleNumber {
    init(clamping: Int)
    init(clamping: UInt)
}

extension Int   : ConvertibleInteger {}
extension Int8  : ConvertibleInteger {}
extension Int16 : ConvertibleInteger {}
extension Int32 : ConvertibleInteger {}
extension Int64 : ConvertibleInteger {}
extension UInt  : ConvertibleInteger {}
extension UInt8 : ConvertibleInteger {}
extension UInt16: ConvertibleInteger {}
extension UInt32: ConvertibleInteger {}
extension UInt64: ConvertibleInteger {}
extension Float : ConvertibleNumber {}
extension Double: ConvertibleNumber {}

protocol CanBeNil {
    var isNil: Bool {get}
}

extension NSNull: CanBeNil { var isNil: Bool { return true } }
extension Optional: CanBeNil {
    var isNil: Bool {
        if case .some(let wrapped) = self {
            if let canBeNil = wrapped as? CanBeNil {
                return canBeNil.isNil
            } else {
                return false
            }
        } else {
            return true
        }
    }
}

func isNil(_ value: Any?) -> Bool {
    return value.isNil
}

extension NumberFormatter {
    static var shared = NumberFormatter()
}

extension ISO8601DateFormatter {
    static let shared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        return formatter
    }()
}


