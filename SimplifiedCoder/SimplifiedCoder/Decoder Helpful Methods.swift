//
//  Decoder Helpful Methods.swift
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




//open func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T {
//    let topLevel: Any
//    do {
//        topLevel = try JSONSerialization.jsonObject(with: data)
//    } catch {
//        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid JSON.", underlyingError: error))
//    }
//
//    let decoder = _JSONDecoder(referencing: topLevel, options: self.options)
//    guard let value = try decoder.unbox(topLevel, as: T.self) else {
//        throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
//    }
//
//    return value
//}




//    typealias Options = (
//        dateDecodingStrategy: DateDecodingStrategy,
//        dataDecodingStrategy: DataDecodingStrategy,
//        nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy
//    )
//
//
//func unbox(_ value: Any) throws -> Float {
//    do {
//        return try self.convert(number: value)
//    } catch {
//
//        if let value = value as? String,
//            case .convertFromString(let posInfString, let negInfString, let nanString) = self.options.nonConformingFloatDecodingStrategy {
//
//            switch value {
//            case posInfString: return .infinity
//            case negInfString: return -.infinity
//            case nanString: return .nan
//            default: throw error
//            }
//        } else {
//            throw error
//        }
//    }
//}
//
//func unbox(_ value: Any) throws -> Double {
//    do {
//        return try self.convert(number: value)
//    } catch {
//
//        if let value = value as? String,
//            case .convertFromString(let posInfString, let negInfString, let nanString) = self.options.nonConformingFloatDecodingStrategy {
//
//            switch value {
//            case posInfString: return .infinity
//            case negInfString: return -.infinity
//            case nanString: return .nan
//            default: throw error
//            }
//        } else {
//            throw error
//        }
//    }
//}
//
//    /// unbox Date uses other unbox functions to get value
//    func unbox(_ value: Any) throws -> Date {
//
//        switch options.dateDecodingStrategy {
//
//        case .deferredToDate:
//            storage.append(value)
//            let date = try Date(from: self)
//            storage.removeLast()
//            return date
//
//        case .secondsSince1970:
//            return try Date(timeIntervalSince1970: unbox(value))
//
//        case .millisecondsSince1970:
//            return try Date(timeIntervalSince1970: unbox(value) / 1000.0)
//
//        case .iso8601:
//            if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
//                guard let date = try ISO8601DateFormatter.shared.date(from: unbox(value) as String) else {
//                    throw corrupted("Expected date string to be ISO8601-formatted.")
//                }
//                return date
//            } else {
//                fatalError("ISO8601DateFormatter is unavailable on this platform.")
//            }
//
//        case .formatted(let formatter):
//            guard let date = try formatter.date(from: unbox(value) as String) else {
//                throw corrupted("Date string does not match format expected by formatter.")
//            }
//            return date
//
//        case .custom(let closure):
//            storage.append(value)
//            let date = try closure(self)
//            storage.removeLast()
//            return date
//        }
//    }
//
//    func unbox(_ value: Any) throws -> Data {
//
//        switch self.options.dataDecodingStrategy {
//        case .deferredToData:
//            self.storage.append(value)
//            let data = try Data(from: self)
//            self.storage.removeLast()
//            return data
//
//        case .base64:
//            guard let data = try Data(base64Encoded: unbox(value) as String) else {
//                throw corrupted("Encountered Data is not valid Base64.")
//            }
//
//            return data
//
//        case .custom(let closure):
//            self.storage.append(value)
//            let data = try closure(self)
//            self.storage.removeLast()
//            return data
//        }
//    }
//
//    func unbox(_ value: Any) throws -> Decimal {
//
//        // Attempt to bridge from NSDecimalNumber.
//        if let decimal = value as? Decimal {
//            return decimal
//        } else {
//            return try Decimal(unbox(value) as Double)
//        }
//    }
//
//    func unbox(_ value: Any) throws -> URL {
//
//        guard let url = try URL(string: unbox(value)) else {
//            throw corrupted("Invalid url string.")
//        }
//
//        return url
//    }
//
//    func unbox<T : Decodable>(_ value: Any) throws -> T {
//
//        switch T.self {
//        case is Date.Type:    return try unbox(value) as Date    as! T
//        case is Data.Type:    return try unbox(value) as Data    as! T
//        case is URL.Type:     return try unbox(value) as URL     as! T
//        case is Decimal.Type: return try unbox(value) as Decimal as! T
//        default: return try redecode(value)
//        }
//    }
