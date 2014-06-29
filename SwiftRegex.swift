//
//  SwiftRegex.swift
//  SwiftRegex
//
//  Created by John Holdsworth on 26/06/2014.
//  Copyright (c) 2014 John Holdsworth.
//
//  This code is in the public domain from:
//  https://github.com/johnno1962/SwiftRegex
//

import Foundation

var swiftRegexCache = Dictionary<String,NSRegularExpression>()

extension NSRange {
    func regexFound() -> Bool {
        return location != NSNotFound
    }
}

func RegexMutable(string: NSString) -> NSMutableString {
    return NSMutableString.stringWithString(string)
}

class SwiftRegex: NSObject {

    var target: NSString
    var regex: NSRegularExpression

    init(target:NSString, pattern:String, options:NSRegularExpressionOptions = nil) {
        self.target = target
        if let regex = swiftRegexCache[pattern] {
            self.regex = regex
        } else {
            var error: NSError?
            if let regex = NSRegularExpression.regularExpressionWithPattern(pattern, options:options, error:&error) {
                swiftRegexCache[pattern] = regex
                self.regex = regex
            }
            else {
                SwiftRegex.failure("Error in pattern: \(pattern) - \(error)")
                self.regex = NSRegularExpression()
            }
        }
        super.init()
    }

    class func failure(message: String) {
        println("SwiftRegex: "+message)
        //assert(false,"SwiftRegex: failed")
    }

    @final var targetRange: NSRange {
        return NSRange(location: 0,length: target.length)
    }

    func substring(range: NSRange) -> String! {
        if ( range.regexFound() ) {
            return target.substringWithRange(range)
        } else {
            return nil
        }
    }

    func doesMatch(options: NSMatchingOptions = nil) -> Bool {
        return range(options: options).regexFound()
    }

    func range(options: NSMatchingOptions = nil) -> NSRange {
        return regex.rangeOfFirstMatchInString(target, options: nil, range: targetRange)
    }

    func match(options: NSMatchingOptions = nil) -> String! {
        return substring(range(options: options))
    }

    func groups(options: NSMatchingOptions = nil) -> String[]! {
        return groupsForMatch( regex.firstMatchInString(target, options: options, range: targetRange) )
    }

    func groupsForMatch(match: NSTextCheckingResult!) -> String[]! {
        if match {
            var groups = Array<String>()
            for group in 0...regex.numberOfCaptureGroups {
                var groupRange = match.rangeAtIndex(group)
                if ( groupRange.regexFound() ) {
                    groups.append( substring(groupRange) )
                } else {
                    groups.append( "_" ) // avoids bridging problems
                }
            }
            return groups
        } else {
            return nil
        }
    }

    subscript(group: Int) -> String! {
        get {
            return groups()[group]
        }
        set(newValue) {
            if let mutableTarget = target as? NSMutableString {
                for match in matchResults().reverse() {
                    let replacement = regex.replacementStringForResult( match,
                                inString: target, offset: 0, template: newValue )
                    mutableTarget.replaceCharactersInRange(match.rangeAtIndex(group), withString: replacement)
                }
            } else {
                SwiftRegex.failure("Group modify on non-mutable")
            }
        }
    }

    func matchResults(options: NSMatchingOptions = nil) -> NSTextCheckingResult[] {
        return regex.matchesInString(target, options: options, range: targetRange) as NSTextCheckingResult[]
    }
    
    func ranges(options: NSMatchingOptions = nil) -> NSRange[] {
        return matchResults(options: options).map { $0.range }
    }

    func matches(options: NSMatchingOptions = nil) -> String[] {
        return matchResults(options: options).map { self.substring($0.range) }
    }
    
    func allGroups(options: NSMatchingOptions = nil) -> String[][] {
        return matchResults(options: options).map { self.groupsForMatch($0) }
    }

    func dictionary(options: NSMatchingOptions = nil) -> Dictionary<String,String> {
        var out = Dictionary<String,String>()
        for match in matchResults(options: options) {
            out[substring(match.rangeAtIndex(1))] =
                substring(match.rangeAtIndex(2))
        }
        return out
    }

    func substituteMatches(substitution: (NSTextCheckingResult, CMutablePointer<ObjCBool>) -> String,
                                options:NSMatchingOptions = nil) -> NSMutableString {
        let out = NSMutableString()
        var pos = 0

        regex.enumerateMatchesInString(target, options: options, range: targetRange ) {
            (match: NSTextCheckingResult!, flags: NSMatchingFlags, stop: CMutablePointer<ObjCBool>) in

            let matchRange = match.range
            out.appendString( self.substring( NSRange(location:pos, length:matchRange.location-pos)) )
            out.appendString( substitution(match, stop) )
            pos = matchRange.location + matchRange.length
        }

        out.appendString(substring( NSRange(location:pos, length:targetRange.length-pos)))

        if let mutableTarget = target as? NSMutableString {
            mutableTarget.setString(out)
            return mutableTarget
        } else {
            SwiftRegex.failure("Modify on non-mutable")
            return out
        }
    }

    // only first type seems to work
    func no__conversion() -> NSRange {
        return range()
    }

    func no__conversion() -> String {
        return match()
    }

    func no__conversion() -> Bool {
        return doesMatch()
    }

    func __conversion() -> String[] {
        return matches()
    }

    func __conversion() -> String[][] {
        return allGroups()
    }

    func __conversion() -> Dictionary<String,String> {
        return dictionary()
    }
}

extension NSString {
    subscript(pattern: String, options: NSRegularExpressionOptions) -> SwiftRegex {
        return SwiftRegex(target: self, pattern: pattern, options: options)
    }
}

extension NSString {
    subscript(pattern: String) -> SwiftRegex {
        return SwiftRegex(target: self, pattern: pattern)
    }
}

extension String {
    subscript(pattern: String, options: NSRegularExpressionOptions) -> SwiftRegex {
        return SwiftRegex(target: self, pattern: pattern, options: options)
    }
}

extension String {
    subscript(pattern: String) -> SwiftRegex {
        return SwiftRegex(target: self, pattern: pattern)
    }
}

func ~= (left: SwiftRegex, right: String) -> NSMutableString {
    return left.substituteMatches {
        (match: NSTextCheckingResult, stop: CMutablePointer<ObjCBool>) in
        return left.regex.replacementStringForResult( match,
            inString: left.target, offset: 0, template: right )
    }
}

func ~= (left: SwiftRegex, right: String[]) -> NSMutableString {
    var matchNumber = 0
    return left.substituteMatches {
        (match: NSTextCheckingResult, stop: CMutablePointer<ObjCBool>) in

        if ++matchNumber == right.count {
            stop.withUnsafePointer { $0.memory = true }
        }

        return left.regex.replacementStringForResult( match,
            inString: left.target, offset: 0, template: right[matchNumber-1] )
    }
}

func ~= (left: SwiftRegex, right: (String) -> String) -> NSMutableString {
    return left.substituteMatches {
        (match: NSTextCheckingResult, stop: CMutablePointer<ObjCBool>) in
        return right(left.substring(match.range))
    }
}

func ~= (left: SwiftRegex, right: (String[]) -> String) -> NSMutableString {
    return left.substituteMatches {
        (match: NSTextCheckingResult, stop: CMutablePointer<ObjCBool>) in
        return right(left.groupsForMatch(match))
    }
}

