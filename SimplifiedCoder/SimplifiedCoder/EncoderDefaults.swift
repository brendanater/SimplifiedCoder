//
//  EncoderDefaults.swift
//  Retrolux
//
//  Created by Brendan Henderson on 10/2/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

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
