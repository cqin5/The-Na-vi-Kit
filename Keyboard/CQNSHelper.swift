//
//  NSHelper.swift
// 
//
//  Created by Chuhan Qin on 2015-07-13.
// 
//

import Foundation
import UIKit

func NSAttributedStringMake(string string:String, font:UIFont, colour:UIColor) -> NSAttributedString {
    
    return NSAttributedString(string: string, attributes: [NSFontAttributeName : font, NSForegroundColorAttributeName : colour])
    
}

func NSMutableAttributedStringMake(string string:String, font:UIFont, colour:UIColor) -> NSMutableAttributedString {
    
    return NSMutableAttributedString(string: string, attributes: [NSFontAttributeName : font, NSForegroundColorAttributeName : colour])
    
}

func randomStringWithLength(length length: Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    let randomString : NSMutableString = NSMutableString(capacity: length)
    
    for (var i=0; i < length; i++){
        let length = UInt32 (letters.length)
        let rand = arc4random_uniform(length)
        randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
    }
    
    return randomString.stringValue
}

extension NSTimeInterval {
    
    func toHHmmss() -> String {
        var minutes = 0
        var seconds = 0
        
        var secondsToReturn = ""
        
        if self.isNormal {
            minutes = Int(floor(self/60))
            seconds = Int(Int(self)%60)
        }
        
        secondsToReturn = "\(seconds)"
        if seconds < 10 {
            secondsToReturn = "0\(seconds)"
        }
        
        if minutes == -1 {
            minutes = 0
        }
        
        return "\(minutes):\(secondsToReturn)"
    }
    
    var timeIntervalRoundedToSeconds:NSTimeInterval {
        return NSTimeInterval(Int(self/1))
    }
}

extension String {
    
    var floatValue:Float{
        return NSString(string: self).floatValue
    }
    
    var doubleValue:Double{
        return NSString(string: self).doubleValue
    }
    
    var intValue:Int{
        return NSString(string: self).integerValue
    }

    var isValidEmailAddress:Bool{
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        return emailTest.evaluateWithObject(self)
    }
    
    func contains(string:String) -> Bool {
        return (self.rangeOfString(string) != nil)
    }
    
//    var base64String:String {
//        let data = self.dataUsingEncoding(NSUTF8StringEncoding);
//        return data!.base64EncodedStringWithOptions(0).stringValue;
//    }
    
    var stringWithCapitalizedFirstLetter: String {
        let first = String(characters.prefix(1)).capitalizedString
        let other = String(characters.dropFirst())
        return first + other
    }
}

extension NSString {
    var stringValue:String{
        return self as String
    }
}
