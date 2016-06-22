//
//  CQHelper.swift
//  
//
//  Created by Chuhan Qin on 2015-07-10.
// 
//

import Foundation
import UIKit

class CQHelper {
    
    static var sfMayaBlue = UIColor(hex: "#5BC9FB")
    static var sfTangerine = UIColor(hex: "#FFCC00")
    static var sfSafetyOrange = UIColor(hex: "#FF9500")
    static var sfRadicalRed = UIColor(hex: "#FF2D55")
    static var sfAzure = UIColor(hex: "#007BFF")
    static var sfUfoGreen = UIColor(hex: "#4EDA64")
    static var sfRedOrange = UIColor(hex: "#FF3B30")
    static var sfSyncifyPurple = UIColor(hex: "#4B4097")
    
    static var homeNavbarBackgroundColour = sfAzure
    static var searchNavbarBackgroundColour = sfTangerine
    
    static var homeNavbarTintColour = sfTangerine
    static var searchNavbarTintColour = sfTangerine
    
    class func getRandomColourFromSystemColours() -> UIColor {
        var colours = [sfMayaBlue, sfTangerine, sfSafetyOrange, sfRadicalRed, sfAzure, sfUfoGreen, sfRedOrange]
        return colours[Int(arc4random_uniform(UInt32(colours.count)))]
    }
    
    
    /* Sizes */
    static var screenWidth = UIScreen.mainScreen().bounds.width
    static var screenHeight = UIScreen.mainScreen().bounds.height
    
    static var baseSpacing = CGFloat(10.0)
    static var edgeSpacing = baseSpacing * 2
    static var spaceBetweenFeeds = baseSpacing
    
    class func xCoordinateOfRightEdge(ofView view:UIView) -> CGFloat {
        return view.frame.origin.x + view.frame.width
    }
    
    class func yCoordinateOfBottomEdge(ofView view:UIView) -> CGFloat {
        return view.frame.origin.y + view.frame.height
    }
    
    class func centerYCoordinateOffsetBy(points points:CGFloat, fromView view:UIView) -> CGPoint {
        return CGPoint(x: view.center.x, y: view.center.y + points)
    }
    
    class func loadImageInBackground(imageURL imageURL:String, inView view:UIImageView) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            let image = UIImage(data: NSData(contentsOfURL: NSURL(string: imageURL)!)!)
            dispatch_async(dispatch_get_main_queue(), {
                view.image = image
            })
        })
    }
    
    
    class func blur(anImage image:UIImage, withRadius radius:CGFloat) -> UIImage {
        
        let context = CIContext(options: nil)
        let inputImage = CIImage(image: image)
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter!.setValue(inputImage, forKey: kCIInputImageKey)
        filter!.setValue(radius, forKey: "inputRadius")
        let result:CIImage = filter!.valueForKey(kCIOutputImageKey) as! CIImage
        
        let cgImage = context.createCGImage(result, fromRect: inputImage!.extent)
        
        return UIImage(CGImage: cgImage)
    }
    
    class func get(image:UIImage, forView view:UIView, withGradientColoursTopColour topColour:UIColor, andBottomColour bottomColour:UIColor) -> UIImageView {
        let viewToBeReturned = UIImageView(frame: view.frame)
        let backgroundImageView = UIImageView(image: image)
        backgroundImageView.frame = view.frame
        viewToBeReturned.addSubview(view.getGradient(topColour, bottomColour: bottomColour))
        viewToBeReturned.addSubview(backgroundImageView)
        return viewToBeReturned
    }
    
    
}

extension UIButton {
    
    func changeToHalfHeightCornerRadiusButtonWith(borderColour borderColour:UIColor) {
        self.layer.cornerRadius = self.frame.height/2
        self.layer.borderColor = borderColour.CGColor
        self.layer.borderWidth = 0.6
        self.layer.opacity = 0.7

    }
    
}

extension UIView {
    
    func getGradient(topColour:UIColor, bottomColour:UIColor) -> UIView {
        let gradient = CAGradientLayer()
        let gradientView = UIView()
        
        gradient.frame = self.frame
        gradient.colors = [topColour.CGColor, bottomColour.CGColor]
        gradientView.frame = self.frame
        gradientView.layer.insertSublayer(gradient, above: gradientView.layer)
        
        return gradientView
    }
    
    func showActivityIndicator(){
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityIndicator.frame = CGRectMake(0, 0, 140, 140)
        if self.isKindOfClass(UITableView) {
            activityIndicator.frame = CGRectMake(0, (self as! UITableView).contentOffset.y, self.frame.width, self.frame.height)
        } else {
            activityIndicator.center = self.center
        }
        activityIndicator.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        activityIndicator.layer.cornerRadius = 20
        activityIndicator.startAnimating()
        self.userInteractionEnabled = false
        self.addSubview(activityIndicator)
//        println(self.frame)
//        println(container.frame)
//        println((self as! UITableView).contentOffset)
    }
    
    func hideActivityIndicator() {
        for subview in self.subviews {
            if subview.isKindOfClass(UIActivityIndicatorView) {
                (subview as! UIActivityIndicatorView).stopAnimating()
                (subview as! UIActivityIndicatorView).hidden = true
                (subview as! UIActivityIndicatorView).removeFromSuperview()
            }
        }
        self.userInteractionEnabled = true
    }
    
    func addBackgroundImage(image:UIImage, withBlurRadius radius:CGFloat, withGradientColoursTopColour topColour:UIColor, andBottomColour bottomColour:UIColor){
        let backgroundImageView = UIImageView(image: CQHelper.blur(anImage: image, withRadius: radius))
        backgroundImageView.frame = self.frame
        self.addSubview(getGradient(topColour, bottomColour: bottomColour))
        self.addSubview(backgroundImageView)
    }
    
    func addBackgroundImage(image:UIImage, withGradientColoursTopColour topColour:UIColor, andBottomColour bottomColour:UIColor){
        let backgroundImageView = UIImageView(image: image)
        backgroundImageView.frame = self.frame
        self.addSubview(getGradient(topColour, bottomColour: bottomColour))
        self.addSubview(backgroundImageView)
    }

    //UIView manipulation
    func showBorder() {
        self.layer.borderColor = UIColor.redColor().CGColor
        self.layer.borderWidth = 1
        
    }
    
    //UIView manipulation
    func hideBorder() {
            self.layer.borderColor = UIColor.clearColor().CGColor
            self.layer.borderWidth = 0
    }

}

extension UIButton {
    
    func set(backgroundColour backgroundColour:UIColor, cornerRadius:CGFloat, borderWidth:CGFloat, borderColour:UIColor){
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = cornerRadius
        self.layer.borderColor = borderColour.CGColor
        self.layer.borderWidth = borderWidth
    }
    
}

extension UITextField {
    
    func monitorTextLength(maxLength:Int) {
        
        if self.text!.characters.count > maxLength {
            self.deleteBackward()
        }
        
    }
    
    func setUpKeyboardForNumber() {
        self.keyboardType = UIKeyboardType.NumberPad
        self.clearButtonMode = UITextFieldViewMode.WhileEditing
    }
    
    func setUpKeyboardForUserame() {
        self.keyboardType = UIKeyboardType.Default
        self.autocapitalizationType = UITextAutocapitalizationType.None
        self.autocorrectionType = UITextAutocorrectionType.No
    }
    
    func setUpKeyboardForName() {
        self.keyboardType = UIKeyboardType.Default
        self.autocapitalizationType = UITextAutocapitalizationType.Words
        self.autocorrectionType = UITextAutocorrectionType.Yes
    }
    
    func setUpKeyboardForPhone() {
        self.keyboardType = UIKeyboardType.PhonePad
        self.clearButtonMode = UITextFieldViewMode.WhileEditing
    }
    //TODO autoformat phone numbers
    
    func setUpKeyboardForAddress() {
        self.keyboardType = UIKeyboardType.Default
        self.clearButtonMode = UITextFieldViewMode.WhileEditing
        self.autocapitalizationType = UITextAutocapitalizationType.Words
        self.autocorrectionType = UITextAutocorrectionType.Yes
    }
    
    
    func setUpKeyboardForPostalCode() {
        self.keyboardType = UIKeyboardType.Default
        self.clearButtonMode = UITextFieldViewMode.WhileEditing
        self.autocapitalizationType = UITextAutocapitalizationType.AllCharacters
        self.autocorrectionType = UITextAutocorrectionType.No
    }
    
    func setUpKeyboardForPIN() {
        self.keyboardType = UIKeyboardType.NumberPad
        self.clearButtonMode = UITextFieldViewMode.WhileEditing
    }
    
    
    //TODO autoformat postal code
    
    func setUpKeyboardForPassword() {
        self.keyboardType = UIKeyboardType.Default
        self.clearButtonMode = UITextFieldViewMode.WhileEditing
        self.secureTextEntry = true
    }
    
    func setUpKeyboardForEmail() {
        self.keyboardType = UIKeyboardType.EmailAddress
        self.clearButtonMode = UITextFieldViewMode.WhileEditing
        self.autocapitalizationType = UITextAutocapitalizationType.None
        self.autocorrectionType = UITextAutocorrectionType.No
    }
    
    
    //TODO autoformat email
    
    func setUpKeyboardForCreditCard(textField:UITextField) {
        self.keyboardType = UIKeyboardType.NumberPad
        self.clearButtonMode = UITextFieldViewMode.WhileEditing
        self.autocapitalizationType = UITextAutocapitalizationType.None
    }
    

}

//  This method was created by R0CKSTAR on 6/13/14.
extension UIColor {
    convenience init(hex: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        if hex.hasPrefix("#") {
            let index   = hex.startIndex.advancedBy(1)
            let hex     = hex.substringFromIndex(index)
            let scanner = NSScanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexLongLong(&hexValue) {
                switch (hex.characters.count) {
                case 3:
                    red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                    green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                    blue  = CGFloat(hexValue & 0x00F)              / 15.0
                case 4:
                    red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                    green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                    blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                    alpha = CGFloat(hexValue & 0x000F)             / 15.0
                case 6:
                    red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
                case 8:
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                default:
                    print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8", terminator: "")
                }
            } else {
                print("Scan hex error")
            }
        } else {
            print("Invalid RGB string, missing '#' as prefix", terminator: "")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    
    
    convenience init(hex: String, alpha: CGFloat) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = alpha
        
        if hex.hasPrefix("#") {
            let index   = hex.startIndex.advancedBy(1)
            let hex     = hex.substringFromIndex(index)
            let scanner = NSScanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexLongLong(&hexValue) {
                switch (hex.characters.count) {
                case 3:
                    red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                    green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                    blue  = CGFloat(hexValue & 0x00F)              / 15.0
                case 4:
                    red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                    green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                    blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                    alpha = CGFloat(hexValue & 0x000F)             / 15.0
                case 6:
                    red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
                case 8:
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                default:
                    print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8", terminator: "")
                }
            } else {
                print("Scan hex error")
            }
        } else {
            print("Invalid RGB string, missing '#' as prefix", terminator: "")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}

