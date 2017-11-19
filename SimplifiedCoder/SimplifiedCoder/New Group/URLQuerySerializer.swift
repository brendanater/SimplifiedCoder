//
//  URLQuerySerializer.swift
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
//

import Foundation


/// all "dictionaries" are arrays of (String, Any).
/// can serialize from [String: Any]
/// all values are Optional<String>

/**
 
 Converts URLQuery objects to/from a query string or it's associated types
 
 dictionaries are: [String: Any] or [(String, Any)]
 
 deserializes to [(String, Any)]
 
 top-level: dictionary
 values:
 dictionary,
 NSArray,
 NSString,
 NSNumber,
 or
 isNil
 */

public struct URLQuerySerializer {
    
    public var boolRepresentation: (true: String, false: String) = (true.description, false.description)
    
    public var stringEncoding: String.Encoding = .utf8
    
    public enum ArraySerialization {
        /// throw if there is an array or dictionary inside another array
        case defaultAndThrowIfNested
        /// convert the array to/from a numbered dictionary starting at 0
        case arraysAreDictionaries
    }
    
    public var arraySerialization: ArraySerialization = .defaultAndThrowIfNested
    
    public var contentType: String {
        return "application/x-www-form-urlencoded" + (self.stringEncoding.charset.map { "; charset=\($0)" } ?? "")
    }
    
    public init() {}
    
    public enum ToQueryError: Error {
        
        case nestedContainerInArray
        case invalidQueryObject(Any)
        case emptyQueryKey
        case invalidQueryValue(Any)
        case failedToEncodeToData(query: String, using: String.Encoding)
        case failedToEncodeToQuery(queryItems: [URLQueryItem])
    }
    
    public enum FromQueryError: Error {
        
        public enum InvalidNameReason {
            
            case cannotBeEmpty
            case unevenOpenAndCloseBracketCount
            case startsWithAClosingBracket
            case nestedContainerInArray
            case doesNotEndWithAClosingBracket(component: String)
            case moreThanOneClosingBracket(component: String)
            case duplicateValues
        }
        
        case invalidName(String, reason: InvalidNameReason)
        
        case failedToGetQueryItems(fromQuery: String)
        case failedToGetString(fromData: Data, withEncoding: String.Encoding)
    }
    
    // MARK: isValidObject
    
    public func isValidObject(_ value: Any) -> Bool {
        
        do {
            try assertValidObject(value)
            return true
            
        } catch {
            return false
        }
    }
    
    public func assertValidObject(_ object: Any) throws {
        if let object = object as? [String: Any] {
            
            for (key, value) in object {
                
                try _assert(key: key)
                
                try _assert(value: value)
            }
            
        } else if let object = object as? [(String, Any)] {
            
            for (key, value) in object {
                
                try _assert(key: key)
                
                try _assert(value: value)
            }
            
        } else {
            throw ToQueryError.invalidQueryObject(object)
        }
    }
    
    private func _assert(key: String) throws {
        
        if key.isEmpty {
            throw ToQueryError.emptyQueryKey
        }
    }
    
    private func _assert(value: Any, inArray: Bool = false) throws {
        
        if value is NSNumber {
            return
            
        } else if value is NSString {
            return
            
        } else if isNil(value) {
            return
            
        } else if inArray, case .defaultAndThrowIfNested = self.arraySerialization {
            
            throw ToQueryError.nestedContainerInArray
            
        } else if let value = value as? [String: Any] {
            
            for (key, value) in value {
                
                try _assert(key: key)
                
                try _assert(value: value, inArray: inArray)
            }
            
        } else if let value = value as? [(String, Any)] {
            
            for (key, value) in value {
                
                try _assert(key: key)
                
                try _assert(value: value, inArray: inArray)
            }
            
        } else if let value = value as? NSArray {

            for value in value {
                try _assert(value: value, inArray: true)
            }

        } else {
            
            throw ToQueryError.invalidQueryValue(value)
        }
    }
    
    // MARK: serialization
    
    public func queryData(from value: Any) throws -> Data {
        
        let query = try self.query(from: value)
        
        if let data = query.data(using: self.stringEncoding, allowLossyConversion: false) {
            
            return data
            
        } else {
            
            throw ToQueryError.failedToEncodeToData(query: query, using: self.stringEncoding)
        }
    }
    
    public func query(from value: Any, percentEncode: Bool = true) throws -> String {
        
        let queryItems = try self.queryItems(from: value)
        
        var components = URLComponents(url: URL(string: "?")!, resolvingAgainstBaseURL: false)!
        
        components.queryItems = queryItems
        
        // components.query removes percent encoding, components.url?.query does not
        guard let query = percentEncode ? components.url?.query : components.query else {
            throw ToQueryError.failedToEncodeToQuery(queryItems: queryItems)
        }
        
        return query
    }
    
    public func queryItems(from value: Any) throws -> [URLQueryItem] {
        
        try self.assertValidObject(value)
        
        var query: [URLQueryItem] = []
        
        if let value = value as? [String: Any] {
            
            for (name, value) in value {
                
                self._queryItems(name: name, value: value, to: &query)
            }
            
        } else if let value = value as? [(String, Any)] {
            
            for (name, value) in value {
                
                self._queryItems(name: name, value: value, to: &query)
            }
            
        } else {

            fatalError("URLQuerySerializer.assertValidObject(_:) did not catch top-level object: \(value) of type: \(type(of: value))")
        }
        
        return query
    }
    
    private func _queryItems(name: String, value: Any, to query: inout [URLQueryItem]) {
        
        if let value = value as? NSNumber {
            
            if value.isBool {
                
                query.append(URLQueryItem(name: name, value: (value.boolValue ? boolRepresentation.true : boolRepresentation.false)))
                
            } else {
                
                query.append(URLQueryItem(name: name, value: value.description))
            }
            
        } else if let value = value as? String {
            
            query.append(URLQueryItem(name: name, value: value))
            
        } else if isNil(value) {
            
            query.append(URLQueryItem(name: name, value: nil))
            
        } else if let value = value as? [String: Any] {
            
            for (key, value) in value {
                
                self._queryItems(name: name + "[\(key)]", value: value, to: &query)
            }
        
        } else if let value = value as? [(String, Any)] {
            
            for (key, value) in value {
                
                self._queryItems(name: name + "[\(key)]", value: value, to: &query)
            }
            
        } else if let value = value as? NSArray {
            
            switch arraySerialization {
                
            case .defaultAndThrowIfNested:
                
                for value in value {
                    
                    self._queryItems(name: name + "[]", value: value, to: &query)
                }
                
            case .arraysAreDictionaries:
                
                for (index, value) in value.enumerated() {
                    
                    self._queryItems(name: name + "[\(index)]", value: value, to: &query)
                }
            }
            
        } else {
            
            fatalError("Uncaught value: \(value) of type: \(type(of: value)). URLQuerySerializer.assertValidObject(_:) did not catch a value")
        }
    }
    
    // MARK - deserialization
    
    // Data
    
    public func object(from data: Data) throws -> [(String, Any)] {
        
        if let string = String(data: data, encoding: self.stringEncoding) {
            
            return try self.object(from: string)
            
        } else {
            
            throw URLQuerySerializer.FromQueryError.failedToGetString(fromData: data, withEncoding: self.stringEncoding)
        }
    }
    
    // String
    
    public func object(from query: String, percentEncoded: Bool = true) throws -> [(String, Any)] {
        
        if let query = (percentEncoded ? query : query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)),
            let url = URL(string: "?" + query),
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            
            return try self.object(from: queryItems)
            
        } else {
            
            throw FromQueryError.failedToGetQueryItems(fromQuery: query)
        }
    }
    
    // [QueryItem]
    
    private typealias Components = [String?]
    private typealias Value = (name: String, components: Components, value: String?)
    private typealias Values = [Value]
    
    public func object(from queryItems: [URLQueryItem]) throws -> [(String, Any)] {
        
        var values: _URLQueryDictionary<Values> = [:]
        
        for item in queryItems {
            
            let name = item.name
            let value = item.value
            
            // name components
            
            if name.isEmpty {
                throw FromQueryError.invalidName(name, reason: .cannotBeEmpty)
            }
            
            if name.contains("[") {
                
                guard name.countInstances(of: "[") == name.countInstances(of: "]") else {
                    throw FromQueryError.invalidName(name, reason: .unevenOpenAndCloseBracketCount)
                }
                
                var components: Components = []
                
                var subComponents = name.split(separator: "[").map { String($0) }
                
                let firstKey = subComponents.removeFirst()
                
                guard firstKey.contains("]") == false else {
                    throw FromQueryError.invalidName(name, reason: .startsWithAClosingBracket)
                }
                
                var hasSetArrayComponent = false
                
                for var component in subComponents {
                    
                    if hasSetArrayComponent {
                        throw FromQueryError.invalidName(name, reason: .nestedContainerInArray)
                    }
                    
                    guard component.last == "]" else {
                        throw FromQueryError.invalidName(name, reason: .doesNotEndWithAClosingBracket(component: component))
                    }
                    
                    // remove closing bracket
                    component.removeLast()
                    
                    if component.contains("]") {
                        throw FromQueryError.invalidName(name, reason: .moreThanOneClosingBracket(component: component))
                    }
                    
                    if component == "" {
                        components.append(nil)
                        hasSetArrayComponent = true
                    } else {
                        components.append(component)
                    }
                }
                
                values.append((name, components, value), forKey: firstKey)
                
            } else {
                
                values.append((name, [], value), forKey: name)
            }
        }
        
        // top-level arrays are not checked
        return try values.elements.map { ($0.key, try self._combine($0.value)) }
    }
    
    private func _combine(_ values: Values) throws -> Any {
        
        // guaranteed to have at least one value even if String?.none
        
        if let key = values.first?.components.first {
            
            if key != nil {
                
                // first component is dict
                
                var _values: _URLQueryDictionary<Values> = [:]
                
                // remove first component
                for (name, var keys, value) in values {
                    
                    // all other values are dict
                    guard let c = keys.popFirst(), let key = c else {
                        throw FromQueryError.invalidName(name, reason: .duplicateValues)
                    }
                    
                    // combine values
                    _values.append((name, keys, value), forKey: key)
                }
                
                // if values.keys contains "0", "1", "2", ..< elements.count, top-level is an array
                isArray: if case .arraysAreDictionaries = arraySerialization {
                    
                    var array: [Values] = []
                    
                    for (index, element) in _values.elements.enumerated() {
                        
                        guard _values.elements.first(where: { $0.key == "\(index)" }) != nil else {
                            break isArray
                        }
                        
                        array.append(element.value)
                    }
                    
                    return try array.map { try self._combine($0) }
                }
                
                return try _values.elements.map { ($0.key, try self._combine($0.value)) }
                
            } else {
                // first component is array
                
                // no nested containers (handled by .object(from:) using hasSetArrayComponent)
                
                return try values.map { (value) throws -> String? in
                    
                    // all other values are the same type
                    guard value.components.first != nil && value.components.first! == nil else {
                        throw FromQueryError.invalidName(values.first!.name, reason: .duplicateValues)
                    }
                    
                    return value.value
                }
            }
            
        } else {
            // no more components
            
            // no other values
            guard values.count == 1 else {
                throw FromQueryError.invalidName(values.first!.name, reason: .duplicateValues)
            }
            
            // return value
            
            let value = values.first?.value ?? ""
            
            if value.isEmpty {
                
                return NSNull()
                
            } else {
                
                return value
            }
        }
    }
}

fileprivate struct _URLQueryDictionary<V>: ExpressibleByDictionaryLiteral {
    
    typealias Key = String
    typealias Value = V
    typealias Element = (key: Key, value: Value)
    
    var elements: [Element]
    
    init(dictionaryLiteral elements: (String, V)...) {
        self.elements = elements
    }
    
    subscript(key: Key) -> Value? {
        
        get {
            return self.elements.first(where: { $0.key == key })?.value
        }
        
        set {
    
            if let newValue = newValue {
    
                if let index = self.elements.index(where: { $0.key == key }) {
                    self.elements.remove(at: index)
    
                    self.elements.insert((key, newValue), at: index)
                } else {
                    self.elements.append((key, newValue))
                }
            } else {
                self.elements.popFirst(where: { $0.key == key })
            }
        }
    }
}

extension _URLQueryDictionary where Value: Sequence & ExpressibleByArrayLiteral & RangeReplaceableCollection {

    mutating func append(_ value: Value.Element, forKey key: String) {

        var element = self[key] ?? []

        element.append(value)

        self[key] = element
    }
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
        if self.first != nil {
            return self.removeFirst()
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

fileprivate extension String {
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

fileprivate extension Array {
    
    func _unordered(_ value: Any) -> Any {
        
        if let value = value as? [(String, Any)] {
            
            var result: [String: Any] = [:]
            
            for (key, value) in value {
                
                result[key] = self._unordered(value)
            }
            
            return result
            
        } else if let value = value as? [Any] {
            
            return value.map(self._unordered(_:))
            
        } else {
            return value
        }
    }
    
    /// converts self, if tupleArray, and any nested tuple arrays to a dictionary
    func _unordered() -> Any {
        
        return self._unordered(self)
    }
}


















