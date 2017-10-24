//
//  JSONEncoder.swift
//
//  Created by Brendan Henderson on 9/22/17.
//

import Foundation

extension JSONEncoder: TopLevelEncoder {
    
    public static var contentType: String = "application/json"

    public func encode<T: Encodable>(value: T) throws -> Any {
        
        let data = try self.encode(value)
        
        return try JSONSerialization.jsonObject(with: data)
    }
}

