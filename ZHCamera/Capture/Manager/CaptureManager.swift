//
//  CaptureManager.swift
//  ZHCamera
//
//  Created by xuzhenhao on 2018/11/8.
//  Copyright © 2018年 xuzhenhao. All rights reserved.
//

import UIKit
import AVFoundation

/// 录制管理类，管理录制输入、录制过程，输出SampleBuffer数据
class CaptureManager: NSObject {
    let captureSession = AVCaptureSession()
    //当前正在使用的输入设备(摄像头)
    weak var activeCamera : AVCaptureDeviceInput?
    //视频数据处理队列
    let videoDataQueue = DispatchQueue(label: "com.xzh.videoDataCaptureQueue")
    //音频数据处理队列
    let audioDataQueue = DispatchQueue(label: "com.xzh.audioDataCaptureQueue")
    //捕捉的视频数据输出对象
    let videoDataOutput = AVCaptureVideoDataOutput()
    //捕捉的音频数据输出对象
    let audioDataOutput = AVCaptureAudioDataOutput()
    //视频数据回调
    var videoDataCallback: ((CMSampleBuffer) -> Void)?
    //音频数据回调
    var audioDataCallback: ((CMSampleBuffer) -> Void)?
    
    // MARK: - SessionConfig
    
    typealias SetupCompletionHandler = ((Bool,Error?) -> Void)
    public func setupSession(completion:SetupCompletionHandler){
        captureSession.sessionPreset = .hd1920x1080
        setupSessionInput { (isSuccess, error) in
            if !isSuccess {
                completion(isSuccess,error);
                return;
            }
        }
        setupSessionOutput { (isSuccess, error) in
            completion(isSuccess,error)
        }
    }
    private func setupSessionInput(completion:SetupCompletionHandler) {
        let deviceError = NSError.init(
            domain: "com.session.error",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("配置录制设备出错", comment: "")])
        
        //配置摄像头
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            completion(false,deviceError)
            return
        }
        do {
            let videoInput = try AVCaptureDeviceInput.init(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                activeCamera = videoInput
            }
        } catch {
            completion(false,deviceError)
            return
        }
        
        //配置麦克风
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            completion(false,deviceError)
            return
        }
        do {
            let audioInput = try AVCaptureDeviceInput.init(device: audioDevice)
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
        } catch {
            completion(false,deviceError)
            return
        }
        completion(true,nil)
    }
    private func setupSessionOutput(completion: SetupCompletionHandler){
        let outputError = NSError.init(
            domain: "com.session.error",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("输出设置出错", comment: "")])
        
        //摄像头采集的yuv是压缩的视频信号，要还原成可以处理的数字信号
        let outputSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoDataOutput.videoSettings = outputSettings
        //不丢弃迟到帧，但会增加内存开销
        videoDataOutput.alwaysDiscardsLateVideoFrames = false
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataQueue)
        if captureSession.canAddOutput(videoDataOutput){
            captureSession.addOutput(videoDataOutput)
        }else{
            completion(false,outputError)
            return
        }
        
        audioDataOutput.setSampleBufferDelegate(self, queue: audioDataQueue)
        if captureSession.canAddOutput(audioDataOutput) {
            captureSession.addOutput(audioDataOutput)
        }else{
            completion(false,outputError)
            return
        }
        
        //写入配置,AVAssetWriter
        
        completion(true,nil)
    }
    // MARK: - Session operation
    public func startSession() {
        //防止阻塞主线程
        videoDataQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    public func stopSession() {
        videoDataQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    // MARK: - utils
    public func recommendedVideoSettingsForAssetWriter(writingTo outputFileType: AVFileType) -> [String: Any]? {
        return videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: outputFileType)
    }
    public func recommendedAudioSettingsForAssetWriter(writingTo outputFileType: AVFileType) -> [String: Any]? {
        return audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: outputFileType) as? [String: Any]
    }
}

extension CaptureManager : AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output == videoDataOutput {
            //数据处理
            guard let callback = videoDataCallback else {
                return;
            }
            callback(sampleBuffer)
            
        }else{
            guard let callback = audioDataCallback else {
                return;
            }
            callback(sampleBuffer)
        }
    }
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}
