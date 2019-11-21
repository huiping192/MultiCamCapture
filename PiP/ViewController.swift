//
//  ViewController.swift
//  SODualCamera
//
//  Created by SOTSYS207 on 05/08/19.
//  Copyright © 2019 SOTSYS207. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureAudioDataOutputSampleBufferDelegate{

    @IBOutlet weak var frontPreview: ViewPreview!
    var frontViewLayer:AVCaptureVideoPreviewLayer?

    
    @IBOutlet weak var backPreview1: ViewPreview!
    var backViewLayer1:AVCaptureVideoPreviewLayer?
    
    @IBOutlet weak var backPreview2: ViewPreview!
    var backViewLayer2:AVCaptureVideoPreviewLayer?
    
    
    @IBOutlet weak var backPreview3: ViewPreview!
    var backViewLayer3:AVCaptureVideoPreviewLayer?
    
    let camManager = CamManager()
    let recordManager = RecordManager()
   
    //MARK:- View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUp()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if targetEnvironment(simulator)
          let alertController = UIAlertController(title: "SODualCamera", message: "Please run on physical device", preferredStyle: .alert)
          alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
          self.present(alertController, animated: true, completion: nil)
          return
        #endif
    }
    
    
    //MARK:- User Permission for Dual Video Session

    //ask user permissin for recording video from device
    func dualVideoPermisson(){
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                // The user has previously granted access to the camera.
                configureDualVideo()
                break
                
            case .notDetermined:
                
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if granted{
                        self.configureDualVideo()
                    }
                })
                
                break
                
            default:
                // The user has previously denied access.
            DispatchQueue.main.async {
                let changePrivacySetting = "Device doesn't have permission to use the camera, please change privacy settings"
                let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                alertController.addAction(UIAlertAction(title: "Settings", style: .`default`,handler: { _ in
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL,  options: [:], completionHandler: nil)
                    }
                }))
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    func configureDualVideo() {
        camManager.configureDualVideo(viewController: self) { [weak self] in
            guard let self = self else { return }
            
            guard self.camManager.setUpCamera(type: .builtInWideAngleCamera, position: .front, outputViewlayer: self.frontViewLayer!) else{
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "issue while setuping front camera", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
            
            guard self.camManager.setUpCamera(type: .builtInWideAngleCamera, position: .back, outputViewlayer: self.backViewLayer1!) else{
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "issue while setuping back camera", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
            
            guard self.camManager.setUpCamera(type: .builtInUltraWideCamera, position: .back, outputViewlayer: self.backViewLayer2!) else{
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "issue while setuping back ultra wide camera", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
            
//            guard self.camManager.setUpCamera(type: .builtInWideAngleCamera, position: .front, outputViewlayer: self.frontViewLayer!) else{
//                DispatchQueue.main.async {
//                    let alertController = UIAlertController(title: "Error", message: "issue while setuping front camera", preferredStyle: .alert)
//                    alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
//                    self.present(alertController, animated: true, completion: nil)
//                }
//                return
//            }
        }
    }
    

    //MARK:- Setup Dual Video Session

    
    func setUp(){
        #if targetEnvironment(simulator)
            return
        #endif
        
        // Store the back and front video preview layers so we can connect them to their inputs
        frontViewLayer = frontPreview.videoPreviewLayer
        backViewLayer1 = backPreview1.videoPreviewLayer
        backViewLayer2 = backPreview2.videoPreviewLayer
        backViewLayer3 = backPreview3.videoPreviewLayer

        // Keep the screen awake
        UIApplication.shared.isIdleTimerDisabled = true
        
        dualVideoPermisson()
        
        addGestures()
        
        recordManager.configure(viewController: self)
    }
                    
     //MARK:- Add Gestures and Handle Gesture Response
    
    func addGestures(){
        
        //add gesture single tap
        let tapSingle = UITapGestureRecognizer(target: self, action: #selector(self.handleSingleTap(_:)))
        tapSingle.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapSingle)
        
        //add gesture double tap

        let tapDouble = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTap(_:)))
        tapDouble.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(tapDouble)
        
        //ask single tap detect onserver to wait for double tap gesture
        tapSingle.require(toFail: tapDouble)
    }
    
    
    @objc func handleSingleTap(_ sender: UITapGestureRecognizer) {
        recordManager.handleSingleTap()
    }
    
    @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        recordManager.handleDoubleTap()
    }

}

