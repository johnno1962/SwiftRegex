//
//  SwiftRegex.swift
//  SwiftRegex
//
//  Created by John Holdsworth on 26/06/2014.
//  Copyright (c) 2014 John Holdsworth.
//
//  $Id: //depot/SwiftRegex/SwiftRegex.swift#44 $
//
//  This code is in the public domain from:
//  https://github.com/johnno1962/SwiftRegex
//

import Foundation

private var swiftRegexCache = Dictionary<String,NSRegularExpression>()
public let regexNoGroup = "__nil__"

public class SwiftRegex: NSObject, BooleanType {

    let target: NSString
    let regex: NSRegularExpression
    var regexFile: RegexFile?

    init( target:NSString, pattern:String, options:NSRegularExpressionOptions = .DotMatchesLineSeparators ) {
        self.target = target
        if let regex = swiftRegexCache[pattern] {
            self.regex = regex
        } else {
            do {
                let regex = try NSRegularExpression( pattern: pattern, options:options)
                swiftRegexCache[pattern] = regex
                self.regex = regex
            } catch let error as NSError {
                SwiftRegex.failure("Error in pattern: \(pattern) - \(error.localizedDescription)")
                self.regex = NSRegularExpression()
            }
        }
        super.init()
    }

    class func failure( message: String ) {
        NSLog( "*** SwiftRegex: \(message)"["%"]["%%"] )
        //assert(false,"SwiftRegex: failed")
    }

    public class func loadFile( path: String, bleat: Bool = true ) -> NSMutableString! {
        do {
            let string = try NSMutableString( contentsOfFile: path, encoding: NSUTF8StringEncoding )
            return string
        } catch let error as NSError {
            if bleat {
                failure( "Could not load file: \(path), \(error.localizedDescription)" )
            }
        }
        return nil
    }

    public class func saveFile( path: String, newContents: NSString, force: Bool = false ) -> Bool {
        let current = force ? nil : loadFile( path, bleat: false )

        if current == nil || current != newContents {
            do {
                try newContents.writeToFile( path, atomically: true, encoding: NSUTF8StringEncoding)
                return true
            } catch let error as NSError {
                failure( "Could not write to file: \(path), \(error.localizedDescription)" )
            }
        }

        return false
    }

    public class func patchFile( path: String, replace pattern: String, with template: String ) -> Bool {
        let patched = loadFile( path )
        patched[pattern] ~= template
        return saveFile( path, newContents: patched )
    }
    
    final var targetRange: NSRange {
        return NSRange(location: 0,length: target.length)
    }

    final func substring( range: NSRange ) -> String! {
        if ( range.location != NSNotFound ) {
            return target.substringWithRange(range)
        } else {
            return nil
        }
    }

    public func doesMatch( options: NSMatchingOptions? = nil ) -> Bool {
        return range(options).location != NSNotFound
    }

    public func range( options: NSMatchingOptions? = nil ) -> NSRange {
        return regex.rangeOfFirstMatchInString( target as String, options: options ?? NSMatchingOptions(rawValue: 0), range: targetRange )
    }

    public func match( options: NSMatchingOptions? = nil ) -> String! {
        return substring( range( options ) )
    }

    public func groups( options: NSMatchingOptions? = nil ) -> [String]! {
        return groupsForMatch( regex.firstMatchInString(target as String, options: options ?? NSMatchingOptions(rawValue: 0), range: targetRange) )
    }

    func groupsForMatch( match: NSTextCheckingResult! ) -> [String]! {
        if match != nil {
            var groups = [String]()
            for groupno in 0...regex.numberOfCaptureGroups {
                if let group = substring( match.rangeAtIndex(groupno) ) as String! {
                    groups.append( group )
                } else {
                    groups.append( regexNoGroup ) // avoids bridging problems
                }
            }
            return groups
        } else {
            return nil
        }
    }

    public subscript( groupno: Int ) -> String! {
        get {
            if let groups = groups() {
                let group = groups[groupno]
                return group != regexNoGroup ? group : nil
            } else {
                return nil
            }
        }
        set( newValue ) {
            if let mutableTarget = target as? NSMutableString {
                for match in Array(matchResults().reverse()) {
                    let replacement = regex.replacementStringForResult( match,
                        inString: target as String, offset: 0, template: newValue )
                    mutableTarget.replaceCharactersInRange( match.rangeAtIndex(groupno), withString: replacement )
                }
            } else {
                SwiftRegex.failure("Group modify on non-mutable")
            }
        }
    }

    public subscript( template: String ) -> String {
        get {
            return replaceWith( template ) as String
        }
    }

    func matchResults( options: NSMatchingOptions? = nil ) -> [NSTextCheckingResult] {
        return regex.matchesInString( target as String, options: options ?? NSMatchingOptions(rawValue: 0), range: targetRange ) as [NSTextCheckingResult]
    }
    
    public func ranges( options: NSMatchingOptions? = nil ) -> [NSRange] {
        return matchResults( options ).map { $0.range }
    }

    public func matches( options: NSMatchingOptions? = nil ) -> [String] {
        return matchResults( options ).map { self.substring($0.range) }
    }
    
    public func allGroups( options: NSMatchingOptions? = nil ) -> [[String]] {
        return matchResults( options ).map { self.groupsForMatch($0) }
    }

    public func dictionary( options: NSMatchingOptions? = nil ) -> Dictionary<String,String> {
        var out = Dictionary<String,String>()
        for match in matchResults(options) {
            out[substring(match.rangeAtIndex(1))] =
                substring(match.rangeAtIndex(2))
        }
        return out
    }

    func substituteMatches( substitution: (NSTextCheckingResult, UnsafeMutablePointer<ObjCBool>) -> String ) -> Bool {
        let out = NSMutableString()
        var pos = 0

        regex.enumerateMatchesInString( target as String, options: NSMatchingOptions(rawValue: 0), range: targetRange ) {
            (match: NSTextCheckingResult?, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in

            let matchRange = match!.range
            out.appendString( self.substring( NSRange(location:pos, length:matchRange.location-pos) ) )
            out.appendString( substitution(match!, stop) )
            pos = matchRange.location + matchRange.length
        }

        out.appendString( substring( NSRange(location:pos, length:targetRange.length-pos) ) )

        if let mutableTarget = target as? NSMutableString {
            if out != target {
                mutableTarget.setString(out as String)
                return true
            }
        } else {
            SwiftRegex.failure("Modify on non-mutable")
        }
        return false

    }

    func replaceWith( template: String, options: NSMatchingOptions? = nil ) -> NSMutableString {
        let mutable = /*target as? NSMutableString ??*/ RegexMutable( target )
        regex.replaceMatchesInString( mutable, options: options ?? NSMatchingOptions(rawValue: 0), range: targetRange, withTemplate: template )
        return mutable
    }

/* removed Beta6
    public func __conversion() -> Bool {
        return doesMatch()
    }

    public func __conversion() -> NSRange {
        return range()
    }

    public func __conversion() -> String {
        return match()
    }

    public func __conversion() -> [String] {
        return matches()
    }

    public func __conversion() -> [[String]] {
        return allGroups()
    }

    public func __conversion() -> [String:String] {
        return dictionary()
    }
*/
    public var boolValue: Bool {
        return doesMatch()
    }
}

extension NSString {
    public subscript( pattern: String, options: NSRegularExpressionOptions ) -> SwiftRegex {
        return SwiftRegex( target: self, pattern: pattern, options: options )
    }
}

extension String {
    public subscript( pattern: String, options: NSRegularExpressionOptions ) -> SwiftRegex {
        return SwiftRegex( target: self, pattern: pattern, options: options )
    }
}

extension NSString {
    public subscript( pattern: String ) -> SwiftRegex {
        return SwiftRegex( target: self, pattern: pattern )
    }
}

extension String {
    public subscript( pattern: String ) -> SwiftRegex {
        return SwiftRegex( target: self, pattern: pattern )
    }
}

public func RegexMutable( string: NSString ) -> NSMutableString {
    return NSMutableString( string: string )
}

// for switch
public var lastRegexMatchGroups: [String!]!

public func ~= ( left: String, right: String ) -> Bool {
    if let groups = SwiftRegex( target: right, pattern: left ).groups() {
        lastRegexMatchGroups = groups.map { $0 != regexNoGroup ? $0 : nil }
        return true
    }
    return false
}

// for replacements
public func ~= ( left: SwiftRegex, right: String ) -> Bool {
    return left.substituteMatches( {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return left.regex.replacementStringForResult( match,
            inString: left.target as String, offset: 0, template: right )
    } )
}

public func ~= ( left: SwiftRegex, right: [String] ) -> Bool {
    var matchNumber = 0
    return left.substituteMatches( {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in

        if ++matchNumber == right.count {
            stop.memory = true
        }

        return left.regex.replacementStringForResult( match,
            inString: left.target as String, offset: 0, template: right[matchNumber-1] )
    } )
}

public func ~= ( left: SwiftRegex, right: (String) -> String ) -> Bool {
    return left.substituteMatches( {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return right( left.substring(match.range) )
    } )
}

public func ~= ( left: SwiftRegex, right: ([String]) -> String ) -> Bool {
    return left.substituteMatches( {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return right( left.groupsForMatch(match) )
    } )
}

public class RegexFile {

    let filepath: String
    let contents: NSMutableString!

    public init( _ path: String ) {
        filepath = path
        contents = SwiftRegex.loadFile( path )
    }

    public subscript( pattern: String ) -> SwiftRegex {
        let regex = SwiftRegex( target: contents, pattern: pattern )
        regex.regexFile = self // retains until after substitution
        return regex
    }

    deinit {
        SwiftRegex.saveFile( filepath, newContents: contents )
    }

}
