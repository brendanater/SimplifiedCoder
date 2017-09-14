//
//  URLDecoder.swift
//  SimplifiedCoderTests
//
//  Created by Brendan Henderson on 9/14/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import Foundation
import XCTest
@testable
import SimplifiedCoder



class TestURLDecoder: XCTestCase {
    
    var decoder = URLDecoder()
    
    func _type<T>(of: T) -> T.Type {
        return T.self
    }

    func testArray() {

        let value = ["key": [1]]

        let expectedResult = "key[]=1"

        do {
            
            _ = try decoder.decode(_type(of: value), from: expectedResult)

        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testNestedArray() {

        let value = [[[[1]]]]
        
        let expectedResult = "[][][][]=1"

        do {

            _ = try decoder.decode(_type(of: value), from: expectedResult)

            XCTFail()

        } catch URLQuerySerializer.FromQueryError.invalidName(let name, reason: _) {
            XCTAssert(name == "[][][][]")
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testDictionary() {

        let value = ["key": ["key2":1]]

        let expectedResult = "key[key2]=1"

        do {
            
            _ = try decoder.decode(_type(of: value), from: expectedResult)

        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testNestedDictionary() {

        let value = ["key": ["key1":["key2": ["key3": 3], "key4": ["key5": 4]]]]

        let expectedResult = "key[key1][key2][key3]=3&key[key1][key4][key5]=4"

        do {

            _ = try decoder.decode(_type(of: value), from: expectedResult)

        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testMixedDictionaryAndArray() {

        let value = ["key1":["key2": ["key3": [["key4": ["key5": [[[["key6": [1]]]]]]]]]]]
        
        let expectedResult = "key1[key2][key3][][key4][key5][][][][key6][]=1"

        do {
            
            _ = try decoder.decode(_type(of: value), from: expectedResult)

            XCTFail()

        } catch URLQuerySerializer.FromQueryError.invalidName(let name, reason: _) {
            XCTAssert(name == "key1[key2][key3][][key4][key5][][][][key6][]")
        } catch {
            XCTFail("Worng error: \(error)")
        }
    }

    class Object1: Codable {
        var value = 1
        var array = [1]
        var dictionary = ["key": 2]
        var nestedDictionary = ["key": [1]]
    }

    class WithNestedClass: Codable {
        class Nested: Codable {
            class NestedNested: Codable {
                var value = 1
            }

            var value = 1
            var nested = NestedNested()
        }

        var value = 1
        var value2 = "test"
        var nested = Nested()
    }

    func testObject() {

        let value = Object1()

        let expectedResult = "value=1&array[]=1&dictionary[key]=2&nestedDictionary[key][]=1"

        do {
            
            _ = try decoder.decode(_type(of: value), from: expectedResult)

        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testNestedObject() {

        let value = WithNestedClass()

        let expectedResult = "value=1&value2=test&nested[value]=1&nested[nested][value]=1"

        do {
            
            _ = try decoder.decode(_type(of: value), from: expectedResult)

        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
}

