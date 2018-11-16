//
//  CompositionViewController.swift
//  ZHCamera
//
//  Created by xuzhenhao on 2018/11/9.
//  Copyright © 2018年 xuzhenhao. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

enum TransitionType {
    case Dissolve//溶解效果
    case Push
}

class CompositionViewController: UIViewController {
    var videos: [AVAsset] = []
    let composition = AVMutableComposition()
    var videoComposition: AVMutableVideoComposition!
    
    class func compositionViewController() -> UIViewController {
        return UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CompositionViewController")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareResource()
        
        buildCompositionVideoTracks()
        buildCompositionAudioTracks()
        buildVideoComposition()
        export()
    }
    
    func prepareResource() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: ".mp4", subdirectory: nil) else {
            return
        }
        for url in urls {
            let asset = AVAsset(url: url)
            videos.append(asset)
        }
    }
    // MARK: - 编辑视频
    func buildCompositionVideoTracks() {
        //使用invalid，系统会自动分配一个有效的trackId
        let trackId = kCMPersistentTrackID_Invalid
        //创建AB两条视频轨道，视频片段交叉插入到轨道中，通过对两条轨道的叠加编辑各种效果。如0-5秒内，A轨道内容alpha逐渐到0，B轨道内容alpha逐渐到1
        guard let trackA = composition.addMutableTrack(withMediaType: .video, preferredTrackID: trackId) else {
            return
        }
        guard let trackB = composition.addMutableTrack(withMediaType: .video, preferredTrackID: trackId) else {
            return
        }
        let videoTracks = [trackA,trackB]
        
        //视频片段插入时间轴时的起始点
        var cursorTime = CMTime.zero
        //转场动画时间
        let transitionDuration = CMTime(value: 2, timescale: 1)
        for (index,value) in videos.enumerated() {
            //交叉循环A，B轨道
            let trackIndex = index % 2
            let currentTrack = videoTracks[trackIndex]
            //获取视频资源中的视频轨道
            guard let assetTrack = value.tracks(withMediaType: .video).first else {
                continue
            }
            do {
                //插入提取的视频轨道到 空白(编辑)轨道的指定位置中
                try currentTrack.insertTimeRange(CMTimeRange(start: .zero, duration: value.duration), of: assetTrack, at: cursorTime)
                //光标移动到视频末尾处，以便插入下一段视频
                cursorTime = CMTimeAdd(cursorTime, value.duration)
                //光标回退转场动画时长的距离，这一段前后视频重叠部分组合成转场动画
                cursorTime = CMTimeSubtract(cursorTime, transitionDuration)
            } catch {
                
            }
        }
    }
    func buildCompositionAudioTracks() {
        let trackId = kCMPersistentTrackID_Invalid
        guard let trackAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: trackId) else {
            return
        }
        var cursorTime = CMTime.zero
        for (_,value) in videos.enumerated() {
            //获取视频资源中的音频轨道
            guard let assetTrack = value.tracks(withMediaType: .audio).first else {
                continue
            }
            do {
                try trackAudio.insertTimeRange(CMTimeRange(start: .zero, duration: value.duration), of: assetTrack, at: cursorTime)
                cursorTime = CMTimeAdd(cursorTime, value.duration)
            } catch {
                
            }
        }
    }
    
    /// 设置videoComposition来描述A、B轨道该如何显示
    func buildVideoComposition() {
        //创建默认配置的videoComposition
        let videoComposition = AVMutableVideoComposition.init(propertiesOf: composition)
        self.videoComposition = videoComposition
        filterTransitionInstructions(of: videoComposition)
    }
    /// 过滤出转场动画指令
    func filterTransitionInstructions(of videoCompostion: AVMutableVideoComposition) -> Void {
        let instructions = videoCompostion.instructions as! [AVMutableVideoCompositionInstruction]
        for (index,instruct) in instructions.enumerated() {
            //非转场动画区域只有单轨道(另一个的空的)，只有两个轨道重叠的情况是我们要处理的转场区域
            guard instruct.layerInstructions.count > 1 else {
                continue
            }
            var transitionType: TransitionType
            //需要判断转场动画是从A轨道到B轨道，还是B-A
            var fromLayerInstruction: AVMutableVideoCompositionLayerInstruction
            var toLayerInstruction: AVMutableVideoCompositionLayerInstruction
            //获取前一段画面的轨道id
            let beforeTrackId = instructions[index - 1].layerInstructions[0].trackID;
            //跟前一段画面同一轨道的为转场起点，另一轨道为终点
            let tempTrackId = instruct.layerInstructions[0].trackID
            if beforeTrackId == tempTrackId {
                fromLayerInstruction = instruct.layerInstructions[0] as! AVMutableVideoCompositionLayerInstruction
                toLayerInstruction = instruct.layerInstructions[1] as! AVMutableVideoCompositionLayerInstruction
                transitionType = TransitionType.Dissolve
            }else{
                fromLayerInstruction = instruct.layerInstructions[1] as! AVMutableVideoCompositionLayerInstruction
                toLayerInstruction = instruct.layerInstructions[0] as! AVMutableVideoCompositionLayerInstruction
                transitionType = TransitionType.Push
            }
            
            setupTransition(for: instruct, fromLayer: fromLayerInstruction, toLayer: toLayerInstruction,type: transitionType)
        }
    }
    /// 设置转场动画
    func setupTransition(for instruction: AVMutableVideoCompositionInstruction, fromLayer: AVMutableVideoCompositionLayerInstruction, toLayer: AVMutableVideoCompositionLayerInstruction ,type: TransitionType) {
        let identityTransform = CGAffineTransform.identity
        let timeRange = instruction.timeRange
        let videoWidth = self.videoComposition.renderSize.width
        if type == TransitionType.Push{
            let fromEndTranform = CGAffineTransform(translationX: -videoWidth, y: 0)
            let toStartTranform = CGAffineTransform(translationX: videoWidth, y: 0)
            
            fromLayer.setTransformRamp(fromStart: identityTransform, toEnd: fromEndTranform, timeRange: timeRange)
            toLayer.setTransformRamp(fromStart: toStartTranform, toEnd: identityTransform, timeRange: timeRange)
        }else {
            fromLayer.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: timeRange)
        }
        
        //重新赋值
        instruction.layerInstructions = [fromLayer,toLayer]
    }
    // MARK: - 导出合成的视频
    func export(){
        let session = AVAssetExportSession.init(asset: composition.copy() as! AVAsset, presetName: AVAssetExportPreset640x480)
        session?.videoComposition = videoComposition
        session?.outputURL = CompositionViewController.createTemplateFileURL()
        session?.outputFileType = AVFileType.mp4
        session?.exportAsynchronously(completionHandler: {[weak self] in
            guard let strongSelf = self else {return}
            let status = session?.status
            if status == AVAssetExportSession.Status.completed {
                strongSelf.saveToAlbum(atURL: session!.outputURL!, complete: { (success) in
                    DispatchQueue.main.async {
                       strongSelf.showSaveResult(isSuccess: success)
                    }
                })
            }
        })
    }
    // MARK: - utils
    private class func createTemplateFileURL() -> URL {
        
        NSHomeDirectory()
        let path = NSTemporaryDirectory() + "composition.mp4"
        let fileURL = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do { try FileManager.default.removeItem(at: fileURL) } catch {
                
            }
        }
        return fileURL
    }
    private func saveToAlbum(atURL url: URL,complete: @escaping ((Bool) -> Void)){
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }, completionHandler: { (success, error) in
            complete(success)
        })
    }
    private func showSaveResult(isSuccess: Bool) {
        let message = isSuccess ? "已保存到相册" : "保存失败"
        
        let alertController =  UIAlertController.init(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (action) in
        }))
        self .present(alertController, animated: true, completion: nil)
    }
}
