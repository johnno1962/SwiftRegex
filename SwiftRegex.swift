//
//  SwiftRegex.swift
//  SwiftRegex
//
//  Created by John Holdsworth on 26/06/2014.
//  Copyright (c) 2014-6 John Holdsworth.
//
//  $Id: //depot/SwiftRegex/SwiftRegex.swift#46 $
//
//  This code is in the public domain from:
//  https://github.com/johnno1962/SwiftRegex
//

import Foundation

extension String {

    public func index(offset: Int) -> String.Index {
        if offset == NSNotFound {
            return endIndex
        }
        else if offset < 0 {
            return index(endIndex, offsetBy: offset)
        }
        else {
            return index(startIndex, offsetBy: offset)
        }
    }

    public func substring(from: Int, to:Int) -> String {
        return substring(with: index(offset:from)..<index(offset:to))
    }

    public subscript(from: Int) -> String {
        return substring(from: from, to: from+1)
    }

    public subscript(from: Int, to: Int) -> String {
        return substring(from: from, to: to)
    }

    public subscript(range: Range<Int>) -> String {
        return substring(from: range.lowerBound, to: range.upperBound)
    }

    public subscript(pattern: String) -> SwiftRegex {
        return self[pattern, []]
    }

    public subscript(pattern: String, options: NSRegularExpression.Options) -> SwiftRegex {
        return SwiftRegex( source: NSMutableString(string: self), pattern: pattern, options: options )
    }

}

extension NSMutableString {

    public subscript(pattern: String) -> MutableRegex {
        return self[pattern, []]
    }

    public subscript(pattern: String, options: NSRegularExpression.Options) -> MutableRegex {
        return MutableRegex(source: self, pattern: pattern, options: options)
    }

}

open class SwiftRegex {

    private static var cache = Dictionary<String,NSRegularExpression>()

    let target: NSMutableString
    let regex: NSRegularExpression
    var targetRange: NSRange

    public init( source: NSMutableString, pattern: String, options: NSRegularExpression.Options = [] ) {
        target = source
        targetRange = NSMakeRange(0, target.length)
        do {
            regex = try SwiftRegex.cache[pattern] ?? NSRegularExpression(pattern: pattern, options: options)
            SwiftRegex.cache[pattern] = regex
        }
        catch (let e as NSError) {
            print("SwiftRegex: Invalid regexp '\(pattern)': \(e)")
            regex = NSRegularExpression()
        }
    }

    open func targetString(match: NSTextCheckingResult, group: Int) -> String? {
        let groupRange = match.rangeAt(group)
        return groupRange.location != NSNotFound ? target.substring(with: groupRange) : nil
    }

    open func targetStrings(match: NSTextCheckingResult) -> [String?] {
        return (0...regex.numberOfCaptureGroups).map { targetString(match: match, group: $0) }
    }

    open func nextMatch( options: NSRegularExpression.MatchingOptions = [] ) -> NSTextCheckingResult? {
        if let match = regex.firstMatch(in: target as String, options: options, range: targetRange) {
            targetRange.location = match.range.location + match.range.length
            targetRange.length = target.length - targetRange.location
            return match
        }
        targetRange = NSMakeRange(0, target.length)
        return nil
    }

    public func dictionary( options: NSRegularExpression.MatchingOptions = [] ) -> Dictionary<String,String> {
        var out = Dictionary<String,String>()
        while let groupStrings = self[0..<3] {
            out[groupStrings[1] ?? ""] = groupStrings[2]
        }
        return out
    }

    func matchResults( options: NSRegularExpression.MatchingOptions = [] ) -> [NSTextCheckingResult] {
        return regex.matches( in: target as String, options: options, range: targetRange ) as [NSTextCheckingResult]
    }

    open func matches( options: NSRegularExpression.MatchingOptions = [] ) -> [String] {
        return matchResults( options: options ).map { targetString(match: $0, group: 0)! }
    }

    open func allGroups( options: NSRegularExpression.MatchingOptions = [] ) -> [[String?]] {
        return matchResults( options: options ).map { targetStrings(match: $0) }
    }

    open subscript(group: Int) -> String? {
        return self[group, []]
    }

    open subscript(group: Int, options: NSRegularExpression.MatchingOptions) -> String? {
        if let match = nextMatch(options: options) {
            return targetString(match: match, group: group)
        }
        return nil
    }

    open subscript(groups: Range<Int>) -> [String?]? {
        return self[groups, []]
    }

    open subscript(groups: Range<Int>, options: NSRegularExpression.MatchingOptions) -> [String?]? {
        if let match = nextMatch(options: options) {
            return (groups.lowerBound..<groups.upperBound).map { targetString(match: match, group: $0) }
        }
        return nil
    }

    open subscript(template: String) -> String {
        return self[template, []]
    }

    open subscript(template: String, options: NSRegularExpression.MatchingOptions) -> String {
        regex.replaceMatches(in: target, options: options, range: targetRange, withTemplate: template)
        return target as String
    }

    open var boolValue: Bool {
        return nextMatch() != nil
    }

}

open class MutableRegex : SwiftRegex {

    var fileRegex: FileRegex?

    open func substituteMatches( substitution: (NSTextCheckingResult, UnsafeMutablePointer<ObjCBool>) -> String ) -> Bool {
        let out = NSMutableString()
        var matched = false
        var pos = 0

        regex.enumerateMatches( in: target as String, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: targetRange ) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            if let match = match {
                let matchRange = match.range
                out.append( target.substring(with: NSRange(location:pos, length:matchRange.location-pos)) )
                out.append( substitution(match, stop) )
                pos = matchRange.location + matchRange.length
                matched = true
            }
        }

        out.append( target.substring(with: NSRange(location:pos, length:targetRange.length-pos)) )
        target.setString(out as String)
        targetRange = NSMakeRange(0, target.length)
        fileRegex?.update()
        return matched
    }

    open override subscript(group: Int) -> String? {
        get {
            return self[group, []]
        }
        set (newValue) {
            self[group, []] = newValue
        }
    }

    open override subscript(group: Int, options: NSRegularExpression.MatchingOptions) -> String? {
        get {
            if let match = nextMatch(options: options) {
                return targetString(match: match, group: group)
            }
            return nil
        }
        set (newValue) {
            for match in Array(matchResults(options: options).reversed()) {
                let replacement = regex.replacementString( for: match,
                                                           in: target as String, offset: 0, template: newValue ?? "nil" )
                target.replaceCharacters( in: match.rangeAt(group), with: replacement )
            }
        }
    }
}

@discardableResult
public func ~= ( left: MutableRegex, right: String ) -> Bool {
    return left.substituteMatches() {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return left.regex.replacementString( for: match,
                                             in: left.target as String, offset: 0, template: right )
    }
}

@discardableResult
public func ~= ( left: MutableRegex, right: [String] ) -> Bool {
    var matchNumber = 0
    return left.substituteMatches() {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in

        matchNumber += 1
        if matchNumber == right.count {
            stop.pointee = true
        }

        return left.regex.replacementString( for: match,
                                             in: left.target as String, offset: 0, template: right[matchNumber-1] )
    }
}

@discardableResult
public func ~= ( left: MutableRegex, right: @escaping (String) -> String ) -> Bool {
    return left.substituteMatches() {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return right( left.targetString(match: match, group: 0) ?? "" )
    }
}

@discardableResult
public func ~= ( left: MutableRegex, right: @escaping ([String?]) -> String ) -> Bool {
    return left.substituteMatches() {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return right( (0..<left.regex.numberOfCaptureGroups+1).map { left.targetString(match: match, group: $0) } )
    }
}

open class FileRegex {

    let filepath: String
    let contents: NSMutableString!

    public static func load( path: String ) throws -> NSMutableString {
        return try NSMutableString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
    }

    public static func save( path: String, contents: NSString ) {
        do {
            try contents.write(toFile: path, atomically: false, encoding: String.Encoding.utf8.rawValue)
        }
        catch (let e as NSError) {
            print("FileRegex: Error writing to \(path): \(e)")
        }
    }

    public init( path: String ) throws {
        filepath = path
        contents = try FileRegex.load(path: path)
    }

    open subscript( pattern: String ) -> MutableRegex {
        let regex = MutableRegex( source: contents, pattern: pattern )
        regex.fileRegex = self // retains until after substitution
        return regex
    }

    func update() {
        FileRegex.save( path: filepath, contents: contents )
    }
    
}
