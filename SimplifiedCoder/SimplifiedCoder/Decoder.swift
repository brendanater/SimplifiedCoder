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

extension JSONDecoder {
    fileprivate typealias _Options = (
        dateDecodingStrategy: DateDecodingStrategy,
        dataDecodingStrategy: DataDecodingStrategy,
        nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy,
        allowNumberLossyConversion: Bool,
        stringDefaultsToDescription: Bool
    )
}


fileprivate class _JSONDecoder : Decoder {
    // MARK: Properties
    /// The decoder's storage.
    fileprivate var storage: _JSONDecodingStorage
    
    typealias Options = JSONDecoder._Options
    
    /// Options set on the top-level decoder.
    fileprivate let options: Options
    
    /// The path to the current point in encoding.
    fileprivate(set) public var codingPath: [CodingKey]
    
    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any]
    
    // MARK: - Initialization
    /// Initializes `self` with the given top-level container and options.
    fileprivate init(referencing container: Any, at codingPath: [CodingKey] = [], options: Options, userInfo: [CodingUserInfoKey : Any]) {
        self.storage = _JSONDecodingStorage()
        self.storage.push(container: container)
        self.codingPath = codingPath
        self.options = options
        self.userInfo = userInfo
    }
    
    // MARK: - Decoder Methods
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard !(self.storage.topContainer is NSNull) else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<Key>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }
        
        guard let topContainer = self.storage.topContainer as? [String : Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: self.storage.topContainer)
        }
        
        let container = _JSONKeyedDecodingContainer<Key>(referencing: self, wrapping: topContainer)
        return KeyedDecodingContainer(container)
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !(self.storage.topContainer is NSNull) else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get unkeyed decoding container -- found null value instead."))
        }
        
        guard let topContainer = self.storage.topContainer as? [Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: self.storage.topContainer)
        }
        
        return _JSONUnkeyedDecodingContainer(referencing: self, wrapping: topContainer)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

extension _JSONDecoder : SingleValueDecodingContainer {
    // MARK: SingleValueDecodingContainer Methods
    
    public func decodeNil() -> Bool {
        return isNil(storage.topContainer)
    }
    
    public func decode(_: Bool.Type  ) throws -> Bool   { return try unbox(storage.topContainer) }
    public func decode(_: Int.Type   ) throws -> Int    { return try unbox(storage.topContainer) }
    public func decode(_: Int8.Type  ) throws -> Int8   { return try unbox(storage.topContainer) }
    public func decode(_: Int16.Type ) throws -> Int16  { return try unbox(storage.topContainer) }
    public func decode(_: Int32.Type ) throws -> Int32  { return try unbox(storage.topContainer) }
    public func decode(_: Int64.Type ) throws -> Int64  { return try unbox(storage.topContainer) }
    public func decode(_: UInt.Type  ) throws -> UInt   { return try unbox(storage.topContainer) }
    public func decode(_: UInt8.Type ) throws -> UInt8  { return try unbox(storage.topContainer) }
    public func decode(_: UInt16.Type) throws -> UInt16 { return try unbox(storage.topContainer) }
    public func decode(_: UInt32.Type) throws -> UInt32 { return try unbox(storage.topContainer) }
    public func decode(_: UInt64.Type) throws -> UInt64 { return try unbox(storage.topContainer) }
    public func decode(_: Float.Type ) throws -> Float  { return try unbox(storage.topContainer) }
    public func decode(_: Double.Type) throws -> Double { return try unbox(storage.topContainer) }
    public func decode(_: String.Type) throws -> String { return try unbox(storage.topContainer) }
    public func decode<T: Decodable>(_: T.Type) throws -> T { return try unbox(storage.topContainer) }
}

// unboxing
extension _JSONDecoder {
    
    func notFound<T>(_ type: T.Type) -> Error {
        return DecodingError.valueNotFound(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot get \(type) -- found null value instead."))
    }
    
    func typeError(_ type: Any.Type, _ value: Any) -> Error {
        return DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
    }
    
    func convert<T: ConvertibleNumber>(number value: Any?) throws -> T {
        
        if isNil(value) { throw notFound(T.self) }
        
        if let number = value as? T {
            return number
            
        } else if let number = value as? NSNumber ?? NumberFormatter.shared.number(from: value as? String ?? "˜∆åƒ˚")  {
            
            if let number = T(exactly: number) {
                return number
            }
            
            if options.allowNumberLossyConversion {
                return T(number)
            }
        }
        
        throw typeError(T.self, value!)
    }
    
    func convert(double value: Any?) throws -> Double {
        do {
            return try convert(number: value)
        } catch {
            if case .convertFromString(
                positiveInfinity: let pos,
                negativeInfinity: let neg,
                nan: let nan
                ) = options.nonConformingFloatDecodingStrategy,
                let string = value as? String {
                
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
    
    func convert(float value: Any?) throws -> Float {
        do {
            return try convert(number: value)
        } catch {
            if case .convertFromString(
                positiveInfinity: let pos,
                negativeInfinity: let neg,
                nan: let nan
                ) = options.nonConformingFloatDecodingStrategy,
                let string = value as? String {
                
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
    
    func unbox(_ value: Any?) throws -> Bool { return value as? Bool ?? value.isNil }
    
    func unbox(_ value: Any?) throws -> Int    { return try convert(number: value) }
    func unbox(_ value: Any?) throws -> Int8   { return try convert(number: value) }
    func unbox(_ value: Any?) throws -> Int16  { return try convert(number: value) }
    func unbox(_ value: Any?) throws -> Int32  { return try convert(number: value) }
    func unbox(_ value: Any?) throws -> Int64  { return try convert(number: value) }
    func unbox(_ value: Any?) throws -> UInt   { return try convert(number: value) }
    func unbox(_ value: Any?) throws -> UInt8  { return try convert(number: value) }
    func unbox(_ value: Any?) throws -> UInt16 { return try convert(number: value) }
    func unbox(_ value: Any?) throws -> UInt32 { return try convert(number: value) }
    func unbox(_ value: Any?) throws -> UInt64 { return try convert(number: value) }
    func unbox(_ value: Any?) throws -> Float  { return try convert(float : value) }
    func unbox(_ value: Any?) throws -> Double { return try convert(double: value) }
    
    func unbox(_ value: Any?) throws -> String {
        
        if isNil(value) { throw notFound(String.self) }
        
        if let string = value as? String {
            return string
            
        } else if options.stringDefaultsToDescription {
            return "\(value ?? "<null>" as Any)"
        }
        
        throw typeError(String.self, value!)
    }
    
    func unbox(_ value: Any?, as type: Date.Type) throws -> Date {
        if isNil(value) { throw notFound(Date.self) }
        
        switch options.dateDecodingStrategy {
            
        case .deferredToDate:
            storage.push(container: value!)
            let date = try Date(from: self)
            storage.popContainer()
            return date
            
        case .secondsSince1970: return try Date(timeIntervalSince1970: unbox(value))
            
        case .millisecondsSince1970: return try Date(timeIntervalSince1970: unbox(value) / 1000.0)
            
        case .iso8601:
            if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                guard let date = try ISO8601DateFormatter.shared.date(from: unbox(value) as String) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
                }
                return date
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }
            
        case .formatted(let formatter):
            guard let date = try formatter.date(from: unbox(value) as String) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Date string does not match format expected by formatter."))
            }
            return date
            
        case .custom(let closure):
            self.storage.push(container: value!)
            let date = try closure(self)
            self.storage.popContainer()
            return date
        }
    }
    
    func unbox(_ value: Any?, as type: Data.Type) throws -> Data {
        if isNil(value) { throw notFound(Data.self) }
        
        switch self.options.dataDecodingStrategy {
        case .deferredToData:
            self.storage.push(container: value!)
            let data = try Data(from: self)
            self.storage.popContainer()
            return data
            
        case .base64:
            guard let string = value as? String else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value!)
            }
            
            guard let data = Data(base64Encoded: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Encountered Data is not valid Base64."))
            }
            
            return data
            
        case .custom(let closure):
            self.storage.push(container: value!)
            let data = try closure(self)
            self.storage.popContainer()
            return data
        }
    }
    
    func unbox(_ value: Any?) throws -> Decimal {
        if isNil(value) { throw notFound(Decimal.self) }
        
        // Attempt to bridge from NSDecimalNumber.
        if let decimal = value as? Decimal {
            return decimal
        } else {
            return try Decimal(unbox(value) as Double)
        }
    }
    
    func unbox(_ value: Any?) throws -> URL {
        if isNil(value) { throw notFound(Decimal.self) }
        
        guard let url = try URL(string: unbox(value)) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Invalid URL string."))
        }
        
        return url
    }
    
    func redecode<T: Decodable>(_ value: Any?) throws -> T {
        if isNil(value) { throw notFound(T.self) }
        
        self.storage.push(container: value!)
        let decoded = try T(from: self)
        self.storage.popContainer()
        return decoded
    }
    
    func unbox<T : Decodable>(_ value: Any?) throws -> T {
        
        switch T.self {
        case is Date.Type:    return try unbox(value) as Date    as! T
        case is Data.Type:    return try unbox(value) as Data    as! T
        case is URL.Type:     return try unbox(value) as URL     as! T
        case is Decimal.Type: return try unbox(value) as Decimal as! T
        default: return try redecode(value)
        }
    }
}

// MARK: - Decoding Storage
fileprivate struct _JSONDecodingStorage {
    // MARK: Properties
    /// The container stack.
    /// Elements may be any one of the JSON types (NSNull, NSNumber, String, Array, [String : Any]).
    private(set) fileprivate var containers: [Any] = []
    
    // MARK: - Initialization
    /// Initializes `self` with no containers.
    fileprivate init() {}
    
    // MARK: - Modifying the Stack
    fileprivate var count: Int {
        return self.containers.count
    }
    
    fileprivate var topContainer: Any {
        precondition(self.containers.count > 0, "Empty container stack.")
        return self.containers.last!
    }
    
    fileprivate mutating func push(container: Any) {
        self.containers.append(container)
    }
    
    fileprivate mutating func popContainer() {
        precondition(self.containers.count > 0, "Empty container stack.")
        self.containers.removeLast()
    }
}

// MARK: Decoding Containers
fileprivate struct _JSONKeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
    typealias Key = K
    
    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: _JSONDecoder
    
    /// A reference to the container we're reading from.
    private let container: [String : Any]
    
    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    fileprivate init(referencing decoder: _JSONDecoder, wrapping container: [String : Any]) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
    }
    
    public var allKeys: [Key] {
        return self.container.keys.flatMap { Key(stringValue: $0) }
    }
    
    func value(forKey key: Key) throws -> Any {
        guard let value = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }
        
        return value
    }
    
    public func contains(_ key: Key) -> Bool {
        return self.container[key.stringValue] != nil
    }
    
    public func decodeNil(forKey key: Key) throws -> Bool {
        return try isNil(value(forKey: key))
    }
    
    func decode<T>(with unbox: (Any)throws->T, forKey key: Key) throws -> T {
        
        let value = try self.value(forKey: key)
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        return try unbox(value)
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
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: self.codingPath,
                                                                  debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \"\(key.stringValue)\""))
        }
        
        guard let dictionary = value as? [String : Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: value)
        }
        
        let container = _JSONKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }
    
    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: self.codingPath,
                                                                  debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found for key \"\(key.stringValue)\""))
        }
        
        guard let array = value as? [Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)
        }
        
        return _JSONUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }
    
    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        let value: Any = self.container[key.stringValue] ?? NSNull()
        return _JSONDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options, userInfo: decoder.userInfo)
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
    private let decoder: _JSONDecoder
    
    /// A reference to the container we're reading from.
    private let container: [Any]
    
    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey] {
        get {
            return decoder.codingPath
        }
        set {
            decoder.codingPath = newValue
        }
    }
    
    /// The index of the element we're about to decode.
    private(set) public var currentIndex: Int = 0
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    fileprivate init(referencing decoder: _JSONDecoder, wrapping container: [Any]) {
        self.decoder = decoder
        self.container = container
    }
    
    // MARK: - UnkeyedDecodingContainer Methods
    public var count: Int? {
        return self.container.count
    }
    
    public var isAtEnd: Bool {
        return self.currentIndex >= self.count!
    }
    
    func isNotEnded() throws {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSONKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
    }
    
    mutating func decode<T>(with unbox: (Any)throws->T) throws -> T {
        try isNotEnded()
        
        self.decoder.codingPath.append("index \(currentIndex)")
        defer {
            self.decoder.codingPath.removeLast()
            self.currentIndex += 1
        }
        
        return try unbox(self.container[currentIndex])
    }
    
    public mutating func decodeNil() throws -> Bool {
        try isNotEnded()
        
        if isNil(self.container[self.currentIndex]) {
            self.currentIndex += 1
            return true
        } else {
            return false
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
        self.decoder.codingPath.append(_JSONKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }
        
        let value = self.container[self.currentIndex]
        guard !(value is NSNull) else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }
        
        guard let dictionary = value as? [String : Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: value)
        }
        
        self.currentIndex += 1
        let container = _JSONKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(_JSONKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }
        
        let value = self.container[self.currentIndex]
        guard !(value is NSNull) else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }
        
        guard let array = value as? [Any] else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)
        }
        
        self.currentIndex += 1
        return _JSONUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }
    
    public mutating func superDecoder() throws -> Decoder {
        self.decoder.codingPath.append(_JSONKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get superDecoder() -- unkeyed container is at end."))
        }
        
        let value = self.container[self.currentIndex]
        self.currentIndex += 1
        return _JSONDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options, userInfo: decoder.userInfo)
    }
}

fileprivate protocol ConvertibleNumber {
    init?(exactly: NSNumber)
    init(_ value: NSNumber)
}

extension Int: ConvertibleNumber {}
extension Int8: ConvertibleNumber {}
extension Int16: ConvertibleNumber {}
extension Int32: ConvertibleNumber {}
extension Int64: ConvertibleNumber {}
extension UInt: ConvertibleNumber {}
extension UInt8: ConvertibleNumber {}
extension UInt16: ConvertibleNumber {}
extension UInt32: ConvertibleNumber {}
extension UInt64: ConvertibleNumber {}
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




