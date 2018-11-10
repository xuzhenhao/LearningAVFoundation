//
//  CapturePreview.swift
//  ZHCamera
//
//  Created by xuzhenhao on 2018/11/8.
//  Copyright © 2018年 xuzhenhao. All rights reserved.
//

import UIKit

/// 录制时的用户预览界面
class CapturePreview: UIView {

    var image:Data?
    var ciImage: UIImage?{
        didSet{
            guard let image = ciImage else {
                return
            }
            imageView.image = image
            imageView.frame = self.bounds
        }
    }
    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
        return view
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addSubview(imageView)
    }
    
}
