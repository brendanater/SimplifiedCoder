//
//  DecoderTests.swift
//  SimplifiedCoderTests
//
//  Created by Brendan Henderson on 9/13/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import Foundation
import XCTest
@testable
import SimplifiedCoder

class TestDecoderCase: XCTestCase {
    
    var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .throw
        return decoder
    }()
    
    func getValue(_ value: Any) -> Any {
        if var dictionary = value as? [String: Any] {
            
            for (key, value) in dictionary {
                dictionary[key] = getValue(value)
            }
            
            return dictionary
        } else if let value = value as? NSArray {
            
            var result: [Any] = []
            
            for value in value {
                result.append(getValue(value))
            }
            
            return value
        } else if let value = value as? String {
            return value
        } else if let value = value as? NSNumber {
            return value
        } else {
            let mirror = Mirror(reflecting: value).children
            
            var result: [String: Any] = [:]
            
            for (label, value) in mirror {
                guard let label = label else { continue}
                
                result[label] = getValue(value)
            }
            
            return result
        }
    }
    
    func getError<T: Codable>(_ value: T) throws {
        
        let data = try self.data(from: value)
        
        _ = try jsonDecoder.decode(type(of: value), from: data)
        
    }
    
    func data<T: Encodable>(from value: T) throws -> Data {
        
        let encoder = JSONEncoder()
        
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "pos", negativeInfinity: "neg", nan: "nan")
        
        return try encoder.encode(value)
    }
    
    func value<T: Encodable>(from value: T) throws -> Any {
        
        return try JSONSerialization.jsonObject(with: data(from: value), options: [])
    }

    // MARK: ObjectTests
    
    
    /// tests same dict and array types
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
    
    func decoderUnbox<T: Decodable>(_ value: Any, _ type: T.Type) throws -> T {
        
        return try TestDecoder().decode(T.self, fromValue: value)
    }

    func testArray() {
        
        let value = [1]

        do {
            
            let value2 = try self.decoderUnbox(getValue(value), type(of: value))
            
            XCTAssert(same(value, value2), "values not the same: \(value), \(value2)")
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testNestedArray() {

        let value = [[[[1]]]]
        
        do {
            
            let value2 = try self.decoderUnbox(getValue(value), type(of: value))
            
            XCTAssert(same(value, value2), "values not the same: \(value), \(value2)")
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testDictionary() {

        let value = ["":1]
        
        do {
            
            let value2 = try self.decoderUnbox(getValue(value), type(of: value))
            
            XCTAssert(same(value, value2), "values not the same: \(value), \(value2)")
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testNestedDictionary() {

        let value = ["":["": ["": 3]]]
        
        do {
            
            let value2 = try self.decoderUnbox(getValue(value), type(of: value))
            
            XCTAssert(same(value, value2), "values not the same: \(value), \(value2)")
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testMixedDictionaryAndArray() {

        let value = ["":["": ["": [["": ["": [[[["": [1]]]]]]]]]]]
        
        do {
            
            let value2 = try self.decoderUnbox(getValue(value), type(of: value))
            
            XCTAssert(same(value, value2), "values not the same: \(value), \(value2)")
            
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
    
    func testObject() {

        let value = Object1()
        
        do {
            
            let value2 = try self.decoderUnbox(getValue(value), type(of: value))
            
            XCTAssert(same(value, value2), "values not the same: \(value), \(value2)")
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    class WithNestedClass: Codable {
        class Nested: Codable {
            var value = 1
        }

        var value = 1
        var value2 = "test"
        var nested = Nested()
    }
    
    func testNestedObject() {

        let value = WithNestedClass()
        
        do {
            
            let value2 = try self.decoderUnbox(getValue(value), type(of: value))
            
            XCTAssert(same(value, value2), "values not the same: \(value), \(value2)")
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    // MARK: pathTests

    func testArr() {

        let value = [[[[Float.infinity]]]]

        let defaultErrorContext: DecodingError.Context
        
        do {
            try getError(value)
            
            XCTFail()
            return
            
        } catch DecodingError.typeMismatch(let type, let context) {
            
            XCTAssert(type == Float.self)
            
            defaultErrorContext = context
            
        } catch {
            XCTFail("\(error)")
            return
        }
        

        do {
            
            _ = try decoderUnbox(getValue(value), type(of: value))

            XCTFail("no error was thrown")

        } catch DecodingError.typeMismatch(let type, let context) {

            XCTAssert(
                defaultErrorContext.codingPath.count == context.codingPath.count,
                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count)"
            )
            
            XCTAssert(type == Float.self)

        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }

    func testDict() {

        let value = [
            "test": 1.1,
            "test2": Float.infinity
        ]
        
        let defaultErrorContext: DecodingError.Context
        
        do {
            let data = try self.data(from: value)
            
            _ = try jsonDecoder.decode([String: Float].self, from: data)
            XCTFail()
            return
            
        } catch DecodingError.typeMismatch(let type, let context) {
            
            XCTAssert(type == Float.self)
            
            defaultErrorContext = context
            
        } catch {
            XCTFail()
            return
        }
        
        do {
            
            _ = try decoderUnbox(getValue(value), type(of: value))
            
            XCTFail("no error was thrown")
            
        } catch DecodingError.typeMismatch(let type, let context) {
            
            XCTAssert(
                defaultErrorContext.codingPath.count == context.codingPath.count,
                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count)"
            )
            
            XCTAssert(type == Float.self)
            
        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }

    func testTop() {

        let value = Float.infinity

        do {
            let value = try decoderUnbox(getValue(value), type(of: value))

            XCTFail("no error was thrown. value: \(value)")

        } catch DecodingError.typeMismatch(let type, let context) {

            XCTAssert(context.codingPath.count == 0, "Unexpected path count: \(context.codingPath.count)")

            XCTAssert(type == Float.self)

        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }
    
    class TestObject: Codable {
        
        struct Test: Codable {
            var int = 1
            var str = 2
        }
        
        struct Test2: Codable {
            
            struct Test: Codable {
                var nested = TestObject.Test()
            }
            
            var int = 1
            
            var nested = Test()
            
            var str = Float.infinity
        }
        
        var int = 1
        var str = "test"
        var struct_ = Test()
        
        var struct2_ = Test2()
    }

    func testTestObject() {

        let value = TestObject()
        
        let defaultErrorContext: DecodingError.Context
        
        do {
            let data = try self.data(from: value)
            
            _ = try jsonDecoder.decode(type(of: value), from: data)
            XCTFail()
            return
            
        } catch DecodingError.typeMismatch(let type, let context) {
            
            XCTAssert(type == Float.self)
            
            defaultErrorContext = context
            
        } catch {
            XCTFail()
            return
        }
        
        do {
            
            _ = try decoderUnbox(getValue(value), type(of: value))
            
            XCTFail("no error was thrown")
            
        } catch DecodingError.typeMismatch(let type, let context) {
            
            XCTAssert(
                defaultErrorContext.codingPath.count == context.codingPath.count,
                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count) (\(defaultErrorContext.codingPath), \(context.codingPath))"
            )
            
            XCTAssert(type == Float.self)
            
        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }
    
    class TestObject2: Codable {
        
        var int = 1
        var str = Float.infinity
    }
    
    func testObject2() {
        
        let value = TestObject2()
        
        let defaultErrorContext: DecodingError.Context
        
        do {
            let data = try self.data(from: value)
            
            _ = try jsonDecoder.decode(type(of: value), from: data)
            XCTFail()
            return
            
        } catch DecodingError.typeMismatch(let type, let context) {
            
            XCTAssert(type == Float.self)
            
            defaultErrorContext = context
            
        } catch {
            XCTFail()
            return
        }
        
        do {
            
            _ = try decoderUnbox(getValue(value), type(of: value))
            
            XCTFail("no error was thrown")
            
        } catch DecodingError.typeMismatch(let type, let context) {
            
            XCTAssert(
                defaultErrorContext.codingPath.count == context.codingPath.count,
                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count) (\(defaultErrorContext.codingPath), \(context.codingPath))"
            )
            
            XCTAssert(type == Float.self)
            
        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }
    
    struct TestNestedPath: Codable {
        
        func encode(to encoder: Encoder) throws {
            
            var container = encoder.container(keyedBy: String.self)
            
            var nestedContainer = container.nestedContainer(keyedBy: String.self, forKey: "value")
            
            var nestedNestedContainer = nestedContainer.nestedContainer(keyedBy: String.self, forKey: "test")
            
            try nestedNestedContainer.encode(Float.infinity, forKey: "testing")
        }
        
        init(from decoder: Decoder) throws {
            
            let container = try decoder.container(keyedBy: String.self)

            let nestedContainer = try container.nestedContainer(keyedBy: String.self, forKey: "value")

            let nestedNestedContainer = try nestedContainer.nestedContainer(keyedBy: String.self, forKey: "test")

            _ = try nestedNestedContainer.decode(Float.self, forKey: "testing")
        }
    }
    
    
    func testDefaultCorrectNestedContainer() {
        
        let value = ["value": ["test": ["testing": Float.infinity]]]
        
        let encoder = JSONEncoder()
        
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "", negativeInfinity: "", nan: "")
        
        do {
            
            let data = try encoder.encode(value)
            
            do {
                
                let value = try jsonDecoder.decode(TestNestedPath.self, from: data)
                
                XCTFail("no error: \(value)")
                
            } catch DecodingError.typeMismatch(let type, let context) {
            
                XCTAssert(type == Float.self)
                
                XCTAssert(context.codingPath.count != 3 && context.codingPath.count == 1)
                
            } catch {
                XCTFail("\(error)")
            }
            
            
        } catch {
            XCTFail()
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
        
        let expected = ["variable2": 2, "super": ["variable1": Float.infinity]] as Any
        
        let defaultErrorContext: DecodingError.Context
        
        do {
            let data = try self.data(from: value)
            
            _ = try jsonDecoder.decode(type(of: value), from: data)
            XCTFail()
            return
            
        } catch DecodingError.typeMismatch(let type, let context) {
            
            XCTAssert(type == Float.self)
            
            defaultErrorContext = context
            
        } catch {
            XCTFail("\(error)")
            return
        }
        
        do {
            
            _ = try decoderUnbox(expected, type(of: value))
            
            XCTFail("no error was thrown")
            
        } catch DecodingError.typeMismatch(let type, let context) {
            
            XCTAssert(
                defaultErrorContext.codingPath.count == context.codingPath.count,
                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count) (\(defaultErrorContext.codingPath), \(context.codingPath))"
            )
            
            XCTAssert(type == Float.self)
            
        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }
}

