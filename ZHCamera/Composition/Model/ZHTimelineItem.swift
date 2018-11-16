//
//  ZHTimelineItem.swift
//  ZHCamera
//
//  Created by xuzhenhao on 2018/11/14.
//  Copyright © 2018年 xuzhenhao. All rights reserved.
//

import UIKit
import CoreMedia

/// 编辑的时间线上基础资源，媒体资源(音视频)、标题等都继承于它
class ZHTimelineItem: NSObject {
    var timeRange = CMTimeRange.invalid
    var startTime = CMTime.invalid
}
