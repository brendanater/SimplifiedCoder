//
//  SimplifiedCoderTests.swift
//  SimplifiedCoderTests
//
//  Created by Brendan Henderson on 8/23/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import XCTest
@testable import SimplifiedCoder

let dict = [
    "test": "test",
    "test2": "throw"
]

let arr = [
    "throw"
]

let top = "throw"

let topInt = 1

let topDouble = 1.1

class TestObject: Codable {
    
    struct Test: Codable {
        var int = 1
        var str = "throw"
    }
    
    var int = 1
    var str = "test"
    var struct_ = Test()
    
}

class TestEncoder: XCTestCase {
    
    typealias Encoder = TestEncoderBase
    
    var encoder: Encoder = .init(options: (), userInfo: [:])
    
    func testArr() {
        
        let value = [[[arr]]]
        
        do {
            _ = try value.encode(to: encoder)
            
            XCTFail("no error was thrown")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(context.underlyingError is AnError?)
            
            XCTAssert(context.codingPath.count == 4, "Unexpected path count: \(context.codingPath.count)")
            
            XCTAssert(value as? String == "throw")
            
        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }
    
    func testDict() {
        
        let value = ["":[dict]]
        
        do {
            _ = try value.encode(to: encoder)
            
            XCTFail("no error was thrown")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(context.underlyingError is AnError?)
            
            XCTAssert(context.codingPath.count == 3, "Unexpected path count: \(context.codingPath.count)")
            
            XCTAssert(value as? String == "throw")
            
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
            
            XCTAssert(value as? String == "throw")
            
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
        
        do {
            
            try value.encode(to: encoder)
            
            let value = encoder.storage.removeLast()
            
            XCTFail("no error was thrown: \(value)")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(context.underlyingError is AnError?)
            
            XCTAssert(context.codingPath.count == 2, "Unexpected path count: \(context.codingPath.count)")
            
            XCTAssert(value as? String == "throw")
            
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
    
    func box(_ value: String) throws -> Any {
        
        if value == "throw" {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "any"))
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



















