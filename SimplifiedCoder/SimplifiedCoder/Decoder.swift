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

extension JSONDecoder {
    typealias _Options2 = (
        dateDecodingStrategy: DateDecodingStrategy,
        dataDecodingStrategy: DataDecodingStrategy,
        nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy,
        numberLossyConversionStrategy: NumberLossyConversionStrategy,
        stringDefaultsToDescription: Bool
    )
}


class Base2 : Decoder {
    // MARK: Properties
    /// The decoder's storage.
    var storage: [Any]
    
    typealias KeyedContainerType = KeyedContainer2
    typealias UnkeyedContainerType = UnkeyedContainer2
    
    typealias Options = JSONDecoder._Options2
    
    /// Options set on the top-level decoder.
    let options: Options
    
    /// The path to the current point in encoding.
    private(set) public var codingPath: [CodingKey] = []
    
    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any]
    
    // MARK: - Initialization
    /// Initializes `self` with the given top-level container and options.
    init(value: Any, codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any]) {
        
        self.storage = [value]
        self.codingPath = codingPath
        self.options = options
        self.userInfo = userInfo
    }
    
    // MARK: - Decoder Methods
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        
        return try KeyedDecodingContainer(
            KeyedContainerType<Key>(
                decoder: self,
                value: storage.last as Any,
                nestedPath: []
            )
        )
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        return try UnkeyedContainerType(
            decoder: self,
            value: storage.last as Any,
            nestedPath: []
        )
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

extension Base2 : SingleValueDecodingContainer {
    // MARK: SingleValueDecodingContainer Methods
    
    public func decodeNil() -> Bool {
        return isNil(storage.last)
    }
 
    /// casts an error to the right type or delegates the error at the codingPath
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
    public func decode<T: Decodable>(_: T.Type) throws -> T { return try decode(with: unbox(_:)) }
}

// unboxing
extension Base2 {
    
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
            
            switch options.numberLossyConversionStrategy {
                
            case .dontAllow:
                break
                
            case .initNSNumber:
                return T(number)
                
            case .clampingIntegers:
                if let type = T.self as? ConvertibleInteger.Type {
                    if number.intValue < 0 {
                        return type.init(clamping: number.intValue) as! T
                    } else {
                        return type.init(clamping: number.uintValue) as! T
                    }
                } else {
                    return T(number)
                }
                
            case .truncating:
                return T(truncating: number)
                
            default: fatalError("Unknown \(NumberLossyConversionStrategy.self) override \(Base2.self).convert(number:)")
                
            }
        }
        
        throw failedToUnbox(value, to: T.self)
    }
    
    func getFloatDecodingStrategy() -> (pos: String, neg: String, nan: String)? {
        if case .convertFromString(
            positiveInfinity: let pos,
            negativeInfinity: let neg,
            nan: let nan
            ) = options.nonConformingFloatDecodingStrategy {
            return (pos, neg, nan)
        } else {
            return nil
        }
    }
    
    func convert(double value: Any) throws -> Double {
        do {
            return try convert(number: value)
        } catch {
            
            if let string = value as? String, let (pos, neg, nan) = getFloatDecodingStrategy() {
                switch string {
                case pos: return Double.infinity
                case neg: return -Double.infinity
                case nan: return Double.nan
                default: throw error
                }
            } else {
                throw error
            }
        }
    }
    
    func convert(float value: Any) throws -> Float {
        do {
            return try convert(number: value)
        } catch {
            
            if let string = value as? String, let (pos, neg, nan) = getFloatDecodingStrategy() {
                switch string {
                case pos: return Float.infinity
                case neg: return -Float.infinity
                case nan: return Float.nan
                default: throw error
                }
            } else {
                throw error
            }
        }
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
    func unbox(_ value: Any) throws -> Float  { return try convert(float : value) }
    func unbox(_ value: Any) throws -> Double { return try convert(double: value) }
    
    func unbox(_ value: Any) throws -> String {
        
        if let string = value as? String {
            return string
            
        } else if options.stringDefaultsToDescription {
            return "\(value)"
        }
        
        throw failedToUnbox(value, to: String.self)
    }
    
    
    /// unbox Date uses other unbox functions to get value
    func unbox(_ value: Any) throws -> Date {
        
        switch options.dateDecodingStrategy {
            
        case .deferredToDate:
            storage.append(value)
            let date = try Date(from: self)
            storage.removeLast()
            return date
            
        case .secondsSince1970:
            return try Date(timeIntervalSince1970: unbox(value))
            
        case .millisecondsSince1970:
            return try Date(timeIntervalSince1970: unbox(value) / 1000.0)
            
        case .iso8601:
            if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                guard let date = try ISO8601DateFormatter.shared.date(from: unbox(value) as String) else {
                    throw corrupted("Expected date string to be ISO8601-formatted.")
                }
                return date
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }
            
        case .formatted(let formatter):
            guard let date = try formatter.date(from: unbox(value) as String) else {
                throw corrupted("Date string does not match format expected by formatter.")
            }
            return date
            
        case .custom(let closure):
            storage.append(value)
            let date = try closure(self)
            storage.removeLast()
            return date
        }
    }
    
    func unbox(_ value: Any) throws -> Data {
        
        switch self.options.dataDecodingStrategy {
        case .deferredToData:
            self.storage.append(value)
            let data = try Data(from: self)
            self.storage.removeLast()
            return data
            
        case .base64:
            guard let data = try Data(base64Encoded: unbox(value) as String) else {
                throw corrupted("Encountered Data is not valid Base64.")
            }
            
            return data
            
        case .custom(let closure):
            self.storage.append(value)
            let data = try closure(self)
            self.storage.removeLast()
            return data
        }
    }
    
    func unbox(_ value: Any) throws -> Decimal {
        
        // Attempt to bridge from NSDecimalNumber.
        if let decimal = value as? Decimal {
            return decimal
        } else {
            return try Decimal(unbox(value) as Double)
        }
    }
    
    func unbox(_ value: Any) throws -> URL {
        
        guard let url = try URL(string: unbox(value)) else {
            throw corrupted("Invalid url string.")
        }
        
        return url
    }
    
    func unbox<T : Decodable>(_ value: Any) throws -> T {
        
        switch T.self {
        case is Date.Type:    return try unbox(value) as Date    as! T
        case is Data.Type:    return try unbox(value) as Data    as! T
        case is URL.Type:     return try unbox(value) as URL     as! T
        case is Decimal.Type: return try unbox(value) as Decimal as! T
        default: return try redecode(value)
        }
    }
    
    func redecode<T: Decodable>(_ value: Any) throws -> T {
        
        // use this value to decode from (same as creating a new decoder)
        self.storage.append(value)
        let decoded = try T(from: self)
        // not decoding with this value anymore (same as manually deinitializing the new decoder)
        self.storage.removeLast()
        return decoded
    }
}

// MARK: Decoding Containers
struct KeyedContainer2<K : CodingKey> : KeyedDecodingContainerProtocol {
    typealias Key = K
    
    typealias UnkeyedContainerType = UnkeyedContainer
    
    typealias BaseDecoder = Base2
    
    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: BaseDecoder
    
    /// A reference to the container we're reading from.
    private let container: NSDictionary
    
    /// The path of coding keys taken to get to this point in decoding.
    public var codingPath: [CodingKey] {
        return decoder.codingPath + nestedPath
    }
    
    let nestedPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    init(decoder: BaseDecoder, value: Any, nestedPath: [CodingKey]) throws {
        
        guard let dictionary = value as? NSDictionary else {
            throw decoder.failedToUnbox(value, to: KeyedDecodingContainer<K>.self, "keyed decoding container")
                .asDecodingError(with: decoder.codingPath + nestedPath)
        }
        
        self.decoder = decoder
        self.container = dictionary
        self.nestedPath = nestedPath
    }
    
    static var usesStringValue: Bool {
        return true
    }
    
    public var allKeys: [Key] {
        return self.container.allKeys.flatMap {
            
            if KeyedContainer2.usesStringValue, let string = $0 as? String {
                return Key(stringValue: string)
                
            } else if let int = $0 as? Int {
                return Key(intValue: int)
                
            } else {
                return nil
            }
        }
    }
    
    func _key(from key: CodingKey) -> Any {
        
        if KeyedContainer2.usesStringValue {
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
    
    public func decode<T : Decodable>(_ type: T.Type, forKey key: Key) throws -> T { return try decode(with: decoder.unbox(_:), forKey: key) }
    
    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        
        return try KeyedDecodingContainer(
            KeyedContainer2<NestedKey>(
                decoder: decoder,
                value: value(forKey: key),
                nestedPath: nestedPath + [key]
            )
        )
    }
    
    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        
        return try UnkeyedContainer2(
            decoder: self.decoder,
            value: value(forKey: key),
            nestedPath: nestedPath + [key]
        )
    }
    
    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        
        let value = try? self.value(forKey: key)
        
        return BaseDecoder(
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


struct UnkeyedContainer2 : UnkeyedDecodingContainer {
    // MARK: Properties
    
    typealias BaseDecoder = Base2
    
    typealias KeyedContainerType = KeyedContainer2
    
    /// A reference to the container we're reading from.
    private let container: NSArray
    
    /// A reference to the decoder we're reading from.
    private let decoder: BaseDecoder
    
    /// The path of coding keys taken to get to this point in decoding.
    public var codingPath: [CodingKey] {
        return decoder.codingPath + nestedPath
    }
    
    /// The index of the element we're decoding.
    // must call next(for:) before using
    private(set) public var currentIndex = 0
    
    let nestedPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    init(decoder: BaseDecoder, value: Any, nestedPath: [CodingKey]) throws {
        
        guard let container = value as? NSArray else {
            throw decoder.failedToUnbox(value, to: UnkeyedDecodingContainer.self, "unkeyed decoding container")
                .asDecodingError(with: decoder.codingPath + nestedPath)
        }
        
        self.decoder = decoder
        self.container = container
        self.nestedPath = nestedPath
    }
    
    // MARK: - UnkeyedDecodingContainer Methods
    public var count: Int? {
        return self.container.count
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
        
        // avoid this pitfall, isAtEnd is/should be/will be called before decoding a value, so, isAtEnd must be correct before getting next
        
        defer { currentIndex += 1 }
        
        return container[currentIndex]
    }
    
    public var isAtEnd: Bool {
        
        return currentIndex >= container.count
    }
    
    public mutating func decodeNil() throws -> Bool {
        
        return self.isAtEnd || isNil(container[currentIndex])
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
    public mutating func decode<T : Decodable>(_ type: T.Type) throws -> T { return try decode(with: decoder.unbox(_:)) }
    
    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        
        return try KeyedDecodingContainer(
            KeyedContainer2<NestedKey>(
                decoder: decoder,
                value: next(KeyedDecodingContainer<NestedKey>.self, "nested keyed container"),
                nestedPath: nestedPath + [currentKey]
            )
        )
    }
    
    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        return try UnkeyedContainer2(
            decoder: decoder,
            value: next(UnkeyedDecodingContainer.self, "nested unkeyed container"),
            nestedPath: nestedPath + [currentKey]
        )
    }
    
    public mutating func superDecoder() throws -> Decoder {
        
        return try BaseDecoder(
            value: next(Decoder.self, "value for super decoder"),
            codingPath: codingPath + ["super: \(currentKey)"],
            options: decoder.options,
            userInfo: decoder.userInfo
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

extension Int: ConvertibleInteger {}
extension Int8: ConvertibleInteger {}
extension Int16: ConvertibleInteger {}
extension Int32: ConvertibleInteger {}
extension Int64: ConvertibleInteger {}
extension UInt: ConvertibleInteger {}
extension UInt8: ConvertibleInteger {}
extension UInt16: ConvertibleInteger {}
extension UInt32: ConvertibleInteger {}
extension UInt64: ConvertibleInteger {}
extension Float: ConvertibleNumber {}
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




