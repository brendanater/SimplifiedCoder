//
//  CoderTests.swift
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

class TestExpectedPaths: XCTestCase {
    
    func newEncoder() -> JSONEncoder {
        return JSONEncoder()
    }
    
    func newDecoder() -> JSONDecoder {
        return JSONDecoder()
    }
    
    let testingDepth = 3
    
    typealias Objects = CoderTesting.Objects
    
    func testJSONDecodeFunctionsNonLooping() {
        
        let data = try! self.newEncoder().encode([1]) as Data
        
        _ = try! JSONDecoder().decode(from: data) as [Int]
        _ = try! (JSONDecoder() as TopLevelDecoder).decode(from: data) as [Int]
        _ = try! JSONDecoder().decode(from: data) as [Int]
        _ = try! (JSONDecoder() as TopLevelDecoder).decode(from: data) as [Int]
    }
    
    func testEncodePaths() {
        
        self.startEncodePathTest(with: Float.infinity  )
        self.startEncodePathTest(with: Double.infinity )
        // .nan != .nan
        self.startEncodePathTest(with: Date()          )
        self.startEncodePathTest(with: Data()          )
        
        self.startEncodePathTest(with: Objects.VisualCheck())
    }
    
    func testDecodePaths() {
        
        self.startDecodePathTest(with: Float    .self, from: "test"     , errorType: .typeMismatch(Float    .self))
        self.startDecodePathTest(with: Int      .self, from: UInt64.max , errorType: .dataCorrupted               ) // number does not fit
        self.startDecodePathTest(with: UInt     .self, from: -1         , errorType: .dataCorrupted               ) // number does not fit
        self.startDecodePathTest(with: Bool     .self, from: 2          , errorType: .typeMismatch(Bool     .self))
        self.startDecodePathTest(with: Double   .self, from: "test"     , errorType: .typeMismatch(Double   .self))
        self.startDecodePathTest(with: String   .self, from: 1          , errorType: .typeMismatch(String   .self))
        self.startDecodePathTest(with: URL      .self, from: "%"        , errorType: .dataCorrupted               ) // invalid url
        self.startDecodePathTest(with: Decimal  .self, from: "test"     , errorType: .typeMismatch(Double   .self)) // try decode as Double
        // .nan != .nan
        self.startDecodePathTest(with: Date.self, from: "test", errorType: .typeMismatch(Date.self))
        self.startDecodePathTest(with: Data.self, from: 1     , errorType: .typeMismatch(Data.self))

        self.startDecodePathTest(with: Objects.VisualCheck.self         , from: "test"          , errorType: .valueNotFound(Objects.VisualCheck.self))
        self.startDecodePathTest(with: Objects.KeyNotFoundCheck.self    , from: ["test": "test"], errorType: Objects.KeyNotFoundCheck.errorType)
        self.startDecodePathTest(with: Objects.UnkeyedIsAtEndCheck.self , from: ["test"]        , errorType: .valueNotFound(Objects.UnkeyedIsAtEndCheck.self))
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
            print("will fail at:", type(of: value), expected)
        }
        
        let stats = try! CoderTesting.encodeStats(expected: expected, encodable: value)
        
        if stats.willCrashIfJSONEncoder {
            return
        }
        
        switch stats.topLevelType {
        case .keyed, .unkeyed:
            
            do {
                
                let encoder = self.newEncoder()
                
                encoder.dateEncodingStrategy = .custom { throw EncodingError.invalidValue($0, EncodingError.Context(codingPath: $1.codingPath, debugDescription: "threw at path")) }
                encoder.dataEncodingStrategy = .custom { throw EncodingError.invalidValue($0, EncodingError.Context(codingPath: $1.codingPath, debugDescription: "threw at path")) }
                
                _ = try encoder.encode(value) as Data
                
                willFail()
                XCTFail("failed to throw")
                return
                
            } catch let error as EncodingError {
                
                guard type(of: error.value) == expected else {
                    willFail()
                    XCTFail("unexpected invalidValue: \(type(of: error.value)) expected: \(expected)")
                    return
                }
                
                if let fail = CoderTesting.guardEqual(expected: error.context.codingPath, actual: stats.codingPathOfFirstExpected!) {
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
            self.encodePathTest(Objects.Single(value)       , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.Keyed(value)        , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.SubKeyed1(value)    , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.SubKeyed2(value)    , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.Unkeyed(value)      , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.SubUnkeyed1(value)  , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.SubUnkeyed2(value)  , expected: expected, currentCount: currentCount + 1)
            self.encodePathTest(Objects.MultipleStore(value), expected: expected, currentCount: currentCount + 1)
        }
    }

    func decodePathTest<T: Decodable, D: Decodable, E>(_ decodable: D.Type, from value: E, expected: T.Type, errorType: CoderTesting.DecodingErrorType, currentCount: Int) {
        
        func willFail() {
            print("will fail:", decodable, type(of: value), expected, errorType)
        }
        
        let stats = try! CoderTesting.decodeStats(expected: expected, decodable: decodable)
        
        switch stats.topLevelType {
            
        case .keyed, .unkeyed:
            
            do {
                
                guard JSONSerialization.isValidJSONObject(value) else {
                    willFail()
                    XCTFail("\(type(of: value)) is not a valid JSON object")
                    return
                }
                
                let data = try JSONSerialization.data(withJSONObject: value)
                
                let decoder = self.newDecoder()
                
                decoder.dateDecodingStrategy = .custom { throw DecodingError.typeMismatch(Date.self, DecodingError.Context(codingPath: $0.codingPath, debugDescription: "threw at path")) }
                decoder.dataDecodingStrategy = .custom { throw DecodingError.typeMismatch(Data.self, DecodingError.Context(codingPath: $0.codingPath, debugDescription: "threw at path")) }
                
                _ = try decoder.decode(decodable, from: data)
                
                willFail()
                XCTFail("failed to throw")
                
            } catch let error as DecodingError {
                
                guard errorType.isCorrect(error) else {
                    willFail()
                    XCTFail("incorrect error type. expected: \(errorType) actual: \(error)")
                    return
                }
                
                if let fail = CoderTesting.guardEqual(expected: error.context.codingPath, actual: stats.codingPathOfFirstExpected!) {
                    willFail()
                    XCTFail(fail.description)
                    return
                }
            } catch {
                willFail()
                XCTFail("\(error)")
            }
            
        default: break
        }

        if currentCount < self.testingDepth {
            
            self.decodePathTest(Objects.Single<D>.self        , from: value                     , expected: expected, errorType: errorType, currentCount: currentCount + 1)
            self.decodePathTest(Objects.Keyed<D>.self         , from: ["test": value]           , expected: expected, errorType: errorType, currentCount: currentCount + 1)
            self.decodePathTest(Objects.SubKeyed1<D>.self     , from: ["test": value]           , expected: expected, errorType: errorType, currentCount: currentCount + 1)
            self.decodePathTest(Objects.SubKeyed2<D>.self     , from: ["super": ["test": value]], expected: expected, errorType: errorType, currentCount: currentCount + 1)
            self.decodePathTest(Objects.Unkeyed<D>.self       , from: [value]                   , expected: expected, errorType: errorType, currentCount: currentCount + 1)
            self.decodePathTest(Objects.SubUnkeyed1<D>.self   , from: [value]                   , expected: expected, errorType: errorType, currentCount: currentCount + 1)
            self.decodePathTest(Objects.SubUnkeyed2<D>.self   , from: [[value]]                 , expected: expected, errorType: errorType, currentCount: currentCount + 1)
        }
    }
}
