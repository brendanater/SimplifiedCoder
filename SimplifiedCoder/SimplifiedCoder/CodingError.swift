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
    
    func withNestedPath(_ nestedPath: [CodingKey]) -> Self
}

extension EncodingError: HasCodingPath {
    
    private func newContext(_ context: Context, with nestedPath: [CodingKey]) -> Context {
        if context.debugDescription.starts(with: "_ ") == false {
            return Context(
                codingPath: context.codingPath + nestedPath,
                debugDescription: "_ " + context.debugDescription,
                underlyingError: context.underlyingError
            )
        } else {
            return context
        }
    }
    
    public func withNestedPath(_ nestedPath: [CodingKey]) -> EncodingError {
        
        switch self {
        case .invalidValue(let value, let context):
            return .invalidValue(value, newContext(context, with: nestedPath))
        }
    }
}

extension DecodingError: HasCodingPath {
    
    private func newContext(_ context: Context, with nestedPath: [CodingKey]) -> Context {
        if context.debugDescription.starts(with: "_ ") == false {
            return Context(
                codingPath: context.codingPath + nestedPath,
                debugDescription: "_ " + context.debugDescription,
                underlyingError: context.underlyingError
            )
        } else {
            return context
        }
    }
    
    public func withNestedPath(_ nestedPath: [CodingKey]) -> DecodingError {
        
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
