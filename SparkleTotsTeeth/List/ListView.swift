//
//  ListView.swift
//  SparkleTotsTeeth
//
//  Created by Joseph Kevin Fredric on 17/11/25.
//
import SwiftUI
import PDFKit

struct Student: Identifiable {
    var id = UUID()
    var name: String
    var tier: String
    var image: Image
}

struct ListView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isLocked: Bool
    @Binding var students: [Student]
    @State private var taskIsComplete = false
    @State private var showAlert = false
    @State private var isEditing = false
    @State private var selectedStudents: Set<UUID> = []
    @State private var showingConfirmation = false
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                ScrollView {
                    if students.isEmpty {
                        ContentUnavailableView(
                            "No Students",
                            systemImage: "person.fill.questionmark",
                            description: Text("Scan a student to begin.")
                        ).foregroundStyle(.black).font(.largeTitle)
                        
                    } else {
                        VStack {
                            content()
                        }
                        .padding(.bottom, 70)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !isEditing {
                        Button {
                            if students.isEmpty {
                                isLocked = false
                                dismiss()
                            } else {
                                showAlert = true
                                taskIsComplete = true
                            }
                            showAlert = true
                            taskIsComplete = true
                            
                        } label: {
                            Label("xmark", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                                .font(.title)
                                .foregroundStyle(.blue)
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                        }
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .sensoryFeedback(.success, trigger: taskIsComplete)
                        .buttonBorderShape(.circle)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        guard !students.isEmpty else {
                            return
                        }
                        isEditing.toggle()
                        taskIsComplete = true
                        if !isEditing {
                            selectedStudents.removeAll()
                            taskIsComplete = true
                        }
                    } label: {
                        Label(isEditing ? "Cancel" : "Edit", systemImage: "pencil")
                            .labelStyle(.iconOnly)
                            .font(.title)
                            .foregroundStyle(.blue)
                            .padding(.vertical, 10)
                            .padding(.horizontal)
                    }
                    .disabled(students.isEmpty)
                    .opacity(students.isEmpty ? 0.4 : 1)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .sensoryFeedback(.success, trigger: taskIsComplete)
                    .buttonBorderShape(.circle)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button(role: .destructive) {
                            taskIsComplete = true
                            showingConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .disabled(selectedStudents.isEmpty)
                        .sensoryFeedback(.success, trigger: taskIsComplete)
                        .font(.title2)
                        .foregroundStyle(.red)
                        
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    
                    ShareLink("Export As PDF", item: render())
                        .bold()
                        .sensoryFeedback(.success, trigger: taskIsComplete)
                        .font(.title)
                        .padding(40)
                        .foregroundStyle(.white)
                        .buttonStyle(.glassProminent)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                        .disabled(isEditing)
                        .disabled(students.isEmpty)
                    
                }
                
                
            }
        }
        .alert("Are you sure?", isPresented: $showingConfirmation) {
            Button("Delete all", role: .destructive) {
                deleteSelected()
            }
            Button("Cancel", role: .cancel) {
                selectedStudents.removeAll()
            }
        } message: {
            Text("Deleting this data is irreversible.")
        }
        
        .alert("Are you sure?", isPresented: Binding(
            get: { showAlert && !students.isEmpty },
            set: { showAlert = $0 }
        )) {
            Button("Delete Data", role: .destructive) {
                students.removeAll()
                isLocked = false
                dismiss()
            }
            Button("Keep Scanning", role: .cancel) {
                isLocked = false
                dismiss()
            }
        } message: {
            Text("You may lose ALL your data if you delete it.")
                .multilineTextAlignment(.center)
        }
        
    }
    
    @ViewBuilder
    private func content() -> some View {
        ForEach(students) { student in
            HStack(alignment: .top) {
                if isEditing {
                    Button {
                        toggleSelection(for: student)
                    } label: {
                        Image(systemName: selectedStudents.contains(student.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .padding(.leading, 30)
                    }
                }
                
                VStack(alignment: .center) {
                    ZStack {
                        VStack(alignment: .center) {
                            HStack {
                                student.image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 350)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .padding()
                                Spacer()
                               
                            }
                            HStack {
                                Text(student.name)
                                    .font(.title)
                                    .foregroundColor(.blue)
                                    .padding(.leading)
                                    .bold()
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            HStack {
                                Text(student.tier)
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .padding(.leading)
                                    .padding(.bottom)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                        }
                       
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)
                        
                    }
                }
            }
            .padding()
        }
    }
    
    private func toggleSelection(for student: Student) {
        if selectedStudents.contains(student.id) {
            selectedStudents.remove(student.id)
        } else {
            selectedStudents.insert(student.id)
        }
    }
    
    private func deleteSelected() {
        students.removeAll { selectedStudents.contains($0.id) }
        selectedStudents.removeAll()
        isEditing = false
    }
    
    private func render() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        let renderer = ImageRenderer(content:
                                        content()
            .environment(\.editMode, .constant(.inactive))
        )
        let url = URL.documentsDirectory.appending(path: "Student Teeth Health \(timestamp).pdf")
        
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        
        return url
    }
    
    
}
