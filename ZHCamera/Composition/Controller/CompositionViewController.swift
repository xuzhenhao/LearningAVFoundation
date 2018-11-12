//
//  CompositionViewController.swift
//  ZHCamera
//
//  Created by xuzhenhao on 2018/11/9.
//  Copyright © 2018年 xuzhenhao. All rights reserved.
//

import UIKit

class CompositionViewController: UIViewController {

    class func compositionViewController() -> UIViewController {
        return UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CompositionViewController")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    

    

}
