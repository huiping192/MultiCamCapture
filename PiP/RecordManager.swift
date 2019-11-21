//
//  RecordManager.swift
//  PiP
//
//  Created by Huiping Guo on 2019/11/21.
//  Copyright © 2019 Huiping Guo. All rights reserved.
//

import Foundation
import Photos
import ReplayKit

class RecordManager: NSObject {
    let screenRecorder = RPScreenRecorder.shared()

    var isRecording = false

    var assetWriter:AssetWriter?
    
    weak var viewController: UIViewController!

    
    func configure(viewController: UIViewController?) {
        let outputFileName = NSUUID().uuidString + ".mp4"
        assetWriter = AssetWriter(fileName: outputFileName)
        
        self.viewController = viewController
    }
     
    func handleSingleTap() {
         print("startScreenRecording")
          
         guard screenRecorder.isAvailable else {
             print("Recording is not available at this time.")
             return
         }
         
         if !isRecording {
            // startRecord()
             startCapture()
         }
     }
     
     func handleDoubleTap() {
         print("stopScreenRecording")
         if isRecording{
             // stopRecord()
             stopCapture()
         }
            
     }
     
      //MARK:- ReplayKit
     
     func startRecord(){
     
         screenRecorder.isMicrophoneEnabled = true
         screenRecorder.startRecording{ [unowned self] (error) in
             self.isRecording = true
         }
     }
     
    
     
     func stopRecord(){
         screenRecorder.stopRecording { [unowned self] (preview, error) in
             print("Stopped recording")
             
             guard preview != nil else {
                 print("Preview controller is not available.")
                 return
             }
             
             let alert = UIAlertController(title: "Recording Completed", message: "Would you like to edit or delete your recording?", preferredStyle: .alert)
                 
             let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction) in
                 self.screenRecorder.discardRecording(handler: { () -> Void in
                     print("Recording suffessfully deleted.")
                 })
             })
                 
             let editAction = UIAlertAction(title: "Edit", style: .default, handler: { (action: UIAlertAction) -> Void in
                 preview?.previewControllerDelegate = self as RPPreviewViewControllerDelegate
                self.viewController.present(preview!, animated: true, completion: nil)
             })
                 
             alert.addAction(editAction)
             alert.addAction(deleteAction)
            self.viewController.present(alert, animated: true, completion: nil)
                 
             self.isRecording = false
                         
         }
     }
     
     
    
    func startCapture() {
       screenRecorder.startCapture(handler: { (buffer, bufferType, err) in
            self.isRecording = true
            self.assetWriter!.write(buffer: buffer, bufferType: bufferType)
        }, completionHandler: {
            if let error = $0 {
                print(error)
            }
        })
    }
        
    func stopCapture() {
        screenRecorder.stopCapture {
            self.isRecording = false
            if let err = $0 {
                print(err)
            }
            self.assetWriter?.finishWriting()
        }
    }
    
}


extension RecordManager: RPPreviewViewControllerDelegate {

      func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        viewController.dismiss(animated: true)
      }
      
    
}
