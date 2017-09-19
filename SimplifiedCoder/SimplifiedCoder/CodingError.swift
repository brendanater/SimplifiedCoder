//
//  CoderError.swift
//  SimplifiedCoder
//
//  Created by Brendan Henderson on 9/12/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import Foundation

/// an error that has an associated codingPath
public protocol HasCodingPath {
    
    var codingPath: [CodingKey] {get}
}

extension EncodingError: HasCodingPath {
    
    private func newContext(_ context: Context, codingPath: [CodingKey]) -> Context {
        return Context(
            codingPath: codingPath,
            debugDescription: context.debugDescription,
            underlyingError: context.underlyingError
        )
    }
    
    public func with(codingPath: [CodingKey]) -> EncodingError {
        switch self {
        case .invalidValue(let value, let context):
            return .invalidValue(value, self.newContext(context, codingPath: codingPath))
        }
    }
    
    public var codingPath: [CodingKey] {
        switch self {
        case .invalidValue(_, let context):
            return context.codingPath
        }
    }
}

extension DecodingError: HasCodingPath {
    
    private func newContext(_ context: Context, with nestedPath: [CodingKey]) -> Context {
        return Context(
            codingPath: context.codingPath + nestedPath,
            debugDescription: "_ " + context.debugDescription,
            underlyingError: context.underlyingError
        )
    }
    
    private func hasNestedPath(_ context: Context) -> Bool {
        return context.debugDescription.starts(with: "_ ")
    }
    
    public var hasNestedPath: Bool {
        
        switch self {
        case .dataCorrupted(let context):
            return self.hasNestedPath(context)
        case .keyNotFound(_, let context):
            return self.hasNestedPath(context)
        case .typeMismatch(_, let context):
            return self.hasNestedPath(context)
        case .valueNotFound(_, let context):
            return self.hasNestedPath(context)
        }
    }
    
    public func withNestedPath(_ nestedPath: [CodingKey]) -> DecodingError {
        
        if self.hasNestedPath {
            return self
        } else {
            switch self {
            case .dataCorrupted(let context):
                return .dataCorrupted(newContext(context, with: nestedPath))
            case .keyNotFound(let key, let context):
                return .keyNotFound(key, newContext(context, with: nestedPath))
            case .typeMismatch(let type, let context):
                return .typeMismatch(type, newContext(context, with: nestedPath))
            case .valueNotFound(let type, let context):
                return .valueNotFound(type, newContext(context, with: nestedPath))
            }
        }
    }
}
