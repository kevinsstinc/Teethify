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
    @State private var detectedBoxes: [VNRecognizedObjectObservation] = []
    
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
                    .rotationEffect(.degrees(90)) // rotate silhouette
                
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
                    let rotated = img.rotated90CounterClockwise()
                    capturedUIImage = rotated
                    classifyImage(rotated)
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
            let model = try VNCoreMLModel(for: Sparkle().model)
            let request = VNCoreMLRequest(model: model) { request, _ in
                let detections = request.results as? [VNRecognizedObjectObservation] ?? []
                self.detectedBoxes = detections

                let debugImage = drawBoundingBoxes(on: image, observations: detections)
                self.capturedUIImage = debugImage

                DispatchQueue.main.async {
                    if detections.count > 0 {
                        self.capturedTier = "Not Acceptable (Detections: \(detections.count))"
                        self.captureType = .uncertain
                    } else {
                        self.capturedTier = "Acceptable"
                        self.captureType = .lowTier
                    }

                    self.isProcessingPhoto = false
                    self.showCaptureSheet = true
                }
            }

            request.imageCropAndScaleOption = .scaleFill
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try handler.perform([request])

        } catch {
            print("ML object detection failed:", error)
            self.isProcessingPhoto = false
        }
    }

    private func drawBoundingBoxes(
        on image: UIImage,
        observations: [VNRecognizedObjectObservation]
    ) -> UIImage {

        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { ctx in
            image.draw(at: .zero)
            ctx.cgContext.setStrokeColor(UIColor.red.cgColor)
            ctx.cgContext.setLineWidth(4)
            
            for obs in observations {
                let rect = VNImageRectForNormalizedRect(
                    obs.boundingBox,
                    Int(image.size.width),
                    Int(image.size.height)
                )
                ctx.cgContext.stroke(rect)

                // Confidence text
                let text = String(format: "%.0f%%", obs.confidence * 100)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 20),
                    .foregroundColor: UIColor.red
                ]
                text.draw(at: CGPoint(x: rect.minX, y: rect.minY - 22), withAttributes: attrs)
            }
        }
    }
}

extension UIImage {
    func rotated90CounterClockwise() -> UIImage {
        guard let cgImage = self.cgImage else { return self }
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: .right)
    }
}

#Preview {
    CameraView()
}

