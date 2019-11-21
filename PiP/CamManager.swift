//
//  CamManager.swift
//  PiP
//
//  Created by Huiping Guo on 2019/11/21.
//  Copyright © 2019 Huiping Guo. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class  CamManager: NSObject {
    
    var dualVideoSession = AVCaptureMultiCamSession()
    
    var audioDeviceInput: AVCaptureDeviceInput?
    var backAudioDataOutput = AVCaptureAudioDataOutput()
    var frontAudioDataOutput = AVCaptureAudioDataOutput()

     let dualVideoSessionQueue = DispatchQueue(label: "dual video session queue")
      
     let dualVideoSessionOutputQueue = DispatchQueue(label: "dual video session data output queue")
    
    
    weak var viewController: UIViewController!
    
    
    func configureDualVideo(viewController: UIViewController,block: @escaping () -> Void){
        self.viewController = viewController
        addNotifer()
        dualVideoSessionQueue.async {
            self.setUpSession(block: block)
        }
      }
    

        func setUpSession(block: () -> Void){
            if !AVCaptureMultiCamSession.isMultiCamSupported{
                DispatchQueue.main.async {
                   let alertController = UIAlertController(title: "Error", message: "Device is not supporting multicam feature", preferredStyle: .alert)
                   alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                    self.viewController.present(alertController, animated: true, completion: nil)
                }
                return
            }
                
            block()
            
            start()
        }
    
    func setUpCamera(type: AVCaptureDevice.DeviceType,position: AVCaptureDevice.Position, outputViewlayer: AVCaptureVideoPreviewLayer) -> Bool{
        
        outputViewlayer.setSessionWithNoConnection(dualVideoSession)

        //start configuring dual video session
        dualVideoSession.beginConfiguration()
            defer {
                //save configuration setting
                dualVideoSession.commitConfiguration()
            }
                
            //search back camera
            guard let backCamera = AVCaptureDevice.default(type, for: .video, position: position) else {
                print("no back camera")
                return false
            }
            
            let videoDataOutput = AVCaptureVideoDataOutput()

            let deviceInput: AVCaptureDeviceInput?
            // append back camera input to dual video session
            do {
                deviceInput = try AVCaptureDeviceInput(device: backCamera)
                
                guard let deviceInput = deviceInput, dualVideoSession.canAddInput(deviceInput) else {
                    print("no back camera device input")
                    return false
                }
                dualVideoSession.addInputWithNoConnections(deviceInput)
            } catch {
                print("no back camera device input: \(error)")
                return false
            }
            
            // seach back video port
            guard let backVideoPort = deviceInput?.ports(for: .video, sourceDeviceType: backCamera.deviceType, sourceDevicePosition: backCamera.position).first else {
                print("no back camera input's video port")
                return false
            }
            
            // append back video ouput
            guard dualVideoSession.canAddOutput(videoDataOutput) else {
                print("no back camera output")
                return false
            }
            dualVideoSession.addOutputWithNoConnections(videoDataOutput)
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            videoDataOutput.setSampleBufferDelegate(self, queue: dualVideoSessionOutputQueue)
            
            // connect back ouput to dual video connection
            let backOutputConnection = AVCaptureConnection(inputPorts: [backVideoPort], output: videoDataOutput)
            guard dualVideoSession.canAddConnection(backOutputConnection) else {
                print("no connection to the back camera video data output")
                return false
            }
            dualVideoSession.addConnection(backOutputConnection)
            backOutputConnection.videoOrientation = .portrait

            // connect back input to back layer
        
            let backConnection = AVCaptureConnection(inputPort: backVideoPort, videoPreviewLayer: outputViewlayer)
            guard dualVideoSession.canAddConnection(backConnection) else {
                print("no a connection to the back camera video preview layer")
                return false
            }
            dualVideoSession.addConnection(backConnection)
        
        return true
    }
    
    func setUpAudio() -> Bool{
         //start configuring dual video session
        dualVideoSession.beginConfiguration()
        defer {
            //save configuration setting
            dualVideoSession.commitConfiguration()
        }
        
        // serach audio device for dual video session
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("no the microphone")
            return false
        }
        
        // append auido to dual video session
        do {
            audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            guard let audioInput = audioDeviceInput,
                dualVideoSession.canAddInput(audioInput) else {
                    print("no audio input")
                    return false
            }
            dualVideoSession.addInputWithNoConnections(audioInput)
        } catch {
            print("no audio input: \(error)")
            return false
        }
        
        //search audio port back
        guard let audioInputPort = audioDeviceInput,
            let backAudioPort = audioInputPort.ports(for: .audio, sourceDeviceType: audioDevice.deviceType, sourceDevicePosition: .back).first else {
            print("no front back port")
            return false
        }
        
        // search audio port front
        guard let frontAudioPort = audioInputPort.ports(for: .audio, sourceDeviceType: audioDevice.deviceType, sourceDevicePosition: .front).first else {
            print("no front audio port")
            return false
        }
        
        // append back output to dual video session
        guard dualVideoSession.canAddOutput(backAudioDataOutput) else {
            print("no back audio data output")
            return false
        }
        dualVideoSession.addOutputWithNoConnections(backAudioDataOutput)
        backAudioDataOutput.setSampleBufferDelegate(self, queue: dualVideoSessionOutputQueue)
        
        // append front ouput to dual video session
        guard dualVideoSession.canAddOutput(frontAudioDataOutput) else {
            print("no front audio data output")
            return false
        }
        dualVideoSession.addOutputWithNoConnections(frontAudioDataOutput)
        frontAudioDataOutput.setSampleBufferDelegate(self, queue: dualVideoSessionOutputQueue)
        
        // add back output to dual video session
        let backOutputConnection = AVCaptureConnection(inputPorts: [backAudioPort], output: backAudioDataOutput)
        guard dualVideoSession.canAddConnection(backOutputConnection) else {
            print("no back audio connection")
            return false
        }
        dualVideoSession.addConnection(backOutputConnection)
        
        // add front output to dual video session
        let frontutputConnection = AVCaptureConnection(inputPorts: [frontAudioPort], output: frontAudioDataOutput)
        guard dualVideoSession.canAddConnection(frontutputConnection) else {
            print("no front audio connection")
            return false
        }
        dualVideoSession.addConnection(frontutputConnection)
        
        return true
    }
    
    func start() {
        dualVideoSessionQueue.async {
            self.dualVideoSession.startRunning()
        }
    }
    
    //MARK:- Add and Handle Observers
    func addNotifer() {
        
        // A session can run only when the app is full screen. It will be interrupted in a multi-app layout.
        // Add observers to handle these session interruptions and inform the user.
                
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: .AVCaptureSessionRuntimeError,object: dualVideoSession)
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: .AVCaptureSessionWasInterrupted, object: dualVideoSession)
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: .AVCaptureSessionInterruptionEnded, object: dualVideoSession)
    }
    
    
    @objc func sessionWasInterrupted(notification: NSNotification) {
            
    }
        
    @objc func sessionInterruptionEnded(notification: NSNotification) {
        
    }
        
    @objc func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        
        /*
        Automatically try to restart the session running if media services were
        reset and the last start running succeeded. Otherwise, enable the user
        to try to resume the session running.
        */
        if error.code == .mediaServicesWereReset {
            
        } else {
           
        }
    }
}


extension CamManager: AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate {

     //MARK:- AVCaptureOutput Delegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){

    }
}

