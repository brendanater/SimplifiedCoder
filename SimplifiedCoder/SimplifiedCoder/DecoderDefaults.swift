//
//  DecoderDefaults.swift
//  SimplifiedCoder
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

public struct DecoderDefaultKeyedContainer<K: CodingKey>: DecoderKeyedContainer {
    
    public typealias Key = K
    
    public var decoder: AnyDecoderBase
    public var container: DecoderKeyedContainerContainer
    public var nestedPath: [CodingKey]
    
    public init(decoder: AnyDecoderBase, container: DecoderKeyedContainerContainer, nestedPath: [CodingKey]) {
        self.decoder = decoder
        self.container = container
        self.nestedPath = nestedPath
    }
}

public struct DecoderDefaultUnkeyedContainer: DecoderUnkeyedContainer {
    
    public var decoder: AnyDecoderBase
    public var container: DecoderUnkeyedContainerContainer
    public var nestedPath: [CodingKey]
    
    public init(decoder: AnyDecoderBase, container: DecoderUnkeyedContainerContainer, nestedPath: [CodingKey]) {
        self.decoder = decoder
        self.container = container
        self.nestedPath = nestedPath
    }
    
    public var currentIndex: Int = 0
}
