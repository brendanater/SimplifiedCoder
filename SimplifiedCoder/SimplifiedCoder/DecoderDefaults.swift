//
//  DecoderDefaults.swift
//  Retrolux
//
//  Created by Brendan Henderson on 10/2/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

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

