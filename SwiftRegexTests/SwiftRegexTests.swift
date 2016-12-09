//
//  SwiftRegexTests.swift
//  SwiftRegexTests
//
//  Created by John Holdsworth on 26/06/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

import XCTest
import SwiftRegex

class SwiftRegexTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        let input = "The quick brown fox jumps over the lazy dog."

        XCTAssertEqual(input["quick .* fox"][0], "quick brown fox", "basic match")

        if let _ = input["quick orange fox"][0] {
            XCTAssert(false, "non-match fail")
        }
        else {
            XCTAssert(true, "non-match pass")
        }

        let match:[String] = input["the .* dog"].matches()
        XCTAssertEqual(match, ["the lazy dog"], "convert pass")

        XCTAssertEqual(input["quick brown (\\w+)"][1], "fox", "group subscript")

        XCTAssertEqual(input["(the lazy) (cat)?"][2], nil, "optional group pass")

//        let groups = input["the (.*?) (fox|dog)", .caseInsensitive].allGroups()
//        XCTAssertEqual(groups.map( { $0.map { $0! } } ), [["The quick brown fox", "quick brown", "fox"],
//                             ["the lazy dog", "lazy", "dog"]], "groups match")

        let minput = NSMutableString(string:input)

        minput["(the) (\\w+)"] ~= "$1 very $2"
        XCTAssertEqual(minput, "The quick brown fox jumps over the very lazy dog.", "replace pass")

        minput["(fox|dog)"] ~= ["$0", "brown $1"]
        XCTAssertEqual(minput, "The quick brown fox jumps over the very lazy brown dog.", "replace array pass")

        minput["(\\w)(\\w+)"] ~= {
            (groups: [String?]) in
            return groups[1]!.uppercased()+groups[2]!
        }

        XCTAssertEqual(minput, "The Quick Brown Fox Jumps Over The Very Lazy Brown Dog.", "block pass")

        minput["Quick (\\w+)"][1] = "Red $1"

        XCTAssertEqual(minput, "The Quick Red Brown Fox Jumps Over The Very Lazy Brown Dog.", "group replace pass")

        minput["The"][0] = ["$0", "$0 Very"]

        XCTAssertEqual(minput, "The Quick Red Brown Fox Jumps Over The Very Very Lazy Brown Dog.", "group replace pass")

        var str = minput as String
        str += minput as String

        let y = "👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦  👩‍👩‍👦👩‍👩‍👦👩‍👩‍👦 🇭🇺🇭🇺🇭🇺"
//        XCTAssertEqual(y[0], "👨‍👩‍👧‍👦", "subscript 0") // bug in Swift.String
//        XCTAssertEqual(y[-1], "🇭🇺", "subscript -1") // bug in Swift.String

        let z = y.mutable
        z["👨‍👩‍👧‍👦"] ~= ["$0", "👩‍👩‍👦"]
        z["👩‍👩‍👦"][0] = ["$0", "$0", "👨‍👩‍👧‍👦"]
        z["🇭🇺"] ~= ["$0", "🇫🇷"]

        XCTAssertEqual(z, "👨‍👩‍👧‍👦👩‍👩‍👦👨‍👩‍👧‍👦  👩‍👩‍👦👨‍👩‍👧‍👦👩‍👩‍👦 🇭🇺🇫🇷🇭🇺", "emoji pass")

        let props = "name1=value1\nname2='value2\nvalue2\n'\n"
        let dict = props["(\\w+)=('[^']*'|[^\n]*)"].dictionary()
        XCTAssertEqual(dict, ["name1": "value1", "name2": "'value2\nvalue2\n'"], "dictionary pass")

        XCTAssert(true, "Pass")

//        switch "john john" {
//        case "jo..":
//            XCTAssert(true, "switch match pass")
//        default:
//            XCTFail("switch match fail")
//        }

        switch "john john" {
        case "no..":
            XCTFail("switch non-match fail")
        default:
            XCTAssert(true, "switch non-match pass")
        }

        let tmpFile = "/tmp/b"
        FileRegex.save( path: tmpFile, contents: "john john john")
        let fregex = try! FileRegex( path: tmpFile )
        fregex["john"] ~= "sam"
        fregex["sam"] ~= ["tim"]
        XCTAssertEqual(try! FileRegex.load(path: tmpFile), "tim sam sam", "file replace pass")
        XCTAssertEqual(tmpFile["tmp"]["mnt"]["a"]["b"], "/mnt/b", "chained")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
