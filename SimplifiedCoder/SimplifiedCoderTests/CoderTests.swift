//
//  CoderTests.swift
//  SimplifiedCoderTests
//
//  Created by Brendan Henderson on 9/20/17.
//  Copyright © 2017 OKAY. All rights reserved.
//

import Foundation
import XCTest
@testable import SimplifiedCoder


class CoderTests: XCTestCase {
    
    func testRoundTrip() {
        
        if let fail = roundTrip(["test"]) { XCTFail(fail.description) }
        if let fail = roundTrip([true]) { XCTFail(fail.description) }
        if let fail = roundTrip([UInt64.max, UInt64.min]) { XCTFail(fail.description) }
        if let fail = roundTrip([String?.none, String?.some("test")]) { XCTFail(fail.description) }
        if let fail = roundTrip([Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, 0, Float.leastNormalMagnitude, Float.leastNonzeroMagnitude]) { XCTFail(fail.description) }
        if let fail = roundTrip([Double.greatestFiniteMagnitude, -Double.greatestFiniteMagnitude, 0, Double.leastNormalMagnitude, Double.leastNonzeroMagnitude]) { XCTFail(fail.description) }
        if let fail = roundTrip([Int8.max, Int8.min]) { XCTFail(fail.description) }
        if let fail = roundTrip([UInt8.max, UInt8.min]) { XCTFail(fail.description) }
        if let fail = roundTrip([Int.max, Int.min]) { XCTFail(fail.description) }
        if let fail = roundTrip([UInt.max, UInt.min]) { XCTFail(fail.description) }
        
        // array
        single: if let fail = roundTrip([1]) { XCTFail(fail.description) }
        multiple: if let fail = roundTrip([1, 2, 3, 4, 5]) { XCTFail(fail.description) }
        nested: if let fail = roundTrip([[[[[[1]]], [[[2]]]]]]) { XCTFail(fail.description) }
        
        // dictionary
        single: if let fail = roundTrip([1: 1]) { XCTFail(fail.description) }
        multiple: if let fail = roundTrip(asDictionary([1, 2, 3, 4, 5])) { XCTFail(fail.description) }
        nested: if let fail = roundTrip(asDictionary([[[[[[1]]], [[[2]]]]]])) { XCTFail(fail.description) }
        
        // mixed array and dictionary
        arrayFirst: if let fail = roundTrip([[1: 1]]) { XCTFail(fail.description) }
        dictionaryFirst: if let fail = roundTrip([1: [1]]) { XCTFail(fail.description) }
        arrayDictArray: if let fail = roundTrip([[1: [1: 1]]]) { XCTFail(fail.description) }
        dictArrayDict: if let fail = roundTrip([1: [[1: 1]]]) { XCTFail(fail.description) }
        
        // objects
        if let fail = roundTrip([Objects.Single()]) { XCTFail(fail.description) } // JSONSerialization cannot handle single top-level objects
        if let fail = roundTrip(Objects.Keyed()) { XCTFail(fail.description) }
        if let fail = roundTrip(Objects.Unkeyed()) { XCTFail(fail.description) }
        if let fail = roundTrip(Objects.NestedKeyed()) { XCTFail(fail.description) }
        if let fail = roundTrip(Objects.NestedUnkeyed()) { XCTFail(fail.description) }
        if let fail = roundTrip(Objects.SubKeyed()) { XCTFail(fail.description) }
        if let fail = roundTrip(Objects.SubUnkeyed()) { XCTFail(fail.description) }
    }
    
    func testPath() {
        
        let v = Float.infinity

        // array
        single: if let fail = path([v]) { XCTFail(fail.description) }
        nested: if let fail = path([[[[[[1 as Float]]], [[[v]]]]]]) { XCTFail(fail.description) }

        // dictionary
        single: if let fail = path(["1": v]) { XCTFail(fail.description) }
        nested: if let fail = path(asStringDictionary([[[[[[v]]], [[[1 as Float]]]]]])) { XCTFail(fail.description) }

        // mixed array and dictionary
        arrayFirst: if let fail = path([["1": v]]) { XCTFail(fail.description) }
        dictionaryFirst: if let fail = path(["1": [v]]) { XCTFail(fail.description) }
        arrayDictArray: if let fail = path([["1": ["1": v]]]) { XCTFail(fail.description) }
        dictArrayDict: if let fail = path(["1": [["1": v]]]) { XCTFail(fail.description) }

        // objects
        if let fail = path([Objects.Throwing.Single()]) { XCTFail(fail.description) } // JSONSerialization cannot handle single top-level objects
        if let fail = path(Objects.Throwing.Keyed()) { XCTFail(fail.description) }
        if let fail = path(Objects.Throwing.Unkeyed()) { XCTFail(fail.description) }
        if let fail = path(Objects.Throwing.NestedKeyed()) { XCTFail(fail.description) }
        if let fail = path(Objects.Throwing.NestedUnkeyed()) { XCTFail(fail.description) }
        if let fail = path(Objects.Throwing.SubKeyed()) { XCTFail(fail.description) }
        if let fail = path(Objects.Throwing.SubUnkeyed()) { XCTFail(fail.description) }
    }
    
    // MARK: round trip
    
    enum RoundTripFail: CustomStringConvertible {
        
        case valueToAny(Error)
        case valueToData(Error)
        case valueFromData(Error)
        case valueFromAny(Error)
        
        private var error: Error {
            switch self {
            case .valueToAny(let error): return error
            case .valueToData(let error): return error
            case .valueFromData(let error): return error
            case .valueFromAny(let error): return error
            }
        }
        
        private var name: String {
            
            switch self {
            case .valueToAny(_): return "value to Any"
            case .valueToData(_): return "value to Data"
            case .valueFromData(_): return "value from Data"
            case .valueFromAny(_): return "value from Any"
            }
        }
        
        var description: String {
            return "\(self.name): \(self.error)"
        }
    }
    
    enum RTError<T>: Error {
        case unequal(T, T)
    }
    
    func roundTrip<T: Codable>(_ value1: T) -> RoundTripFail? {
        
        let value: Any
        
        // value to Any
        do {
            
            value = try TestEncoder().encode(value: value1)
            
        } catch {
            
            return RoundTripFail.valueToAny(error)
            
        }
        
        // value to Data
        
        let data: Data
        
        do {
            
            data = try TestEncoder().encode(value1)
            
        } catch {
            
            return RoundTripFail.valueToData(error)
            
        }
        
        // value from Data
        
        do {
            
            let value2 = try TestDecoder().decode(T.self, from: data)
            
            guard same(value1, value2) else {
                return RoundTripFail.valueFromData(RTError.unequal(value1, value2))
            }
            
        } catch {
            
            return RoundTripFail.valueFromData(error)
        }
        
        // value from Any
        
        do {
            
            let value2 = try TestDecoder().decode(T.self, fromValue: value)
            
            guard same(value1, value2) else {
                return RoundTripFail.valueFromData(RTError.unequal(value1, value2))
            }
            
        } catch {
            
            return RoundTripFail.valueFromAny(error)
            
        }
        
        return nil
    }
    
    func asDictionary<U>(_ array: [U]) -> [Int: U] {
        return array.enumerated().reduce(into: [Int: U](), { (result, next) in
            result[next.offset] = next.element
        })
    }
    
    func asStringDictionary<U>(_ array: [U]) -> [String: U] {
        return array.enumerated().reduce(into: [String: U](), { (result, next) in
            result[next.offset.description] = next.element
        })
    }
    
    // MARK: Path
    
    indirect enum PathFail: CustomStringConvertible {
        // encoding
        case jsonEncoderDidNotThrow(result: Any)
        case encoderDidNotThrow(result: Any)
        case notEncodingError(Error)
        case encoderDifferentPaths(expected: EncodingError.Context, returned: EncodingError.Context)
        
        // decoding
        case jsonDecoderDidNotThrow(result: Any)
        case decoderDidNotThrow(result: Any)
        case notDecodingError(Error)
        case decoderDifferentPaths(expected: DecodingError.Context, returned: DecodingError.Context)
        case mismatchErrors(expected: DecodingError, returned: DecodingError)
        case mismatchCodingKeyNotFound(expected: DecodingError, returned: DecodingError)
        case mismatchType(expected: DecodingError, returned: DecodingError)
        
        case somethingFailed(encode: PathFail?, decode: PathFail?)
        
        var description: String {
            
            func description(for value: Any) -> String {
                return "\(type(of: value)) :: \(value)"
            }
            
            func add(expected: Any, received: Any) -> String {
                return ", expected: \(expected) received: \(received)"
            }
            
            func add(context1: Any, context2: Any) -> String {
                return ", context1: \(context1), context2: \(context2)"
            }
            
            switch self {
                
            case .jsonEncoderDidNotThrow(result: let result):
                return "JSONEncoder did not throw, result: " + description(for: result)
                
            case .encoderDidNotThrow(result: let result):
                return "did not throw, result: " + description(for: result)
                
            case .notEncodingError(let error):
                return "not encoding error: " + description(for: error)
                
            case .encoderDifferentPaths(expected: let context1, returned: let context2):
                return "different paths" + add(expected: context1.codingPath.count, received: context2.codingPath.count) + add(context1: context1, context2: context2)
                
            case .jsonDecoderDidNotThrow(result: let result):
                return "JSONDecoder did not throw, result: " + description(for: result)
                
            case .decoderDidNotThrow(result: let result):
                return "did not throw, result: " + description(for: result)
                
            case .notDecodingError(let error):
                return "not decoding error: " + description(for: error)
                
            case .decoderDifferentPaths(expected: let context1, returned: let context2):
                return "different paths" + add(expected: context1.codingPath.count, received: context2.codingPath.count) + add(context1: context1, context2: context2)
                
            case .mismatchErrors(expected: let error1, returned: let error2):
                return "mismatch errors" + add(expected: error1, received: error2)
                
            case .mismatchCodingKeyNotFound(expected: let error1, returned: let error2):
                guard case .keyNotFound(let key1, let context1) = error1 else { fatalError() }
                guard case .keyNotFound(let key2, let context2) = error2 else { fatalError() }
                
                return "mismatch key not found" + add(expected: description(for: key1), received: description(for: key2)) + add(context1: context1, context2: context2)
                
            case .mismatchType(expected: let error1, returned: let error2):
                
                if case .typeMismatch(let type1, let context1) = error1 {
                    guard case .typeMismatch(let type2, let context2) = error2 else { fatalError() }
                    
                    return "mismatch types" + add(expected: type1, received: type2) + add(context1: context1, context2: context2)
                    
                } else {
                    
                    guard case .valueNotFound(let type1, let context1) = error1 else { fatalError() }
                    guard case .valueNotFound(let type2, let context2) = error2 else { fatalError() }
                    
                    return "value not found: mismatch types" + add(expected: type1, received: type2) + add(context1: context1, context2: context2)
                    
                }
                
            case .somethingFailed(encode: let encodeReason, decode: let decodeReason):
                
                switch (encodeReason, decodeReason) {
                case (.some(let encodeReason), .some(let decodeReason)):
                    return "encodeError: \(encodeReason), decodeError: \(decodeReason)"
                    
                case (.some(let encodeReason), .none):
                    return "encodeError: \(encodeReason)"
                    
                case (.none, .some(let decodeReason)):
                    return "decodeError: \(decodeReason)"
                    
                case (.none, .none):
                    fatalError()
                }
                
            }
        }
    }
    
    func checkContexts(expected context1: EncodingError.Context, returned context2: EncodingError.Context) -> PathFail? {
        
        func failed() -> PathFail {
            return PathFail.encoderDifferentPaths(expected: context1, returned: context2)
        }
        
        if context1.codingPath.count != context2.codingPath.count {
            return failed()
        }
        
        for (key1, key2) in zip(context1.codingPath, context2.codingPath) {
            
            if key1.stringValue != key2.stringValue {
                print("key1: \(key1), key2: \(key2)")
                return failed()
            }
            
            // cannot get _JSONKey
            if type(of: key2) is String.Type {
                continue
            }
            
            if type(of: key1) != type(of: key2) {
                return failed()
            }
        }
        
        if context1.debugDescription != context2.debugDescription {
            print("\(context1.debugDescription) || \(context2.debugDescription)")
        }
        
        if context1.underlyingError != nil {
            print("context1 error: \(context1.underlyingError!)")
        }
        
        if context2.underlyingError != nil {
            print("context2 error: \(context2.underlyingError!)")
        }
        
        return nil
    }
    
    func encodePath<T: Encodable>(_ value: T) -> PathFail? {
        
        let encodingContext: EncodingError.Context
        
        do {
            let result = try JSONEncoder().encode(value)
            
            return PathFail.jsonEncoderDidNotThrow(result: result)
            
        } catch let error as EncodingError {
            
            switch error {
            case .invalidValue(let _value, let context):
                
                assert(_value is Float)
                
                encodingContext = context
            }
            
        } catch {
            
            fatalError("jsonEncoder threw wrong type of error: \(type(of: error)) :: \(error)")
        }
        
        
        do {
            
            let result = try TestEncoder().encode(value)
            
            return PathFail.encoderDidNotThrow(result: result)
            
        } catch let error as EncodingError {
            
            switch error {
            case .invalidValue(let _value, let context):
                
                assert(_value is Float)
                
                return checkContexts(expected: encodingContext, returned: context)
            }
        } catch {
            return PathFail.notEncodingError(error)
        }
    }
    
    func checkContexts(expected context1: DecodingError.Context, returned context2: DecodingError.Context) -> PathFail? {
        
        func failed() -> PathFail {
            return PathFail.decoderDifferentPaths(expected: context1, returned: context2)
        }
        
        if context1.codingPath.count != context2.codingPath.count {
            return failed()
        }
        
        for (key1, key2) in zip(context1.codingPath, context2.codingPath) {
            
            if key1.stringValue != key2.stringValue {
                return failed()
            }
            
            // cannot get _JSONKey
            if type(of: key2) is String.Type {
                continue
            }
            
            if type(of: key1) != type(of: key2) {
                return failed()
            }
        }
        
        if context1.debugDescription != context2.debugDescription {
            print("\(context1.debugDescription) || \(context2.debugDescription)")
        }
        
        if context1.underlyingError != nil {
            print("context1 error: \(context1.underlyingError!)")
        }
        
        if context2.underlyingError != nil {
            print("context2 error: \(context2.underlyingError!)")
        }
        
        return nil
    }
    
    func decodePath<T: Decodable>(_ value: T) -> PathFail? {
        
        
        let encoded = artificialEncode(value)
        
        assert(JSONSerialization.isValidJSONObject(encoded), "\(type(of: value)) :: \(value) invalid json object: \(type(of: encoded)) :: \(encoded)")
        
        let data = try! JSONSerialization.data(withJSONObject: artificialEncode(value))
        
        let jsonDecoderError: DecodingError
        
        do {
            
            let result = try JSONDecoder().decode(T.self, from: data)
            
            return PathFail.jsonDecoderDidNotThrow(result: result)
            
        } catch let error as DecodingError {
            
            jsonDecoderError = error
            
        } catch {
            
            fatalError("did not test correctly")
        }
        
        do {
            
            let result = try TestDecoder().decode(T.self, from: data)
            
            return PathFail.decoderDidNotThrow(result: result)
            
        } catch let error as DecodingError {
            
            switch jsonDecoderError {
            case .dataCorrupted(let context1):
                guard case .dataCorrupted(let context2) = error else {
                    return PathFail.mismatchErrors(expected: jsonDecoderError, returned: error)
                }
                
                return checkContexts(expected: context1, returned: context2)
                
            case .keyNotFound(let key1, let context1):
                
                guard case .keyNotFound(let key2, let context2) = error else {
                    return PathFail.mismatchErrors(expected: jsonDecoderError, returned: error)
                }
                
                guard key1.stringValue == key2.stringValue else {
                    return PathFail.mismatchCodingKeyNotFound(expected: jsonDecoderError, returned: error)
                }
                
                return checkContexts(expected: context1, returned: context2)
                
            case .typeMismatch(let type1, let context1):
                
                guard case .typeMismatch(let type2, let context2) = error else {
                    return PathFail.mismatchErrors(expected: jsonDecoderError, returned: error)
                }
                
                mismatchTypes: if type1 != type2 {
                    if type1 == Array<Any>.self && type2 == DecoderUnkeyedContainerContainer.self {
                        break mismatchTypes
                    } else if type1 == Dictionary<AnyHashable, Any>.self && type2 == DecoderKeyedContainerContainer.self {
                        break mismatchTypes
                    } else {
                        return PathFail.mismatchType(expected: jsonDecoderError, returned: error)
                    }
                }
                
                return checkContexts(expected: context1, returned: context2)
                
            case .valueNotFound(let type1, let context1):
                
                guard case .typeMismatch(let type2, let context2) = error else {
                    return PathFail.mismatchErrors(expected: jsonDecoderError, returned: error)
                }
                
                mismatchTypes: if type1 != type2 {
                    if type1 == Array<Any>.self && type2 == DecoderUnkeyedContainerContainer.self {
                        break mismatchTypes
                    } else if type1 == Dictionary<AnyHashable, Any>.self && type2 == DecoderKeyedContainerContainer.self {
                        break mismatchTypes
                    } else {
                        return PathFail.mismatchType(expected: jsonDecoderError, returned: error)
                    }
                }
                
                guard type1 == type2 else {
                    return PathFail.mismatchType(expected: jsonDecoderError, returned: error)
                }
                
                return checkContexts(expected: context1, returned: context2)
            }
            
        } catch {
            
            return PathFail.notDecodingError(error)
        }
    }
    
    func path<T: Codable>(_ value: T) -> PathFail? {
        
        let encodeResult = encodePath(value)
        let decodeResult = decodePath(value)
        
        if encodeResult != nil || decodeResult != nil {
            return PathFail.somethingFailed(encode: encodeResult, decode: decodeResult)
        } else {
            return nil
        }
    }
}

// MARK: Objects

struct Objects {
    
    class Single: Codable {
        
        struct Single {
            var value: String
        }
        
        var value: Single
        
        init() {
            value = Single(value: "test")
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            try container.encode(value.value)
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            value = Single(value: try container.decode(String.self))
        }
    }
    
    class Keyed: Codable {
        var value = 1
    }
    
    class Unkeyed: Codable {
        
        var values: [Int]
        
        init() {
            self.values = [1, 2, 3]
        }
        
        init(values: [Int]) {
            self.values = values
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            
            for value in values {
                try container.encode(value)
            }
        }
        
        convenience required init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            
            var values: [Int] = []
            
            while container.isAtEnd == false {
                values.append(try container.decode(Int.self))
            }
            
            self.init(values: values)
        }
    }
    
    class NestedKeyed: Codable {
        struct Nested: Codable {
            var value = 1
        }
        var value: Nested = Nested()
    }
    
    class NestedUnkeyed: Codable {
        
        struct Nested: Codable {
            
            var values: [Int] = []
            
            init() {
                self.values = [1, 2, 3]
            }
            
            init(values: [Int]) {
                self.values = values
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                
                for value in values {
                    try container.encode(value)
                }
            }
            
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                
                var values: [Int] = []
                
                while container.isAtEnd == false {
                    values.append(try container.decode(Int.self))
                }
                
                self.init(values: values)
            }
        }
        
        var nested = Nested()
    }
    
    class SubKeyed: Keyed {
        
        private enum CodingKeys: CodingKey {
            case value2
        }
        
        override var value: Int {
            get {
                return super.value + 1
            }
            set {
                super.value = newValue
            }
        }
        
        var value2: Int
        
        override init() {
            self.value2 = 2
            super.init()
        }
        
        override func encode(to encoder: Encoder) throws {
            
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(value2, forKey: .value2)
            
            try super.encode(to: encoder)
        }
        
        required init(from decoder: Decoder) throws {
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            value2 = try container.decode(Int.self, forKey: .value2)
            
            try super.init(from: decoder)
        }
    }
    
    class SubUnkeyed: Unkeyed {
        
        override var values: [Int] {
            get {
                return super.values + [privateValue]
            }
            set {
                super.values = newValue
            }
        }
        
        override init() {
            super.init()
        }
        
        override func encode(to encoder: Encoder) throws {
            
            var container = encoder.unkeyedContainer()
            
            for value in values {
                try container.encode(value)
            }
            
            assert(values.last == privateValue)
        }
        
        required init(from decoder: Decoder) throws {
            
            var container = try decoder.unkeyedContainer()
            
            var values: [Int] = []
            
            while container.isAtEnd == false {
                values.append(try container.decode(Int.self))
            }
            
            assert(values.last == privateValue)
            
            values.removeLast()
            
            super.init(values: values)
        }
    }
    
    // MARK: Objects.Throwing
    
    struct Throwing {
        
        class Single: Codable {
            
            struct Single {
                var value: Float
            }
            
            var value: Single
            
            init() {
                value = Single(value: Float.infinity)
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                
                try container.encode(value.value)
            }
            
            required init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                
                value = Single(value: try container.decode(Float.self))
            }
        }
        
        class Keyed: Codable {
            var value = Float.infinity
        }
        
        class Unkeyed: Codable {
            
            var values: [Float]
            
            init() {
                self.values = [Float.infinity]
            }
            
            init(values: [Float]) {
                self.values = values
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                
                for value in values {
                    try container.encode(value)
                }
            }
            
            convenience required init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                
                var values: [Float] = []
                
                while container.isAtEnd == false {
                    values.append(try container.decode(Float.self))
                }
                
                self.init(values: values)
            }
        }
        
        class NestedKeyed: Codable {
            struct Nested: Codable {
                var value = Float.infinity
            }
            var value: Nested = Nested()
        }
        
        class NestedUnkeyed: Codable {
            
            struct Nested: Codable {
                
                var values: [Float]
                
                init() {
                    self.values = [1.1, 1.2, Float.infinity]
                }
                
                init(values: [Float]) {
                    self.values = values
                }
                
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    
                    for value in values {
                        try container.encode(value)
                    }
                }
                
                init(from decoder: Decoder) throws {
                    var container = try decoder.unkeyedContainer()
                    
                    var values: [Float] = []
                    
                    while container.isAtEnd == false {
                        values.append(try container.decode(Float.self))
                    }
                    
                    self.init(values: values)
                }
            }
            
            var nested = Nested()
        }
        
        class SubKeyed: Keyed {
            
            private enum CodingKeys: CodingKey {
                case value2
            }
            
            override var value: Float {
                get {
                    return super.value + 1
                }
                set {
                    super.value = newValue
                }
            }
            
            var value2: Int
            
            override init() {
                self.value2 = 2
                super.init()
            }
            
            override func encode(to encoder: Encoder) throws {
                
                var container = encoder.container(keyedBy: CodingKeys.self)
                
                try container.encode(value2, forKey: .value2)
                
                try super.encode(to: encoder)
            }
            
            required init(from decoder: Decoder) throws {
                
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                value2 = try container.decode(Int.self, forKey: .value2)
                
                try super.init(from: decoder)
            }
        }
        
        class SubUnkeyed: Unkeyed {
            
            override var values: [Float] {
                get {
                    return super.values + [Float(privateValue)]
                }
                set {
                    super.values = newValue
                }
            }
            
            override init() {
                super.init()
            }
            
            override func encode(to encoder: Encoder) throws {
                
                var container = encoder.unkeyedContainer()
                
                for value in values {
                    try container.encode(value)
                }
                
                assert(values.last == Float(privateValue))
            }
            
            required init(from decoder: Decoder) throws {
                
                var container = try decoder.unkeyedContainer()
                
                var values: [Float] = []
                
                while container.isAtEnd == false {
                    values.append(try container.decode(Float.self))
                }
                
                assert(values.last == Float(privateValue))
                
                values.removeLast()
                
                super.init(values: values)
            }
        }
    }
}

private var privateValue = 92134638746

// MARK: TestEncoder

struct TestEncoder: TopLevelEncoder {
    
    func encode(_ value: Encodable) throws -> Data {
        
        let value = try self.encode(value: value)
        
        do {
            
            try TestSerializer.assertValidObject(value)
            
        } catch TestSerializer.NotValid.notValid(let _value) {
            
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid top-level object. Invalid value: \(type(of: _value)) :: \(_value)"
                )
            )
        }
        
        do {
            
            return try TestSerializer.serialize(value)
            
        } catch {
            
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to encode value to data",
                    underlyingError: error
                )
            )
        }
    }
    
    func encode(value: Encodable) throws -> Any {
        return try Base.start(with: value, options: (), userInfo: [:])
    }
    
    fileprivate class Base: TypedEncoderBase {
        
        static var unkeyedContainerType: EncoderUnkeyedContainer.Type = UnkeyedContainer.self
        
        var codingPath: [CodingKey]
        var options: ()
        var userInfo: [CodingUserInfoKey : Any]
        var reference: EncoderReference?
        
        var storage: [Any] = []
        var canEncodeNewValue: Bool = true
        
        required init(codingPath: [CodingKey], options: (), userInfo: [CodingUserInfoKey : Any], reference: EncoderReference?) {
            self.codingPath = codingPath
            self.options = options
            self.userInfo = userInfo
            self.reference = reference
        }
        
        func box(_ value: Float, at codingPath: [CodingKey]) throws -> Any {
            
            if value == Float.infinity {
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "Unable to encode Float.infinity directly in JSON. Use JSONEncoder.NonConformingFloatEncodingStrategy.convertToString to specify how the value should be encoded."))
            } else {
                return value
            }
        }
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            return self.createKeyedContainer(KeyedContainer<Key>.self)
        }
        
        deinit {
            self.willDeinit()
        }
    }
    
    fileprivate struct KeyedContainer<K: CodingKey>: EncoderKeyedContainer {
        typealias Key = K
        
        var encoder: EncoderBase
        var container: EncoderKeyedContainerContainer
        var nestedPath: [CodingKey]
        
        init(encoder: EncoderBase, container: EncoderKeyedContainerContainer, nestedPath: [CodingKey]) {
            self.encoder = encoder
            self.container = container
            self.nestedPath = nestedPath
        }
        
        static func initSelf<Key>(encoder: EncoderBase, container: EncoderKeyedContainerContainer, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            return KeyedEncodingContainer(KeyedContainer<Key>(encoder: encoder, container: container, nestedPath: nestedPath))
        }
        
        var usesStringValue: Bool = true
    }
    
    fileprivate struct UnkeyedContainer: EncoderUnkeyedContainer {
        
        var encoder: EncoderBase
        var container: EncoderUnkeyedContainerContainer
        var nestedPath: [CodingKey]
        
        init(encoder: EncoderBase, container: EncoderUnkeyedContainerContainer, nestedPath: [CodingKey]) {
            self.encoder = encoder
            self.container = container
            self.nestedPath = nestedPath
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return self.createKeyedContainer(KeyedContainer<NestedKey>.self)
        }
    }
}

// MARK: TestDecoder

struct TestDecoder: TopLevelDecoder {
    
    func decode<T>(_: T.Type, from data: Data) throws -> T where T : Decodable {
        
        let value: Any
        
        do {
            value = try TestSerializer.deserialize(data)
        } catch {
            
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Failed to decode value from data",
                    underlyingError: error
                )
            )
        }
            
        return try self.decode(T.self, fromValue: value)
    }
    
    func decode<T>(_: T.Type, fromValue value: Any) throws -> T where T : Decodable {
        
        return try Base.start(with: value, options: (), userInfo: [:])
    }
    
    
    class Base: TypedDecoderBase {
        
        typealias Options = ()
        var unkeyedContainerType: DecoderUnkeyedContainer.Type = UnkeyedContainer.self
        
        var codingPath: [CodingKey]
        var options: ()
        var userInfo: [CodingUserInfoKey : Any]
        
        required init(codingPath: [CodingKey], options: (), userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.options = options
            self.userInfo = userInfo
        }
        
        var storage: [Any] = []
        
        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            return try self.createKeyedContainer(KeyedContainer<Key>.self)
        }
        
        func unbox(_ value: Any, at codingPath: [CodingKey]) throws -> Float {
            
            if let value = value as? Float {
                if value == Float.infinity {
                    throw self.failedToUnbox(value, to: Float.self, at: codingPath)
                } else {
                    return value
                }
            } else {
                throw self.failedToUnbox(value, to: Float.self, at: codingPath)
            }
        }
    }
    
    struct KeyedContainer<K: CodingKey>: DecoderKeyedContainer {
        
        typealias Key = K
        
        var decoder: DecoderBase
        var container: DecoderKeyedContainerContainer
        var nestedPath: [CodingKey]
        
        init(decoder: DecoderBase, container: DecoderKeyedContainerContainer, nestedPath: [CodingKey]) {
            self.decoder = decoder
            self.container = container
            self.nestedPath = nestedPath
        }
        
        var usesStringValue: Bool = true
        
        static func initSelf<Key>(decoder: DecoderBase, container: DecoderKeyedContainerContainer, nestedPath: [CodingKey], keyedBy: Key.Type) -> KeyedDecodingContainer<Key> where Key : CodingKey {
            return KeyedDecodingContainer(KeyedContainer<Key>.init(decoder: decoder, container: container, nestedPath: nestedPath))
        }
    }
    
    struct UnkeyedContainer: DecoderUnkeyedContainer {
        
        var decoder: DecoderBase
        var container: DecoderUnkeyedContainerContainer
        var nestedPath: [CodingKey]
        
        init(decoder: DecoderBase, container: DecoderUnkeyedContainerContainer, nestedPath: [CodingKey]) {
            self.decoder = decoder
            self.container = container
            self.nestedPath = nestedPath
        }
        
        var currentIndex: Int = 0
        
        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try self.createKeyedContainer(KeyedContainer<NestedKey>.self)
        }
    }
}

// MARK: TestSerializer

struct TestSerializer {
    
    enum NotValid: Error {
        case notValid(Any)
    }
    
    static func serialize(_ value: Any) throws -> Data {
        try self.assertValidObject(value)
        return try JSONSerialization.data(withJSONObject: value)
    }
    
    static func deserialize(_ data: Data) throws -> Any {
        return try JSONSerialization.jsonObject(with: data)
    }
    
    static func assertValidObject(_ value: Any) throws {
        
        switch value {
            
        case is NSDictionary:
            
            for (_, value) in value as! NSDictionary {
                try assertValidObject(value)
            }
            
            
        case is NSArray:
            
            for value in value as! NSArray {
                try assertValidObject(value)
            }
            
        case is Bool: return
        case is Int: return
        case is Int8: return
        case is Int16: return
        case is Int32: return
        case is Int64: return
        case is UInt: return
        case is UInt8: return
        case is UInt16: return
        case is UInt32: return
        case is UInt64: return
        case is Float: return
        case is Double: return
        case is String: return
            
        default:
            if isNil(value) {
                return
                
            } else {
                
                throw NotValid.notValid(value)
            }
        }
    }
}

// MARK: same(_:_:)

func same(_ value1: Any, _ value2: Any) -> Bool {
    
    if let value1 = value1 as? NSDictionary {
        guard let value2 = value2 as? NSDictionary else {
            return false
        }
        
        for (key, value1) in value1 {
            guard let value2 = value2[key] else {
                return false
            }
            
            if same(value1, value2) == false {
                return false
            }
        }
        
        return true
        
    } else if let value1 = value1 as? NSArray {
        
        guard let value2 = value2 as? NSArray else {
            return false
        }
        
        if value1.count != value2.count {
            return false
        }
        
        for (value1, value2) in zip(value1, value2) {
            
            if same(value1, value2) == false {
                return false
            }
        }
        
        return true
        
    } else if isNil(value1) {
        
        return isNil(value2)
        
    } else if let value1 = value1 as? NSNumber {
        
        guard let value2 = value2 as? NSNumber else {
            return false
        }
        
        guard type(of: value1) == type(of: value2) else {
            return false
        }
        
        return value1.isEqual(to: value2)
        
    } else if let value1 = value1 as? String {
        
        guard let value2 = value2 as? String else {
            return false
        }
        
        return value1 == value2
        
    } else {
        
        let mirror1 = Mirror(reflecting: value1).children
        let mirror2 = Mirror(reflecting: value2).children
        
        guard mirror1.count != 0 else {
            return type(of: value1) == type(of: value2)
        }
        
        guard mirror1.count == mirror2.count else {
            return false
        }
        
        for (child1, child2) in zip(mirror1, mirror2) {
            
            if child1.label != child2.label || same(child1.value, child2.value) == false {
                return false
            }
        }
        
        return type(of: value1) == type(of: value2)
    }
}

// MARK: artificial encode

protocol ArtificialUnkeyed {
    func getEncodedValue() -> Any
}

func artificialEncode(_ value: Any) -> Any {
    
    if let value = value as? NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        for (key, value) in value {
            dictionary[key] = artificialEncode(value)
        }
        
        return dictionary

    } else if let value = value as? NSArray {
        
        let result = NSMutableArray()
        
        for value in value {
            result.add(artificialEncode(value))
        }
        
        return result

    } else if isNil(value) {

        return NSNull()

    } else if value is NSNumber {
        
        if let value = value as? Float {
            if value == Float.infinity || value == Float.nan || value == -Float.infinity {
                return value.description
            }
        }

        return value

    } else if value is String {

        return value

    } else if let value = value as? ArtificialUnkeyed {

        return value.getEncodedValue()
    
    } else {
        
        let mirror = Mirror(reflecting: value).children
        
        let result = NSMutableDictionary()
        
        for (label, value) in mirror {
            guard let label = label else {
                fatalError("no label for child with value: \(type(of: value)) :: \(value)")
            }
            
            result[label] = artificialEncode(value)
        }
        
        return result
    }
}






