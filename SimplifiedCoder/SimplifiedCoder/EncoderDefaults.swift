//
//  EncoderDefaults.swift
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


struct EncoderDefaultKeyedContainer<K: CodingKey>: EncoderKeyedContainer {
    
    typealias Key = K
    
    var encoder: AnyEncoderBase
    var container: EncoderKeyedContainerContainer
    var nestedPath: [CodingKey]
    
    init(encoder: AnyEncoderBase, container: EncoderKeyedContainerContainer, nestedPath: [CodingKey]) {
        self.encoder = encoder
        self.container = container
        self.nestedPath = nestedPath
    }
}

struct EncoderDefaultUnkeyedContainer: EncoderUnkeyedContainer {
    
    var encoder: AnyEncoderBase
    var container: EncoderUnkeyedContainerContainer
    var nestedPath: [CodingKey]
    
    init(encoder: AnyEncoderBase, container: EncoderUnkeyedContainerContainer, nestedPath: [CodingKey]) {
        self.encoder = encoder
        self.container = container
        self.nestedPath = nestedPath
    }
}
