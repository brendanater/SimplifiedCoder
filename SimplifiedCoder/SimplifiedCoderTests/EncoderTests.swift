//
//  SimplifiedCoderTests.swift
//  SimplifiedCoderTests
//
//  Created by Brendan Henderson on 8/23/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import XCTest
@testable import SimplifiedCoder

class TestEncoderCase: XCTestCase {
    
    var jsonEncoder = JSONEncoder()
    
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
    
    func start(with value: Encodable) throws -> Any {
        return try TestEncoder().encode(value: value)
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
            
            let value2 = try self.start(with: value)
            
            XCTAssert(same(value1, value2), "values not the same: \(value1, value2)")
            
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
            
            let value2 = try self.start(with: value)
            
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
            
            let value2 = try self.start(with: value)
            
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
            
            let value2 = try self.start(with: value)
            
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
            
            let value2 = try self.start(with: value)
            
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
            
            let value2 = try self.start(with: value)
            
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
            
            let value2 = try self.start(with: value)
            
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
            let value = try self.start(with: value)
            
            XCTFail("no error was thrown, value: \(value)")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
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
            return
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(value as? Float == Float.infinity)
            
            defaultErrorContext = context
            
        } catch {
            XCTFail()
            return
        }
        
        do {
            _ = try self.start(with: value)
            
            XCTFail("no error was thrown")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
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
        
        let value = Float.infinity
        
        do {
            _ = try self.start(with: value)
            
            XCTFail("no error was thrown")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(context.codingPath.count == 0, "Unexpected path count: \(context.codingPath.count)")
            
            XCTAssert(value as? Float == Float.infinity)
            
        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }
    
    func testTopInt() {
        
        let value = 1
        
        do {
            
            let result = try self.start(with: value)
            
            XCTAssert(result is Int)
            XCTAssert(result as? Int == 1)
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
    
    func testTopDouble() {
        
        let value = 1.1
        
        do {
            
            let result = try self.start(with: value)
            
            XCTAssert(result is Double)
            XCTAssert(result as? Double == topDouble)
            
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
            return
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(value as? Float == Float.infinity)
            
            defaultErrorContext = context
            
        } catch {
            XCTFail()
            return
        }
        
        do {
            let value = try self.start(with: value)
            
            XCTFail("no error was thrown: \(value)")
            
        } catch EncodingError.invalidValue(let value, let context) {
            
            XCTAssert(
                defaultErrorContext.codingPath.count == context.codingPath.count,
                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count)"
            )
            
            XCTAssert(value as? Float == Float.infinity)
            
        } catch {
            XCTFail("\(type(of: error)).\(error)")
        }
    }
    
    class SuperClass: Codable {
        
        var variable1 = Float.infinity
    }
    
    class SubClass: SuperClass {
        
        var variable2 = 2
        
        private enum CodingKeys: String, CodingKey {
            
            case variable2
        }
        
        override func encode(to encoder: Encoder) throws {
            
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(variable2, forKey: .variable2)
            
            try super.encode(to: container.superEncoder())
        }
        
        override init() {
            super.init()
        }
        
        required init(from decoder: Decoder) throws {
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            variable2 = try container.decode(Int.self, forKey: .variable2)
            
            try super.init(from: try container.superDecoder())
        }
    }
    
    func testSuper() {
        
        let value = SubClass()

        let defaultErrorContext: EncodingError.Context

        do {
            
            _ = try jsonEncoder.encode(value)
            
            XCTFail()
            return

        } catch EncodingError.invalidValue(let value, let context) {

            XCTAssert(value as? Float == Float.infinity)

            defaultErrorContext = context

        } catch {
            XCTFail("\(error)")
            return
        }

        do {

            let result = try self.start(with: value)

            XCTFail("no error was thrown: \(result)")

        } catch EncodingError.invalidValue(let value, let context) {

            XCTAssert(
                defaultErrorContext.codingPath.count == context.codingPath.count,
                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count) (\(defaultErrorContext.codingPath), \(context.codingPath))"
            )
            
            // expected: ["super", "variable1"]

            XCTAssert(value as? Float == Float.infinity)

        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }
}



















