//
//  JSONDecoder.swift
//  Retrolux
//
//  Created by Brendan Henderson on 9/25/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation


extension JSONDecoder: TopLevelDecoder {
    
    // decoding
    
    public func decode<T>(_: T.Type, fromValue value: Any) throws -> T where T : Decodable {
        
        let data: Data
        
        do {
            data = try JSONSerialization.data(withJSONObject: value)
        } catch {
            throw DecodingError.typeMismatch(
                type(of: value),
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "value is not a JSON Object",
                    underlyingError: error
                )
            )
        }
        
        return try self.decode(T.self, from: data)
    }
}
