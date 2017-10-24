//
//  CoderTesting.swift
//  SimplifiedCoder
//
//  MIT License
//
//  Copyright (c) 8/27/17 Brendan Henderson
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


import Foundation

// MARK: CoderTesting

// a struct to hold various Testing values
public struct CoderTesting {
    
    public enum DecodingErrorType {
        case dataCorrupted
        case keyNotFound(stringValue: String, intValue: Int?)
        case typeMismatch(Any.Type)
        case valueNotFound(Any.Type)
        
        public func isCorrect(_ error: DecodingError) -> Bool {
            
            switch (self, error) {
                
            case (.dataCorrupted, .dataCorrupted(_)):
                return true
                
            case (.keyNotFound(let stringValue, let intValue), .keyNotFound(let rhs, _)):
                if stringValue == rhs.stringValue && intValue == rhs.intValue {
                    return true
                }
                
            case (.typeMismatch(let lhs), .typeMismatch(let rhs, _)):
                if lhs == rhs {
                    return true
                }
                
            case (.valueNotFound(let lhs), .valueNotFound(let rhs, _)):
                if lhs == rhs {
                    return true
                }
                
            default: break
            }
            
            return false
        }
    }
    
    public static func testingValues<T: SignedInteger & FixedWidthInteger>(for: T.Type) -> [T] {
        return [
            .max,
            .min,
            0,
            34,
            110,
            -13,
            -72
        ]
    }
    
    public static func testingValues<T: UnsignedInteger & FixedWidthInteger>(for: T.Type) -> [T] {
        return [
            .max,
            .min,
            0,
            34,
            110,
            220
        ]
    }
    
    public static func testingValues<T: FloatingPoint>(for: T.Type) -> [T] {
        
        let type = "\(T.self)"
        
        var result: [T] = []
        
        func add(_ value: T) {
            result.append(value)
            result.append(-value)
        }
        
        add(.greatestFiniteMagnitude)
        add(.infinity)
        add(.leastNonzeroMagnitude)
        add(.leastNormalMagnitude)
        add(.nan)
        add(.signalingNaN)
        add(.pi)
        add(.ulpOfOne)
        add(0)
        add(123234)
        
        return result
    }
    
    public static var intValues   : Array<Int   > { return self.testingValues(for: Int   .self) }
    public static var int8Values  : Array<Int8  > { return self.testingValues(for: Int8  .self) }
    public static var int16Values : Array<Int16 > { return self.testingValues(for: Int16 .self) }
    public static var int32Values : Array<Int32 > { return self.testingValues(for: Int32 .self) }
    public static var int64Values : Array<Int64 > { return self.testingValues(for: Int64 .self) }
    public static var uintValues  : Array<UInt  > { return self.testingValues(for: UInt  .self) }
    public static var uint8Values : Array<UInt8 > { return self.testingValues(for: UInt8 .self) }
    public static var uint16Values: Array<UInt16> { return self.testingValues(for: UInt16.self) }
    public static var uint32Values: Array<UInt32> { return self.testingValues(for: UInt32.self) }
    public static var uint64Values: Array<UInt64> { return self.testingValues(for: UInt64.self) }
    public static var floatValues : Array<Float > { return self.testingValues(for: Float .self) }
    public static var doubleValues: Array<Double> { return self.testingValues(for: Double.self) }
    
    /// splits all the characters in the character sets into a string with a max length of maxCharactersInEachString and a description of the string in it's characterSet.
    /// WARNING! printing this result may freeze the app for a few minutes! print and use only one value at a time.
    public static func stringValues(from characterSets: [CharacterSet], removeCharacters: String, maxCharactersInEachString: Int = 50) -> [(stringToEncode: String, description: String)] {
        
        var result: [(String, String)] = []
        
        for characterSet in characterSets {
            
            var subCharacterSet = characterSet
            
            subCharacterSet.remove(charactersIn: removeCharacters)
            
            let allCharacters = subCharacterSet.allCharacters()
            
            var counter = 0
            
            while let charactersToEncode = allCharacters.slice(at: counter, count: maxCharactersInEachString) {
                counter += 1
                
                let __add = (removeCharacters.isEmpty ? "" : " with removed characters: " + removeCharacters)
                
                let stringToEncode = String(charactersToEncode)
                
                let descriptionOfString = stringToEncode.map { $0.description }.joined(separator: " ")
                
                result.append((stringToEncode, "\(characterSet.description + __add) current value: \(descriptionOfString)"))
            }
        }
        
        return result
    }
    
    public static func guardEqual(expected: [CodingKey], actual: [CodingKey]) -> CustomStringConvertible? {
        
        guard expected.count == actual.count else {
            return """
            different coding path counts:
            expected: \(expected.count) from: \(expected)
            actual: \(actual.count) from: \(actual)
            """
        }
        
        for (expectedKeyAtIndex, key2) in zip(expected.enumerated(), actual) {
            
            let key1 = expectedKeyAtIndex.element
            
            guard key1 == key2 else {
                
                func description(for key: CodingKey) -> String {
                    return "\(type(of: key))(stringValue: \(key.stringValue), intValue: \(key.intValue?.description ?? "nil"))"
                }
                
                func description(forPath path: [CodingKey]) -> [String] {
                    return path.map { description(for: $0) }
                }
                
                let key1 = description(for: key1)
                let key2 = description(for: key2)
                let expected = description(forPath: expected)
                let actual = description(forPath: actual)
                
                return """
                different coding keys at index \(expectedKeyAtIndex.offset):
                expected: \(key1) from: \(expected)
                actual: \(key2) from: \(actual)
                """
            }
        }
        
        return nil
    }
    
    // MARK: CodingStats
    
    public enum CodedType {
        case single
        case unkeyed
        case keyed
    }
    
    class VoidEncoderOptions {
        
        var topLevelType: CodedType = .single
        
        func checkTopLevel(_ newType: CodedType) {
            if self.topLevelType == .single && newType != .single {
                self.topLevelType = newType
            }
        }
        
        lazy var willCrashIfJSONEncoder: Bool = false
    }
    
    public typealias EncodeStats = (codingPathOfFirstExpected: [CodingKey]?, willCrashIfJSONEncoder: Bool, topLevelType: CodedType)
    public typealias DecodeStats = (codingPathOfFirstExpected: [CodingKey]?, topLevelType: CodedType)
    
    /**
     returns:
     codingPath: the codingPath of the first expected type encountered
     willCrashIfJSONEncoder: whether JSONEncoder will crash: "Reference encoder deallocated with multiple values in storage."
     topLevelType: the top container type of the encoded value
     
     rethrows unknown errors.
     */
    public static func encodeStats<T: Encodable, E: Encodable>(expected: T.Type, encodable: E, userInfo: [CodingUserInfoKey: Any] = [:]) throws -> EncodeStats {
        
        let encoder = VoidEncoder<T>(options: VoidEncoderOptions(), userInfo: userInfo)
        
        do {
            _ = try encoder.start(with: encodable)
            
            return (nil, encoder.options.willCrashIfJSONEncoder, encoder.options.topLevelType)
            
        } catch let error as EncodingError {
            
            if error.context.debugDescription == sharedThrowDescription {
                
                return (error.context.codingPath, encoder.options.willCrashIfJSONEncoder, encoder.options.topLevelType)
            } else {
                throw error
            }
        }
    }
    
    class VoidDecoderOptions {
        var topLevelType: CodedType = .single
        
        func checkTopLevel(_ newType: CodedType) {
            if self.topLevelType == .single && newType != .single {
                self.topLevelType = newType
            }
        }
    }
    
    /**
     returns:
     codingPath: the codingPath of the first expected type encountered
     
     rethrows unknown errors
     
     cannot decode more than two values from an unkeyed container
     cannot decode from more than two values in a keyed container
    */
    public static func decodeStats<T: Decodable, D: Decodable>(expected: T.Type, decodable: D.Type, userInfo: [CodingUserInfoKey: Any] = [:]) throws -> DecodeStats {
        
        let decoder = VoidDecoder<T>(options: VoidDecoderOptions(), userInfo: userInfo)
        
        do {
            _ = try decoder.start(with: ()) as D
            
            return (nil, decoder.options.topLevelType)
            
        } catch let error as DecodingError {
            
            if error.context.debugDescription == sharedThrowDescription {
                return (error.context.codingPath, decoder.options.topLevelType)
            } else {
                throw error
            }
        }
    }
    
    // MARK: VoidEncoder
    
    /// the debug description to tell stats to catch this codingPath
    public static var sharedThrowDescription = "Threw error at expected codingPath"
    
    private class VoidEncoder<Expected: Encodable>: EncoderBase {
        
        typealias Options = VoidEncoderOptions
        
        var codingPath: [CodingKey]
        var options: Options
        var userInfo: [CodingUserInfoKey : Any]
        var reference: EncoderReference?
        
        required init(codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any], reference: EncoderReference?) {
            self.codingPath = codingPath
            self.options = options
            self.userInfo = userInfo
            self.reference = reference
        }
        
        var storage: [Any] = []
        var canEncodeNewValue: Bool = true
        
        static var usesStringValue: Bool {
            return true
        }
        
        func check<T: Encodable>(_ value: T, at codingPath: [CodingKey]) throws {
            
            if value is Expected {
                
                if value is CoderTestingSelfThrowingValue {
                    
                    _ = try self.reencode(value, at: codingPath)
                    
                    fatalError("\(type(of: value)) conforms to CoderTestingSelfThrowingValue but did not throw")
                }
                
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: sharedThrowDescription))
            }
        }
        
        func boxNil(              at codingPath: [CodingKey]) throws -> Any { return NSNull() }
        func box(_ value: Bool  , at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: Int   , at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: Int8  , at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: Int16 , at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: Int32 , at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: Int64 , at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: UInt  , at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: UInt8 , at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: UInt16, at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: UInt32, at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: UInt64, at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: Float , at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: Double, at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box(_ value: String, at codingPath: [CodingKey]) throws -> Any { try self.check(value, at: codingPath) ; return () }
        func box<T>(_ value: T, at codingPath: [CodingKey]) throws -> Any where T : Encodable {
            
            try self.check(value, at: codingPath)
            
            return try self.box(default: value, at: codingPath)
                ?? self.reencode(value, at: codingPath)
        }
        
        // need to break the storage count fix to test if JSONEncoder will crash
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
                        fatalError("\(type(of: value)) encoded multiple containers to storage (this is an encoder failure). codingPath: \(codingPath)")
                    } else {
                        fatalError("encoder lost values from storage while encoding \(type(of: value)).")
                    }
                }
            }
            
            self.canEncodeNewValue = true
            
            do {
                try closure(value, self)
            } catch {
                // the only change
//                _ = getEncoded()
                throw error
            }
            
            return getEncoded() ?? { ()->Any in fatalError("\(type(of: value)) did not encode a value or container at codingPath: \(codingPath).") }()
        }
        
        deinit {
            if self.storage.count > 1 && self.reference != nil {
                self.options.willCrashIfJSONEncoder = true
                self.storage = []
            }
            self.willDeinit()
        }
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            self.options.checkTopLevel(.keyed)
            return self._container(keyedBy: type)
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            self.options.checkTopLevel(.unkeyed)
            return self._unkeyedContainer()
        }
    }
    
    // MARK: VoidDecoder
    
    private class VoidDecoder<U: Decodable>: DecoderBase {
        
        typealias Options = VoidDecoderOptions
        
        var codingPath: [CodingKey]
        var options: Options
        var userInfo: [CodingUserInfoKey : Any]
        
        required init(codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.options = options
            self.userInfo = userInfo
        }
        
        var storage: [Any] = []
        
        static var usesStringValue: Bool {
            return true
        }
        
        func check<T: Decodable>(_ value: Any, to: T.Type, at codingPath: [CodingKey]) throws {
            
            if T.self == U.self {
                
                if T.self is CoderTestingSelfThrowingValue.Type {
                    
                    _ = try self.redecode(value, at: codingPath) as T
                    
                    fatalError("\(T.self) conforms to CoderTestingSelfThrowingValue but did not throw")
                }
                
                throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: sharedThrowDescription))
            }
        }
        
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Bool   { try self.check(value, to: Bool  .self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int    { try self.check(value, to: Int   .self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int8   { try self.check(value, to: Int8  .self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int16  { try self.check(value, to: Int16 .self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int32  { try self.check(value, to: Int32 .self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Int64  { try self.check(value, to: Int64 .self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt   { try self.check(value, to: UInt  .self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt8  { try self.check(value, to: UInt8 .self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt16 { try self.check(value, to: UInt16.self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt32 { try self.check(value, to: UInt32.self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> UInt64 { try self.check(value, to: UInt64.self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Float  { try self.check(value, to: Float .self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Double { try self.check(value, to: Double.self, at: codingPath) ; return .init() }
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> String { try self.check(value, to: String.self, at: codingPath) ; return .init() }
        func unbox<T>(_ value: Any, at codingPath: [CodingKey]) throws -> T where T : Decodable {
            
            try self.check(value, to: T.self, at: codingPath)
            
            return try self.unbox(default: value, at: codingPath)
                ?? self.redecode(value, at: codingPath)
        }
        
        func keyedContainerContainer(_ value: Any, at codingPath: [CodingKey], nested: Bool) throws -> DecoderKeyedContainerContainer {
            self.options.checkTopLevel(.keyed)
            return LimitingKeyedContainer()
        }
        
        func unkeyedContainerContainer(_ value: Any, at codingPath: [CodingKey], nested: Bool) throws -> DecoderUnkeyedContainerContainer {
            self.options.checkTopLevel(.unkeyed)
            return LimitingUnkeyedContainer()
        }
    }
    
    private static var maxCount: Int = 2
    
    /// an unkeyed container that has limited decodable values
    private struct LimitingUnkeyedContainer: DecoderUnkeyedContainerContainer {
        
        func fromStorage(_ index: Int) -> Any { return () }
        var storageCount: Int? { return maxCount }
        func isAtEnd(index: Int) -> Bool { return index >= maxCount }
    }
    
    /// a keyed container that has limited decodable keys
    private struct LimitingKeyedContainer: DecoderKeyedContainerContainer {
        
        func value(forStringValue key: String) -> Any? {
            if key == "throw KeyNotFound" {
                return nil
            } else {
                return ()
            }
        }
        func value(forIntValue key: Int) -> Any? {
            if key == "throw KeyNotFound".hashValue {
                return nil
            } else {
                return ()
            }
        }
        var stringValueKeys: [String] {
            return ["throw KeyNotFound"]
        }
        var intValueKeys: [Int] {
            return ["throw KeyNotFound".hashValue]
        }
    }
    
    // MARK: Objects
    
    public struct Objects {
        
        // MARK: Optional
        
        public struct TestOptional<T>: Codable {
            
            public var value: T?
            
            public init(_ value: T?) {
                self.value = value
            }
            
            public func encode(to encoder: Encoder) throws {
                try self.value.__encode(to: encoder)
            }
            
            public init(from decoder: Decoder) throws {
                self.value = try .init(__from: decoder)
            }
        }
        
        // MARK: Single
        
        public struct Single<T>: Codable {
            
            public var value: T
            
            public init(_ value: T) {
                self.value = value
            }
            
            // Codable
            
            public func encode(to encoder: Encoder) throws {
                
                var container = encoder.singleValueContainer()
                
                assertTypeIsEncodable(T.self, in: Single.self)
                
                try (self.value as! Encodable).__encode(to: &container)
            }
            
            public init(from decoder: Decoder) throws {
                
                let container = try decoder.singleValueContainer()
                
                assertTypeIsDecodable(T.self, in: Single.self)
                
                self.value = try (T.self as! Decodable.Type).init(__from: container) as! T
            }
        }
        
        // MARK: Keyed
        
        
        private struct TestKey: CodingKey {
            
            var stringValue: String = "test"
            var intValue: Int? = 1
            
            init?(stringValue: String) {
                if stringValue != "test" {
                    return nil
                }
            }
            
            init?(intValue: Int) {
                if intValue != 1 {
                    return nil
                }
            }
            
            static var test = TestKey(intValue: 1)!
        }
        
        private static func encodeKeyed<T>(to encoder: Encoder, value: T, in _type: Any.Type) throws {
            
            assertTypeIsEncodable(T.self, in: _type)
            
            var container = encoder.container(keyedBy: TestKey.self)
            try (value as! Encodable).__encode(to: &container, forKey: .test)
        }
        
        private static func decodeKeyed<T>(from decoder: Decoder, _: T.Type, in _type: Any.Type) throws -> T {
            
            assertTypeIsDecodable(T.self, in: _type)
            
            let container = try decoder.container(keyedBy: TestKey.self)
            return try (T.self as! Decodable.Type).init(__from: container, forKey: .test) as! T
        }
        
        public struct Keyed<T>: Codable {
            
            public var value: T
            
            public init(_ value: T) {
                
                self.value = value
            }
            
            public func encode(to encoder: Encoder) throws {
                
                try Objects.encodeKeyed(to: encoder, value: self.value, in: Keyed.self)
            }
            
            public init(from decoder: Decoder) throws {
                
                self.value = try Objects.decodeKeyed(from: decoder, T.self, in: Keyed.self)
            }
        }
        
        // MARK: SubKeyed1
        
        public struct SubKeyed1<T>: Codable {
            
            public var value: T
            
            public init(_ value: T) {
                
                self.value = value
            }
            
            public func encode(to encoder: Encoder) throws {
                
                _ = encoder.container(keyedBy: TestKey.self)
                try Objects.encodeKeyed(to: encoder, value: self.value, in: SubKeyed1.self)
            }
            
            public init(from decoder: Decoder) throws {
                
                _ = try decoder.container(keyedBy: TestKey.self)
                self.value = try Objects.decodeKeyed(from: decoder, T.self, in: SubKeyed1.self)
            }
        }
        
        // MARK: SubKeyed2
        
        public struct SubKeyed2<T>: Codable {
            
            public var value: T
            
            public init(_ value: T) {
                
                self.value = value
            }
            
            public func encode(to encoder: Encoder) throws {
                
                var c = encoder.container(keyedBy: TestKey.self)
                let superEncoder = c.superEncoder()
                try Objects.encodeKeyed(to: superEncoder, value: self.value, in: SubKeyed2.self)
            }
            
            public init(from decoder: Decoder) throws {
                
                let c = try decoder.container(keyedBy: TestKey.self)
                let superDecoder = try c.superDecoder()
                self.value = try Objects.decodeKeyed(from: superDecoder, T.self, in: SubKeyed2.self)
            }
        }
        
        public struct KeyedNestedUnkeyed<T>: Codable {
            
            public var value: T
            
            public init(_ value: T) {
                self.value = value
            }
            
            public func encode(to encoder: Encoder) throws {
                
                assertTypeIsEncodable(T.self, in: type(of: self))
                
                var container = encoder.container(keyedBy: TestKey.self)
                var nestedContainer1 = container.nestedUnkeyedContainer(forKey: .test)
                var nestedContainer2 = nestedContainer1.nestedUnkeyedContainer()
                
                try (self.value as! Encodable).__encode(to: &nestedContainer2)
            }
            
            public init(from decoder: Decoder) throws {
                
                assertTypeIsDecodable(T.self, in: KeyedNestedUnkeyed.self)
                
                let container = try decoder.container(keyedBy: TestKey.self)
                var nestedContainer1 = try container.nestedUnkeyedContainer(forKey: .test)
                var nestedContainer2 = try nestedContainer1.nestedUnkeyedContainer()
                
                self.value = try (T.self as! Decodable.Type).init(__from: &nestedContainer2) as! T
            }
        }
        
        public struct KeyedNestedKeyed<T>: Codable {
            
            public var value: T
            
            public init(_ value: T) {
                self.value = value
            }
            
            public func encode(to encoder: Encoder) throws {
                
                assertTypeIsEncodable(T.self, in: type(of: self))
                
                var container = encoder.container(keyedBy: TestKey.self)
                var nestedContainer1 = container.nestedContainer(keyedBy: TestKey.self, forKey: .test)
                var nestedContainer2 = nestedContainer1.nestedContainer(keyedBy: TestKey.self, forKey: .test)
                
                try (self.value as! Encodable).__encode(to: &nestedContainer2, forKey: .test)
            }
            
            public init(from decoder: Decoder) throws {
                
                assertTypeIsDecodable(T.self, in: KeyedNestedKeyed.self)
                
                let container = try decoder.container(keyedBy: TestKey.self)
                let nestedContainer1 = try container.nestedContainer(keyedBy: TestKey.self, forKey: .test)
                let nestedContainer2 = try nestedContainer1.nestedContainer(keyedBy: TestKey.self, forKey: .test)
                
                self.value = try (T.self as! Decodable.Type).init(__from: nestedContainer2, forKey: .test) as! T
            }
        }
        
        // MARK: Unkeyed
        
        public struct Unkeyed<E>: Codable {
            
            public var elements: [E]
            
            public init(_ element: E) {
                self.elements = [element]
            }
            
            public init(_ array: [E]) {
                self.elements = array
            }
            
            public func encode(to encoder: Encoder) throws {
                try self.elements.__encode(to: encoder)
            }
            
            public init(from decoder: Decoder) throws {
                self.elements = try .init(__from: decoder)
            }
        }
        
        public struct TestSet<E: Hashable>: Codable {
            
            public var elements: Set<E>
            
            public init(_ element: E) {
                self.elements = Set([element])
            }
            
            public init(_ elements: Set<E>) {
                self.elements = elements
            }
            
            public func encode(to encoder: Encoder) throws {
                try self.elements.__encode(to: encoder)
            }
            
            public init(from decoder: Decoder) throws {
                self.elements = try .init(__from: decoder)
            }
        }
        
        public struct SubUnkeyed1<T>: Codable {
            
            public var elements: [T]
            
            public init(_ element: T) {
                self.elements = [element]
            }
            
            public init(_ elements: [T]) {
                self.elements = elements
            }
            
            public func encode(to encoder: Encoder) throws {
                
                _ = encoder.unkeyedContainer()
                try self.elements.__encode(to: encoder)
            }
            
            public init(from decoder: Decoder) throws {
                _ = try decoder.unkeyedContainer()
                self.elements = try .init(__from: decoder)
            }
        }
        
        public struct SubUnkeyed2<T>: Codable {
            
            public var elements: [T]
            
            public init(_ element: T) {
                self.elements = [element]
            }
            
            public init(_ elements: [T]) {
                self.elements = elements
            }
            
            public func encode(to encoder: Encoder) throws {
                
                var container1 = encoder.unkeyedContainer()
                let superEncoder = container1.superEncoder()
                // super.encode(to: superEncoder)
                try self.elements.__encode(to: superEncoder)
            }
            
            public init(from decoder: Decoder) throws {
                
                var container1 = try decoder.unkeyedContainer()
                let superDecoder = try container1.superDecoder()
                // super.init(from: superDecoder)
                self.elements = try .init(__from: superDecoder)
            }
        }
        
        public struct UnkeyedNestedUnkeyed<T>: Codable {
            
            public var value: T
            
            public init(_ value: T) {
                self.value = value
            }
            
            public func encode(to encoder: Encoder) throws {
                
                assertTypeIsEncodable(T.self, in: type(of: self))
                
                var container = encoder.unkeyedContainer()
                var nestedContainer1 = container.nestedUnkeyedContainer()
                var nestedContainer2 = nestedContainer1.nestedUnkeyedContainer()
                
                try (self.value as! Encodable).__encode(to: &nestedContainer2)
            }
            
            public init(from decoder: Decoder) throws {
                
                assertTypeIsDecodable(T.self, in: UnkeyedNestedUnkeyed.self)
                
                var container = try decoder.unkeyedContainer()
                var nestedContainer1 = try container.nestedUnkeyedContainer()
                var nestedContainer2 = try nestedContainer1.nestedUnkeyedContainer()
                
                self.value = try (T.self as! Decodable.Type).init(__from: &nestedContainer2) as! T
            }
        }
        
        public struct UnkeyedNestedKeyed<T>: Codable {
            
            public var value: T
            
            public init(_ value: T) {
                self.value = value
            }
            
            public enum CodingKeys: Int, CodingKey {
                case value = 1
            }
            
            public func encode(to encoder: Encoder) throws {
                
                assertTypeIsEncodable(T.self, in: type(of: self))
                
                var container = encoder.unkeyedContainer()
                var nestedContainer1 = container.nestedContainer(keyedBy: CodingKeys.self)
                var nestedContainer2 = nestedContainer1.nestedContainer(keyedBy: CodingKeys.self, forKey: .value)
                
                try (self.value as! Encodable).__encode(to: &nestedContainer2, forKey: .value)
            }
            
            public init(from decoder: Decoder) throws {
                
                assertTypeIsDecodable(T.self, in: UnkeyedNestedKeyed.self)
                
                var container = try decoder.unkeyedContainer()
                let nestedContainer1 = try container.nestedContainer(keyedBy: CodingKeys.self)
                let nestedContainer2 = try nestedContainer1.nestedContainer(keyedBy: CodingKeys.self, forKey: .value)
                
                self.value = try (T.self as! Decodable.Type).init(__from: nestedContainer2, forKey: .value) as! T
            }
        }
        
        // MARK: Multiple Store
        
        /// adds more than one value to a referencing encoder's storage before encoding the value
        public struct MultipleStore<T: Encodable>: Encodable {
            
            public var value: T
            
            public init(_ value: T) {
                self.value = value
            }
            
            // move to a reference encoder using superEncoder
            // add a value to stack and reset canEncodeNewValue ( encode(Next) )
            // then encode value.
            
            private enum CodingKeys: Int, CodingKey {
                case value = 1
            }
            
            public func encode(to encoder: Encoder) throws {
                
                var container1 = encoder.container(keyedBy: CodingKeys.self)
                let superEncoder = container1.superEncoder()
                var container2 = superEncoder.container(keyedBy: CodingKeys.self)
                try container2.encode(Next(value: self.value), forKey: .value)
            }
            
            public struct Next: Encodable {
                public var value: T
                
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(value, forKey: .value)
                }
            }
        }
        
        // MARK: Visual
        
        /// throws the encoder or decoder codingPath in an encoding or decoding error
        public struct VisualCheck: Codable, CoderTestingSelfThrowingValue {
            
            public init() {}
            
            public func encode(to encoder: Encoder) throws {
                throw EncodingError.invalidValue(
                    self,
                    EncodingError.Context(
                        codingPath: encoder.codingPath,
                        debugDescription: CoderTesting.sharedThrowDescription
                    )
                )
            }
            
            public init(from decoder: Decoder) throws {
                throw DecodingError.valueNotFound(
                    type(of: self),
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: CoderTesting.sharedThrowDescription
                    )
                )
            }
        }
        
        public struct KeyNotFoundCheck: Decodable, CoderTestingSelfThrowingValue {
            
            public struct NotFound: CodingKey {
                public var stringValue: String = "throw KeyNotFound"
                
                public init() {}
                
                public init(stringValue: String) {}
                
                public var intValue: Int? = "throw KeyNotFound".hashValue
                
                public init?(intValue: Int) {}
            }
            
            public static var errorType: CoderTesting.DecodingErrorType = .keyNotFound(stringValue: "throw KeyNotFound", intValue: "throw KeyNotFound".hashValue)
            
            public init(from decoder: Decoder) throws {
                
                let container = try decoder.container(keyedBy: NotFound.self)
                
                do {
                    
                    _ = try container.decode(String.self, forKey: NotFound())
                    
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "KeyNotFoundCheck from \(type(of: decoder)) failed to throw for a random key"
                        )
                    )
                    
                } catch DecodingError.keyNotFound(let key, let context) {
                    throw DecodingError.keyNotFound(
                        key,
                        DecodingError.Context(
                            codingPath: context.codingPath,
                            debugDescription: CoderTesting.sharedThrowDescription
                        )
                    )
                }
            }
        }
        
        public struct UnkeyedIsAtEndCheck: Decodable, CoderTestingSelfThrowingValue {
            
            public init(from decoder: Decoder) throws {
                
                var container = try decoder.unkeyedContainer()
                
                do {
                    for _ in 1...300 {
                        _ = try container.decode(String.self)
                    }
                    
                } catch DecodingError.valueNotFound(_, let context) {
                    
                    guard context.codingPath.count == decoder.codingPath.count + 1 else {
                        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: context.codingPath, debugDescription: "expected path count: \(decoder.codingPath.count + 1)"))
                    }
                    
                    throw DecodingError.valueNotFound(
                        type(of: self),
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: CoderTesting.sharedThrowDescription
                        )
                    )
                } catch {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "UnkeyedIsAtEndCheck for \(type(of: decoder)) failed to throw not found",
                            underlyingError: error
                        )
                    )
                }
                
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "UnkeyedIsAtEndCheck for \(type(of: decoder)) failed to throw not found after the 300th value."
                    )
                )
            }
        }
    }
}

/// an identifier for a value that throws by itself when Encoded and/or Decoded
public protocol CoderTestingSelfThrowingValue {}

// MARK: CharacterSet

fileprivate extension CharacterSet {

    func allCharacters() -> [Character] {
        var result: [Character] = []
        for plane: UInt8 in 0...16 where self.hasMember(inPlane: plane) {
            for unicode in UInt32(plane) << 16 ..< UInt32(plane + 1) << 16 {
                if let uniChar = UnicodeScalar(unicode), self.contains(uniChar) {
                    result.append(Character(uniChar))
                }
            }
        }
        return result
    }
}

