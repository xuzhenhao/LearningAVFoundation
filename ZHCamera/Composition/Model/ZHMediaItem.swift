//
//  ZHMediaItem.swift
//  ZHCamera
//
//  Created by xuzhenhao on 2018/11/14.
//  Copyright © 2018年 xuzhenhao. All rights reserved.
//

import UIKit
import AVFoundation

/// 时间线上的媒体资源
class ZHMediaItem: ZHTimelineItem {
    let url: URL
    let asset: AVAsset
    
    init(url: URL) {
        self.url = url
        self.asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        super.init()
    }
    func mediaType() -> AVMediaType {
        //需要子类重写
        return AVMediaType.video
    }
}
