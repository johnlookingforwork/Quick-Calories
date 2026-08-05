//
//  SettingsView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var foodEntries: [FoodEntry]
    @Query(sort: \WorkoutEntry.timestamp, order: .reverse) private var workoutEntries: [WorkoutEntry]
    
    @State private var calorieTarget = 2000
    @State private var proteinTarget = 150.0
    @State private var carbsTarget = 200.0
    @State private var fatTarget = 67.0
    @State private var dietMode: DietMode = .normal
    @State private var showTargetSetup = false
    @State private var showRecalculateConfirmation = false
    @State private var showPaywall = false
    @State private var showDeveloperConfig = false
    @State private var showDataSources = false
    @State private var versionTapCount = 0
    
    private var settings = SettingsManager.shared
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        Form {
            Section {
                // Display current targets
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("\(calorieTarget)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text("calories per day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 20) {
                        MacroTargetBadge(name: "Protein", amount: proteinTarget, color: .red)
                        MacroTargetBadge(name: "Carbs", amount: carbsTarget, color: .blue)
                        MacroTargetBadge(name: "Fat", amount: fatTarget, color: .yellow)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                
                Button {
                    showTargetSetup = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Edit Targets")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if settings.hasProfileData {
                    Button {
                        showRecalculateConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Recalculate from Profile", systemImage: "arrow.clockwise")
                            Spacer()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } header: {
                Text("Daily Targets")
            } footer: {
                if settings.hasProfileData {
                    Text("Based on your profile: \(settings.userAge) years old, \(settings.useMetricSystem ? String(format: "%.0f kg", settings.userWeight) : String(format: "%.0f lbs", settings.userWeight.kgToLbs))")
                }
            }
            
            Section {
                Picker("Mode", selection: $dietMode) {
                    ForEach(DietMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Diet Mode")
            } footer: {
                switch dietMode {
                case .normal:
                    Text("Normal: within ±10% of your calorie target is acceptable.")
                case .bulk:
                    Text("Bulk: you need to eat at least your calorie target. Red if under by more than 10%.")
                case .cut:
                    Text("Cut: stay at or under your calorie target. Red if over by more than 10%.")
                }
            }

            // Profile section (if exists)
            if settings.hasProfileData {
                Section("Your Profile") {
                    HStack {
                        Text("Age")
                        Spacer()
                        Text("\(settings.userAge) years")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        if settings.useMetricSystem {
                            Text(String(format: "%.0f kg", settings.userWeight))
                                .foregroundStyle(.secondary)
                        } else {
                            Text(String(format: "%.0f lbs", settings.userWeight.kgToLbs))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        if settings.useMetricSystem {
                            Text(String(format: "%.0f cm", settings.userHeight))
                                .foregroundStyle(.secondary)
                        } else {
                            Text(String(format: "%.0f in", settings.userHeight.cmToInches))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Activity Level")
                        Spacer()
                        Text(settings.activityLevel)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Goal")
                        Spacer()
                        Text(settings.goalType)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // API Key Status (read-only display)
            Section {
                if let apiKey = settings.openAIApiKey, !apiKey.isEmpty {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundStyle(.blue)
                        Text("Using Your Own API Key")
                        Spacer()
                        Text("Unlimited")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("Remove API Key", role: .destructive) {
                        SettingsManager.shared.openAIApiKey = nil
                    }
                } else if settings.hasActiveSubscription {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Active Subscription")
                        Spacer()
                        Text("Unlimited")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Free Plan")
                            Spacer()
                            Text("\(SettingsManager.shared.dailyAIRequestCount) / 1")
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "bolt.circle.fill")
                                Text("Upgrade to Unlimited")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } header: {
                Text("AI Access")
            } footer: {
                if settings.openAIApiKey != nil {
                    Text("You have unlimited AI requests. You will be billed directly by OpenAI for usage.")
                } else {
                    Text("Subscribe for unlimited AI requests, or use your own OpenAI API key")
                }
            }
            
            Section("Data Management") {
                ShareLink(
                    item: CSVExporter(foodEntries: foodEntries, workoutEntries: workoutEntries),
                    preview: SharePreview("QuickCalories Export", image: Image(systemName: "tablecells"))
                ) {
                    Label("Export Logs to CSV", systemImage: "square.and.arrow.up")
                }
            }
            
            Section("About") {
                Button {
                    showDataSources = true
                } label: {
                    HStack {
                        Label("Data Sources & Citations", systemImage: "doc.text.magnifyingglass")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
                
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    versionTapCount += 1
                    if versionTapCount >= 7 {
                        showDeveloperConfig = true
                        versionTapCount = 0
                    }
                }
                
                Link("Privacy Policy", destination: URL(string: "https://www.quickcaloriesapp.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://www.quickcaloriesapp.com/terms")!)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTargetSetup) {
            CalorieTargetSetupView(
                dailyCalorieTarget: $calorieTarget,
                proteinTarget: $proteinTarget,
                carbsTarget: $carbsTarget,
                fatTarget: $fatTarget,
                isOnboarding: false
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showDeveloperConfig) {
            DeveloperConfigView()
        }
        .sheet(isPresented: $showDataSources) {
            DataSourcesView()
        }
        .confirmationDialog(
            "Recalculate Targets",
            isPresented: $showRecalculateConfirmation,
            titleVisibility: .visible
        ) {
            Button("Recalculate") {
                recalculateTargets()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will update your daily targets based on your saved profile information.")
        }
        .task {
            loadSettings()
        }
        .onChange(of: calorieTarget) { _, newValue in
            SettingsManager.shared.dailyCalorieTarget = newValue
        }
        .onChange(of: proteinTarget) { _, newValue in
            SettingsManager.shared.proteinTarget = newValue
        }
        .onChange(of: carbsTarget) { _, newValue in
            SettingsManager.shared.carbsTarget = newValue
        }
        .onChange(of: fatTarget) { _, newValue in
            SettingsManager.shared.fatTarget = newValue
        }
        .onChange(of: dietMode) { _, newValue in
            SettingsManager.shared.dietMode = newValue
        }
    }
    
    private func loadSettings() {
        let settings = SettingsManager.shared
        calorieTarget = settings.dailyCalorieTarget
        proteinTarget = settings.proteinTarget
        carbsTarget = settings.carbsTarget
        fatTarget = settings.fatTarget
        dietMode = settings.dietMode
    }
    
    private func recalculateTargets() {
        SettingsManager.shared.recalculateFromProfile()
        loadSettings()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct MacroTargetBadge: View {
    let name: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Text("\(Int(amount))g")
                .font(.headline)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct APIKeyInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Why provide your own API key?")
                        .font(.headline)
                    
                    Text("QuickCalories uses OpenAI's GPT-4o-mini model to convert natural language into nutritional data. The free tier includes 1 AI request per day.")
                        .font(.body)
                    
                    Text("If you have your own OpenAI API key, you can:")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Make unlimited AI log requests", systemImage: "checkmark.circle.fill")
                        Label("Pay only for what you use (typically < $0.01 per request)", systemImage: "checkmark.circle.fill")
                        Label("Bypass in-app subscription", systemImage: "checkmark.circle.fill")
                    }
                    .font(.body)
                    
                    Divider()
                    
                    Text("How to get an API key:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Visit platform.openai.com")
                        Text("2. Create an account or sign in")
                        Text("3. Navigate to API Keys")
                        Text("4. Create a new secret key")
                        Text("5. Copy and paste it above")
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                    
                    Text("⚠️ Keep your API key secure. Never share it publicly.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.top)
                }
                .padding()
            }
            .navigationTitle("API Key Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: [FoodEntry.self, WorkoutEntry.self], inMemory: true)
    }
}

// Lazy CSV Transferable Document
struct CSVExporter: Transferable {
    let foodEntries: [FoodEntry]
    let workoutEntries: [WorkoutEntry]
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { exporter in
            let csvText = exporter.generateCSV()
            return Data(csvText.utf8)
        }
        .suggestedFileName { _ in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateStr = formatter.string(from: Date())
            return "QuickCalories_Export_\(dateStr).csv"
        }
    }
    
    private func generateCSV() -> String {
        var csv = "Date,Type,Name,Calories Consumed,Calories Burned,Protein (g),Carbs (g),Fat (g),Servings\n"
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        struct ExportableItem: Comparable {
            let date: Date
            let type: String
            let name: String
            let caloriesConsumed: Int
            let caloriesBurned: Int
            let protein: Double
            let carbs: Double
            let fat: Double
            let servings: Double
            
            static func < (lhs: ExportableItem, rhs: ExportableItem) -> Bool {
                lhs.date < rhs.date
            }
        }
        
        var items: [ExportableItem] = []
        for food in foodEntries {
            items.append(ExportableItem(
                date: food.timestamp,
                type: "Food",
                name: food.foodName,
                caloriesConsumed: food.calories,
                caloriesBurned: 0,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                servings: food.servings
            ))
        }
        for workout in workoutEntries {
            items.append(ExportableItem(
                date: workout.timestamp,
                type: "Workout",
                name: workout.workoutName,
                caloriesConsumed: 0,
                caloriesBurned: workout.caloriesBurned,
                protein: 0,
                carbs: 0,
                fat: 0,
                servings: 0
            ))
        }
        
        items.sort()
        
        for item in items {
            let dateStr = displayFormatter.string(from: item.date)
            let escapedName = item.name.replacingOccurrences(of: "\"", with: "\"\"")
            let row = "\"\(dateStr)\",\"\(item.type)\",\"\(escapedName)\",\(item.caloriesConsumed),\(item.caloriesBurned),\(item.protein),\(item.carbs),\(item.fat),\(item.servings)\n"
            csv.append(row)
        }
        
        return csv
    }
}
