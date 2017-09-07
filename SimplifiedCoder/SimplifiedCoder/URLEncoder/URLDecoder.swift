//
//  URLDecoder.swift
//  URLEncoder
//
//  Created by Brendan Henderson on 8/31/17.
//  Copyright © 2017 OKAY. All rights reserved.
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


/// decodes from data or Dictionary<String, String> to a decodable type
public struct URLDecoder: TopLevelDecoder {
    
    // Note: have to decode each value from a JSON object where every value is a String.
    
    public var serializer = URLQuerySerializer()
    
    public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
    public var dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .deferredToData
    public var nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy = .throw
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    public init() {}
    
    internal typealias Options = (
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy,
        nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy,
        boolRepresentation: (true: String, false: String)
    )
    
    public func decode<T>(_: T.Type, from data: Data) throws -> T where T : Decodable {
        
        return try self.decode(T.self, from: self.serializer.deserialize(unordered: data))
    }
    
    public func decode<T>(_: T.Type, from string: String) throws -> T where T : Decodable {
        
        return try self.decode(T.self, from: self.serializer.deserialize(unordered: string))
    }
    
    public func decode<T>(_: T.Type, from query: [URLQueryItem]) throws -> T where T : Decodable {
        
        return try self.decode(T.self, from: self.serializer.deserialize(unordered: query))
    }
    
    public func decode<T>(_: T.Type, from queryObject: [String: Any]) throws -> T where T : Decodable {
        
        return try Base(
            value: queryObject,
            codingPath: [],
            options: (
                self.dateDecodingStrategy,
                self.dataDecodingStrategy,
                self.nonConformingFloatDecodingStrategy,
                self.serializer.boolRepresentation
            ),
            userInfo: self.userInfo
        )
        .decode(T.self)
    }
    
    fileprivate class Base: DecoderBase {
        
        typealias KeyedContainer = URLDecoder.KeyedContainer<String>
        typealias UnkeyedContainer = URLDecoder.UnkeyedContainer
        
        typealias Options = URLDecoder.Options
        
        var storage: [Any]
        var options: Options
        var userInfo: [CodingUserInfoKey : Any]
        
        var codingPath: [CodingKey] = []
        
        required init(value: Any, codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any]) {
            
            self.storage = [value]
            self.options = options
            self.userInfo = userInfo
        }
    
        func convert<T: ConvertibleNumber>(number value: Any) throws -> T {
    
            if let number = NumberFormatter.shared.number(from: value as? String ?? "˜∆åƒ˚"), let result = T(exactly: number) {
                return result
            }
    
            throw self.failedToUnbox(value, to: T.self)
        }
        
        func unbox(_ value: Any) throws -> Bool {
            let value = value as? String
            
            if value == self.options.boolRepresentation.true {
                return true
            } else if value == self.options.boolRepresentation.false {
                return false
            } else {
                return isNil(value)
            }
        }
        
        /// unbox Date uses other unbox functions to get value
        func unbox(_ value: Any) throws -> Date {

            switch self.options.dateDecodingStrategy {

            case .deferredToDate:
                self.storage.append(value)
                let date = try Date(from: self)
                self.storage.removeLast()
                return date

            case .secondsSince1970:
                return try Date(timeIntervalSince1970: self.unbox(value))

            case .millisecondsSince1970:
                return try Date(timeIntervalSince1970: self.unbox(value) / 1000.0)

            case .iso8601:
                if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                    guard let date = try ISO8601DateFormatter.shared.date(from: self.unbox(value) as String) else {
                        throw self.corrupted("Expected date string to be ISO8601-formatted.")
                    }
                    return date
                } else {
                    fatalError("ISO8601DateFormatter is unavailable on this platform.")
                }

            case .formatted(let formatter):
                guard let date = try formatter.date(from: self.unbox(value) as String) else {
                    throw self.corrupted("Date string does not match format expected by formatter.")
                }
                return date

            case .custom(let closure):
                self.storage.append(value)
                let date = try closure(self)
                self.storage.removeLast()
                return date
            }
        }

        func unbox(_ value: Any) throws -> Data {

            switch self.options.dataDecodingStrategy {
            case .deferredToData:
                self.storage.append(value)
                let data = try Data(from: self)
                self.storage.removeLast()
                return data

            case .base64:
                guard let data = try Data(base64Encoded: self.unbox(value) as String) else {
                    throw self.corrupted("Encountered Data is not valid Base64.")
                }

                return data

            case .custom(let closure):
                self.storage.append(value)
                let data = try closure(self)
                self.storage.removeLast()
                return data
            }
        }

        func unbox(_ value: Any) throws -> Decimal {

            // Attempt to bridge from NSDecimalNumber.
            if let decimal = value as? Decimal {
                return decimal
            } else {
                return try Decimal(self.unbox(value) as Double)
            }
        }

        func unbox(_ value: Any) throws -> URL {

            guard let url = try URL(string: self.unbox(value)) else {
                throw self.corrupted("Invalid url string.")
            }

            return url
        }

        func unbox<T : Decodable>(_ value: Any) throws -> T {

            switch T.self {
            case is Date.Type:    return try self.unbox(value) as Date    as! T
            case is Data.Type:    return try self.unbox(value) as Data    as! T
            case is URL.Type:     return try self.unbox(value) as URL     as! T
            case is Decimal.Type: return try self.unbox(value) as Decimal as! T
            default: return try self.redecode(value)
            }
        }
    }
    
    fileprivate struct KeyedContainer<K: CodingKey>: DecoderKeyedContainer {
        
        
        typealias Key = K
        typealias UnkeyedContainer = URLDecoder.UnkeyedContainer
        typealias Base = URLDecoder.Base
        
        var decoder: Base
        var container: NSDictionary
        var nestedPath: [CodingKey]
        
        init(decoder: Base, container: NSDictionary, nestedPath: [CodingKey]) {
            self.decoder = decoder
            self.container = container
            self.nestedPath = nestedPath
        }
        
        static func initSelf<NewKey>(decoder: Base, container: NSDictionary, nestedPath: [CodingKey], keyedBy: NewKey.Type) -> KeyedDecodingContainer<NewKey> where NewKey : CodingKey {
            
            let _self = KeyedContainer<NewKey>(decoder: decoder, container: container, nestedPath: nestedPath)
            return KeyedDecodingContainer(_self)
        }
        
        static var usesStringValue: Bool {
            return true
        }
    }
    
    fileprivate struct UnkeyedContainer: DecoderUnkeyedContainer {
        
        typealias KeyedContainer = URLDecoder.KeyedContainer<String>
        typealias Base = URLDecoder.Base
        
        var decoder: Base
        var container: NSArray
        var nestedPath: [CodingKey]
        
        init(decoder: Base, container: NSArray, nestedPath: [CodingKey]) {
            self.decoder = decoder
            self.container = container
            self.nestedPath = nestedPath
        }
        
        var currentIndex: Int = 0
        
    }
}





