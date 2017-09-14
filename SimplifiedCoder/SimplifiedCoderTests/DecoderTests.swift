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

class TestDecoder: XCTestCase {
    
    func decoder(value: Any) -> Decoder & SingleValueDecodingContainer & DecoderBase {
        return TestDecoderBase.init(value: value, codingPath: [], options: (), userInfo: [:])
    }
    
    var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .throw
        return decoder
    }()
    
    func data<T: Encodable>(from value: T) throws -> Data {
        
        let encoder = JSONEncoder()
        
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "pos", negativeInfinity: "neg", nan: "nan")
        
        return try encoder.encode(value)
    }
    
    func value<T: Encodable>(from value: T) throws -> Any {
        
        return try JSONSerialization.jsonObject(with: data(from: value), options: [])
    }
    
    func _type<T>(of: T) -> T.Type {
        return T.self
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

    func testArray() {
        
        let value = [1]

        do {
            
            let decoder = try self.decoder(value: self.value(from: value))

            let value2 = try decoder.decode(_type(of: value))
            
            XCTAssert(same(value, value2), "values not the same: \(value), \(value2)")
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testNestedArray() {

        let value = [[[[1]]]]
        
        do {
            
            let decoder = try self.decoder(value: self.value(from: value))
            
            let value2 = try decoder.decode(_type(of: value))
            
            XCTAssert(same(value, value2), "values not the same: \(value), \(value2)")
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testDictionary() {

        let value = ["":1]
        
        do {
            
            let decoder = try self.decoder(value: self.value(from: value))
            
            let value2 = try decoder.decode(_type(of: value))
            
            XCTAssert(same(value, value2), "values not the same: \(value), \(value2)")
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testNestedDictionary() {

        let value = ["":["": ["": 3]]]
        
        do {
            
            let decoder = try self.decoder(value: self.value(from: value))
            
            let value2 = try decoder.decode(_type(of: value))
            
            XCTAssert(same(value, value2), "values not the same: \(value), \(value2)")
            
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testMixedDictionaryAndArray() {

        let value = ["":["": ["": [["": ["": [[[["": [1]]]]]]]]]]]
        
        do {
            
            let decoder = try self.decoder(value: self.value(from: value))
            
            let value2 = try decoder.decode(_type(of: value))
            
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
            
            let decoder = try self.decoder(value: self.value(from: value))
            
            let value2 = try decoder.decode(_type(of: value))
            
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
            
            let decoder = try self.decoder(value: self.value(from: value))
            
            let value2 = try decoder.decode(_type(of: value))
            
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
            let data = try self.data(from: value)
            
            _ = try jsonDecoder.decode(_type(of: value), from: data)
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
            
            _ = try decoder(value: self.value(from: value)).decode(_type(of: value))

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
            
            _ = try jsonDecoder.decode(_type(of: value), from: data)
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
            
            _ = try decoder(value: self.value(from: value)).decode(_type(of: value))
            
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

        let value = 1.1

        do {
            let value = try decoder(value: value).decode(Int.self)

            XCTFail("no error was thrown. value: \(value)")

        } catch DecodingError.typeMismatch(let type, let context) {

            XCTAssert(context.codingPath.count == 0, "Unexpected path count: \(context.codingPath.count)")

            XCTAssert(type == Int.self)

        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }

    func testTopInt() {
        
        let value = String?.some("pos")
        
        do {
            _ = try decoder(value: value as Any).decode(Float?.self)
            
            XCTFail("no error was thrown")
            
        } catch DecodingError.typeMismatch(let type, let context) {
            
            XCTAssert(context.codingPath.count == 0, "Unexpected path count: \(context.codingPath.count)")
            
            XCTAssert(type == Float.self)
            
        } catch {
            XCTFail("Wrong error was thrown: \(error)")
        }
    }

    func testTopDouble() {
        
        let value = 1.1
        
        do {
            _ = try decoder(value: value).decode(Int.self)
            
            XCTFail("no error was thrown")
            
        } catch DecodingError.typeMismatch(let type, let context) {
            
            XCTAssert(context.codingPath.count == 0, "Unexpected path count: \(context.codingPath.count)")
            
            XCTAssert(type == Int.self)
            
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
            
            _ = try jsonDecoder.decode(_type(of: value), from: data)
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
            
            _ = try decoder(value: self.value(from: value)).decode(_type(of: value))
            
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
            
            _ = try jsonDecoder.decode(_type(of: value), from: data)
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
            
            _ = try decoder(value: self.value(from: value)).decode(_type(of: value))
            
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

class TestDecoderBase: TypedDecoderBase {
    required init(value: Any, codingPath: [CodingKey], options: (), userInfo: [CodingUserInfoKey : Any]) {
        self.storage = [value]
        self.codingPath = codingPath
        self.options = options
        self.userInfo = userInfo
    }
    
    var options: ()
    
    typealias Options = ()
    
    var unkeyedContainerType: DecoderUnkeyedContainer.Type = TestDecoderUnkeyedContainer.self
    
    var storage: [Any]
    
    var codingPath: [CodingKey]
    
    var userInfo: [CodingUserInfoKey : Any]
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return try self.createKeyedContainer(TestDecoderKeyedContainer<Key>.self)
    }
}

struct TestDecoderKeyedContainer<K: CodingKey>: DecoderKeyedContainer {
    var decoder: DecoderBase
    
    var container: DecoderKeyedContainerType
    
    var nestedPath: [CodingKey]
    
    init(decoder: DecoderBase, container: DecoderKeyedContainerType, nestedPath: [CodingKey]) {
        self.decoder = decoder
        self.container = container
        self.nestedPath = nestedPath
    }
    
    static func initSelf<Key>(decoder: DecoderBase, container: DecoderKeyedContainerType, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(TestDecoderKeyedContainer<Key>.init(decoder: decoder, container: container, nestedPath: nestedPath))
    }
    
    var usesStringValue: Bool = true
    
    typealias Key = K
}

struct TestDecoderUnkeyedContainer: DecoderUnkeyedContainer {
    var decoder: DecoderBase
    
    var container: DecoderUnkeyedContainerType
    
    var nestedPath: [CodingKey]
    
    init(decoder: DecoderBase, container: DecoderUnkeyedContainerType, nestedPath: [CodingKey]) {
        self.decoder = decoder
        self.container = container
        self.nestedPath = nestedPath
    }
    
    var currentIndex: Int = 0
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        return try self.createKeyedContainer(TestDecoderKeyedContainer<NestedKey>.self)
    }
    
}

