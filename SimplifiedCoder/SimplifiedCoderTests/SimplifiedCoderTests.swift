//
//  SimplifiedCoderTests.swift
//  SimplifiedCoderTests
//
//  Created by Brendan Henderson on 8/23/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import XCTest
@testable import SimplifiedCoder

class SimplifiedCoderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
        let data: Data = """
        [
        {
            "date": "1504116151"
        },
        {
            "date": "1504116151"
        }
        ]
        """.data(using: .utf8)!
        
        // default
        let value2 = try! JSONDecoder().decode([[String: String]].self, from: data)
        
        // copy-pasted
        let value1 = try! [[String: String]](from: _JSONDecoder2.init(referencing: JSONSerialization.jsonObject(
            with: data,
            options: []
        ), options: (.deferredToDate, .deferredToData, .throw, userInfo: [:])))
        
        // simplified
        let value = try! [[String: String]](from: Base2(
            value: JSONSerialization.jsonObject(
                with: data,
                options: []
            ),
            codingPath: [],
            options: Base2.Options(.deferredToDate, .deferredToData, .throw, .dontAllow, true),
            userInfo: [:]
            ))
        
        XCTAssert(zip(value1, value2).flatMap{$0.0["date"] != $0.1["date"] ? true : nil}.count == 0 && zip(value, value1).flatMap{$0.0["date"] != $0.1["date"] ? true : nil}.count == 0)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
