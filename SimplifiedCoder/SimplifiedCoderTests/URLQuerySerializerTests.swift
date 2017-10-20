//
//  URLQuerySerializerTests.swift
//  RetroluxTests
//
//  Created by Brendan Henderson on 10/19/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

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




