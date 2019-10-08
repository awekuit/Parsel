//
//  ParserTests.swift
//  ParselTests
//
//  Created by Benjamin Herzog on 13.08.17.
//

import XCTest
@testable import Parsel

class Parser_TestCase: XCTestCase {
    
    // MARK: - Tests
    
    func test_just() throws {
        let p = Parser<String, Int>.just(3)
        
        let res1 = try p.parse("123")
        XCTAssertTrue(res1 == .success(result: 3, rest: "123"))
        
        // state should not change
        let res2 = try p.parse("123")
        XCTAssertTrue(res2 == .success(result: 3, rest: "123"))
    }
    
    func test_init_producesSuccess() throws {
        let p = Parser<String, Int>.just(1)
        
        let res = try p.parse("123")
        XCTAssertTrue(res == .success(result: 1, rest: "123"))
    }
    
    func test_init_producesFail() throws {
        let p = Parser<String, Int> { str in
            return .fail(TestError(1))
        }
        
        let res = try p.parse("123")
        XCTAssertTrue(res == .fail(TestError(1)))
    }
    
    func test_init() throws {
        let lit = Parser<String, Character> { str in
            guard let first = str.first else {
                return .fail(TestError(1))
            }
            return .success(result: first, rest: String(str.dropFirst()))
        }
        
        let res1 = try lit.parse("123")
        XCTAssertTrue(res1 == .success(result: "1", rest: "23"))
        
        let res2 = try lit.parse("")
        XCTAssertTrue(res2 == .fail(TestError(1)))
    }
    
    func test_flatMap_success() throws {
        let doubleA = char("a").flatMap(char)
        let res1 = try doubleA.parse("aab")
        XCTAssertTrue(res1 == .success(result: "a", rest: "b"))
        
        let doubleAPlusB = doubleA.flatMap { _ in char("b") }
        let res2 = try doubleAPlusB.parse("aab")
        XCTAssertTrue(res2 == .success(result: "b", rest: ""))
    }
    
    func test_flatMap_fail() throws {
        let doubleA = char("a").flatMap(char)
        
        let res1 = try doubleA.parse("")
        XCTAssertTrue(res1 == .fail(TestError(1)))
        
        let res2 = try doubleA.parse("ab")
        XCTAssertTrue(res2 == .fail(TestError(1)))
    }
    
    func test_map() throws {
        let p = string("abc")
        let pMapped = p.map { $0.count }
        
        let res1 = try pMapped.parse("abcde")
        XCTAssertTrue(res1 == .success(result: 3, rest: "de"))
        
        let res2 = try pMapped.parse("edcba")
        XCTAssertTrue(res2 == .fail(TestError(1)))
    }
    
    func test_filter() throws {
        struct TempError: ParseError {
            let code: UInt64 = 1
        }
        
        let p = char("a").rep.filter { res in
            if res.count < 3 {
                return TempError()
            }
            return nil
        }
        
        let res1 = try p.parse("aaa")
        XCTAssertEqual(try res1.unwrap(), ["a", "a", "a"])
        
        let res2 = try p.parse("aa")
        XCTAssertTrue(res2.isFailed())
    }
    
    func test_fail_error() throws {
        let p = Parser<String, Int>.fail(error: TestError(1))
        let res = try p.parse("123")
        XCTAssertEqual(try res.error() as! TestError, TestError(1))
    }
    
    func test_fail_message() throws {
        let p = Parser<String, Int>.fail(message: "a message")
        let res = try p.parse("123")
        XCTAssertEqual(try res.error() as! GenericParseError, GenericParseError(message: "a message"))
    }

    func test_subscript() throws {
        let p = L.char
        let res = p["abc"]
        XCTAssertEqual(try res.unwrap(), "a")
    }

}

#if os(Linux)
    extension Parser_TestCase {
        static var allTests = [
            ("test_just", test_just),
            ("test_init_producesSuccess", test_init_producesSuccess),
            ("test_init_producesFail", test_init_producesFail),
            ("test_init", test_init),
            ("test_flatMap_success", test_flatMap_success),
            ("test_flatMap_fail", test_flatMap_fail),
            ("test_map", test_map),
            ("test_filter", test_filter),
            ("test_fail_error", test_fail_error),
            ("test_fail_message", test_fail_message),
            ("test_subscript", test_subscript),
        ]
    }
#endif
