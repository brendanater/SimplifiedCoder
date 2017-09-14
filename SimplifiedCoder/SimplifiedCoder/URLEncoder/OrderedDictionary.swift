//
//  DictionaryArray.swift
//  URLEncoder
//
//  Created by Brendan Henderson on 9/5/17.
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

//import Foundation
//
///// a type that can disorder to a dictionary of AnyHashable and Any.
///// (used in OrderedDictionaryProtocol.disorderAll() to cast and disorder other nested)
//public protocol CanDisorder {
//
//    func disorderAllUntyped() -> Dictionary<AnyHashable, Any>
//}
//
//public protocol HasOrderedDictionaryElementType {
//
//    func _elementsUntyped() -> [(key: AnyHashable, value: Any)]
//}
//
///// a temporary simple dictionary using an array to preserve the order of a dictionary
///// setting a value should remove the value for the key and insert at that index, or append a new value
//public protocol OrderedDictionaryProtocol: Sequence, ExpressibleByDictionaryLiteral, CanDisorder, HasOrderedDictionaryElementType where Key: Hashable, Element == (key: Key, value: Value) {
//
//    // required
//
//    var elements: [Element] {get set}
//
//    init(_ elements: [Element])
//
//    // new
//
//    subscript(key: Key) -> Value? {get set}
//
//    func getValue(forKey key: Key) -> Value?
//
//    mutating func replaceOrAppend(_ newValue: Value?, forKey key: Key)
//}
//
//public extension OrderedDictionaryProtocol {
//
//    public init(dictionaryLiteral elements: (Key, Value)...) {
//        self.init(elements)
//    }
//
//    public var count: Int {
//        return elements.count
//    }
//
//    public func getValue(forKey key: Key) -> Value? {
//        return elements.first(where: { $0.key == key })?.value
//    }
//
//    public mutating func replaceOrAppend(_ newValue: Value?, forKey key: Key) {
//
//        if let newValue = newValue {
//
//            if let index = self.elements.index(where: { $0.key == key }) {
//                self.elements.remove(at: index)
//
//                self.elements.insert((key, newValue), at: index)
//            } else {
//                self.elements.append((key, newValue))
//            }
//        } else {
//            self.elements.popFirst(where: { $0.key == key })
//        }
//    }
//
//    public subscript(key: Key) -> Value? {
//
//        get {
//            return self.getValue(forKey: key)
//        }
//
//        set {
//            self.replaceOrAppend(newValue, forKey: key)
//        }
//    }
//
//    public func makeIterator() -> Array<Element>.Iterator {
//        return self.elements.makeIterator()
//    }
//
//    public mutating func popFirst() -> Element? {
//        return self.elements.popFirst()
//    }
//
//    private func _disorder(_ value: Any) -> Any {
//
//        if let value = value as? CanDisorder {
//            return value.disorderAllUntyped()
//        } else if let value = value as? [Any] {
//            return value.map(_disorder(_:))
//        } else {
//            return value
//        }
//    }
//
//    /// casts to a normal dictionary and any nested ordered dictionaries to a normal dictionary (untyped for conformance to CanDisorder).
//    public func disorderAllUntyped() -> Dictionary<AnyHashable, Any> {
//
//        return self.disorderAll()
//    }
//
//    /// converts the top level dictionary to a normal dictionary
//    public func disorder() -> Dictionary<Key, Value> {
//
//        var result: Dictionary<Key, Value> = [:]
//
//        for (key, value) in self {
//
//            result[key] = value
//        }
//
//        return result
//    }
//
//    /// casts to a normal dictionary and any nested ordered dictionaries to a normal dictionary
//    public func disorderAll() -> Dictionary<Key, Any> {
//
//        var result: Dictionary<Key, Any> = [:]
//
//        for (key, value) in self {
//
//            result[key] = self._disorder(value)
//        }
//
//        return result
//    }
//}
//
//extension Array {
//
//    public init<T: OrderedDictionaryProtocol>(_ orderedDictionary: T) where Element == T.Element {
//        self = orderedDictionary.elements
//    }
//}
//
//extension Dictionary {
//
//    public init(_ elements: [(key: Key, value: Value)]) {
//
//        self.init()
//
//        for (key, value) in elements {
//            self[key] = value
//        }
//    }
//
//    /// inits self with orderedDictionary.disorder()
//    public init<T: OrderedDictionaryProtocol>(disorder orderedDictionary: T) where Element == T.Element, Value == Any {
//        self = orderedDictionary.disorder()
//    }
//
//    public init<T: OrderedDictionaryProtocol>(_ orderedDictionary: T) where Element == T.Element {
//        self.init(orderedDictionary.elements)
//    }
//}
//
//extension OrderedDictionaryProtocol where Value: Sequence & ExpressibleByArrayLiteral & RangeReplaceableCollection {
//
//    mutating func append(_ value: Value.Element, forKey key: Key) {
//
//        var element = self[key] ?? []
//
//        element.append(value)
//
//        self[key] = element
//    }
//}
//
//extension OrderedDictionaryProtocol {
//
//    private func _untype(_ value: Any) -> Any {
//
//        if let value = value as? HasOrderedDictionaryElementType {
//
//            return value._elementsUntyped()
//
//        } else if var result = value as? [AnyHashable: Any] {
//
//            for (key, value) in result {
//                result[key] = self._untype(value)
//            }
//
//            return result
//
//        } else if let value = value as? [(AnyHashable, Any)] {
//
//            var result: [(AnyHashable, Any)] = []
//
//            for (key, value) in value {
//                result.append((key, self._untype(value)))
//            }
//
//            return result
//
//        } else if let value = value as? [Any] {
//
//            return value.map(self._untype(_:))
//
//        } else {
//
//            return value
//        }
//    }
//
//    /// takes the elements out of self and any nested HasOrderedDictionaryElementType and returns them
//    func _elementsUntyped() -> [(key: AnyHashable, value: Any)] {
//
//        return self._untype(self.elements) as! [(key: AnyHashable, value: Any)]
//    }
//
//    func elementsUntyped() -> [(key: Key, value: Any)] {
//        return self._elementsUntyped() as! [(key: Key, value: Any)]
//    }
//}

















