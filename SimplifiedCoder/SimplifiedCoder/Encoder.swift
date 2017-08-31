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

// MARK: - _JSONEncoder
fileprivate class _JSONEncoder : Encoder {
    // MARK: Properties
    /// The encoder's storage.
    fileprivate var storage: [(key: CodingKey?, value: Any)] = []
    
    fileprivate typealias Options = JSONEncoder._Options
    
    /// Options set on the top-level encoder.
    fileprivate let options: Options
    
    /// The path to the current point in encoding.
    public var codingPath: [CodingKey]
    
    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any] {
        return self.options.userInfo
    }
    
    // MARK: - Initialization
    /// Initializes `self` with the given top-level encoder options.
    fileprivate init(options: Options, codingPath: [CodingKey] = []) {
        self.options = options
        self.codingPath = codingPath
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
        
        let container = _JSONKeyedEncodingContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
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
        
        return _JSONUnkeyedEncodingContainer(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
}

// MARK: - Encoding Containers
fileprivate struct _JSONKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    typealias Key = K
    
    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: _JSONEncoder
    
    /// A reference to the container we're writing to.
    private let container: NSMutableDictionary
    
    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: _JSONEncoder, codingPath: [CodingKey], wrapping container: NSMutableDictionary) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }
    
    // MARK: - KeyedEncodingContainerProtocol Methods
    public mutating func encodeNil(forKey key: Key)               throws { self.container[key.stringValue] = NSNull() }
    public mutating func encode(_ value: Bool, forKey key: Key)   throws { self.container[key.stringValue] = self.encoder.box(value) }
    public mutating func encode(_ value: Int, forKey key: Key)    throws { self.container[key.stringValue] = self.encoder.box(value) }
    public mutating func encode(_ value: Int8, forKey key: Key)   throws { self.container[key.stringValue] = self.encoder.box(value) }
    public mutating func encode(_ value: Int16, forKey key: Key)  throws { self.container[key.stringValue] = self.encoder.box(value) }
    public mutating func encode(_ value: Int32, forKey key: Key)  throws { self.container[key.stringValue] = self.encoder.box(value) }
    public mutating func encode(_ value: Int64, forKey key: Key)  throws { self.container[key.stringValue] = self.encoder.box(value) }
    public mutating func encode(_ value: UInt, forKey key: Key)   throws { self.container[key.stringValue] = self.encoder.box(value) }
    public mutating func encode(_ value: UInt8, forKey key: Key)  throws { self.container[key.stringValue] = self.encoder.box(value) }
    public mutating func encode(_ value: UInt16, forKey key: Key) throws { self.container[key.stringValue] = self.encoder.box(value) }
    public mutating func encode(_ value: UInt32, forKey key: Key) throws { self.container[key.stringValue] = self.encoder.box(value) }
    public mutating func encode(_ value: UInt64, forKey key: Key) throws { self.container[key.stringValue] = self.encoder.box(value) }
    public mutating func encode(_ value: String, forKey key: Key) throws { self.container[key.stringValue] = self.encoder.box(value) }
    
    public mutating func encode(_ value: Float, forKey key: Key)  throws {
        // Since the float may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }
    
    public mutating func encode(_ value: Double, forKey key: Key) throws {
        // Since the double may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }
    
    public mutating func encode<T : Encodable>(_ value: T, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let dictionary = NSMutableDictionary()
        self.container[key.stringValue] = dictionary
        
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        let container = _JSONKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let array = NSMutableArray()
        self.container[key.stringValue] = array
        
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return _JSONUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }
    
    public mutating func superEncoder() -> Encoder {
        return _JSONReferencingEncoder(encoder: self.encoder, reference: .keyed(self.container, key: "super"))
    }
    
    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return _JSONReferencingEncoder(encoder: self.encoder, reference: .keyed(self.container, key: key))
    }
}

fileprivate struct _JSONUnkeyedEncodingContainer : UnkeyedEncodingContainer {
    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: _JSONEncoder
    
    /// A reference to the container we're writing to.
    private let container: NSMutableArray
    
    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]
    
    /// The number of elements encoded into the container.
    public var count: Int {
        return self.container.count
    }
    
    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: _JSONEncoder, codingPath: [CodingKey], wrapping container: NSMutableArray) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }
    
    // MARK: - UnkeyedEncodingContainer Methods
    public mutating func encodeNil()             throws { self.container.add(NSNull()) }
    public mutating func encode(_ value: Bool)   throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int)    throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int8)   throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int16)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int32)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int64)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt)   throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt8)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt16) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt32) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt64) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: String) throws { self.container.add(self.encoder.box(value)) }
    
    public mutating func encode(_ value: Float)  throws {
        // Since the float may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append("index \(self.count)")
        defer { self.encoder.codingPath.removeLast() }
        self.container.add(try self.encoder.box(value))
    }
    
    public mutating func encode(_ value: Double) throws {
        // Since the double may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append("index \(self.count)")
        defer { self.encoder.codingPath.removeLast() }
        self.container.add(try self.encoder.box(value))
    }
    
    public mutating func encode<T : Encodable>(_ value: T) throws {
        self.encoder.codingPath.append("index \(self.count)")
        defer { self.encoder.codingPath.removeLast() }
        self.container.add(try self.encoder.box(value))
    }
    
    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        self.codingPath.append("index \(self.count)")
        defer { self.codingPath.removeLast() }
        
        let dictionary = NSMutableDictionary()
        self.container.add(dictionary)
        
        let container = _JSONKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        self.codingPath.append("index \(self.count)")
        defer { self.codingPath.removeLast() }
        
        let array = NSMutableArray()
        self.container.add(array)
        return _JSONUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }
    
    public mutating func superEncoder() -> Encoder {
        defer { container.add("placeholder") }
        return _JSONReferencingEncoder(encoder: self.encoder, reference: .unkeyed(self.container, index: container.count))
    }
}

extension _JSONEncoder : SingleValueEncodingContainer {
    // MARK: - SingleValueEncodingContainer Methods
    fileprivate func assertCanEncodeNewValue() {
        precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
    }
    
    public func encodeNil() throws {
        assertCanEncodeNewValue()
        self.storage.append((key, NSNull()))
    }
    
    public func encode(_ value: Bool) throws {
        assertCanEncodeNewValue()
        self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: Int) throws {
        assertCanEncodeNewValue()
        self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: Int8) throws {
        assertCanEncodeNewValue()
        self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: Int16) throws {
        assertCanEncodeNewValue()
        self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: Int32) throws {
        assertCanEncodeNewValue()
        self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: Int64) throws {
        assertCanEncodeNewValue()
        self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: UInt) throws {
        assertCanEncodeNewValue()
        self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: UInt8) throws {
        assertCanEncodeNewValue()
        self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: UInt16) throws {
        assertCanEncodeNewValue()
        self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: UInt32) throws {
        assertCanEncodeNewValue()
        self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: UInt64) throws {
        assertCanEncodeNewValue()
        self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: String) throws {
        assertCanEncodeNewValue()
        self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: Float) throws {
        assertCanEncodeNewValue()
        try self.storage.append((key, self.box(value)))
    }
    
    public func encode(_ value: Double) throws {
        assertCanEncodeNewValue()
        try self.storage.append((key, self.box(value)))
    }
    
    public func encode<T : Encodable>(_ value: T) throws {
        assertCanEncodeNewValue()
        try self.storage.append((key, self.box(value)))
    }
}

fileprivate enum FloatingPointError<T: FloatingPoint>: Error {
    case invalidFloatingPoint(T)
}

// MARK: - Concrete Value Representations
extension _JSONEncoder {
    /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
    fileprivate func box(_ value: Bool)   -> Any { return NSNumber(value: value) }
    fileprivate func box(_ value: Int)    -> Any { return NSNumber(value: value) }
    fileprivate func box(_ value: Int8)   -> Any { return NSNumber(value: value) }
    fileprivate func box(_ value: Int16)  -> Any { return NSNumber(value: value) }
    fileprivate func box(_ value: Int32)  -> Any { return NSNumber(value: value) }
    fileprivate func box(_ value: Int64)  -> Any { return NSNumber(value: value) }
    fileprivate func box(_ value: UInt)   -> Any { return NSNumber(value: value) }
    fileprivate func box(_ value: UInt8)  -> Any { return NSNumber(value: value) }
    fileprivate func box(_ value: UInt16) -> Any { return NSNumber(value: value) }
    fileprivate func box(_ value: UInt32) -> Any { return NSNumber(value: value) }
    fileprivate func box(_ value: UInt64) -> Any { return NSNumber(value: value) }
    fileprivate func box(_ value: String) -> Any { return NSString(string: value) }
    
    fileprivate func box(_ float: Float) throws -> Any {
        guard !float.isInfinite && !float.isNaN else {
            guard case let .convertToString(positiveInfinity: posInfString,
                                            negativeInfinity: negInfString,
                                            nan: nanString) = self.options.nonConformingFloatEncodingStrategy else {
                                                throw FloatingPointError.invalidFloatingPoint(float)
            }
            
            if float == Float.infinity {
                return NSString(string: posInfString)
            } else if float == -Float.infinity {
                return NSString(string: negInfString)
            } else {
                return NSString(string: nanString)
            }
        }
        
        return NSNumber(value: float)
    }
    
    fileprivate func box(_ double: Double) throws -> Any {
        guard !double.isInfinite && !double.isNaN else {
            guard case let .convertToString(positiveInfinity: posInfString,
                                            negativeInfinity: negInfString,
                                            nan: nanString) = self.options.nonConformingFloatEncodingStrategy else {
                                                throw FloatingPointError.invalidFloatingPoint(double)
            }
            
            if double == Double.infinity {
                return NSString(string: posInfString)
            } else if double == -Double.infinity {
                return NSString(string: negInfString)
            } else {
                return NSString(string: nanString)
            }
        }
        
        return NSNumber(value: double)
    }
    
    fileprivate func box(_ date: Date) throws -> Any {
        switch self.options.dateEncodingStrategy {
        case .deferredToDate:
            // Must be called with a surrounding with(pushedKey:) call.
            try date.encode(to: self)
            return self.storage.removeLast().value
            
        case .secondsSince1970:
            return NSNumber(value: date.timeIntervalSince1970)
            
        case .millisecondsSince1970:
            return NSNumber(value: 1000.0 * date.timeIntervalSince1970)
            
        case .iso8601:
            if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                return NSString(string: ISO8601DateFormatter.shared.string(from: date))
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }
            
        case .formatted(let formatter):
            return NSString(string: formatter.string(from: date))
            
        case .custom(let closure):
            let depth = self.storage.count
            try closure(date, self)
            
            guard self.storage.count > depth else {
                // The closure didn't encode anything. Return the default keyed container.
                return NSDictionary()
            }
            
            // We can pop because the closure encoded something.
            return self.storage.removeLast().value
        }
    }
    
    fileprivate func box(_ data: Data) throws -> Any {
        switch self.options.dataEncodingStrategy {
        case .deferredToData:
            // Must be called with a surrounding with(pushedKey:) call.
            try data.encode(to: self)
            return self.storage.removeLast().value
            
        case .base64:
            return NSString(string: data.base64EncodedString())
            
        case .custom(let closure):
            let depth = self.storage.count
            try closure(data, self)
            
            guard self.storage.count > depth else {
                // The closure didn't encode anything. Return the default keyed container.
                return NSDictionary()
            }
            
            // We can pop because the closure encoded something.
            return self.storage.removeLast().value
        }
    }
    
    fileprivate func box<T : Encodable>(_ value: T) throws -> Any {
        return try self.box_(value) ?? NSDictionary()
    }
    
    // This method is called "box_" instead of "box" to disambiguate it from the overloads. Because the return type here is different from all of the "box" overloads (and is more general), any "box" calls in here would call back into "box" recursively instead of calling the appropriate overload, which is not what we want.
    fileprivate func box_<T : Encodable>(_ value: T) throws -> Any? {
        if T.self == Date.self || T.self == NSDate.self {
            // Respect Date encoding strategy
            return try self.box((value as! Date))
        } else if T.self == Data.self || T.self == NSData.self {
            // Respect Data encoding strategy
            return try self.box((value as! Data))
        } else if T.self == URL.self || T.self == NSURL.self {
            // Encode URLs as single strings.
            return self.box((value as! URL).absoluteString)
        } else if T.self == Decimal.self || T.self == NSDecimalNumber.self {
            // JSONSerialization can natively handle NSDecimalNumber.
            return (value as! NSDecimalNumber)
        }
        
        // The value should request a container from the _JSONEncoder.
        let depth = self.storage.count
        try value.encode(to: self)
        
        // The top container should be a new container.
        guard self.storage.count > depth else {
            return nil
        }
        
        return self.storage.removeLast().value
    }
}

enum EncoderReferenceValue {
    case keyed(NSMutableDictionary, key: CodingKey)
    case unkeyed(NSMutableArray, index: Int)
}

// MARK: - _JSONReferencingEncoder
/// _JSONReferencingEncoder is a special subclass of _JSONEncoder which has its own storage, but references the contents of a different encoder.
/// It's used in superEncoder(), which returns a new encoder for encoding a superclass -- the lifetime of the encoder should not escape the scope it's created in, but it doesn't necessarily know when it's done being used (to write to the original container).
fileprivate class _JSONReferencingEncoder : _JSONEncoder {
    // MARK: Reference types.
    
    /// The container reference itself.
    private let reference: EncoderReferenceValue
    
    var previousPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` by referencing the given array container in the given encoder.
    fileprivate init(encoder: _JSONEncoder, reference: EncoderReferenceValue, previousPath: [CodingKey] = []) {
        
        self.previousPath = previousPath
        self.reference = reference
        
        super.init(options: encoder.options, codingPath: encoder.codingPath)
        
        self.codingPath.append("index: \(index)")
    }
    
    // MARK: - Coding Path Operations
//    fileprivate override var canEncodeNewValue: Bool {
//        // With a regular encoder, the storage and coding path grow together.
//        // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
//        // We have to take this into account.
//        return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
//    }
    
    func _key(from key: CodingKey) -> Any {
        // TODO: setup usesStringValue
        if true {
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

