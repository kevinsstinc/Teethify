//
//  CameraView.swift
//  SparkleTotsTeeth
//
//  Created by Joseph Kevin Fredric on 17/11/25.
//

import SwiftUI
import CoreML
import Vision

struct CameraView: View {
    @State private var isProcessingPhoto = false
    @State private var showSheet = false
    @State private var isLocked = true
    @State private var students: [Student] = []

    @StateObject private var camera = CameraViewModel()

    @State private var showCaptureSheet = false
    @State private var captureType: CaptureType? = nil
    @State private var capturedUIImage: UIImage? = nil
    @State private var capturedTier: String = ""

    enum CaptureType {
        case uncertain
        case lowTier
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
                    .zIndex(-999)  
                Image("teethsilhouette")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250)
                        .opacity(0.15)
                        .allowsHitTesting(false)
                VStack {
                    Spacer()
                    Button {
                        guard !isProcessingPhoto else { return }
                        isProcessingPhoto = true
                        camera.takePhoto()
                    } label: {
                        Circle()
                            .fill(.white.opacity(0.8))
                            .frame(width: 80, height: 80)
                            .overlay(Circle().stroke(.white, lineWidth: 4))
                    }
                    .padding(.bottom, 40)
                    .disabled(isProcessingPhoto)
                    .opacity(isProcessingPhoto ? 0.5 : 1)
                }
            }
            .onAppear {
                camera.start()
                camera.onPhotoCaptured = { img in
                    capturedUIImage = img
                    classifyImage(img)
                }
            }
            .onDisappear { camera.stop() }
            .sheet(isPresented: $showSheet) {
                ListView(isLocked: $isLocked, students: $students)
                    .interactiveDismissDisabled(isLocked)
            }
            .sheet(isPresented: $showCaptureSheet) {
                if let img = capturedUIImage, let type = captureType {
                    switch type {
                    case .uncertain:
                        UncertainView(
                            isLocked: $isLocked,
                            students: $students,
                            takenImage: img,
                            tier: capturedTier
                        )
                        .interactiveDismissDisabled(true)
                        .onDisappear { camera.capturedImage = nil }

                    case .lowTier:
                        LowTierView(
                            isLocked: $isLocked,
                            students: $students,
                            takenImage: img,
                            tier: capturedTier
                        )
                        .interactiveDismissDisabled(true)
                        .onDisappear { camera.capturedImage = nil }
                    }
                }
            }

            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isLocked = true
                        showSheet = true
                    } label: {
                        Label("list", systemImage: "list.bullet")
                            .labelStyle(.iconOnly)
                            .font(.title)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
    private func classifyImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        do {
            let model = try VNCoreMLModel(for: sparkletotsml().model)

            let request = VNCoreMLRequest(model: model) { request, _ in
                guard let result = request.results?.first as? VNClassificationObservation else {
                    return
                }

                DispatchQueue.main.async {
                    let confidence = result.confidence
                    self.capturedTier = "\(result.identifier) (\(Int(confidence * 100))%)"

                    if result.identifier == "Acceptable", confidence >= 0.75 {
                        self.captureType = .lowTier
                    } else {
                        self.captureType = .uncertain
                    }

                    self.isProcessingPhoto = false
                    self.showCaptureSheet = true
                }
            }

            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage)
            try handler.perform([request])

        } catch {
            print("ML classification failed:", error)
        }
    }

}

#Preview {
    CameraView()
}
