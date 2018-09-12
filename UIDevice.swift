//
//  UIDevice.swift
//  Mary
//
//  Created by Chuhan Qin on 2018-08-28.
//  Copyright © 2018 MaryAg. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
    
    var hasBottom: Bool {
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 1136:
                print("iPhone 5 or 5S or 5C")
            case 1334:
                print("iPhone 6/6S/7/8")
            case 1920, 2208:
                print("iPhone 6+/6S+/7+/8+")
            case 2436:
                print("iPhone X")
                return true
            default:
                print("unknown")
            }
            return false
        }
        return false
    }
}
