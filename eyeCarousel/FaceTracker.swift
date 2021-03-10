//
//  FaceTracker.swift
//  eyeCarousel
//
//  Created by Stone Chen on 3/2/21.
//

import AVFoundation

enum FaceTrackerError: Error {
    case notAuthorized // App does not have permission to use user's camera
    case configurationError
    case runtimeError(Error)
    case unknown
}

enum SessionSetupResult {
    case success
    case notAuthorized
    case configurationFailed
}

protocol FaceTrackerDelegate: AnyObject {
    
    // Come back to this to see if we want facetracker as an argument
    func faceTracker(_ tracker: FaceTracker, didFailWithError error: Error)
    func faceTrackerWasInterrupted(_ tracker: FaceTracker)
    func faceTrackerInterruptionEnded(_ tracker: FaceTracker)
    func faceTrackerDidStartDetectingFace(_ tracker: FaceTracker)
    func faceTrackerDidEndDetectingFace(_ tracker: FaceTracker)
}

class FaceTracker: NSObject {
    
    static var isSupported = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                     for: .metadataObject,
                                                     position: .front) != nil
    
    weak var delegate: FaceTrackerDelegate?
    var faceDetected = false
    
    let session = AVCaptureSession()
    var setupResult: SessionSetupResult = .success
    let sessionQueue = DispatchQueue(label: "sessionQueue")
    let dataOutputQueue = DispatchQueue(label: "dataOutputQueue")
    
    override init() {
        super.init()
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            self.sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            break
        case .authorized:
            self.setupResult = .success
            break
        default:
            self.setupResult = .notAuthorized
            break
        }
        
        //if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
        self.sessionQueue.async {
            self.configureSession()
        }
    }
        
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError),
                                               name: .AVCaptureSessionRuntimeError, object: self.session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted),
                                               name: .AVCaptureSessionWasInterrupted, object: self.session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded),
                                               name: .AVCaptureSessionInterruptionEnded, object: self.session)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func configureSession() {
        if self.setupResult != .success {
            return
        }
        guard let deviceInput = try? AVCaptureDevice.default(.builtInWideAngleCamera, for: .metadataObject, position: .front).map(AVCaptureDeviceInput.init(device:)),
              self.session.canAddInput(deviceInput) else {
            return
        }

        self.session.beginConfiguration()
        self.session.sessionPreset = .low
        self.session.addInput(deviceInput)

        let metadataOutput = AVCaptureMetadataOutput()
        self.session.addOutput(metadataOutput)
        
        if metadataOutput.availableMetadataObjectTypes.contains(.face) {
            metadataOutput.metadataObjectTypes = [.face]
        }

        metadataOutput.setMetadataObjectsDelegate(self, queue: self.dataOutputQueue)
        self.session.commitConfiguration()
    }
    
    func resume() {
        self.sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.addObservers()
                
            case .notAuthorized:
                self.delegate?.faceTracker(self, didFailWithError: FaceTrackerError.notAuthorized)
                
            case .configurationFailed:
                self.delegate?.faceTracker(self, didFailWithError: FaceTrackerError.configurationError)
            }
        }
    }
    
    func pause() {
        self.sessionQueue.async {
            self.session.stopRunning()
            self.removeObservers()
        }
    }
    
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? Error else {
            self.delegate?.faceTracker(self, didFailWithError: FaceTrackerError.unknown)
            return
        }
        
        self.delegate?.faceTracker(self, didFailWithError: FaceTrackerError.runtimeError(error))
    }
    
    @objc
    func sessionWasInterrupted(notification: NSNotification) {
        self.delegate?.faceTrackerWasInterrupted(self)
    }
    
    @objc
    func sessionInterruptionEnded(notification: NSNotification) {
        self.delegate?.faceTrackerInterruptionEnded(self)
    }

}

extension FaceTracker: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        let isFaceDetected = metadataObjects.contains(where: { $0.type == .face })
        
        print(isFaceDetected)
        
        if isFaceDetected && !self.faceDetected {
            self.faceDetected = true
            self.delegate?.faceTrackerDidStartDetectingFace(self)
        } else if !isFaceDetected && self.faceDetected {
            self.faceDetected = false
            self.delegate?.faceTrackerDidEndDetectingFace(self)
        }
    }
}
