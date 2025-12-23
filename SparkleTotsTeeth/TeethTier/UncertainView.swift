//
//  UncertainView.swift
//  SparkleTotsTeeth
//
//  Created by Joseph Kevin Fredric on 19/11/25.
//

import SwiftUI

struct UncertainView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isLocked: Bool
    @Binding var students: [Student]
    
    var takenImage: UIImage
    var tier: String
    
    @State private var name: String = ""
    @State private var showingDiscardAlert = false
    
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
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.black)
                    .font(.title)
            }
            .padding()
            .background(Color.red.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            
            TextField("Enter Full Name", text: $name)
                .foregroundStyle(.black)
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 16) {
                
                Button {
                    showingDiscardAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Discard")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .alert("Are you sure?", isPresented: $showingDiscardAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        dismiss()
                    }
                }
                Button {
                    saveStudent()
                    isLocked = false
                    dismiss()
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
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    private func saveStudent() {
        let student = Student(
            name: name,
            tier: tier,
            image: Image(uiImage: takenImage)
        )
        students.append(student)
    }
}

#Preview {
    UncertainView(
        isLocked: .constant(true),
        students: .constant([]),
        takenImage: UIImage(named: "teeth")!,
        tier: "Not Acceptable"
    )
}
