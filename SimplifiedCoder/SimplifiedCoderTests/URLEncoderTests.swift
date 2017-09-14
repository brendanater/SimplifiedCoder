//
//  URLEncoderTests.swift
//  SimplifiedCoderTests
//
//  Created by Brendan Henderson on 9/13/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import Foundation
import XCTest
@testable
import SimplifiedCoder

class TestURLEncoder: XCTestCase {
    
    var encoder = URLEncoder()

    func testArray() {

        let value = ["key": [1]]
        
        let expectedResult = "key[]=1"

        do {

            let string = try String(data: self.encoder.encode(value), encoding: .utf8)

            XCTAssert(string != nil)
            
            XCTAssert(string ?? "" == expectedResult, "Incorrect string: \(string ?? "")")

        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testNestedArray() {

        let value = [[[[1]]]]

        do {

            _ = try self.encoder.encode(value)

            XCTFail()

        } catch URLEncoder.URLEncoderError.incorrectTopLevelObject(_) {
            
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testDictionary() {

        let value = ["key": ["key2":1]]
        
        let expectedResult = "key[key2]=1"
        
        do {
            
            let string = try String(data: self.encoder.encode(value), encoding: .utf8)
            
            XCTAssert(string != nil)
            
            XCTAssert(string! == expectedResult, "Incorrect result: \(string!)")
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
//
//    func testNestedDictionary() {
//
//        let value = ["":["": ["": 3]]]
//
//        let value1: Any
//
//        do {
//            value1 = try JSONSerialization.jsonObject(with: jsonEncoder.encode(value), options: [])
//
//        } catch {
//            XCTFail()
//            value1 = 1
//        }
//
//        do {
//
//            let value2 = try encoder.box(value)
//
//            XCTAssert(same(value1, value2))
//
//        } catch {
//            XCTFail("Error was thrown: \(error)")
//        }
//    }
//
//    func testMixedDictionaryAndArray() {
//
//        let value = ["":["": ["": [["": ["": [[[["": [1]]]]]]]]]]]
//
//        let value1: Any
//
//        do {
//            value1 = try JSONSerialization.jsonObject(with: jsonEncoder.encode(value), options: [])
//
//        } catch {
//            XCTFail()
//            value1 = 1
//        }
//
//        do {
//
//            let value2 = try encoder.box(value)
//
//            XCTAssert(same(value1, value2))
//
//        } catch {
//            XCTFail("Error was thrown: \(error)")
//        }
//    }
//
//    class Object1: Codable {
//        var value = 1
//        var array = [1]
//        var dictionary = ["": 2]
//        var nestedDictionary = ["": [1]]
//    }
//
//    class WithNestedClass: Codable {
//        class Nested: Codable {
//            var value = 1
//        }
//
//        var value = 1
//        var value2 = "test"
//        var nested = Nested()
//    }
//
//    func testObject() {
//
//        let value = Object1()
//
//        let value1: Any
//
//        do {
//            value1 = try JSONSerialization.jsonObject(with: jsonEncoder.encode(value), options: [])
//
//        } catch {
//            XCTFail()
//            value1 = 1
//        }
//
//        do {
//
//            let value2 = try encoder.box(value)
//
//            XCTAssert(same(value1, value2))
//
//        } catch {
//            XCTFail("Error was thrown: \(error)")
//        }
//    }
//
//    func testNestedObject() {
//
//        let value = WithNestedClass()
//
//        let value1: [String: Any]
//
//        do {
//            value1 = try JSONSerialization.jsonObject(with: jsonEncoder.encode(value), options: []) as! [String: Any]
//
//        } catch {
//            XCTFail()
//            value1 = [:]
//        }
//
//        do {
//
//            let value2 = try encoder.box(value)
//
//            // NSTaggedPointerString != _NSContinguousString
//
//            XCTAssert(same(value1, value2))
//
//        } catch {
//            XCTFail("Error was thrown: \(error)")
//        }
//    }
//
//    // MARK: pathTests
//
//    let top = Float.infinity
//
//    let topInt = 1
//
//    let topDouble = 1.1
//
//    class TestObject: Codable {
//
//        struct Test: Codable {
//            var int = 1
//            var str = Float.infinity
//        }
//
//        var int = 1
//        var str = "test"
//        var struct_ = Test()
//
//    }
//
//    func testArr() {
//
//        let value = [[[[Float.infinity]]]]
//
//        let defaultErrorContext: EncodingError.Context
//
//        do {
//            _ = try jsonEncoder.encode(value)
//            XCTFail()
//            defaultErrorContext = .init(codingPath: [CodingKey].init(repeating: "", count: 1000), debugDescription: "")
//
//        } catch EncodingError.invalidValue(let value, let context) {
//
//            XCTAssert(value as? Float == Float.infinity)
//
//            defaultErrorContext = context
//
//        } catch {
//            XCTFail()
//            defaultErrorContext = .init(codingPath: [CodingKey].init(repeating: "", count: 1000), debugDescription: "")
//        }
//
//        do {
//            _ = try value.encode(to: encoder)
//
//            XCTFail("no error was thrown")
//
//        } catch EncodingError.invalidValue(let value, let context) {
//
//            XCTAssert(context.underlyingError is AnError?)
//
//            XCTAssert(
//                defaultErrorContext.codingPath.count == context.codingPath.count,
//                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count)"
//            )
//
//            XCTAssert(value as? Float == Float.infinity)
//
//        } catch {
//            XCTFail("Wrong error was thrown: \(error)")
//        }
//    }
//
//    func testDict() {
//
//        let value = [
//            "test": 1.1,
//            "test2": Float.infinity
//        ]
//
//        let defaultErrorContext: EncodingError.Context
//
//        do {
//            _ = try jsonEncoder.encode(value)
//            XCTFail()
//            defaultErrorContext = .init(codingPath: [CodingKey].init(repeating: "", count: 1000), debugDescription: "")
//
//        } catch EncodingError.invalidValue(let value, let context) {
//
//            XCTAssert(value as? Float == Float.infinity)
//
//            defaultErrorContext = context
//
//        } catch {
//            XCTFail()
//            defaultErrorContext = .init(codingPath: [CodingKey].init(repeating: "", count: 1000), debugDescription: "")
//        }
//
//        do {
//            _ = try value.encode(to: encoder)
//
//            XCTFail("no error was thrown")
//
//        } catch EncodingError.invalidValue(let value, let context) {
//
//            XCTAssert(context.underlyingError is AnError?)
//
//            XCTAssert(
//                defaultErrorContext.codingPath.count == context.codingPath.count,
//                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count)"
//            )
//
//            XCTAssert(value as? Float == Float.infinity)
//
//        } catch {
//            XCTFail("Wrong error was thrown: \(error)")
//        }
//    }
//
//    func testTop() {
//
//        let value = top
//
//        do {
//            _ = try value.encode(to: encoder)
//
//            XCTFail("no error was thrown")
//
//        } catch EncodingError.invalidValue(let value, let context) {
//
//            XCTAssert(context.underlyingError is AnError?)
//
//            XCTAssert(context.codingPath.count == 0, "Unexpected path count: \(context.codingPath.count)")
//
//            XCTAssert(value as? Float == Float.infinity)
//
//        } catch {
//            XCTFail("Wrong error was thrown: \(error)")
//        }
//    }
//
//    func testTopInt() {
//
//        do {
//            try (topInt as Optional<Int>)?.encode(to: encoder)
//
//            let value = encoder.storage.removeLast().value
//
//            XCTAssert(value is Int)
//            XCTAssert(value as? Int == topInt)
//
//        } catch {
//            XCTFail("Error was thrown: \(error)")
//        }
//    }
//
//    func testTopDouble() {
//
//        do {
//            try topDouble.encode(to: encoder)
//
//            let value = encoder.storage.removeLast().value
//
//            XCTAssert(value is Double)
//            XCTAssert(value as? Double == topDouble)
//
//        } catch {
//            XCTFail("Error was thrown: \(error)")
//        }
//    }
//
//    func testTestObject() {
//
//        let value = TestObject()
//
//        let defaultErrorContext: EncodingError.Context
//
//        do {
//            _ = try jsonEncoder.encode(value)
//            XCTFail()
//            defaultErrorContext = .init(codingPath: [CodingKey].init(repeating: "", count: 1000), debugDescription: "")
//
//        } catch EncodingError.invalidValue(let value, let context) {
//
//            XCTAssert(value as? Float == Float.infinity)
//
//            defaultErrorContext = context
//
//        } catch {
//            XCTFail()
//            defaultErrorContext = .init(codingPath: [CodingKey].init(repeating: "", count: 1000), debugDescription: "")
//        }
//
//        do {
//            _ = try value.encode(to: encoder)
//
//            XCTFail("no error was thrown")
//
//        } catch EncodingError.invalidValue(let value, let context) {
//
//            XCTAssert(context.underlyingError is AnError?)
//
//            XCTAssert(
//                defaultErrorContext.codingPath.count == context.codingPath.count,
//                "Differing codingPath count. Expected: \(defaultErrorContext.codingPath.count) actual: \(context.codingPath.count)"
//            )
//
//            XCTAssert(value as? Float == Float.infinity)
//
//        } catch {
//            XCTFail("Wrong error was thrown: \(error)")
//        }
//    }
}















