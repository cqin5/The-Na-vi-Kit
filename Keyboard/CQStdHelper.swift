//
//  CQHelper.swift
//
//
//  Created by Chuhan Qin on 2015-10-20.
// 
//

import Foundation

func delay(bySeconds seconds:Double, block:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
        block()
    })
}

/// TODO delay with different priorities
