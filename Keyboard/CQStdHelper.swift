//
//  CQHelper.swift
//
//
//  Created by Chuhan Qin on 2015-10-20.
// 
//

import Foundation

func delay(bySeconds seconds:Double, block:dispatch_block_t) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
        block()
    })
}

/// TODO delay with different priorities
