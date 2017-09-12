//
//  CoderError.swift
//  SimplifiedCoder
//
//  Created by Brendan Henderson on 9/12/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import Foundation


/// a wrapping error to associate an unknown error on encoding or decoding with a codingPath
public enum CodingError: Error {
    
    case error(Error, atPath: [CodingKey])
    
    public var error: Error {
        
        switch self {
        case .error(let error, atPath: _): return error
        }
    }
    
    public var codingPath: [CodingKey] {
        switch self {
        case .error(_, atPath: let codingPath): return codingPath
        }
    }
}
