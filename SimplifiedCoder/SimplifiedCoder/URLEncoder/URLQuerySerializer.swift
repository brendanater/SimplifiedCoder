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
    
    public enum ToQueryError: Error {
        
        case nestedContainerInArray
        case invalidKey(String, reason: String)
        case invalidQueryObject(Any, reason: String)
    }
    
    public enum FromQueryError: Error {
        
        case invalidName(String, reason: String)
        case duplicateValueForName
        case failedToGetQueryItems(query: String)
    }
    
    // MARK: serialization
    
    public func queryData(from value: Any) throws -> Data {
        
        let query = try self.query(from: value)
        
        if let data = query.data(using: .utf8, allowLossyConversion: false) {
            return data
        } else {
            throw ToQueryError.invalidQueryObject(value, reason: "Could not convert query to Data. Query: \(query)")
        }
    }
    
    public func query(from value: Any) throws -> String {
        
        return try queryItems(from: value).map { "\($0.name)=\($0.value ?? "")"}.joined(separator: "&")
    }
    
    /// pass result to a URLComponents.queryItems to add to a URL
    public func queryItems(from value: Any) throws -> [URLQueryItem] {
        
        try assertValidObject(value)
        
        var query: [URLQueryItem] = []
        
        if let value = value as? [String: Any] {
            
            for (name, value) in value {
                
                try self._queryItems(name: name, value: value, to: &query)
            }
            
        } else if let value = value as? [(String, Any)] {
            
            for (name, value) in value {
                
                try self._queryItems(name: name, value: value, to: &query)
            }
            
        } else {
            fatalError("URLQuerySerializer.assertValidObject(_:) did not catch an invalid top-level object: \(value) of type: \(type(of: value))")
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
            
            for (nestedKey, value) in value {
                
                try self._queryItems(name: name + "[\(nestedKey)]", value: value, to: &query)
            }
            
        } else if let value = value as? NSArray {
            
            if name.hasSuffix("[]") {
                throw ToQueryError.nestedContainerInArray
            }
            
            for value in value {
                
                try self._queryItems(name: name + "[]", value: value, to: &query)
            }
            
        } else if let value = value as? NSNumber {
            
            // one way to tell if a NSNumber is a Bool.
            if type(of: value) == objcBoolType {
                
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
    
    // MARK: isValidObject
    
    public func isValidObject(_ value: Any, printError: Bool = false) -> Bool {
        
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
    
    /// keys cannot contain these characters
    private var _str = "[]#&="
    
    public func assertValidObject(_ value: Any) throws {
        
        if let value = value as? [String: Any] {
            
            for (key, value) in value {
                
                for c in key {
                    if _str.contains(c) {
                        throw ToQueryError.invalidKey(key, reason: "Key: \(key) cannot contain [, ], #, &, or =")
                    }
                }
                
                if key == "" {
                    throw ToQueryError.invalidKey(key, reason: "Dictionary keys cannot be empty.")
                }
                
                try _assertValidObject(value)
            }
            
        } else if let value = value as? [(String, Any)] {
            
            for (key, value) in value {
                
                for c in key {
                    if _str.contains(c) {
                        throw ToQueryError.invalidKey(key, reason: "Key: \(key) cannot contain [, ], #, &, or =")
                    }
                }
                
                if key == "" {
                    throw ToQueryError.invalidKey(key, reason: "Dictionary keys cannot be empty.")
                }
                
                try _assertValidObject(value)
            }
            
        } else {
            
            throw ToQueryError.invalidQueryObject(value, reason: "Invalid top-level object. Top-level object must be: [String: Any] or [(String, Any)]")
        }
    }
    
    private func _assertValidObject(_ value: Any) throws {
        
        if value as? NSNumber != nil {
            return
            
        } else if value as? NSString != nil {
            return
            
        } else if isNil(value) {
            return
            
        } else if let value = value as? [String: Any] {
            
            for (key, value) in value {
                
                for c in key {
                    if _str.contains(c) {
                        throw ToQueryError.invalidKey(key, reason: "Key: \(key) cannot contain [, ], #, &, or =")
                    }
                }
                
                if key == "" {
                    throw ToQueryError.invalidKey(key, reason: "Dictionary keys cannot be empty.")
                }
                
                try _assertValidObject(value)
            }
            
        } else if let value = value as? [(String, Any)] {
            
            for (key, value) in value {
                
                for c in key {
                    if _str.contains(c) {
                        throw ToQueryError.invalidKey(key, reason: "Key: \(key) cannot contain [, ], #, &, or =")
                    }
                }
                
                if key == "" {
                    throw ToQueryError.invalidKey(key, reason: "Dictionary keys cannot be empty.")
                }
                
                try _assertValidObject(value)
            }
            
        } else if let value = value as? NSArray {
            
            for value in value {
                try _assertValidObject(value)
            }
            
        } else {
            
            throw ToQueryError.invalidQueryObject(value, reason: "Unsupported value. Value must be: [String: Any], [(String, Any)], NSArray, Bool, NSNumber, NSString, or isNil(_:)")
        }
    }
    
    // MARK - deserialization
    
    private enum Component {
        case array
        case dictionary(key: String)
    }
    
    // Data
    
    public func objectUnordered(from query: Data) throws -> [String: Any] {
        
        return try self.object(from: query)._unordered()
    }
    
    public func object(from query: Data) throws -> [(key: String, value: Any)] {
        
        return try self.object(from: query.base64EncodedString())
    }
    
    // String
    
    public func objectUnordered(from query: String) throws -> [String: Any] {
        
        return try self.object(from: query)._unordered()
    }
    
    public func object(from query: String) throws -> [(key: String, value: Any)] {
        
        if let url = URL(string: "notAURL.com/"), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            
            components.query = query
            
            return try self.object(from: components.queryItems ?? [])
            
        } else {
            
            throw FromQueryError.failedToGetQueryItems(query: query)
        }
    }
    
    // Array<QueryItem>
    
    public func objectUnordered(from query: [URLQueryItem]) throws -> [String: Any] {
        
        return try self.object(from: query)._unordered()
    }
    
    public func object(from query: [URLQueryItem]) throws -> [(key: String, value: Any)] {
        
        var values: _URLQueryDictionary<[([Component], String?)]> = [:]
        
        for item in query {
            
            let name = item.name
            let value = item.value
            
            // name components
            
            if name.contains("[") {
                
                guard _str.contains(name.first!) == false else {
                    throw FromQueryError.invalidName(name, reason: "Cannot start with [, ], #, &, or =")
                }
                
                guard name.countInstances(of: "[") == name.countInstances(of: "]") else {
                    throw FromQueryError.invalidName(name, reason: "Does not have equal number of open and close brackets")
                }
                
                var components: [Component] = []
                
                var subComponents = name.split(separator: "[").map { String($0) }
                
                let key = subComponents.removeFirst()
                
                guard key.contains("]") == false else {
                    throw FromQueryError.invalidName(name, reason: "Cannot start with a closing bracket")
                }
                
                var hasSetArrayComponent = false
                
                for var component in subComponents {
                    
                    if hasSetArrayComponent {
                        throw FromQueryError.invalidName(name, reason: "Cannot have a nested container in an array")
                    }
                    
                    guard component.last == "]" else {
                        throw FromQueryError.invalidName(name, reason: "Component: \(component) does not end with a closing bracket")
                    }
                    
                    // remove closing bracket
                    component.removeLast()
                    
                    if component.contains("]") {
                        throw FromQueryError.invalidName(name, reason: "Component: \(component) had more than one closing bracket")
                    }
                    
                    if component == "" {
                        components.append(.array)
                        hasSetArrayComponent = true
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
        
        // guaranteed to have at least one value
        
        if let type = values.first?.components.first {
            
            switch type {
                
            case .array:
                // first component is array
                
                // no nested containers (should be handled by .object(from:))
                
                return try values.map { (value) throws -> String? in
                    
                    // all other values are the same type
                    if let c = value.components.first, case .array = c {
                        
                        // return values
                        return value.value
                        
                    } else {
                        throw FromQueryError.duplicateValueForName
                    }
                }
                
            case .dictionary(key: _):
                // first component is dict
                
                var _values: _URLQueryDictionary<[([Component], String?)]> = [:]
                
                // remove first component
                for (var components, value) in values {
                    
                    // all other values are dict
                    if let c = components.first, case .dictionary(let key) = c {
                        
                        // remove first component
                        components.removeFirst()
                        
                        // combine values
                        _values.append((components, value), forKey: key)
                        
                    } else {
                        throw FromQueryError.duplicateValueForName
                    }
                }
                
                return try _values.elements.map { ($0, try combine($1)) }
            }
            
        } else {
            // no component
            
            // no other values
            guard values.count == 1 else {
                throw FromQueryError.duplicateValueForName
            }
            
            // return value
            return values.first?.value as Any
        }
    }
}

fileprivate var objcBoolType = type(of: true as NSNumber)

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

extension Array {
    
    fileprivate func _unordered(_ value: Any) -> Any {
        
        if let value = value as? [(AnyHashable, Any)] {
            
            var result: [AnyHashable: Any] = [:]
            
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
}

fileprivate extension Array where Element == (key: String, value: Any) {
    
    /// converts self and any nested tuple arrays to a dictionary
    func _unordered() -> [String: Any] {
        
        return self._unordered(self) as! [String: Any]
    }
}


















