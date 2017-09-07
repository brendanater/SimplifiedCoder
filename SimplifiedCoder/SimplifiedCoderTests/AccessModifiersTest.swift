//
//  AccessModifiersTest.swift
//  SimplifiedCoderTests
//
//  Created by Brendan Henderson on 9/7/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import Foundation

import SimplifiedCoder


class TestClass: TestClass1 {
    init() {fatalError()}
}

let r = TestClass()

let r2 = TestStruct()

let r3 = { () -> Int in
    
    let cla = TestClass2()
    
    cla.var2 = 2
    
    cla.var4 = 4
    
    return cla.var2
}()


struct TestProtocolT: TestProtocol {
    var var1: Int = 1
}

let r_ = TestGreaterOpen().var1

