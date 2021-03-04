//
//  FaceTracker.swift
//  eyeCarousel
//
//  Created by Stone Chen on 3/2/21.
//

import AVFoundation

protocol FaceTrackerDelegate: AnyObject {
    
}

class FaceTracker {
    
    static var isSupported = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                     for: .metadataObject,
                                                     position: .front) != nil
    
    weak var delegate: FaceTrackerDelegate?

}
