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
    /// use init(NSNumber)
    static let initNSNumber = NumberLossyConversionStrategy(rawValue: 1)
    /// use init(clamping: Int or UInt)
    /// float and double default to init(NSNumber)
    static let clampingIntegers = NumberLossyConversionStrategy(rawValue: 2)
    /// use init(truncating: NSNumber)
    static let truncating = NumberLossyConversionStrategy(rawValue: 3)

}

extension JSONDecoder {
    fileprivate typealias _Options = (
        dateDecodingStrategy: DateDecodingStrategy,
        dataDecodingStrategy: DataDecodingStrategy,
        nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy,
        numberLossyConversionStrategy: NumberLossyConversionStrategy,
        stringDefaultsToDescription: Bool
    )
}


fileprivate class _JSONDecoder : Decoder {
    // MARK: Properties
    /// The decoder's storage.
    fileprivate var storage: [Any]
    
    typealias KeyedContainerType = _JSONKeyedDecodingContainer
    typealias UnkeyedContainerType = _JSONUnkeyedDecodingContainer
    
    typealias Options = JSONDecoder._Options
    
    /// Options set on the top-level decoder.
    fileprivate let options: Options
    
    /// The path to the current point in encoding.
    fileprivate(set) public var codingPath: [CodingKey] = []
    
    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any]
    
    // MARK: - Initialization
    /// Initializes `self` with the given top-level container and options.
    fileprivate init(_ value: Any, codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any]) {
        self.storage = [value]
        self.codingPath = codingPath
        self.options = options
        self.userInfo = userInfo
    }
    
    // MARK: - Decoder Methods
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        
        if isNil(storage.last) {
            throw notFound(KeyedDecodingContainer<Key>.self)
        }
        
        guard let topContainer = storage.last as? NSDictionary else {
            throw typeError(NSDictionary.self, storage.last!)
        }
        
        return KeyedDecodingContainer(KeyedContainerType<Key>(decoder: self, container: topContainer, nestedPath: []))
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        
        if isNil(storage.last) {
            throw notFound(UnkeyedDecodingContainer.self)
        }
        
        guard let topContainer = self.storage.last as? NSArray else {
            throw typeError(NSArray.self, storage.last!)
        }
        
        return UnkeyedContainerType(decoder: self, container: topContainer, nestedPath: [])
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

extension _JSONDecoder : SingleValueDecodingContainer {
    // MARK: SingleValueDecodingContainer Methods
    
    public func decodeNil() -> Bool {
        return isNil(storage.last)
    }
    
    public func decode(_: Bool.Type  ) throws -> Bool   { return try unbox(storage.last!) }
    public func decode(_: Int.Type   ) throws -> Int    { return try unbox(storage.last!) }
    public func decode(_: Int8.Type  ) throws -> Int8   { return try unbox(storage.last!) }
    public func decode(_: Int16.Type ) throws -> Int16  { return try unbox(storage.last!) }
    public func decode(_: Int32.Type ) throws -> Int32  { return try unbox(storage.last!) }
    public func decode(_: Int64.Type ) throws -> Int64  { return try unbox(storage.last!) }
    public func decode(_: UInt.Type  ) throws -> UInt   { return try unbox(storage.last!) }
    public func decode(_: UInt8.Type ) throws -> UInt8  { return try unbox(storage.last!) }
    public func decode(_: UInt16.Type) throws -> UInt16 { return try unbox(storage.last!) }
    public func decode(_: UInt32.Type) throws -> UInt32 { return try unbox(storage.last!) }
    public func decode(_: UInt64.Type) throws -> UInt64 { return try unbox(storage.last!) }
    public func decode(_: Float.Type ) throws -> Float  { return try unbox(storage.last!) }
    public func decode(_: Double.Type) throws -> Double { return try unbox(storage.last!) }
    public func decode(_: String.Type) throws -> String { return try unbox(storage.last!) }
    public func decode<T: Decodable>(_: T.Type) throws -> T { return try unbox(storage.last!) }
}

// unboxing
extension _JSONDecoder {
    
    func notFound(_ type: Any.Type, _ debugDescription: String) -> DecodingError {
        
        return DecodingError.valueNotFound(
            type,
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: debugDescription
            )
        )
    }
    
    func notFound(_ type: Any.Type) -> DecodingError {
        
        return notFound(type, "Cannot get \(type) -- found null value instead.")
    }
    
    func typeError(_ type: Any.Type, _ value: Any) -> DecodingError {
        
        return DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }
    
    /// an error to throw if unboxing fails
    func failedToUnbox(_ value: Any, to type: Any.Type) -> DecodingError {
        
        if isNil(value) {
            return notFound(type)
        } else {
            return typeError(type, value)
        }
    }
    
    func corrupted(_ debugDescription: String) -> Error {
        
        return DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: codingPath,
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
                
            default: fatalError("Unknown \(NumberLossyConversionStrategy.self) override \(_JSONDecoder.self).convert(number:)")
                
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
        
        // use this value to decode from
        self.storage.append(value)
        let decoded = try T(from: self)
        // not decoding with this value anymore
        self.storage.removeLast()
        
        return decoded
    }
}

// MARK: Decoding Containers
fileprivate struct _JSONKeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
    typealias Key = K
    
    typealias UnkeyedContainerType = _JSONUnkeyedDecodingContainer
    
    typealias BaseDecoder = _JSONDecoder
    
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
    fileprivate init(decoder: BaseDecoder, container: NSDictionary, nestedPath: [CodingKey]) {
        
        self.decoder = decoder
        self.container = container
        self.nestedPath = nestedPath
    }
    
    public var allKeys: [Key] {
        return self.container.allKeys.flatMap {
            
            // TODO: setup usesStringValue
            Key(stringValue: $0 as! String)
        }
    }
    
    func _key(from key: CodingKey) -> Any {
        
        // TODO: setup usesStringValue
        return key.stringValue
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
            
        } catch let error as DecodingError {
            throw error.setPathIfEqualOrLonger(codingPath + [key])
        } catch let error as DecodeError {
            throw error
        } catch {
            throw DecodeError.decodeError(error, atPath: codingPath + [key])
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
        
        let value = try self.value(forKey: key)
        
        guard let dictionary = value as? NSDictionary else {
            decoder.codingPath.append(contentsOf: nestedPath + [key])
            throw decoder.failedToUnbox(value, to: KeyedDecodingContainer<NestedKey>.self)
        }
        
        let container = _JSONKeyedDecodingContainer<NestedKey>(decoder: self.decoder, container: dictionary, nestedPath: nestedPath + [key])
        return KeyedDecodingContainer(container)
    }
    
    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        
        let value = try self.value(forKey: key)
        
        guard let array = value as? NSArray else {
            decoder.codingPath.append(contentsOf: nestedPath + [key])
            throw decoder.failedToUnbox(value, to: UnkeyedDecodingContainer.self)
        }
        
        return _JSONUnkeyedDecodingContainer(decoder: self.decoder, container: array, nestedPath: nestedPath + [key])
    }
    
    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        
        let value = try? self.value(forKey: key)
        
        return BaseDecoder(value ?? NSNull(), codingPath: codingPath + [key], options: self.decoder.options, userInfo: decoder.userInfo)
    }
    
    public func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: "super")
    }
    
    public func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}


fileprivate struct _JSONUnkeyedDecodingContainer : UnkeyedDecodingContainer {
    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: BaseDecoder
    
    typealias BaseDecoder = _JSONDecoder
    
    typealias KeyedContainerType = _JSONKeyedDecodingContainer
    
    /// A reference to the container we're reading from.
    private let container: NSArray
    
    /// The path of coding keys taken to get to this point in decoding.
    public var codingPath: [CodingKey] {
        return decoder.codingPath + nestedPath
    }
    
    /// The index of the element we're decoding.
    // must call next(for:) before using
    private(set) public var currentIndex = -1
    
    let nestedPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    fileprivate init(decoder: BaseDecoder, container: NSArray, nestedPath: [CodingKey]) {
        self.decoder = decoder
        self.container = container
        self.nestedPath = nestedPath
    }
    
    // MARK: - UnkeyedDecodingContainer Methods
    // why optional?
    public var count: Int? {
        return self.container.count
    }
    
    var currentKey: CodingKey {
        return "index \(currentIndex)"
    }
    
    /// gets the next value if not at end or throws valueNotFound(type, context)
    /// increments currentIndex
    mutating func next(_ type: Any.Type, _ typeDescription: String? = nil) throws -> Any {
        
        let typeDescription = typeDescription ?? "\(type)"
        
        currentIndex += 1
        
        if isAtEnd {
            self.decoder.codingPath = self.codingPath + [currentKey]
            throw decoder.notFound(type, "Cannot get \(typeDescription) -- Unkeyed container is at end.")
        }
        
        return container[currentIndex]
    }
    
    public var isAtEnd: Bool {
        return currentIndex >= container.count
    }
    
    public mutating func decodeNil() throws -> Bool {
        
        return try isNil(next(NSNull.self))
    }
    
    mutating func decode<T>(with unbox: (Any)throws->T) throws -> T {
        
        do {
            return try unbox(next(T.self))
            
        } catch let error as DecodingError {
            throw error.setPathIfEqualOrLonger(codingPath + [currentKey])
        } catch let error as DecodeError {
            throw error
        } catch {
            throw DecodeError.decodeError(error, atPath: codingPath + [currentKey])
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
        
        let value = try self.next(NSDictionary.self, "nested keyed container")
        
        guard let container = value as? NSDictionary else {
            decoder.codingPath = codingPath + [currentKey]
            throw decoder.failedToUnbox(value, to: KeyedDecodingContainer<NestedKey>.self)
        }
        
        return KeyedDecodingContainer(_JSONKeyedDecodingContainer<NestedKey>(decoder: self.decoder, container: container, nestedPath: nestedPath + [currentKey]))
    }
    
    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        let value = try self.next(NSArray.self, "nested unkeyed container")
        
        guard let array = value as? NSArray else {
            decoder.codingPath = self.codingPath + [currentKey]
            throw decoder.failedToUnbox(value, to: UnkeyedDecodingContainer.self)
        }
        
        return _JSONUnkeyedDecodingContainer(decoder: self.decoder, container: array, nestedPath: nestedPath + [currentKey])
    }
    
    public mutating func superDecoder() throws -> Decoder {
        
        let value = try next(Decoder.self, "value for super decoder")
        
        return BaseDecoder(value, codingPath: codingPath + ["super \(currentKey)"], options: self.decoder.options, userInfo: decoder.userInfo)
    }
}

extension DecodingError {
    
    func setPathIfEqualOrLonger(_ codingPath: [CodingKey]) -> DecodingError {
        
        func setPath(to context: DecodingError.Context) -> DecodingError.Context {
            if codingPath.count >= context.codingPath.count {
                return DecodingError.Context(codingPath: codingPath, debugDescription: context.debugDescription, underlyingError: context.underlyingError)
            } else {
                return context
            }
        }
        
        switch self {
        case .dataCorrupted(let context): return .dataCorrupted(setPath(to: context))
        case .keyNotFound(let key, let context): return .keyNotFound(key, setPath(to: context))
        case .typeMismatch(let type, let context): return .typeMismatch(type, setPath(to: context))
        case .valueNotFound(let type, let context): return .valueNotFound(type, setPath(to: context))
        }
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

fileprivate protocol ConvertibleNumber {
    init?(exactly: NSNumber)
    init(truncating: NSNumber)
    init(_ value: NSNumber)
}

fileprivate protocol ConvertibleInteger: ConvertibleNumber {
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

let r = Int8(clamping: 1)

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

fileprivate func _JSONKey(index: Int) -> CodingKey {
    return "index \(index)"
}

extension DecodingError {
    /// Returns a `.typeMismatch` error describing the expected type.
    ///
    /// - parameter path: The path of `CodingKey`s taken to decode a value of this type.
    /// - parameter expectation: The type expected to be encountered.
    /// - parameter reality: The value that was encountered instead of the expected type.
    /// - returns: A `DecodingError` with the appropriate path and debug description.
    internal static func _typeMismatch(at path: [CodingKey], expectation: Any.Type, reality: Any) -> DecodingError {
        let description = "Expected to decode \(expectation) but found \(_typeDescription(of: reality)) instead."
        return .typeMismatch(expectation, Context(codingPath: path, debugDescription: description))
    }
    
    /// Returns a description of the type of `value` appropriate for an error message.
    ///
    /// - parameter value: The value whose type to describe.
    /// - returns: A string describing `value`.
    /// - precondition: `value` is one of the types below.
    fileprivate static func _typeDescription(of value: Any) -> String {
        if value is NSNull {
            return "a null value"
        } else if value is NSNumber /* FIXME: If swift-corelibs-foundation isn't updated to use NSNumber, this check will be necessary: || value is Int || value is Double */ {
            return "a number"
        } else if value is String {
            return "a string/data"
        } else if value is [Any] {
            return "an array"
        } else if value is [String : Any] {
            return "a dictionary"
        } else {
            return "\(type(of: value))"
        }
    }
}



///// As associated values, this case contains the attempted type and context for debugging.
//case typeMismatch(Any.Type, Context)
//
///// An indication that a non-optional value of the given type was expected, but a null value was found.
/////
///// As associated values, this case contains the attempted type and context for debugging.
//case valueNotFound(Any.Type, Context)
//
/////  An indication that a keyed decoding container was asked for an entry for the given key, but did not contain one.
/////
///// As associated values, this case contains the attempted key and context for debugging.
//case keyNotFound(CodingKey, Context)
//
///// An indication that the data is corrupted or otherwise invalid.
/////
///// As an associated value, this case contains the context for debugging.
//case dataCorrupted(Context)




