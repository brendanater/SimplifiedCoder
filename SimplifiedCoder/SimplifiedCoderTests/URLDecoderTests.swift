//
//  URLDecoderTests.swift
//  SimplifiedCoderTests
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
import XCTest
import SimplifiedCoder


class TestURLDecoder: XCTestCase {
    
    var decoder = { () -> URLDecoder in
        
        var decoder = URLDecoder()
        
        decoder.serializer.arraySerialization = .arraysAreDictionaries
        
        return decoder
    }()

    func testArray() {
        
        // top-level cannot be array
        let value = ["key": [UInt64.max, UInt64.min]]

        let expectedResult = "key[]=\(UInt64.max)&key[]=\(UInt64.min)"
        
        let expectedResult2 = "key[1]=\(UInt64.min)&key[0]=\(UInt64.max)"

        do {
            let result = try decoder.decode(type(of: value), from: expectedResult)
            
            if result["key"]?.count == 2, result["key"]?[0] == UInt64.max && result["key"]?[1] == UInt64.min {
                
            } else {
                XCTFail("incorrect: \(result)")
            }
            
            if case .arraysAreDictionaries = self.decoder.serializer.arraySerialization {
                
                do {
                    let result = try decoder.decode(type(of: value), from: expectedResult2)
                    
                    if result["key"]?.count == 2, result["key"]?[0] == UInt64.min && result["key"]?[1] == UInt64.max {
                        
                    } else {
                        XCTFail("incorrect: \(result)")
                    }
                } catch {
                    XCTFail("\(error)")
                }
            }

        } catch {
            XCTFail("\(type(of: error)).\(error)")
        }
    }

    func testNestedArray() {

        let value = ["test": [[[[1]]]]]
        
        let expectedResult = "test[][][][]=1"
        
        let expectedResult2 = "test[0][0][0][0]=1"

        do {

            _ = try decoder.decode(type(of: value), from: expectedResult)

            XCTFail()

        } catch DecodingError.dataCorrupted(let context) {
            
            if let error = (context.underlyingError as? URLQuerySerializer.FromQueryError), case .invalidName(let name, reason: let reason) = error {
                
                XCTAssert(name == "test[][][][]", "\(name), \(reason)")
                
            } else {
                XCTFail("\(context)")
            }
        } catch {
            XCTFail("Worng error: \(error)")
        }
        
        if case .arraysAreDictionaries = self.decoder.serializer.arraySerialization {
            
            do {
                
                let result = try decoder.decode(type(of: value), from: expectedResult2)
                
                if result["test"] != nil, result["test"]!.count > 0, result["test"]![0].count > 0, result["test"]![0][0].count > 0, result["test"]![0][0][0].count > 0 {
                    
                    XCTAssert(result["test"]![0][0][0][0] == 1)
                } else {
                    XCTFail("incorrect: \(result)")
                }
                
            } catch {
                XCTFail("Error thrown: \(error)")
            }
        }
    }

    func testDictionary() {

        let value = ["test": Int.max, "test2": Int.min]

        let expectedResult = "test=\(Int.max)&test2=\(Int.min)"

        do {
            
            let result = try decoder.decode(type(of: value), from: expectedResult)
            
            XCTAssert(result["test"] == Int.max && result["test2"] == Int.min, "incorrect: \(result)")

        } catch {
            XCTFail("error: \(error)")
        }
    }

    func testNestedDictionary() {

        let value = ["key": ["key1":["key2": ["key3": 3], "key4": ["key5": 4]]]]

        let expectedResult = "key[key1][key2][key3]=3&key[key1][key4][key5]=4"

        do {

            _ = try decoder.decode(type(of: value), from: expectedResult)

        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testMixedDictionaryAndArray() {

        let value = ["key1":["key2": ["key3": [["key4": ["key5": [[[["key6": [1]]]]]]]]]]]
        
        let expectedResult = "key1[key2][key3][][key4][key5][][][][key6][]=1"

        do {
            
            _ = try decoder.decode(type(of: value), from: expectedResult)

            XCTFail()

        } catch DecodingError.dataCorrupted(let context) {
            
            if let error = (context.underlyingError as? URLQuerySerializer.FromQueryError), case .invalidName(let name, reason: let reason) = error {
                
                XCTAssert(name == "key1[key2][key3][][key4][key5][][][][key6][]", "\(name), \(reason)")
                
            } else {
                XCTFail("\(context)")
            }
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
            
            _ = try decoder.decode(type(of: value), from: expectedResult)

        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testNestedObject() {

        let value = WithNestedClass()

        let expectedResult = "value=1&value2=test&nested[value]=1&nested[nested][value]=1"

        do {
            
            _ = try decoder.decode(type(of: value), from: expectedResult)

        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
}


