//
//  AILogView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

// Wrapper to make NutritionResponse identifiable for sheet presentation
struct IdentifiableNutritionData: Identifiable {
    let id = UUID()
    let data: NutritionResponse
}

enum AIInputMode: String, CaseIterable {
    case text = "Text"
    case photo = "Photo"
}

struct AILogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let date: Date
    @State private var inputMode: AIInputMode? = nil // nil means showing selection
    @State private var foodInput = ""
    @State private var selectedImage: UIImage?
    @State private var photoContext = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPaywall = false
    @State private var showCamera = false
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var parsedNutrition: IdentifiableNutritionData?
    @FocusState private var isTextFieldFocused: Bool
    @FocusState private var isPhotoContextFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Date indicator
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text(date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // Show selection cards or input form
                if inputMode == nil {
                    // Initial selection view - show both options as cards
                    VStack(spacing: 16) {
                        Text("How would you like to log?")
                            .font(.headline)
                            .padding(.top)
                        
                        // Text option card
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                inputMode = .text
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isTextFieldFocused = true
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.blue.gradient)
                                    .frame(width: 60)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Describe with Text")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Type what you ate")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.blue.opacity(0.3), lineWidth: 2)
                            )
                        }
                        
                        // Photo option card
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                inputMode = .photo
                            }
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.purple.gradient)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.yellow)
                                        .offset(x: 20, y: -15)
                                }
                                .frame(width: 60)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Snap a Picture")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Take a photo of your food")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.purple.opacity(0.3), lineWidth: 2)
                            )
                        }
                        
                        Text("Both powered by AI")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Selected mode view
                    VStack(spacing: 16) {
                        // Mode indicator with back button
                        HStack {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    inputMode = nil
                                    errorMessage = nil
                                    foodInput = ""
                                    selectedImage = nil
                                    photoContext = ""
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.caption)
                                    Text("Change method")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(.blue)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Image(systemName: inputMode == .text ? "text.bubble.fill" : "camera.fill")
                                    .foregroundStyle(inputMode == .text ? .blue : .purple)
                                Text(inputMode == .text ? "Text Input" : "Photo Input")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(uiColor: .tertiarySystemBackground))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        // Input area based on mode
                        inputAreaView
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
                
                Spacer()
                
                // Log button (only show when mode is selected)
                if inputMode != nil {
                    Button(action: logFood) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Log with AI")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canLog ? Color.accentColor : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canLog)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Log with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                        isPhotoContextFocused = false
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showCamera) {
                CameraView(selectedImage: $selectedImage)
            }
            .alert("Permission Required", isPresented: $showPermissionAlert) {
                Button("Settings") {
                    openSettings()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(permissionAlertMessage)
            }
            .sheet(item: $parsedNutrition) { wrapper in
                ConfirmAILogView(nutrition: wrapper.data, date: date) {
                    // Dismiss the parent AILogView after logging
                    dismiss()
                }
            }
            .onChange(of: photoPickerItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }
    
    // Separate view for input area to reduce complexity
    @ViewBuilder
    private var inputAreaView: some View {
        VStack(spacing: 12) {
            if inputMode == .text {
                // Text input
                TextEditor(text: $foodInput)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)
                    .overlay(
                        Group {
                            if foodInput.isEmpty {
                                Text("Describe your meal...\ne.g., 3 scrambled eggs and sourdough toast")
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            } else if inputMode == .photo {
                // Photo input
                if let image = selectedImage {
                    VStack(spacing: 12) {
                        // Photo preview
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                        
                        // Optional context input
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add context (optional)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            TextField("e.g., from restaurant, homemade", text: $photoContext)
                                .textFieldStyle(.roundedBorder)
                                .focused($isPhotoContextFocused)
                        }
                        
                        // Change photo button
                        Button {
                            showCamera = true
                        } label: {
                            Label("Change Photo", systemImage: "photo")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    // Photo picker prompt
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.purple.gradient)
                        
                        Text("Take a photo of your food")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            Button {
                                checkCameraPermission()
                            } label: {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Take Photo")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(12)
                            }
                            
                            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Choose from Library")
                                }
                                .font(.headline)
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(inputMode == .photo ? "Analyzing photo..." : "Processing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .padding(.horizontal)
    }
    
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        permissionAlertMessage = "Camera access is required to take photos of your food."
                        showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            permissionAlertMessage = "Camera access was denied. Please enable it in Settings to take photos."
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private var canLog: Bool {
        guard let mode = inputMode else {
            return false
        }
        
        if isLoading {
            return false
        }
        
        switch mode {
        case .text:
            return !foodInput.isEmpty
        case .photo:
            return selectedImage != nil
        }
    }
    
    private func logFood() {
        guard let mode = inputMode else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let nutrition: NutritionResponse
                
                switch mode {
                case .text:
                    guard !foodInput.isEmpty else { return }
                    nutrition = try await OpenAIService.shared.parseFood(foodInput)
                    
                case .photo:
                    guard let image = selectedImage else { return }
                    let context = photoContext.isEmpty ? nil : photoContext
                    nutrition = try await OpenAIService.shared.parseFood(from: image, context: context)
                }
                
                await MainActor.run {
                    isLoading = false
                    parsedNutrition = IdentifiableNutritionData(data: nutrition)
                }
            } catch OpenAIError.rateLimitExceeded {
                await MainActor.run {
                    isLoading = false
                    showPaywall = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Camera View (UIKit Wrapper)

struct CameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ConfirmAILogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let nutrition: NutritionResponse
    let date: Date
    var onLogComplete: (() -> Void)? = nil
    
    @State private var servings = 1.0
    @State private var showingSaveToSavedFoods = false
    @State private var didSaveFood = false
    @FocusState private var isServingsFocused: Bool
    
    private var calculatedValues: (calories: Int, protein: Double, carbs: Double, fat: Double) {
        (
            calories: Int(Double(nutrition.calories) * servings),
            protein: nutrition.protein * servings,
            carbs: nutrition.carbs * servings,
            fat: nutrition.fat * servings
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nutrition.foodName)
                            .font(.headline)
                        Text("From AI")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    HStack {
                        Text("How many servings?")
                        Spacer()
                        
                        // Interactive servings control
                        HStack(spacing: 8) {
                            TextField("1.0", value: $servings, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                                .focused($isServingsFocused)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1.5)
                                )
                            
                            Image(systemName: "pencil.circle.fill")
                                .foregroundStyle(.secondary)
                                .imageScale(.medium)
                        }
                        .onTapGesture {
                            isServingsFocused = true
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Stepper("Adjust servings", value: $servings, in: 0.1...20, step: 0.5)
                            .labelsHidden()
                    }
                } header: {
                    Text("Servings")
                } footer: {
                    Text("Tap the number to type, or use +/- buttons to adjust")
                }
                
                Section {
                    VStack(spacing: 16) {
                        // Calories
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("Calories")
                                .font(.headline)
                            Spacer()
                            Text("\(calculatedValues.calories)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Divider()
                        
                        // Macros with circles
                        HStack(spacing: 20) {
                            MacroCircle(
                                name: "Protein",
                                value: calculatedValues.protein,
                                color: .red
                            )
                            
                            MacroCircle(
                                name: "Carbs",
                                value: calculatedValues.carbs,
                                color: .blue
                            )
                            
                            MacroCircle(
                                name: "Fat",
                                value: calculatedValues.fat,
                                color: .yellow
                            )
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Total Nutrition")
                }
                
                Section {
                    Button {
                        showingSaveToSavedFoods = true
                    } label: {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("Add to Saved Foods")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    if didSaveFood {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Saved for quick logging later!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Save this food for quick logging without AI in the future.")
                }
            }
            .navigationTitle("Confirm Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isServingsFocused = false
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        logFood()
                    }
                }
            }
            .sheet(isPresented: $showingSaveToSavedFoods) {
                SaveToSavedFoodsView(
                    foodName: nutrition.foodName,
                    calories: nutrition.calories,
                    protein: nutrition.protein,
                    carbs: nutrition.carbs,
                    fat: nutrition.fat,
                    didSave: $didSaveFood
                )
            }
        }
    }
    
    private func logFood() {
        // Use current time instead of midnight
        let now = Date()
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
        
        var finalComponents = DateComponents()
        finalComponents.year = dateComponents.year
        finalComponents.month = dateComponents.month
        finalComponents.day = dateComponents.day
        finalComponents.hour = timeComponents.hour
        finalComponents.minute = timeComponents.minute
        finalComponents.second = timeComponents.second
        
        let timestamp = calendar.date(from: finalComponents) ?? now
        
        let entry = FoodEntry(
            foodName: nutrition.foodName,
            calories: calculatedValues.calories,
            protein: calculatedValues.protein,
            carbs: calculatedValues.carbs,
            fat: calculatedValues.fat,
            servings: servings,
            timestamp: timestamp
        )
        
        modelContext.insert(entry)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
        onLogComplete?()
    }
}

struct SaveToSavedFoodsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let foodName: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    
    @Binding var didSave: Bool
    
    @State private var servingSize = "1"
    @State private var unit = "unit"
    
    private var isValid: Bool {
        Double(servingSize) != nil && !unit.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Name") {
                    Text(foodName)
                        .font(.body)
                }
                
                Section {
                    HStack {
                        TextField("Serving Size", text: $servingSize)
                            .keyboardType(.decimalPad)
                        
                        TextField("Unit", text: $unit)
                            .frame(width: 100)
                    }
                } header: {
                    Text("Serving Size")
                } footer: {
                    Text("Define 1 serving. You can adjust the number of servings when logging.")
                }
                
                Section("Nutrition (per serving)") {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                        Text("Calories")
                        Spacer()
                        Text("\(calories)")
                            .fontWeight(.semibold)
                        Text("cal")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.red)
                            .frame(width: 24)
                        Text("Protein")
                        Spacer()
                        Text("\(protein, specifier: "%.1f")")
                            .fontWeight(.semibold)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        Text("Carbs")
                        Spacer()
                        Text("\(carbs, specifier: "%.1f")")
                            .fontWeight(.semibold)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.yellow)
                            .frame(width: 24)
                        Text("Fat")
                        Spacer()
                        Text("\(fat, specifier: "%.1f")")
                            .fontWeight(.semibold)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Save to Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFood()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveFood() {
        guard let servingSizeValue = Double(servingSize) else { return }
        
        let food = SavedFood(
            foodName: foodName,
            servingSize: servingSizeValue,
            unit: unit,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
        
        modelContext.insert(food)
        didSave = true
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
    }
}

#Preview {
    AILogView(date: Date())
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
