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

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }

        session.addInput(input)

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
                     error: Error?)
    {
        guard let data = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: data)
        else { return }
        capturedImage = uiImage
        onPhotoCaptured?(uiImage)
    }
}

