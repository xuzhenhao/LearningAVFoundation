//
//  CameraViewController.swift
//  ZHCamera
//
//  Created by xuzhenhao on 2018/11/8.
//  Copyright © 2018年 xuzhenhao. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController {

    let captureManager = CaptureManager()
    var videoWriteManager : VideoWriteManager?
    var isRecording = false
    
    @IBOutlet weak var preview: CapturePreview!
    let filters = ["CIPhotoEffectChrome",
                    "CIPhotoEffectFade",
                     "CIPhotoEffectInstant",
                      "CIPhotoEffectMono",
                       "CIPhotoEffectNoir",
                        "CIPhotoEffectProcess",
                          "CIPhotoEffectTransfer"]
    var currentFilter: String  = "CIPhotoEffectTonal"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCaptureManager()
    }
    func setupCaptureManager() {
        captureManager.setupSession { (isSuccess, error) in
            if isSuccess {
                captureManager.startSession()
            }
        }
        captureManager.videoDataCallback = { [weak self] (sampleBuffer) in
            guard let strongSelf = self,let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            //1. 处理图像数据，输出结果为CIImage,作为后续展示和写入的基础数据
            let ciImage = CIImage.init(cvImageBuffer: imageBuffer)
            //加滤镜
            let filter = CIFilter.init(name: strongSelf.currentFilter)!
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            
            guard let finalImage = filter.outputImage else {
                return
            }
            //2. 用户界面展示
            let image = UIImage.init(ciImage: finalImage)
            DispatchQueue.main.async {
                strongSelf.preview.ciImage = image
            }
            //3. 保存写入文件
            strongSelf.videoWriteManager?.processImageData(CIImage: finalImage, atTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        }
        captureManager.audioDataCallback = {[weak self] sample in
            guard let strongSelf = self else { return }
            strongSelf.videoWriteManager?.processAudioData(CMSampleBuffer: sample)
        }
        
    }
    func setupMoiveWriter() {
        //输出视频的参数设置，如果要自定义视频分辨率，在此设置。否则可使用相应格式的推荐参数
        guard let videoSetings = self.captureManager.recommendedVideoSettingsForAssetWriter(writingTo: .mp4),
            let audioSetings = self.captureManager.recommendedAudioSettingsForAssetWriter(writingTo: .mp4)
            else{
                return
        }
        videoWriteManager = VideoWriteManager(videoSetting: videoSetings, audioSetting: audioSetings, fileType: .mp4)
        //录制成功回调
        videoWriteManager?.finishWriteCallback = { [weak self] url in
            guard let strongSelf = self else {return}
            strongSelf.saveToAlbum(atURL: url, complete: { (success) in
                DispatchQueue.main.async {
                    strongSelf.showSaveResult(isSuccess: success)
                }
                
            })
        }
    }
    
    
    @IBAction func didClickChangeFilter(_ sender: UIButton) {
        self.currentFilter = self.filters.randomElement()!
    }
    
    @IBAction func didClickCaptureButton(_ sender: UIButton) {
        //未开始录制，开始录制
        if !isRecording {
            //连续拍摄多段时，每次都需要重新生成一个实例。之前的writer会因为已经完成写入，无法再次使用
            setupMoiveWriter()
            videoWriteManager?.startWriting()
            isRecording = true
            sender.isSelected = true
        }else {
            //录制中，停止录制
            videoWriteManager?.stopWriting()
            isRecording = false
            sender.isSelected = false
        }
    }
    func saveToAlbum(atURL url: URL,complete: @escaping ((Bool) -> Void)){
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }, completionHandler: { (success, error) in
            complete(success)
        })
    }
    func showSaveResult(isSuccess: Bool) {
        let message = isSuccess ? "保存成功" : "保存失败"
        
        let alertController =  UIAlertController.init(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { (action) in
            
        }))
        self .present(alertController, animated: true, completion: nil)
    }
}
