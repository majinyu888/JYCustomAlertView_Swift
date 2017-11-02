//
//  ViewController.swift
//  JYCustomAlertView
//
//  Created by hb on 2017/9/4.
//  Copyright © 2017年 com.bm.hb. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func taped(_ sender: Any) {
        
        let popV = JYCustomAlertView()
        popV.closeOnTouchUpOutside = true
        popV.buttonTitles = ["我是取消", "我是确认"]
        
        let customV = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        let tf = UITextField(frame: CGRect(x: 10, y: 10, width: 200, height: 60))
        tf.backgroundColor = UIColor.red
        customV.addSubview(tf)
        
        popV.containerView = customV
        
        popV.onButtonTouchUpInside = { (pop, index) in
            print("index = \(index)")
            pop.close()
        }
        
        popV.show()
    }
}

