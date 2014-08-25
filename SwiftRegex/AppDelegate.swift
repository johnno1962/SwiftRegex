//
//  AppDelegate.swift
//  SwiftRegex
//
//  Created by John Holdsworth on 26/06/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        // Override point for customization after application launch.

        // for usage see SwiftRegexTests and ViewController

        let input = "Now is the time for all good men to come to the aid of the party"
        //let mtbl:NSMutableString = input

        let words:[String] = input["(\\w+)"].matches()
        let groups:[[String]] = input["(\\w)(\\w+)"].allGroups()

        println(words)
        println(groups)

        if input["good"] {
            println("good")
        }

        var output = input["men"] ~= "people"

        println(output)

        var mutable = RegexMutable( input )

        mutable["men"] ~= "folk"
        mutable["the party"] ~= "their country"

        let adjective = mutable["(\\w+) (men|people|folk)"][1]

        mutable["(good) (\\w+)"][1] = "great"

        println(mutable)

        // "Now is the time for all great folk to come to the aid of their country"

        mutable["\\w+"] ~= {
            (match: String) in
            return match.uppercaseString
        }

        println(mutable)
        // "NOW IS THE TIME FOR ALL GREAT FOLK TO COME TO THE AID OF THEIR COUNTRY"

        mutable["(\\w)(\\w+)"] ~= {
            (groups: [String]) in
            return groups[1]+groups[2].lowercaseString
        }

        println(mutable)
        // "Now Is The Time For All Great Folk To Come To The Aid Of Their Country"

        let props = "name1=value1\nname2='value2\nvalue2\n'\n"
        let dict:[String:String] = props["(\\w+)=('[^']*'|.*)"].dictionary()
        // ["name1": "value1", "name2": "'value2\nvalue2\n'"]

        println(dict)

        var i = 0;

        {
            println("Task #1")
            for var i=0 ; i<10000000 ; i++ {
            }
            println("\(i++)")
        } & {
            println("Task #2")
            for var i=0 ; i<20000000 ; i++ {
            }
            println("\(i++)")
        } & {
            println("Task #3")
            for var i=0 ; i<30000000 ; i++ {
            }
            println("\(i++)")
        } | {
            println("Completed \(i)")
        };

        {
            return 99
        } | {
            (result:Int) in
            println("\(result)")
        };

        {
            return 88
        } & {
            return 99
        } | {
            (results:[Int!]) in
            println("\(results)")
        };

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

