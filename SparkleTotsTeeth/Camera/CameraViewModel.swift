//
//  CameraViewModel.swift
//  SparkleTotsTeeth
//
//  Created by Joseph Kevin Fredric on 19/11/25.
//

import AVFoundation
import SwiftUI
import Combine

@MainActor
class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedImage: UIImage?
    var onPhotoCaptured: ((UIImage) -> Void)?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()

    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: cameraDevice),
              session.canAddInput(input) else { return }

        session.addInput(input)

        do {
            try cameraDevice.lockForConfiguration()
            if cameraDevice.isFocusPointOfInterestSupported {
                cameraDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            }
            if cameraDevice.isFocusModeSupported(.autoFocus) {
                cameraDevice.focusMode = .autoFocus
            }
            if cameraDevice.isFocusModeSupported(.continuousAutoFocus) {
                cameraDevice.focusMode = .continuousAutoFocus
            }
            if cameraDevice.isAutoFocusRangeRestrictionSupported {
                cameraDevice.autoFocusRangeRestriction = .near
            }

            cameraDevice.unlockForConfiguration()
        } catch {
            print("Failed to set focus modes:", error)
        }


        guard session.canAddOutput(photoOutput) else { return }
        session.addOutput(photoOutput)

        session.commitConfiguration()
    }

    func start() {
        if !session.isRunning {
            session.startRunning()
        }
    }

    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: data) else { return }
        capturedImage = uiImage
        onPhotoCaptured?(uiImage)
    }
}
