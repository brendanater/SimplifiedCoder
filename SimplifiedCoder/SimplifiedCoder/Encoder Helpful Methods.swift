//
//  Encoder Helpful Methods.swift
//  SimplifiedCoder
//
//  Created by Brendan Henderson on 8/31/17.
//  Copyright © 2017 OKAY.
//
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation


// JSON

//    open func encode<T : Encodable>(_ value: T) throws -> Data {
//        let encoder = _JSONEncoder(options: self.options)
//
//        guard let topLevel = try encoder.box_(value) else {
//            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
//        }
//
//        if topLevel is NSNull {
//            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) encoded as null JSON fragment."))
//        } else if topLevel is NSNumber {
//            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) encoded as number JSON fragment."))
//        } else if topLevel is NSString {
//            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) encoded as string JSON fragment."))
//        }
//
//        let writingOptions = JSONSerialization.WritingOptions(rawValue: self.outputFormatting.rawValue)
//        do {
//            return try JSONSerialization.data(withJSONObject: topLevel, options: writingOptions)
//        } catch {
//            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unable to encode the given top-level value to JSON.", underlyingError: error))
//        }
//    }

//fileprivate typealias _Options = (
//    dateEncodingStrategy: JSONEncoder.DateEncodingStrategy,
//    dataEncodingStrategy: JSONEncoder.DataEncodingStrategy,
//    nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy
//)
//
//func box(_ value: Float) throws -> Any {
//    return try box(floatingPoint: value)
//}
//
//func box(_ value: Double) throws -> Any {
//    return try box(floatingPoint: value)
//}
//
//func box<T: FloatingPoint>(floatingPoint value: T) throws -> Any {
//    
//    if value.isInfinite || value.isNaN {
//        
//        guard case let .convertToString(
//            positiveInfinity: positiveString,
//            negativeInfinity: negitiveString,
//            nan: nan) = self.options.nonConformingFloatEncodingStrategy else {
//                
//                throw FloatingPointError.invalidFloatingPoint(value)
//        }
//        
//        switch value {
//        case .infinity: return positiveString
//        case -.infinity: return negitiveString
//        default: return nan
//        }
//        
//    } else {
//        return value
//    }
//}
//
//func box(_ date: Date) throws -> Any {
//    switch self.options.dateEncodingStrategy {
//    case .deferredToDate:
//        // Must be called with a surrounding with(pushedKey:) call.
//        try date.encode(to: self)
//        return self.storage.removeLast()
//        
//    case .secondsSince1970:
//        return NSNumber(value: date.timeIntervalSince1970)
//        
//    case .millisecondsSince1970:
//        return NSNumber(value: 1000.0 * date.timeIntervalSince1970)
//        
//    case .iso8601:
//        if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
//            return NSString(string: ISO8601DateFormatter.shared.string(from: date))
//        } else {
//            fatalError("ISO8601DateFormatter is unavailable on this platform.")
//        }
//        
//    case .formatted(let formatter):
//        return NSString(string: formatter.string(from: date))
//        
//    case .custom(let closure):
//        let depth = self.storage.count
//        try closure(date, self)
//        
//        guard self.storage.count > depth else {
//            //return default, throw, or fatal (I picked fatal because an encoder should encodeNil() even if it is nil)
//            fatalError("Encoder did not encode any values")
//        }
//        
//        return self.storage.removeLast()
//    }
//}
//
//func box(_ data: Data) throws -> Any {
//    switch self.options.dataEncodingStrategy {
//    case .deferredToData:
//        // data encodes a value (no need to check)
//        try data.encode(to: self)
//        return self.storage.removeLast()
//        
//    case .base64:
//        return NSString(string: data.base64EncodedString())
//        
//    case .custom(let closure):
//        let count = self.storage.count
//        
//        try closure(data, self)
//        
//        guard self.storage.count > count else {
//            //return default, throw, or fatal (I picked fatal because an encoder should encodeNil() even if it is nil)
//            fatalError("Encoder did not encode any values")
//        }
//        
//        // We can pop because the closure encoded something.
//        return self.storage.removeLast()
//    }
//}
//
//func box(_ value: URL) throws -> Any { return value.absoluteString }
//
//func box(_ value: Encodable) throws -> Any {
//    
//    switch value {
//    case is Date   , is NSDate: return try box(value as! Date   )
//    case is Data   , is NSData: return try box(value as! Data   )
//    case is URL    , is NSURL : return try box(value as! URL    )
//    case is Decimal           : return try box(value as! Decimal)
//    default: return try reencode(value)
//    }
//}

