//
//  LowTierView.swift
//  SparkleTotsTeeth
//
//  Created by Joseph Kevin Fredric on 19/11/25.
//

import SwiftUI

struct LowTierView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isLocked: Bool
    @Binding var students: [Student]
    
    var takenImage: UIImage
    var tier: String
    
    @State private var taskIsComplete = false
    
    var body: some View {
        VStack(spacing: 20) {
            
            Image(uiImage: takenImage)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 6)
                .padding(.top)
            
            HStack {
                Text(tier)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.black)
                
                Spacer()
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                    .font(.title)
            }
            .padding()
            .background(Color.green.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                isLocked = false
                dismiss()
                taskIsComplete = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Done")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            .padding(.horizontal)
            .padding(.bottom, 20)
            .sensoryFeedback(.success, trigger: taskIsComplete)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    LowTierView(
        isLocked: .constant(true),
        students: .constant([]),
        takenImage: UIImage(named: "teeth")!,
        tier: "Acceptable"
    )
}

