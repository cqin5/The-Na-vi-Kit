//
//  Na_viTests.swift
//  Na'viTests
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import XCTest
@testable import Na_vi

class Na_viTests: XCTestCase {
    let dict = NDDictionary()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    func testNDDictionaryLoadingTime1() {
        self.measureBlock { 
            self.dict.classifyDictionary()
        }
    }
    
    func testNDDictionaryLoadingTime2() {
        self.measureBlock {
            self.dict.classifyDictionaryV2()
        }
    }
    
}
