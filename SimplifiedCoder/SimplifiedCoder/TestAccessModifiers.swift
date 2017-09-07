//
//  TestAccessModifiers.swift
//  SimplifiedCoder
//
//  Created by Brendan Henderson on 9/7/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import Foundation

// this means I can code anything I want and not have to worry so much about cluttering outside the module

// the class has to be public or open to be seen

// if the class is open, it and it's open variables can be overridden and subclassed

open class TestClass1 {
    var var1 = 1
    public var var2 = 2
    internal var var3 = 3
    open var var4 = 4
}

// what if the class is public and the variables are open?

// variables can be set, but not overridden

public class TestClass2 {
    
    public init() {}
    
    var var1 = 1
    public var var2 = 2
    internal var var3 = 3
    open var var4 = 4
}

// the struct itself has to be public to be seen

public struct TestStruct {
    
    public init() {}
    
    var var1 = 1
    public var var2 = 2
    internal var var3 = 3
    // only classes and overridable classes can declare open
//    open var var4 = 4
}

// what about protocols

// can only be seen outside of module if public
public protocol TestProtocol {
    // all variables have the same access as the protocol
    var var1: Int {get}
}

internal struct TestComplianceToProtocol: TestProtocol {
    // must be as accessable as the enclosing object or greater.
    public var var1: Int = 1
}


open class TestGreaterOpen: TestProtocol {
    
    public init() {fatalError()}
    
    // has to be at least public because of protocol being public
    open var var1: Int = 1
}




// internal can be accessed anywhere in the module

// fileprivate is limited to the file

// private is limited to the object and the extensions in the same file
