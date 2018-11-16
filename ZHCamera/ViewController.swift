//
//  ViewController.swift
//  ZHCamera
//
//  Created by xuzhenhao on 2018/11/8.
//  Copyright © 2018年 xuzhenhao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    let items = ["拍摄+滤镜+导出",
                 "视频片段合成+转场动画"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    

}

extension ViewController: UITableViewDataSource,UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "entrance")
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = viewController(at: indexPath)
        self.navigationController?
            .pushViewController(vc, animated: true)
    }
    
    func viewController(at indexPath:IndexPath) -> UIViewController {
        
        let index = indexPath.row
        if index == 0 {
            return CameraViewController.cameraViewController()
        }else {
            return CompositionViewController.compositionViewController()
        }
    }
}
