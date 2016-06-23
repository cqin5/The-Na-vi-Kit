//
//  NDDefinitionViewController.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-23.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class NDDefinitionViewController: UIViewController {

    @IBOutlet var naviLabel : UILabel!
    @IBOutlet var categoryLabel : UILabel!
    @IBOutlet var definitionView : UITextView!
    
    var entry : NDDictionaryEntry!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadEntry()
    }
    
    func loadEntry() {
        naviLabel.text = entry.navi
        categoryLabel.text = entry.category
        definitionView.text = entry.english
    }
    
    @IBAction func backButtonTapped(sender:AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.navigationController?.popViewControllerAnimated(true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
