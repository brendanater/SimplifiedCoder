//
//  URLQuerySerializer.swift
//  URLEncoder
//
//  Created by Brendan Henderson on 9/1/17.
//  Copyright © 2017 OKAY.
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
//
//  ParameterEncoding.swift
//
//  Copyright (c) 2014-2016 Alamofire Software Foundation (http://alamofire.org/)
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

public struct URLQuerySerializer {
    
    public var boolRepresentation: (true: String, false: String) = ("True", "False")
    
    public init() {}
    
    /// A generic error that something happend in parsing the query.
    /// Too many different errors.
    public enum QueryParsingError: Error {
        case queryParsingError(String)
    }
    
    /// T.Element must be exactly: (key: String, value: Any) ((String, Any) will not work, (key: String, value: Int) will not work)
    public func serialize<T: Sequence>(_ sequence: T) throws -> [URLQueryItem] where T.Element == (key: String, value: Any) {
        
        var query: [URLQueryItem] = []
        
        for (key, value) in sequence {
            try self.queryComponents(fromKey: key, value: value, to: &query)
        }
        
        return query
    }
    
    /// T.Element must be exactly: (key: String, value: Any) ((String, Any) will not work, (key: String, value: Int) will not work)
    public func serialize<T: Sequence>(toString sequence: T) throws -> String where T.Element == (key: String, value: Any) {
        
        return try serialize(sequence).map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
    }
    
    /// T.Element must be exactly: (key: String, value: Any) ((String, Any) will not work, (key: String, value: Int) will not work)
    public func serialize<T: Sequence>(toData sequence: T) throws -> Data where T.Element == (key: String, value: Any) {
        
        let string = try serialize(toString: sequence)
        
        if let data = string.data(using: .utf8) {
            return data
        } else {
            throw QueryParsingError.queryParsingError("Failed to parse to data, string: \(string)")
        }
    }
    
    public func deserialize(_ query: [URLQueryItem]) throws -> [(name: String, value: Any)] {
        
        return try self.object(from: query)
    }
    
    public func deserialize(unordered query: [URLQueryItem]) throws -> [String: Any] {
        
        return self._unordered(try deserialize(query)) as! [String: Any]
    }
    
    public func deserialize(_ query: String) throws -> [(name: String, value: Any)] {
        
        if let url = URL(string: "notAURL.com/" + query), let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems {
            
            return try deserialize(queryItems)
            
        } else {
            throw QueryParsingError.queryParsingError("Failed to convert to query, string: \(query)")
        }
    }
    
    public func deserialize(unordered query: String) throws -> [String: Any] {
        
        return self._unordered(try deserialize(query)) as! [String: Any]
    }
    
    public func deserialize(_ query: Data) throws -> [(name: String, value: Any)] {
        
        if let string = String(data: query, encoding: .utf8) {
            return try deserialize(string)
        } else {
            throw QueryParsingError.queryParsingError("Failed to deserialize data")
        }
    }
    
    public func deserialize(unordered query: Data) throws -> [String: Any] {
        
        return self._unordered(try deserialize(query)) as! [String: Any]
    }
    
    // MARK - serialization
    
    internal func queryComponents(fromKey key: String, value: Any, to query: inout [URLQueryItem]) throws {
        
        if key == "" {
            throw QueryParsingError.queryParsingError("Cannot have an empty key, parsed: \(query)")
        }
        
        func set(_ name: String, _ value: String?) throws {
            
            if name == "" {
                throw QueryParsingError.queryParsingError("Cannot have an empty name (parsed: \"\(key)\")")
            }
            
            if let value = value {
                try query.append(URLQueryItem(name: escape(name), value: escape(value)))
            } else {
                try query.append(URLQueryItem(name: escape(name), value: nil))
            }
        }
        
        if isNil(value) {
            
            try set(key, "")
            
        } else if let bool = value as? Bool {
            
            try set(key, (bool ? boolRepresentation.true : boolRepresentation.false))
            
        } else if let dictionary = value as? [String: Any] {
            
            for (nestedKey, value) in dictionary {
                
                if nestedKey == "" {
                    throw QueryParsingError.queryParsingError("Dictionary keys cannot be nil, at: \(key)")
                }
                
                if key.hasSuffix("[]") {
                    throw QueryParsingError.queryParsingError("Cannot nest a container in an array with a standard url query")
                }
                
                try queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value, to: &query)
            }
            
        } else if let dictionary = value as? [(nestedKey: String, value: Any)] {
            
            for (nestedKey, value) in dictionary {
                
                if nestedKey == "" {
                    throw QueryParsingError.queryParsingError("Dictionary keys cannot be nil, at: \(key)")
                }
                
                if key.hasSuffix("[]") {
                    throw QueryParsingError.queryParsingError("Cannot nest a container in an array with a standard url query")
                }
                
                try queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value, to: &query)
            }
            
        } else if let array = value as? [Any] {
            
            if key.hasSuffix("[]") {
                throw QueryParsingError.queryParsingError("Cannot nest a container in an array with a standard url query")
            }
            
            for value in array {
                try queryComponents(fromKey: "\(key)[]", value: value, to: &query)
            }
            
        } else {
            
            try set(key, "\(value)")
        }
    }
    
    /// Returns a percent-escaped string following RFC 3986 for a query string key or value.
    ///
    /// RFC 3986 states that the following characters are "reserved" characters.
    ///
    /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
    ///
    /// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
    /// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
    /// should be percent-escaped in the query string.
    ///
    /// - parameter string: The string to be percent-escaped.
    ///
    /// - returns: The percent-escaped string.
    internal func escape(_ string: String) throws -> String {
        
        let generalDelimiters = ":#[]@"
        let subDelimiters = "!$&'()*+,;="
        
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.remove(charactersIn: generalDelimiters + subDelimiters)
        
        if #available(iOS 8.1, *) {
            
            if let string = string.addingPercentEncoding(withAllowedCharacters: allowedCharacters) {
                return string
            } else {
                throw QueryParsingError.queryParsingError(string)
            }
            
        } else {
            var escaped = ""
            
            let batchSize = 1
            
            var startIndex = string.startIndex
            
            while startIndex < string.endIndex {
                
                if let endIndex = string.index(startIndex, offsetBy: batchSize, limitedBy: string.endIndex) {
                    
                    if let substring = string.substring(with: startIndex..<endIndex).addingPercentEncoding(withAllowedCharacters: allowedCharacters) {
                        
                        escaped.append(substring)
                        
                        startIndex = endIndex
                        
                        continue
                    }
                }
                
                throw QueryParsingError.queryParsingError(string)
            }
            
            return escaped
        }
    }
    
    // MARK - deserialization
    
    internal func object(from query: [URLQueryItem]) throws -> [(name: String, value: Any)] {
        
        var values: _URLQueryDictionary<[([Component], String?)]> = [:]
        
        for item in query {
            let name = item.name
            let value = item.value
            
            if name.contains("[") {
                guard name.starts(with: "[") == false || name.starts(with: "]") == false else {
                    throw QueryParsingError.queryParsingError("Name: \(name) cannot start with an open or close bracket")
                }
                
                guard name.last! == "]" else {
                    throw QueryParsingError.queryParsingError("Name: \(name) (with an opening bracket) does not end with a closing bracket")
                }
                
                guard name.countInstances(of: "[") == name.countInstances(of: "]") else {
                    throw QueryParsingError.queryParsingError("Name: \(name) does not have equal number of open and close brackets")
                }
                
                var components = [Component]()
                
                var subComponents = name.split(separator: "[").map { String($0) }
                
                let key = subComponents.removeFirst()
                
                guard key.contains("]") == false else {
                    throw QueryParsingError.queryParsingError("Name: \(name) cannot start with a closing bracket")
                }
                
                for var component in subComponents {
                    
                    guard component.last == "]" else {
                        throw QueryParsingError.queryParsingError("component does not end with a closing bracket")
                    }
                    
                    component.removeLast()
                    
                    if component.contains("]") {
                        throw QueryParsingError.queryParsingError("component has more than one closing bracket")
                    }
                    
                    if component == "" {
                        components.append(.array)
                    } else {
                        components.append(.dictionary(key: component))
                    }
                }
                
                values.append((components, value), forKey: key)
                
            } else {
                
                values.append(([], value), forKey: name)
            }
        }
        
        return try values.elements.map { ($0, try self.combine($1)) }
    }
    
    private func combine(_ values: [(components: [Component], value: String?)]) throws -> Any {
        
        guard values.count > 0 else {
            throw QueryParsingError.queryParsingError("no values to combine, need at least one")
        }
        
        if let type = values.first?.components.first {
            
            switch type {
                
            case .array:
                // first component is array
                
                // no other items are nested
                
                guard (values.filter { $0.components.count > 1 }.count == 0) else {
                    throw QueryParsingError.queryParsingError("cannot have a nested array or dictionary in an array")
                }
                
                return try values.map { (value) throws -> String? in
                    
                    // all other values are the same type
                    if let c = value.components.first, case .array = c {
                        
                        // return values
                        return value.value
                        
                    } else {
                        throw QueryParsingError.queryParsingError("mismatch component type expected array")
                    }
                }
                
            case .dictionary(key: _):
                // first component is dict
                
                var _values: _URLQueryDictionary<[([Component], String?)]> = [:]
                
                // remove first component
                for (var components, value) in values {
                    
                    // all other values are dict
                    if let c = components.first, case .dictionary(let key) = c {
                        
                        components.removeFirst()
                        
                        // filter out key / return value
                        _values.append((components, value), forKey: key)
                        
                    } else {
                        throw QueryParsingError.queryParsingError("mismatch component type expected dictionary")
                    }
                }
                
                return try _values.elements.map { ($0, try combine($1)) }
            }
            
        } else {
            // first component is nil
            
            // no other values
            guard values.count == 1 else {
                throw QueryParsingError.queryParsingError("duplicate value for key")
            }
            
            // return value
            return values.first?.value as Any
        }
    }
    
    private func _unordered(_ value: Any) -> Any {
        
        if let value = value as? [(String, Any)] {
            
            var result: [String: Any] = [:]
            for (key, value) in value {
                result[key] = self._unordered(value)
            }
            return result
            
        } else if let value = value as? [Any] {
            return value.map { self._unordered($0) }
            
        } else {
            return value
        }
    }
}

fileprivate struct _URLQueryDictionary<V>: OrderedDictionaryProtocol {
    typealias Key = String
    typealias Value = V
    typealias Element = (key: Key, value: Value)
    
    var elements: [(key: Key, value: Value)]
    
    init() {
        self.elements = []
    }
    
    init(_ elements: [Element]) {
        self.elements = elements
    }
}

extension Dictionary where Value: Sequence & ExpressibleByArrayLiteral & RangeReplaceableCollection {
    
    mutating func append(_ value: Value.Element, to key: Key) {
        
        var element = self[key] ?? []
        
        element.append(value)
        
        self[key] = element
    }
}

enum Component {
    case array
    case dictionary(key: String)
}

extension Array {
    
    @discardableResult
    mutating func popFirst(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        if let index = try self.index(where: predicate) {
            return self.remove(at: index)
        } else {
            return nil
        }
    }
    
    @discardableResult
    mutating func popFirst() -> Element? {
        if let element = self.first {
            self.removeFirst()
            return element
        } else {
            return nil
        }
    }
    
    @discardableResult
    mutating func pop(at index: Int) -> Element? {
        if index < self.count {
            return self.remove(at: index)
        } else {
            return nil
        }
    }
}

extension String {
    func countInstances(of stringToFind: String) -> Int {
        assert(!stringToFind.isEmpty)
        var searchRange: Range<String.Index>?
        var count = 0
        while let foundRange = range(of: stringToFind, options: .diacriticInsensitive, range: searchRange) {
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
            count += 1
        }
        return count
    }
}


















