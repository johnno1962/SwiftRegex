//
//  ViewController.swift
//  SwiftRegex
//
//  Created by John Holdsworth on 26/06/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate {
                            
    @IBOutlet var input : UITextView = nil
    @IBOutlet var regex : UITextField = nil
    @IBOutlet var groups : UITextView = nil
    @IBOutlet var replace : UITextField = nil
    @IBOutlet var result : UITextView = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        regexChanged(nil)
    }

    @IBAction func regexChanged(sender : UITextField!) {
        sender?.resignFirstResponder()
        let text = input.text
        let gps = text[regex.text].allGroups()
        groups.text = "\(gps)"
        replaceChanged(sender)
    }

    @IBAction func replaceChanged(sender : UITextField!) {
        sender?.resignFirstResponder()
        var mtext = RegexMutable(input.text)
        mtext[regex.text] ~= replace.text
        result.text = mtext
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

