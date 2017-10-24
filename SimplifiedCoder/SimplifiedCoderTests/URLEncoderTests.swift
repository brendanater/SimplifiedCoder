//
//  URLEncoderTests.swift
//  SimplifiedCoderTests
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
import XCTest
import SimplifiedCoder

class TestURLEncoder: XCTestCase {
    
    func newEncoder() -> URLEncoder {
        
        return URLEncoder()
    }
    
    func newDecoder() -> URLDecoder {
        
        return URLDecoder()
    }
    
    let testingDepth = 2
    
    typealias Objects = CoderTesting.Objects
    
    func testRoundTrips() {
        
        self.roundTrip(CoderTesting.intValues   , isEqual: { $0 == $1 })
        self.roundTrip(CoderTesting.int8Values  , isEqual: { $0 == $1 })
        self.roundTrip(CoderTesting.int16Values , isEqual: { $0 == $1 })
        self.roundTrip(CoderTesting.int32Values , isEqual: { $0 == $1 })
        self.roundTrip(CoderTesting.int64Values , isEqual: { $0 == $1 })
        self.roundTrip(CoderTesting.uintValues  , isEqual: { $0 == $1 })
        self.roundTrip(CoderTesting.uint8Values , isEqual: { $0 == $1 })
        self.roundTrip(CoderTesting.uint16Values, isEqual: { $0 == $1 })
        self.roundTrip(CoderTesting.uint32Values, isEqual: { $0 == $1 })
        self.roundTrip(CoderTesting.uint64Values, isEqual: { $0 == $1 })
        
        self.roundTrip(CoderTesting.floatValues.filter { $0 == $0 && Float(($0 as NSNumber).description) == $0 }, isEqual: { $0 == $1 })
        self.roundTrip(Float.nan, isEqual: { $0.isNaN && $1.isNaN })
        
        let doubleValues = CoderTesting.doubleValues.filter { $0 == $0 && Double(($0 as NSNumber).description) == $0 }
        self.roundTrip(doubleValues, isEqual: { $0 == $1 })
        self.roundTrip(Double.nan, isEqual: { $0.isNaN && $1.isNaN })
        
        // Decimal freezes on init(inf)
        self.roundTrip(doubleValues.filter { !$0.isInfinite }.map { Decimal($0) }, isEqual: { (value1: [Decimal], value2: [Decimal])->Bool in value1 == value2 })
        self.roundTrip(Decimal(Double.nan), isEqual: { $0.isNaN && $1.isNaN })
        
        
        for (string, description) in CoderTesting.stringValues(from: [.urlQueryAllowed], removeCharacters: "#&") {
            
            if self.roundTrip(string, description, isEqual: { $0 == $1 }) {
                continue
            } else {
                break
            }
        }
        
        // if there is no value, the query will be empty, so it cannot be decoded correctly.
//        self.roundTrip([] as [String], isEqual: { $0.isEmpty && $1.isEmpty })
//        self.roundTrip([:] as [String: String], isEqual: { $0.isEmpty && $1.isEmpty })
        
        self.roundTrip([true, false], isEqual: { $0 == $1 })
        
        self.roundTrip([1: true, 2: false], isEqual: { $0 == $1 })
        
        self.roundTrip(Date(), isEqual: { $0 == $1 })
        self.roundTrip(Data(bytes: CoderTesting.uint8Values), isEqual: { $0 == $1 })
        self.roundTrip(URL(string: "test.com/random.orgdasdioahgsfas@dalk"), isEqual: { $0 == $1 })
        self.roundTrip(URL(string: "test.com")!, isEqual: { $0 == $1 })
        self.roundTrip(Decimal(), isEqual: { $0 == $1 })
        
        self.roundTrip(String?.none, isEqual: { $0 == $1 })
    }
    
    func testEncodePaths() {
        
        self.startEncodePathTest(with: Float.infinity  )
        self.startEncodePathTest(with: Double.infinity )
        self.startEncodePathTest(with: Float.nan  )
        self.startEncodePathTest(with: Double.nan )
        self.startEncodePathTest(with: Float.signalingNaN  )
        self.startEncodePathTest(with: Double.signalingNaN )
        self.startEncodePathTest(with: Date()          )
        self.startEncodePathTest(with: Data()          )
        self.startEncodePathTest(with: "%%@(*#$&"          )
        
        self.startEncodePathTest(with: Objects.VisualCheck())
    }
    
    func testDecodePaths() {
        
        self.startDecodePathTest(with: Float    .self, from: "test"     , errorType: .typeMismatch(Float    .self))
        self.startDecodePathTest(with: Int      .self, from: UInt64.max , errorType: .dataCorrupted               )
        self.startDecodePathTest(with: UInt     .self, from: -1         , errorType: .dataCorrupted               )
        self.startDecodePathTest(with: Bool     .self, from: 2          , errorType: .typeMismatch(Bool     .self)) // value never throws
        self.startDecodePathTest(with: Double   .self, from: "test"     , errorType: .typeMismatch(Double   .self))
        self.startDecodePathTest(with: String   .self, from: ""         , errorType: .valueNotFound(String  .self)) // empty should be nil
//        self.startDecodePathTest(with: URL      .self, from: "%"        , errorType: .dataCorrupted               ) // has to be decodable from a URL
        self.startDecodePathTest(with: Decimal  .self, from: "test"     , errorType: .typeMismatch(Decimal  .self))
        // .nan != .nan
        self.startDecodePathTest(with: Date.self, from: "test", errorType: .typeMismatch(Date.self))
        self.startDecodePathTest(with: Data.self, from: "test", errorType: .typeMismatch(Data.self))
        
        self.startDecodePathTest(with: Objects.VisualCheck.self         , from: "test"          , errorType: .valueNotFound(Objects.VisualCheck.self))
        self.startDecodePathTest(with: Objects.KeyNotFoundCheck.self    , from: ["test": true]  , errorType: Objects.KeyNotFoundCheck.errorType)
        self.startDecodePathTest(with: Objects.UnkeyedIsAtEndCheck.self , from: [true]          , errorType: .valueNotFound(Objects.UnkeyedIsAtEndCheck.self))
    }
    
    @discardableResult
    func roundTrip<T: Codable>(_ start: T, _ valueDescription: String = "\(T.self)", currentCount: Int = 0, isEqual: @escaping (T, T)->Bool) -> Bool {
        
        func willFail() {
            print("roundTrip will fail:", valueDescription)
        }
        
        var stats: CoderTesting.EncodeStats

        do {
            stats = try CoderTesting.encodeStats(expected: Objects.VisualCheck.self, encodable: start)
        } catch {
            willFail()
            XCTFail("failed to get stats. \(error)")
            return false
        }
        
        switch start {
        case is URL, is Decimal: stats.topLevelType = .single
        default:
            if T.self is Optional<URL>.Type {
                stats.topLevelType = .single
            }
        }
        
        switch stats.topLevelType {
            
        case .single, .unkeyed:
            
            return self.roundTrip(Objects.Keyed(start), valueDescription, currentCount: currentCount + 1, isEqual: { isEqual($0.value, $1.value) })
            
        default:
            
            var arraysAreDictionaries: Bool = false
            
            let value: Any
            
            // value to Any
            do {
                
                var encoder = self.newEncoder()
                
                encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
                
                value = try encoder.encode(value: start)
                
            } catch {
                
                if let error = (error as? EncodingError)?.context.underlyingError as? URLQuerySerializer.ToQueryError, case .nestedContainerInArray = error {
                    
                    arraysAreDictionaries = true
                    
                    do {
                        var encoder = self.newEncoder()
                        
                        encoder.serializer.arraySerialization = .arraysAreDictionaries
                        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
                        
                        value = try encoder.encode(value: start)
                        
                    } catch {
                        
                        willFail()
                        XCTFail("\(error)")
                        return false
                    }
                    
                } else {
                        
                    willFail()
                    XCTFail("\(error)")
                    return false
                }
            }
            
            // value to Data
            
            let data: Data
            
            do {
                
                var encoder = self.newEncoder()
                
                if arraysAreDictionaries {
                    encoder.serializer.arraySerialization = .arraysAreDictionaries
                }
                encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
                
                data = try encoder.encode(start)
                
                let query1 = String(data: data, encoding: URLQuerySerializer().dataStringEncoding)!
                let query2: String
                do {
                    query2 = try encoder.serializer.query(from: value)
                } catch {
                    willFail()
                    XCTFail("\(type(of: value)): \(value) failed to be serialized")
                    return false
                }
                
                guard query1 == query2 else {
                    willFail()
                    XCTFail("unequal queries:\nquery1: \(query1)\nquery2: \(query2)")
                    return false
                }
                
            } catch {
                    
                willFail()
                XCTFail("\(error)")
                return false
            }
            
            // value from Data
            
            do {
                
                var decoder = self.newDecoder()
                
                if arraysAreDictionaries {
                    decoder.serializer.arraySerialization = .arraysAreDictionaries
                }
                decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
                
                let result = try decoder.decode(T.self, from: data)
                
                guard isEqual(start, result) else {
                    
                    willFail()
                    XCTFail("unequal decoded value: \nstart:  \(start)\nresult: \(result)")
                    return false
                }
                
            } catch {
                
                willFail()
                XCTFail("\(error)")
                return false
            }
            
            // value from Any
            
            do {
                
                var decoder = self.newDecoder()
                
                if arraysAreDictionaries {
                    decoder.serializer.arraySerialization = .arraysAreDictionaries
                }
                decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
                
                let result = try decoder.decode(T.self, fromValue: value)
                
                guard isEqual(start, result) else {
                    
                    willFail()
                    XCTFail("decoded value: \(result) != \(start)")
                    return false
                }
                
            } catch {
                
                willFail()
                XCTFail("\(error)")
                return false
            }
            
            if currentCount < self.testingDepth {
                
                self.roundTrip(Objects.Single(start)                     , valueDescription, currentCount: currentCount + 1, isEqual: { return isEqual($0.value, $1.value) })
                self.roundTrip(Objects.Keyed(start)       , valueDescription, currentCount: currentCount + 1, isEqual: { isEqual($0.value, $1.value) })
                self.roundTrip(Objects.SubKeyed1(start)   , valueDescription, currentCount: currentCount + 1, isEqual: { isEqual($0.value, $1.value) })
                self.roundTrip(Objects.SubKeyed2(start)   , valueDescription, currentCount: currentCount + 1, isEqual: { isEqual($0.value, $1.value) })
                self.roundTrip(Objects.KeyedNestedUnkeyed(start)       , valueDescription, currentCount: currentCount + 1, isEqual: { isEqual($0.value, $1.value) })
                self.roundTrip(Objects.KeyedNestedKeyed(start)         , valueDescription, currentCount: currentCount + 1, isEqual: { isEqual($0.value, $1.value) })
                self.roundTrip(Objects.Unkeyed(start)                    , valueDescription, currentCount: currentCount + 1, isEqual: {
                    if let rhs = $1.elements.first { return isEqual($0.elements.first!, rhs) } else { return false } })
                self.roundTrip(Objects.SubUnkeyed1(start)                , valueDescription, currentCount: currentCount + 1, isEqual: {
                    if let rhs = $1.elements.first { return isEqual($0.elements.first!, rhs) } else { return false } })
                self.roundTrip(Objects.SubUnkeyed2(start)                , valueDescription, currentCount: currentCount + 1, isEqual: {
                    if let rhs = $1.elements.first { return isEqual($0.elements.first!, rhs) } else { return false } })
                self.roundTrip(Objects.UnkeyedNestedUnkeyed(start)       , valueDescription, currentCount: currentCount + 1, isEqual: { isEqual($0.value, $1.value) })
                self.roundTrip(Objects.UnkeyedNestedKeyed(start)         , valueDescription, currentCount: currentCount + 1, isEqual: { isEqual($0.value, $1.value) })
                
                self.roundTrip(T?.some(start), currentCount: currentCount + 1, isEqual: { if let value = $1 { return isEqual($0!, value) } else { return false } })
                self.roundTrip(T?.none, currentCount: currentCount + 1, isEqual: { $0.isNil && $1.isNil })
            }
            
            return true
        }
    }
    
    func startEncodePathTest<T: Encodable>(with value: T) {
        
        self.encodePathTest(value, expected: type(of: value), currentCount: 0)
    }
    
    func startDecodePathTest<T: Decodable, E>(with decodable: T.Type, from value: E, errorType: CoderTesting.DecodingErrorType) {
        
        self.decodePathTest(decodable, from: value, expected: decodable, errorType: errorType, currentCount: 0)
    }
    
    func encodePathTest<T: Encodable, E: Encodable>(_ value: E, expected: T.Type, currentCount: Int) {
        
        /// print where the fail is.
        func willFail() {
            print("encodePathTest will fail:", type(of: value), expected)
        }
        
        let stats = try! CoderTesting.encodeStats(expected: expected, encodable: value)
        
        if stats.willCrashIfJSONEncoder {
            return
        }
        
        switch stats.topLevelType {
        case .keyed, .unkeyed:
            
            do {
                
                var encoder = self.newEncoder()
                
                encoder.dateEncodingStrategy = .custom { throw EncodingError.invalidValue($0, EncodingError.Context(codingPath: $1.codingPath, debugDescription: "threw at path")) }
                encoder.dataEncodingStrategy = .custom { throw EncodingError.invalidValue($0, EncodingError.Context(codingPath: $1.codingPath, debugDescription: "threw at path")) }
                
                _ = try encoder.encode(value)
                
                willFail()
                XCTFail("failed to throw")
                return
                
            } catch let error as EncodingError {
                
                guard type(of: error.value) == expected else {
                    willFail()
                    XCTFail("unexpected invalidValue: \(type(of: error.value)) expected: \(expected), error: \(error)")
                    return
                }
                
                if let fail = CoderTesting.guardEqual(expected: stats.codingPathOfFirstExpected!, actual: error.context.codingPath) {
                    willFail()
                    XCTFail(fail.description)
                    return
                }
                
            } catch {
                willFail()
                XCTFail("\(error)")
                return
            }
            
        case .single: break
        }
        
        if currentCount < self.testingDepth {
            self.encodePathTest(Objects.Single(value)                   , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.Keyed(value)                    , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.SubKeyed1(value)                , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.SubKeyed2(value)                , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.Unkeyed(value)                  , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.SubUnkeyed1(value)              , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.SubUnkeyed2(value)              , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.MultipleStore(value)            , expected: expected, currentCount: currentCount + 1)
        }
    }
    
    func decodePathTest<T: Decodable, D: Decodable, E>(_ decodable: D.Type, from value: E, expected: T.Type, errorType: CoderTesting.DecodingErrorType, currentCount: Int) {
        
        func willFail() {
            print("decodePathTest will fail:", decodable, type(of: value), expected, errorType)
        }
        
        let stats = try! CoderTesting.decodeStats(expected: expected, decodable: decodable)
        
        switch stats.topLevelType {
            
        case .keyed:
            
            do {
                
                var serializer = URLQuerySerializer()
                serializer.arraySerialization = .arraysAreDictionaries
                
                do {
                    try serializer.assertValidObject(value)
                } catch {
                    willFail()
                    XCTFail("\(type(of: value)): \(value) is not a valid URLQuery object. error: \(error)")
                    return
                }
                
                let data = try! serializer.queryData(from: value)
                
                var decoder = self.newDecoder()
                
                decoder.dateDecodingStrategy = .custom { throw DecodingError.typeMismatch(Date.self, DecodingError.Context(codingPath: $0.codingPath, debugDescription: "threw at path")) }
                decoder.dataDecodingStrategy = .custom { throw DecodingError.typeMismatch(Data.self, DecodingError.Context(codingPath: $0.codingPath, debugDescription: "threw at path")) }
                decoder.serializer.arraySerialization = .arraysAreDictionaries
                
                _ = try decoder.decode(decodable, from: data)
                
                willFail()
                XCTFail("failed to throw")
                return
                
            } catch let error as DecodingError {
                
                guard errorType.isCorrect(error) else {
                    willFail()
                    XCTFail("incorrect error type. expected: \(errorType) actual: \(error)")
                    return
                }
                
                if let fail = CoderTesting.guardEqual(expected: stats.codingPathOfFirstExpected!, actual: error.context.codingPath) {
                    willFail()
                    XCTFail(fail.description)
                    return
                }
            } catch {
                willFail()
                XCTFail("\(error)")
                return
            }
            
        default: break
        }
        
        if currentCount < self.testingDepth {
            
            self.decodePathTest(Objects.Single<D>.self        , from: value                   , expected: expected, errorType: errorType, currentCount: currentCount + 1)
            self.decodePathTest(Objects.Keyed<D>.self         , from: ["test": value]            , expected: expected, errorType: errorType, currentCount: currentCount + 1)
            self.decodePathTest(Objects.SubKeyed1<D>.self     , from: ["test": value]            , expected: expected, errorType: errorType, currentCount: currentCount + 1)
            self.decodePathTest(Objects.SubKeyed2<D>.self     , from: ["super": ["test": value]] , expected: expected, errorType: errorType, currentCount: currentCount + 1)
            self.decodePathTest(Objects.Unkeyed<D>.self       , from: [value]                 , expected: expected, errorType: errorType, currentCount: currentCount + 1)
            self.decodePathTest(Objects.SubUnkeyed1<D>.self   , from: [value]                 , expected: expected, errorType: errorType, currentCount: currentCount + 1)
            self.decodePathTest(Objects.SubUnkeyed2<D>.self   , from: [[value]]               , expected: expected, errorType: errorType, currentCount: currentCount + 1)
        }
    }
    
    
    
    var encoder = URLEncoder()
    
    var encoding: String.Encoding {
        return encoder.serializer.dataStringEncoding
    }

    func encode<T: Encodable>(_ value: T) throws -> Data {
        return try self.encoder.encode(value)
    }

    func testArray() {

        let value = ["key": [1]]

        let expectedResult = "key[]=1"

        do {

            let string = try String(data: self.encoder.encode(value), encoding: encoder.serializer.dataStringEncoding)

            XCTAssert(string != nil)

            XCTAssert(string ?? "" == expectedResult, "Incorrect string: \(string ?? "")")

        } catch {
            XCTFail("\(type(of: error)).\(error)")
        }
    }

    func testNestedArray() {

        let value = [[[[1]]]]

        do {

            _ = try self.encode(value)

            XCTFail()

        } catch EncodingError.invalidValue(let value, let context) {

            XCTAssert(value is NSArray)

            XCTAssert(context.codingPath.count == 0, context.debugDescription + ". CodingPath: \(context.codingPath)")

        } catch {
            XCTFail("\(error)")
        }
    }

    func testDictionary() {

        let value = ["key": ["key2":1]]

        let expectedResult = "key[key2]=1"

        do {

            let string = try String(data: self.encode(value), encoding: encoder.serializer.dataStringEncoding)

            XCTAssert(string != nil)

            XCTAssert(string! == expectedResult, "Incorrect result: \(string!)")

        } catch {
            XCTFail("\(error)")
        }
    }

    func testNestedDictionary() {

        let value = ["key": ["key1":["key2": ["key3": 3], "key4": ["key5": 4]]]]

        let expectedResult = "key[key1][key2][key3]=3&key[key1][key4][key5]=4"

        do {

            let string = try String(data: self.encode(value), encoding: encoder.serializer.dataStringEncoding)

            XCTAssert(string != nil)

            XCTAssert(string! == expectedResult, "Incorrect result: \(string!)")

        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testMixedDictionaryAndArray() {

        let value = ["key1":["key2": ["key3": [["key4": ["key5": [[[["key6": [1]]]]]]]]]]]

        do {

            let value2 = try String(data: self.encode(value), encoding: encoder.serializer.dataStringEncoding)

            XCTFail("encoder did not throw: \(value2 ?? "<void>__")")

        } catch EncodingError.invalidValue(let value, let context) {

            XCTAssert(value is NSDictionary)

            XCTAssert(context.underlyingError is URLQuerySerializer.ToQueryError?)

            XCTAssert(context.codingPath.count == 0)

            if let error = context.underlyingError {
                do {
                    throw error
                } catch URLQuerySerializer.ToQueryError.nestedContainerInArray {

                } catch {
                    XCTFail("\(error)")
                }
            }

        } catch {
            XCTFail("Worng error: \(error)")
        }
    }

    class Object1: Codable {
        var value = 1
        var array = [1]
        var dictionary = ["key": 2]
        var nestedDictionary = ["key": [1]]
    }

    class WithNestedClass: Codable {
        class Nested: Codable {
            class NestedNested: Codable {
                var value = 1
            }

            var value = 1
            var nested = NestedNested()
        }

        var value = 1
        var value2 = "test"
        var nested = Nested()
    }

    func testObject() {

        let value = Object1()

        let expectedResult = "value=1&array[]=1&dictionary[key]=2&nestedDictionary[key][]=1"

        do {

            let string = try String(data: self.encode(value), encoding: encoder.serializer.dataStringEncoding)

            XCTAssert(string == expectedResult, "Incorrect result: \(string!)")

        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }

    func testNestedObject() {

        let value = WithNestedClass()

        let expectedResult = "value=1&value2=test&nested[value]=1&nested[nested][value]=1"

        do {

            let string = try String(data: self.encode(value), encoding: encoding)

            XCTAssert(string != nil)

            XCTAssert(string! == expectedResult, "Incorrect result: \(string!)")

        } catch {
            XCTFail("Error was thrown: \(error)")
        }
    }
}















