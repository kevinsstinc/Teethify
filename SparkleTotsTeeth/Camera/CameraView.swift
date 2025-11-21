//
//  CameraView.swift
//  SparkleTotsTeeth
//
//  Created by Joseph Kevin Fredric on 17/11/25.
//

import SwiftUI
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
                    if Bool.random() {
                        captureType = .uncertain
                        capturedTier = "Tier 3B"
                    } else {
                        captureType = .lowTier
                        capturedTier = "Tier 1A"
                    }
                    showCaptureSheet = true
                    isProcessingPhoto = false
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
}

#Preview {
    CameraView()
}
