//
//  SimplifiedCoderTests.swift
//  SimplifiedCoderTests
//
//  Created by Brendan Henderson on 8/23/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import XCTest
@testable import SimplifiedCoder

enum AnError: Error {
    case error
}

class TestEncoderBase: EncoderBase {
    
    typealias KeyedContainer = TestEncoderKeyedContainer<String>
    
    typealias UnkeyedContainer = TestEncoderUnkeyedContainer
    
    typealias Options = ()
    
    var options: ()
    var userInfo: [CodingUserInfoKey : Any]
    
    var storage: [(key: CodingKey?, value: Any)] = []
    var key: CodingKey? = nil
    
    required init(options: (), userInfo: [CodingUserInfoKey : Any]) {
        self.options = options
        self.userInfo = userInfo
    }
    
    func box(_ value: String) throws -> Any {
        if value == "throw" {
            throw AnError.error
        } else {
            return value
        }
    }
}

class TestEncoderReference: TestEncoderBase, EncoderReference {
    
    typealias Super = TestEncoderBase
    
    var reference: EncoderReferenceValue = .unkeyed(NSMutableArray(), index: 1)
    var previousPath: [CodingKey] = []
    
    deinit {
        willDeinit()
    }
}

struct TestEncoderKeyedContainer<K: CodingKey>: EncoderKeyedContainer {
    
    typealias UnkeyedContainer = TestEncoderUnkeyedContainer
    typealias Reference = TestEncoderReference
    typealias Base = TestEncoderBase
    typealias Key = K
    
    var encoder: TestEncoderBase
    var container: NSMutableDictionary
    var nestedPath: [CodingKey]
    
    init(encoder: TestEncoderBase, container: NSMutableDictionary, nestedPath: [CodingKey]) {
        self.encoder = encoder
        self.container = container
        self.nestedPath = nestedPath
    }
    
    static func initSelf<Key>(encoder: TestEncoderBase, container: NSMutableDictionary, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(TestEncoderKeyedContainer<Key>(encoder: encoder, container: container, nestedPath: nestedPath))
    }
    
    static var usesStringValue: Bool {
        return true
    }
}

struct TestEncoderUnkeyedContainer: EncoderUnkeyedContainer {
    
    typealias KeyedContainer = TestEncoderKeyedContainer<String>
    typealias Reference = TestEncoderReference
    typealias Base = TestEncoderBase
    
    var encoder: TestEncoderBase
    var container: NSMutableArray
    var nestedPath: [CodingKey]
    
    init(encoder: TestEncoderBase, container: NSMutableArray, nestedPath: [CodingKey]) {
        self.encoder = encoder
        self.container = container
        self.nestedPath = nestedPath
    }
}

let dict = [
    "test": "test"
]

let arr = [
    "throw"
]

let top = "test"

let topInt = 1

let topDouble = 1.1

let topFloat = Float(1.1)

class TestObject: Codable {
    
    struct Test: Codable {
        var int = 1
        var str = "test"
    }
    
    var int = 1
    var str = "test"
    
}

class TestEncoder: XCTestCase {
    
    typealias Encoder = TestEncoderBase
    
    var encoder: Encoder = .init(options: (), userInfo: [:])
    
    func test() {
        
        do {
            print(try encoder.box(arr))
        } catch {
            XCTFail("Error was thrown: \(error)")
        }
        
        
        
        
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}



















