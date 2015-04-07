## Some regular expression operators for Swift

It's with a certain hesitance I post a project based on "Operator Overloading"
(generally considered by the programing cognisente as "Unsafe at any speed") but the
absence of direct support for regular expressions in Swift provides an excuse to explore 
the terrain (there are also interesting things you can do with threading operators
added further down.) While "NSRegularExpression" is powerful and complete, 
by the time you fire up an instance up and puzzle out the api the focus has been taken 
so far away from the expression itself it is seldom the concise solution to a particular
class of problem that it should be.

The two new operators defined start with a very basic premise. In the same way that subscripting
into a collection such as an array specifies the address or range on which an operation
can be performed, subscripting into a string with a regular expression can specify a part 
of the string that can be assigned to or from. Let's suppose for a moment it would be a
good idea to be able to write the following in code:

	let input = "Now is the time for all good men to come to the aid of the party"

	let words:[String] = input["(\\w+)"].matches()

	input["men"] = "people"

	// "Now is the time for all good people to come to the aid of the party"
	
### The implementation

The first expression extracting all words in the text is easy enough to realise. A new
operator taking a string subscript on a string returns a SwiftRegex instance which
captures the string being operated on and the compiled regular expression specified
in the subscript. 

	extension String {
		subscript(pattern: String) -> SwiftRegex {
			return SwiftRegex(target: self, pattern: pattern)
		}
	}

Assignment to this new regular expression entity is a little more problematic. Swift 
doesn't' give you control the assignment operator itself so I've had to repurpose
the "~=" compound operator (it is the "pattern matching" operator after all) so
the first iteration is:

	var output = input["men"] ~= "people"

The input string is captured by reference so were it to be mutable the operation could
be performed in place. A global function RegexMutable() is defined as shorthand to 
convert an input string into an NSMutableString under the covers so the above code
can become:

    func RegexMutable(string: NSString) -> NSMutableString {
        return NSMutableString(string:string)
    }

	var mutable = RegexMutable( input )
	
	mutable["men"] ~= "folk"
	mutable["the party"] ~= "their country"

	// "Now is the time for all good folk to come to the aid of their country"
	
You can use either version

### The details

The SwiftRegex class defines a number of methods to get at all aspects of a match
or matches in the input string:

	matches() -> [String] // all matches in the string
	ranges() -> [NSRange] // array of ranges of matches in string
	groups() -> [String] // capture groups of first match
	allGroups() -> [[String]] // all groups of all matches
	
The replacement string is a "template" an can contain "$N" expressions to refer to
capture groups in the source regular expression:

	mutable["(good) (\\w+)"] ~= "great $2"

A subscript operator as been defined on SwiftRegex itself so capture groups can be
extracted and assigned to (this time with a normal "=" assignment.)

	let adjective = mutable["(\\w+) (men|people|folk)"][1]
	
	mutable["(good) (\\w+)"][1] = "great"

	// "Now is the time for all great folk to come to the aid of their country"

The replacement can also be two forms of closure executed once for each match:

	mutable["\\w+"] ~= {
		(match: String) in
        return match.uppercaseString
	}
	
	// "NOW IS THE TIME FOR ALL GREAT FOLK TO COME TO THE AID OF THEIR COUNTRY"

	mutable["(\\w)(\\w+)"] ~= {
		(groups: [String]) in
    	return groups[1]+groups[2].lowercaseString
	}
	
	// "Now Is The Time For All Great Folk To Come To The Aid Of Their Country"

One final conversion is available, that to a dictionary:

	let props = "name1=value1\nname2='value2\nvalue3\n'\n"

    let dict = props["(\\w+)=('[^']*'|[^\n]*)"].dictionary()

	// ["name1": "value1", "name2": "'value2\nvalue3\n'"]

At which point this almost begins to look useful..

Stop press:

You can now regex a file directly e.g.

    RegexFile( "/path/to/file" )["pattern"] ~= "replacement"

And apply replacements inline with chaining

    var result = string["pattern"]["replacement"]["pattern2"]["replacement2"]

This is the best syntax I could up with alas..

### License MIT

Copyright (c) 2015 John Holdsworth

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

