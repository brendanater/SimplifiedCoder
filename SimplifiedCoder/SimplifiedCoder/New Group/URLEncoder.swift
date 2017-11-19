//
//  URLEncoder.swift
//  SimplifiedCoder
//
//  MIT License
//
//  Copyright (c) 8/27/17 Brendan Henderson
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

/// requires top level object to be a keyed container
public struct URLEncoder: TopLevelEncoder {
    
    public var contentType: String {
        return self.serializer.contentType
    }
    
    // MARK: options
    
    public var serializer: URLQuerySerializer = URLQuerySerializer()
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    // JSON
    public var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate
    public var dataEncodingStrategy: JSONEncoder.DataEncodingStrategy = .deferredToData
    public var nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy = .throw
    
    public init() {}
    
    //
    
    private typealias Options = ()
    
    private var options: Base.Options {
        return ((
            self.dateEncodingStrategy,
            self.dataEncodingStrategy,
            self.nonConformingFloatEncodingStrategy
        ), ())
    }
    
    // MARK: TopLevelEncoder
    
    public func encode<T>(_ value: T) throws -> Data where T : Encodable {
        
        let value = try self.encode(value: value)
        
        do {
            return try self.serializer.queryData(from: value)
            
        } catch {
            
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to encode the given top-level value to query data",
                    underlyingError: error
                )
            )
        }
    }
    
    public func encode<T: Encodable>(value: T) throws -> Any {
        
        let result = try Base(options: self.options, userInfo: self.userInfo).start(with: value)
        
        do {
            try self.serializer.assertValidObject(result)
            
            return result
            
        } catch {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to encode the given top-level value to a URLQuery object",
                    underlyingError: error
                )
            )
        }
    }
    
    // MARK: other encode types
    
    public func encode<T: Encodable>(asQuery value: T) throws -> String {
        
        let value = try self.encode(value: value)
        
        do {
            return try self.serializer.query(from: value)
            
        } catch {
            
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to encode the given top-level value to a URLQuery",
                    underlyingError: error
                )
            )
        }
    }
    
    public func encode<T: Encodable>(asQueryItems value: T) throws -> [URLQueryItem] {
        
        let value = try self.encode(value: value)
        
        do {
            return try self.serializer.queryItems(from: value)
            
        } catch {
            
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to encode the given top-level value to URLQuery items",
                    underlyingError: error
                )
            )
        }
    }
    
    // MARK: Base
    
    private class Base: EncoderJSONBase {
        
        static var usesStringValue: Bool = true
        
        typealias ExtraOptions = URLEncoder.Options
        typealias Options = JSONOptions
        
        var codingPath: [CodingKey]
        var options: Options
        var userInfo: [CodingUserInfoKey : Any]
        var reference: EncoderReference?
        
        required init(codingPath: [CodingKey], options: Options, userInfo: [CodingUserInfoKey : Any], reference: EncoderReference?) {
            self.codingPath = codingPath
            self.options = options
            self.userInfo = userInfo
            self.reference = reference
        }
        
        var storage: [Any] = []
        var canEncodeNewValue: Bool = true
        
        deinit {
            self.willDeinit()
        }
        
        // MARK: start
        
        func start<T: Encodable>(with value: T) throws -> Any {
            
            let value = try self.box(value, at: [])
            
            return _OrderedDictionary.baseType(value)
        }
        
        /// URLEncoding needs ordering
        func keyedContainerContainer() -> EncoderKeyedContainerContainer {
            return _OrderedDictionary()
        }
        
        // Boxing
        
        func box(_ value: String, at codingPath: [CodingKey]) throws -> Any {
            
            guard value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) != nil else {
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: self.codingPath, debugDescription: "String cannot be percent encoded."))
            }
            
            return value
        }
    }
    
    /// a URLQuery sometimes needs order, so the standard mutable dictionary is out of the question
    private class _OrderedDictionary: EncoderKeyedContainerContainer {
        
        typealias Element = (key: String, value: Any)
        typealias Elements = [Element]
        
        private var elements: Elements
        
        init() {
            self.elements = []
        }
        
        /// replaces the value for the key at index or appends the new value
        func setToStorage(_ value: Any, forKey key: AnyHashable) {
            
            let key = key as! String
            
            if let index = self.elements.index(where: { $0.key == key }) {
                self.elements.remove(at: index)
                
                self.elements.insert((key, value), at: index)
            } else {
                self.elements.append((key, value))
            }
        }
        
        /// descends into a newly encoded value and removes the elements from all _OrderedDictionaries
        static func baseType(_ value: Any) -> Any {
            
            if let value = value as? _OrderedDictionary {
                
                return value.elements.map { ($0, self.baseType($1)) }
                
            } else if let value = value as? NSArray {
                
                return value.map(self.baseType(_:))
                
            } else {
                
                return value
            }
        }
    }
}














