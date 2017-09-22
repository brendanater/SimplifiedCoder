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
    
    public enum ArraySerialization {
        case defaultAndThrowIfNested
        case arraysAreDictionaries
    }
    
    public var arraySerialization: ArraySerialization = .defaultAndThrowIfNested
    
    public init() {}
    
    public enum ToQueryError: Error {
        
        public enum InvalidKeyReason {
            case cannotContainCharacters(String)
            case cannotBeEmpty
        }
        
        case nestedContainerInArray
        case invalidKey(String, reason: InvalidKeyReason)
        case invalidTopLevelObject(Any, mustBeOneOf: [Any.Type])
        case invalidQueryObject(Any, mustBeOneOfOrIsNil: [Any.Type])
        case failedToConvertToData(query: String)
    }
    
    public enum FromQueryError: Error {
        
        public enum InvalidNameReason {
            
            case cannotBeEmpty
            case cannotContainCharacters(String)
            case unevenOpenAndCloseBracketCount
            case startsWithAClosingBracket
            case nestedContainerInArray
            case doesNotEndWithAClosingBracket(component: String)
            case moreThanOneClosingBracket(component: String)
        }
        
        case invalidName(String, reason: InvalidNameReason)
        
        case duplicateValueForName(String)
        case failedToGetQueryItems(fromQuery: String)
    }
    
    // MARK: isValidObject
    
    public static func isValidObject(_ value: Any, printError: Bool = false) -> Bool {
        
        do {
            try assertValidObject(value)
            
            return true
            
        } catch {
            
            if printError {
                print(error)
            }
            
            return false
        }
    }
    
    private static func _assert(key: String, nested: Bool = false) throws {
        
        for c in key {
            if _str.contains(c) {
                throw ToQueryError.invalidKey(key, reason: .cannotContainCharacters(_str))
            }
        }
        
        if key == "" {
            throw ToQueryError.invalidKey(key, reason: .cannotBeEmpty)
        }
    }
    
    public static func assertValidObject(_ value: Any) throws {
        
        if let value = value as? [String: Any] {
            
            for (key, value) in value {
                
                try _assert(key: key)
                
                try _assertValidObject(value)
            }
            
        } else if let value = value as? [(String, Any)] {
            
            for (key, value) in value {
                
                try _assert(key: key)
                
                try _assertValidObject(value)
            }
            
            // top-level arrays are not allowed
//        } else if case .arraysAreDictionaries = arraySerialization {
//
//            if let value = value as? [Any] {
//
//                for value in value {
//
//                    try _assertValidObject(value)
//                }
//
//            } else {
//                throw ToQueryError.invalidTopLevelObject(value, mustBeOneOf: [[String: Any].self, [(String, Any)].self, [Any].self])
//            }
        } else {
            throw ToQueryError.invalidTopLevelObject(value, mustBeOneOf: [[String: Any].self, [(String, Any)].self])
        }
    }
    
    private static func _assertValidObject(_ value: Any) throws {
        
        if value as? NSNumber != nil {
            return
            
        } else if value as? NSString != nil {
            return
            
        } else if isNil(value) {
            return
            
        } else if let value = value as? [String: Any] {
            
            for (key, value) in value {
                
                try _assert(key: key, nested: true)
                
                try _assertValidObject(value)
            }
            
        } else if let value = value as? [(String, Any)] {
            
            for (key, value) in value {
                
                try _assert(key: key, nested: true)
                
                try _assertValidObject(value)
            }
            
        } else if let value = value as? NSArray {

            for value in value {
                try _assertValidObject(value)
            }

        } else {
            
            throw ToQueryError.invalidQueryObject(value, mustBeOneOfOrIsNil: [[String: Any].self, [(String, Any)].self, NSArray.self, NSNumber.self, NSString.self])
        }
    }
    
    // MARK: serialization
    
    public func queryData(from value: Any) throws -> Data {
        
        let query = try self.query(from: value)
        
        if let data = query.data(using: .utf8, allowLossyConversion: false) {
            return data
        } else {
            throw ToQueryError.failedToConvertToData(query: query)
        }
    }
    
    public func query(from value: Any) throws -> String {
        
        return try queryItems(from: value).map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
    }
    
    /// pass result to a URLComponents.queryItems to add to a URL
    public func queryItems(from value: Any) throws -> [URLQueryItem] {
        
        try URLQuerySerializer.assertValidObject(value)
        
        var query: [URLQueryItem] = []
        
        if let value = value as? [String: Any] {
            
            for (name, value) in value {
                
                try self._queryItems(name: name, value: value, to: &query)
            }
            
        } else if let value = value as? [(String, Any)] {
            
            for (name, value) in value {
                
                try self._queryItems(name: name, value: value, to: &query)
            }
            
            // top-level arrays are not allowed
//        } else if let value = value as? NSArray, case .arraysAreDictionaries = arraySerialization {
//
//            for (index, value) in value.enumerated() {
//                try self._queryItems(name: index.description, value: value, to: &query)
//            }
//
        } else {

            fatalError("URLQuerySerializer.queryItems(from:) did not catch a valid top-level object: \(value) of type: \(type(of: value))")
        }
        
        return query
    }
    
    private func _queryItems(name: String, value: Any, to query: inout [URLQueryItem]) throws {
        
        if let value = value as? [String: Any] {
            
            if name.hasSuffix("[]") {
                throw ToQueryError.nestedContainerInArray
            }
            
            for (key, value) in value {
                
                try self._queryItems(name: name + "[\(key)]", value: value, to: &query)
            }
        
        } else if let value = value as? [(String, Any)] {
            
            if name.hasSuffix("[]") {
                throw ToQueryError.nestedContainerInArray
            }
            
            for (key, value) in value {
                
                try self._queryItems(name: name + "[\(key)]", value: value, to: &query)
            }
            
        } else if let value = value as? NSArray {
            
            if name.hasSuffix("[]") {
                throw ToQueryError.nestedContainerInArray
            }
            
            switch arraySerialization {
                
            case .defaultAndThrowIfNested:
                
                for value in value {
                    
                    try self._queryItems(name: name + "[]", value: value, to: &query)
                }
                
            case .arraysAreDictionaries:
                
                for (index, value) in value.enumerated() {
                    
                    try self._queryItems(name: name + "[\(index)]", value: value, to: &query)
                }
            }
            
        } else if let value = value as? NSNumber {
            
            // one way to tell if a NSNumber is a Bool.
            // type(of: NSNumber subclass) == type(of: true as NSNumber)
            if type(of: value) == _objcBoolType {
                
                query.append(URLQueryItem(name: name, value: (value.boolValue ? boolRepresentation.true : boolRepresentation.false)))
                
            } else {
                
                query.append(URLQueryItem(name: name, value: value.description))
            }
            
        } else if let value = value as? String {
            
            query.append(URLQueryItem(name: name, value: value))
            
        } else {
            
            precondition(isNil(value), "Uncaught value: \(value) of type: \(type(of: value)). URLQuerySerializer.queryComponents(from:) did not catch a valid value")
            
            query.append(URLQueryItem(name: name, value: nil))
        }
    }
    
    // MARK - deserialization
    
    // Data
    
    public func objectUnordered(from query: Data) throws -> Any {
        
        return try self.object(from: query)._unordered()
    }
    
    public func object(from query: Data) throws -> [Any] {
        
        return try self.object(from: query.base64EncodedString())
    }
    
    // String
    
    public func objectUnordered(from query: String) throws -> Any {
        
        return try self.object(from: query)._unordered()
    }
    
    public func object(from query: String) throws -> [Any] {
        
        if let url = URL(string: "notAURL.com/"), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            
            components.query = query
            
            return try self.object(from: components.queryItems ?? [])
            
        } else {
            
            throw FromQueryError.failedToGetQueryItems(fromQuery: query)
        }
    }
    
    // Array<QueryItem>
    
    public func objectUnordered(from query: [URLQueryItem]) throws -> Any {
        
        return try self.object(from: query)._unordered()
    }
    
    private typealias Components = [String?]
    private typealias Value = (name: String, components: Components, value: String?)
    private typealias Values = [Value]
    
    /// if query is empty, will return as empty array of Any
    /// if top-level can be converted to array, top-level will be [Any]
    /// else, top-level will be [(String, Any)]
    public func object(from query: [URLQueryItem]) throws -> [Any] {
        
        if query.isEmpty {
            return []
        }
        
        var values: _URLQueryDictionary<Values> = [:]
        
        for item in query {
            
            let name = item.name
            let value = item.value
            
            // name components
            
            if name.isEmpty {
                throw FromQueryError.invalidName(name, reason: .cannotBeEmpty)
            }
            
            if name.contains("[") {
                
                guard _str.contains(name.first!) == false else {
                    throw FromQueryError.invalidName(name, reason: .cannotContainCharacters(_str))
                }
                
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
                        throw FromQueryError.duplicateValueForName(name)
                    }
                    
                    // combine values
                    _values.append((name, keys, value), forKey: key)
                }
                
                // if values.keys contains "0", "1", "2", ..< elements.count, top-level can be an array
                isArray: if case .arraysAreDictionaries = arraySerialization {
                    
                    var array: [Values] = []
                    
                    var index = 0
                    
                    while index < _values.elements.count {
                        
                        guard let values = _values.elements.first(where: { $0.key == "\(index)" })?.value else {
                            break isArray
                        }
                        
                        index += 1
                        
                        array.append(values)
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
                        throw FromQueryError.duplicateValueForName(value.name)
                    }
                    
                    return value.value
                }
            }
            
        } else {
            // no more components
            
            // no other values
            guard values.count == 1 else {
                throw FromQueryError.duplicateValueForName(values.first!.name)
            }
            
            // return value
            return values.first?.value as Any
        }
    }
}

/// keys cannot contain these characters
fileprivate var _str = "[]#&="

fileprivate var _objcBoolType = type(of: true as NSNumber)

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


















