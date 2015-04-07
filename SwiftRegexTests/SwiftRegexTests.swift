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

        XCTAssert(input["quick .* fox"].match() == "quick brown fox", "basic match");

        if let noMatch = input["quick orange fox"].match() {
            XCTAssert(false, "non-match fail");
        }
        else {
            XCTAssert(true, "non-match pass");
        }

        var match:[String] = input["the .* dog"].matches()
        XCTAssert(match==["the lazy dog"], "convert pass")

        XCTAssert(input["quick brown (\\w+)"][1] == "fox", "group subscript");

        XCTAssert(input["(the lazy) (cat)?"].groups()[2] == regexNoGroup, "optional group pass");

        let groups = input["the (.*?) (fox|dog)", .CaseInsensitive].allGroups()
        XCTAssert(groups == [["The quick brown fox", "quick brown", "fox"],
                             ["the lazy dog", "lazy", "dog"]], "groups match");

        let minput = NSMutableString(string:input)

        minput["(the) (\\w+)"] ~= "$1 very $2"
        XCTAssert(minput == "The quick brown fox jumps over the very lazy dog.", "replace pass");

        minput["(fox|dog)"] ~= ["$0", "brown $1"]
        XCTAssert(minput == "The quick brown fox jumps over the very lazy brown dog.", "replace array pass");

        minput["(\\w)(\\w+)"] ~= {
            (groups: [String]) in
            return groups[1].uppercaseString+groups[2]
        }

        XCTAssert(minput == "The Quick Brown Fox Jumps Over The Very Lazy Brown Dog.", "block pass");

        minput["Quick (\\w+)"][1] = "Red $1"

        XCTAssert(minput == "The Quick Red Brown Fox Jumps Over The Very Lazy Brown Dog.", "group replace pass");

        var str:String = minput
        str += minput

        let props = "name1=value1\nname2='value2\nvalue2\n'\n"
        let dict = props["(\\w+)=('[^']*'|[^\n]*)"].dictionary()
        XCTAssert(dict == ["name1": "value1", "name2": "'value2\nvalue2\n'"], "dictionary pass");

        XCTAssert(true, "Pass")

        switch "john john" {
        case "jo..":
            XCTAssert(true, "switch match pass")
        default:
            XCTFail("switch match fail")
        }

        switch "john john" {
        case "no..":
            XCTFail("switch non-match fail")
        default:
            XCTAssert(true, "switch non-match pass")
        }

        let tmpFile = "/tmp/b"
        SwiftRegex.saveFile( tmpFile, newContents:"john john john" )
        RegexFile( tmpFile )["john"] ~= "sam"
        RegexFile( tmpFile )["sam"] ~= ["tim"]
        XCTAssert(SwiftRegex.loadFile(tmpFile)=="tim sam sam", "file replace pass")
        XCTAssert(tmpFile["tmp"]["mnt"]["a"]["b"]=="/mnt/b", "chained")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
