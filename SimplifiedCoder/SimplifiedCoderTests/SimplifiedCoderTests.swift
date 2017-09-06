//
//  SimplifiedCoderTests.swift
//  SimplifiedCoderTests
//
//  Created by Brendan Henderson on 8/23/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import XCTest
@testable import SimplifiedCoder

class TestEncoder: XCTestCase {
    
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
    }
}
