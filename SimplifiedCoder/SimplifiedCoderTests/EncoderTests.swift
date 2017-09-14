//
//  SimplifiedCoderTests.swift
//  SimplifiedCoderTests
//
//  Created by Brendan Henderson on 8/23/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import XCTest
@testable import SimplifiedCoder

class TestEncoder: XCTestCase {
    
    var encoder: TestEncoderBase = .init(options: (), userInfo: [:])
    
    var jsonEncoder: JSONEncoder = .init()
    
    // MARK: ObjectTests
    
    func same(_ value1: Any, _ value2: Any) -> Bool {
        
        if let array1 = value1 as? NSArray {
            
            guard let array2 = value2 as? NSArray else {
                return false
            }
            
            for (index, value1) in array1.enumerated() {
                guard index < array2.count else {
                    return false
                }
                
                let value2 = array2[index]
                
                if same(value1, value2) == false {
                    return false
                }
            }
            
            return true
            
        } else if let dictionary1 = value1 as? NSDictionary {
            
            guard let dictionary2 = value2 as? NSDictionary else {
                return false
            }
            
            for (key, value1) in dictionary1 {
                guard dictionary2[key] != nil else {
                    return false
                }
                
                let value2 = dictionary2[key]
                
                if same(value1, value2!) == false {
                    return false
                }
            }
            
            return true
            
        } else if value1 as? String != nil, value2 as? String != nil {
            
            return true
            
        } else {
            return type(of: value1) == type(of: value2)
        }
    }
    
    func testArray() {
        
        let value = [1]
        
        let value1: Any
        
        do {
            value1 = try JSONSerialization.jsonObject(with: jsonEncoder.encode(value), options: [])
        } catch {
            XCTFail()
            value1 = 1
        }
        
        do {
            
            let value2 = try encoder.box(value)
            
            XCTAssert(same(value1, value2))
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
    
    func testNestedArray() {
        
        let value = [[[[1]]]]
        
        let value1: Any
        
        do {
            value1 = try JSONSerialization.jsonObject(with: jsonEncoder.encode(value), options: [])
        } catch {
            XCTFail()
            value1 = 1
        }
        
        do {
            
            let value2 = try encoder.box(value)
            
            XCTAssert(same(value1, value2))
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
    
    func testDictionary() {
        
        let value = ["":1]
        
        let value1: Any
        
        do {
            value1 = try JSONSerialization.jsonObject(with: jsonEncoder.encode(value), options: [])
            
        } catch {
            XCTFail()
            value1 = 1
        }
        
        do {
            
            let value2 = try encoder.box(value)
            
            XCTAssert(same(value1, value2))
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
    
    func testNestedDictionary() {
        
        let value = ["":["": ["": 3]]]
        
        let value1: Any
        
        do {
            value1 = try JSONSerialization.jsonObject(with: jsonEncoder.encode(value), options: [])
            
        } catch {
            XCTFail()
            value1 = 1
        }
        
        do {
            
            let value2 = try encoder.box(value)
            
            XCTAssert(same(value1, value2))
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
    
    func testMixedDictionaryAndArray() {
        
        let value = ["":["": ["": [["": ["": [[[["": [1]]]]]]]]]]]
        
        let value1: Any
        
        do {
            value1 = try JSONSerialization.jsonObject(with: jsonEncoder.encode(value), options: [])
            
        } catch {
            XCTFail()
            value1 = 1
        }
        
        do {
            
            let value2 = try encoder.box(value)
            
            XCTAssert(same(value1, value2))
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
    
    class Object1: Codable {
        var value = 1
        var array = [1]
        var dictionary = ["": 2]
        var nestedDictionary = ["": [1]]
    }
    
    class WithNestedClass: Codable {
        class Nested: Codable {
            var value = 1
        }
        
        var value = 1
        var value2 = "test"
        var nested = Nested()
    }
    
    func testObject() {
        
        let value = Object1()
        
        let value1: Any
        
        do {
            value1 = try JSONSerialization.jsonObject(with: jsonEncoder.encode(value), options: [])
            
        } catch {
            XCTFail()
            value1 = 1
        }
        
        do {
            
            let value2 = try encoder.box(value)
            
            XCTAssert(same(value1, value2))
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
    
    func testNestedObject() {
        
        let value = WithNestedClass()
        
        let value1: [String: Any]
        
        do {
            value1 = try JSONSerialization.jsonObject(with: jsonEncoder.encode(value), options: []) as! [String: Any]
            
        } catch {
            XCTFail()
            value1 = [:]
        }
        
        do {
            
            let value2 = try encoder.box(value)
            
            // NSTaggedPointerString != _NSContinguousString
            
            XCTAssert(same(value1, value2))
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
    
    // MARK: pathTests
    
    let top = Float.infinity
    
    let topInt = 1
    
    let topDouble = 1.1
    
    class TestObject: Codable {
        
        struct Test: Codable {
            var int = 1
            var str = Float.infinity
        }
        
        var int = 1
        var str = "test"
        var struct_ = Test()
        
    }
    
    func testArr() {
        
        let value = [[[[Float.infinity]]]]
        
        let defaultErrorContext: EncodingError.Context
        
        do {
            _ = try jsonEncoder.encode(value)
            XCTFail()
            defaultErrorContext = .init(codingPath: [CodingKey].init(repeating: "", count: 1000), debugDescription: "")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(value as? Float == Float.infinity)
            
            defaultErrorContext = context
            
        } catch {
            XCTFail()
            defaultErrorContext = .init(codingPath: [CodingKey].init(repeating: "", count: 1000), debugDescription: "")
        }
        
        do {
            _ = try value.encode(to: encoder)
            
            XCTFail("no error was thrown")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(context.underlyingError is AnError?)
            
            XCTAssert(
                defaultErrorContext.codingPath.count == context.codingPath.count,
                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count)"
            )
            
            XCTAssert(value as? Float == Float.infinity)
            
        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }
    
    func testDict() {
        
        let value = [
            "test": 1.1,
            "test2": Float.infinity
        ]
        
        let defaultErrorContext: EncodingError.Context
        
        do {
            _ = try jsonEncoder.encode(value)
            XCTFail()
            defaultErrorContext = .init(codingPath: [CodingKey].init(repeating: "", count: 1000), debugDescription: "")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(value as? Float == Float.infinity)
            
            defaultErrorContext = context
            
        } catch {
            XCTFail()
            defaultErrorContext = .init(codingPath: [CodingKey].init(repeating: "", count: 1000), debugDescription: "")
        }
        
        do {
            _ = try value.encode(to: encoder)
            
            XCTFail("no error was thrown")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(context.underlyingError is AnError?)
            
            XCTAssert(
                defaultErrorContext.codingPath.count == context.codingPath.count,
                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count)"
            )
            
            XCTAssert(value as? Float == Float.infinity)
            
        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }
    
    func testTop() {
        
        let value = top
        
        do {
            _ = try value.encode(to: encoder)
            
            XCTFail("no error was thrown")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(context.underlyingError is AnError?)
            
            XCTAssert(context.codingPath.count == 0, "Unexpected path count: \(context.codingPath.count)")
            
            XCTAssert(value as? Float == Float.infinity)
            
        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }
    
    func testTopInt() {
        
        do {
            try (topInt as Optional<Int>)?.encode(to: encoder)
            
            let value = encoder.storage.removeLast().value
            
            XCTAssert(value is Int)
            XCTAssert(value as? Int == topInt)
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
    
    func testTopDouble() {
        
        do {
            try topDouble.encode(to: encoder)
            
            let value = encoder.storage.removeLast().value
            
            XCTAssert(value is Double)
            XCTAssert(value as? Double == topDouble)
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
    
    func testTestObject() {
        
        let value = TestObject()
        
        let defaultErrorContext: EncodingError.Context
        
        do {
            _ = try jsonEncoder.encode(value)
            XCTFail()
            defaultErrorContext = .init(codingPath: [CodingKey].init(repeating: "", count: 1000), debugDescription: "")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(value as? Float == Float.infinity)
            
            defaultErrorContext = context
            
        } catch {
            XCTFail()
            defaultErrorContext = .init(codingPath: [CodingKey].init(repeating: "", count: 1000), debugDescription: "")
        }
        
        do {
            _ = try value.encode(to: encoder)
            
            XCTFail("no error was thrown")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(context.underlyingError is AnError?)
            
            XCTAssert(
                defaultErrorContext.codingPath.count == context.codingPath.count,
                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count)"
            )
            
            XCTAssert(value as? Float == Float.infinity)
            
        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }
}

enum AnError: Error {
    case error
}

class TestEncoderBase: TypedEncoderBase {
    
    var unkeyedContainerType: EncoderUnkeyedContainer.Type = TestEncoderUnkeyedContainer.self
    
    var referenceType: EncoderReference.Type = TestEncoderReference.self
    
    typealias Options = ()
    
    var options: ()
    var userInfo: [CodingUserInfoKey : Any]
    
    var storage: [(key: CodingKey?, value: Any)] = []
    var key: CodingKey? = nil
    
    var codingPath: [CodingKey] {
        return _codingPath
    }
    
    required init(options: (), userInfo: [CodingUserInfoKey : Any]) {
        self.options = options
        self.userInfo = userInfo
    }
    
    func box(_ value: Float) throws -> Any {
        
        if value == Float.infinity {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: self.codingPath, debugDescription: "any"))
        } else {
            return value
        }
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return self.createKeyedContainer(TestEncoderKeyedContainer<Key>.self)
    }
}

struct TestEncoderKeyedContainer<K: CodingKey>: EncoderKeyedContainer {
    typealias Key = K
    
    var encoder: EncoderBase
    var container: EncoderKeyedContainerType
    var nestedPath: [CodingKey]
    
    init(encoder: EncoderBase, container: EncoderKeyedContainerType, nestedPath: [CodingKey]) {
        self.encoder = encoder
        self.container = container
        self.nestedPath = nestedPath
    }
    
    static func initSelf<Key>(encoder: EncoderBase, container: EncoderKeyedContainerType, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(TestEncoderKeyedContainer<Key>(encoder: encoder, container: container, nestedPath: nestedPath))
    }
    
    var usesStringValue: Bool = true
}

struct TestEncoderUnkeyedContainer: EncoderUnkeyedContainer {
    
    var encoder: EncoderBase
    var container: EncoderUnkeyedContainerType
    var nestedPath: [CodingKey]
    
    init(encoder: EncoderBase, container: EncoderUnkeyedContainerType, nestedPath: [CodingKey]) {
        self.encoder = encoder
        self.container = container
        self.nestedPath = nestedPath
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return self.createKeyedContainer(TestEncoderKeyedContainer<NestedKey>.self)
    }
}

class TestEncoderReference: TestEncoderBase, EncoderReference {
    
    var reference: EncoderReferenceValue = .unkeyed(NSMutableArray(), index: 1)
    var previousPath: [CodingKey] = []
    
    lazy var usesStringValue: Bool = true
    
    override var codingPath: [CodingKey] {
        return _codingPath
    }
    
    deinit {
        willDeinit()
    }
}



















