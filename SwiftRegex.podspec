Pod::Spec.new do |s|
    s.name        = "SwiftRegex"
    s.version     = "3.0"
    s.summary     = "Some reular expression subscript overload for Swift"
    s.homepage    = "https://github.com/johnno1962/SwiftRegex"
    s.social_media_url = "https://twitter.com/Injection4Xcode"
    s.documentation_url = "https://github.com/johnno1962/SwiftRegex/blob/master/README.md"
    s.license     = { :type => "MIT" }
    s.authors     = { "johnno1962" => "swiftregex@johnholdsworth.com" }

    s.osx.deployment_target = "10.9"
    s.ios.deployment_target = "8.0"
    s.source   = { :git => "https://github.com/johnno1962/SwiftRegex.git", :tag => s.version }
    s.source_files = "SwiftRegex.swift"
end
