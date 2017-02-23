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
    
    let naviFont : UIFont = UIFont.systemFont(ofSize: 18)
    let IPAFont : UIFont = UIFont.systemFont(ofSize: 16)
    let definitionFont : UIFont = UIFont.systemFont(ofSize: 16)
    let naviColour : UIColor = UIColor(white: 0.0, alpha: 1.0)
    let IPAColour : UIColor = UIColor(white: 0.5, alpha: 1.0)
    let definitionColour : UIColor = UIColor(white: 0.0, alpha: 1.0)
    
    var entry : NDDictionaryEntry!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadEntry()
    }
    
    func loadEntry() {
        let firstLine = NSMutableAttributedStringMake(string: entry.navi, font:naviFont, colour: naviColour)
        let firstLineSecondPart = NSMutableAttributedStringMake(string: " \t|" + entry.IPA + "| " , font:IPAFont, colour: IPAColour)
        firstLine.append(firstLineSecondPart)
        
        naviLabel.attributedText = firstLine
        categoryLabel.text = entry.category
        
        definitionView.attributedText = NSAttributedStringMake(string: entry.english, font: definitionFont, colour: definitionColour)
    }
    
    @IBAction func backButtonTapped(_ sender:AnyObject?) {
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
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
