//
//  URLQuerySerializerTests.swift
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
import SimplifiedCoder
import XCTest

class TestURLQuerySerializer: XCTestCase {
    
    func newSerializer() -> URLQuerySerializer {
        
        return URLQuerySerializer()
    }
    
    var serializer: URLQuerySerializer = URLQuerySerializer()
    
    func test() {
        
        test(["test": 1], "test=1")
        test(["test": [Int.max, Int.min]], "test[]=\(Int.max)&test[]=\(Int.min)")
        serializer.arraySerialization = .arraysAreDictionaries
        test(["test": [1, 2]], "test[0]=1&test[1]=2")
        test(["test": true], "test=true")
        serializer.boolRepresentation = ("adaf","asffg")
        test(["test": true, "test2": false], "test=adaf&test2=asffg")
        test(["test": ["test": ["test"]]], "test[test][0]=test")
        test(["test": ["test": [[1]]]], "test[test][0][0]=1")
        serializer.arraySerialization = .defaultAndThrowIfNested
        test(["test": ["test": ["test"]]], "test[test][]=test")
        test(["test": ["test": []]], "")
        test([("test", true), ("test2", false)], "test=adaf&test2=asffg")
        test([("test", [("test", ["test"])])], "test[test][]=test")
        serializer.arraySerialization = .arraysAreDictionaries
        test([("test", [("test", [[1], [2]])])], "test[test][0][0]=1&test[test][1][0]=2")
        serializer.arraySerialization = .defaultAndThrowIfNested
        test([("test", [("test", ["test"])])], "test[test][]=test")
        test([("test", [("test", [])])], "")
        
        serializer.arraySerialization = .arraysAreDictionaries
        testCount(["test": 1], 1)
        testCount(["test": [Int.max, Int.min]], 2)
        testCount(["test": [1, 2]], 2)
        testCount(["test": [1,2,3,4]], 4)
        testCount(["test": true, "test2": false], 2)
        testCount(["test": ["test": ["test"]]], 1)
        testCount(["test": ["test": [[1]]]], 1)
        testCount(["test": ["test": ["test", "test"], "test2": ["test", "test"]]], 4)
        testCount(["test": ["test": []]], 0)
        testCount([("test", true), ("test2", false)], 2)
        testCount([("test", [("test", ["test"])])], 1)
        testCount([("test", [("test", [[1], [1]])])], 2)
        testCount([("test", [("test", ["test"])])], 1)
        testCount([("test", [("test", [])])], 0)
    }
    
    
    func test(_ value: Any, _ expectQuery: String) {
        
        do {
            
            let query = try self.serializer.query(from: value)
            
            XCTAssert(query == expectQuery, """
                unequal:
                query:  \(query)
                expect: \(expectQuery)
                """
            )
            
        } catch {
            
            XCTFail("\(error)")
        }
    }
    
    func testCount(_ value: Any, _ expectQueryCount: Int = 1) {
        
        do {
            
            let query = try self.serializer.queryItems(from: value)
            
            XCTAssert(query.count == expectQueryCount, """
                unequal: \(query)
                query:  \(query.count)
                actual: \(expectQueryCount)
                """
            )
            
        } catch {
            
            XCTFail("\(error)")
        }
    }
}




