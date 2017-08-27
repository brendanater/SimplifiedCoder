//
//  Decoder.swift
//  SimplifiedCoder
//
//  Created by Christopher Bryan Henderson on 8/27/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import Foundation

protocol TopLevelDecoder {
    
    func decode<T: Decodable>(_: T.Type, from data: Data) throws -> T
    func decode<T: Decodable>(_: T.Type, from value: Any) throws -> T
}
