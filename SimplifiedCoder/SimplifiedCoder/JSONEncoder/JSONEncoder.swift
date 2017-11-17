//
//  JSONEncoder.swift
//
//  Created by Brendan Henderson on 9/22/17.
//

import Foundation

extension JSONSerialization {
    
    public static let contentType: String = "application/json"
}

extension JSONEncoder: TopLevelEncoder {
    
    public var contentType: String { return JSONSerialization.contentType }
    public static var contentType: String { return JSONSerialization.contentType }
    
    public func encode<T>(_ value: T) throws -> (contentType: String, data: Data) where T : Encodable {
        return try (JSONEncoder.contentType, self.encode(value))
    }

    public func encode<T: Encodable>(value: T) throws -> Any {
        
        let data = try self.encode(value).data
        
        return try JSONSerialization.jsonObject(with: data)
    }
}

