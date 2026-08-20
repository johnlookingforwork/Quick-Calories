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
    @Query(sort: \DailyTargetLog.date, order: .reverse) private var targetLogs: [DailyTargetLog]
    
    @State private var weightHistory: [Date: Double] = [:]
    
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
    @State private var showAPIKeySetup = false
    @State private var showWeightGoalSetup = false
    @State private var versionTapCount = 0
    @State private var weightAverageDays = 5
    
    private var healthKitManager = HealthKitManager.shared
    private var settings = SettingsManager.shared
    
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "1.0.0"
    }
    
    var body: some View {
        Form {
            // Your Plan Section (Calorie Target Card + Summary Rows)
            Section("Your Plan") {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("\(calorieTarget)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("daily calorie target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 12) {
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
                        Label("Adjust Calories & Macros", systemImage: "slider.horizontal.3")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                
                // Profile summary row
                Button {
                    showTargetSetup = true
                } label: {
                    HStack {
                        Text("Personal Profile")
                            .foregroundStyle(.primary)
                        Spacer()
                        if settings.hasProfileData {
                            Text("\(settings.userAge)y, \(settings.useMetricSystem ? String(format: "%.0f cm", settings.userHeight) : String(format: "%.0f in", settings.userHeight.cmToInches))")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Set Up Profile")
                                .foregroundStyle(.blue)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                // Weight Goal summary row
                Button {
                    showWeightGoalSetup = true
                } label: {
                    HStack {
                        Text("Weight Goal")
                            .foregroundStyle(.primary)
                        Spacer()
                        if settings.targetWeight > 0 {
                            let startStr = settings.useMetricSystem ? String(format: "%.1f kg", settings.startWeight) : String(format: "%.1f lbs", settings.startWeight.kgToLbs)
                            let targetStr = settings.useMetricSystem ? String(format: "%.1f kg", settings.targetWeight) : String(format: "%.1f lbs", settings.targetWeight.kgToLbs)
                            Text("\(startStr) → \(targetStr)")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Set Up Weight Goal")
                                .foregroundStyle(.blue)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            
            // Preferences Section
            Section("Preferences") {
                Picker("Diet Mode", selection: $dietMode) {
                    ForEach(DietMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                
                Picker("Weight Goal Avg", selection: $weightAverageDays) {
                    Text("3-Day Average").tag(3)
                    Text("5-Day Average").tag(5)
                    Text("7-Day Average").tag(7)
                }
                
                Picker("Metabolic Window", selection: Binding(
                    get: { settings.metabolicWindowDays },
                    set: { newValue in
                        settings.metabolicWindowDays = newValue
                        settings.updateAdaptiveCalorieTarget(allEntries: foodEntries)
                        loadSettings()
                    }
                )) {
                    Text("7 Days").tag(7)
                    Text("30 Days").tag(30)
                }
                
                Toggle("Use Metric System", isOn: Binding(
                    get: { settings.useMetricSystem },
                    set: { newValue in
                        settings.useMetricSystem = newValue
                        settings.recalculateFromProfile()
                        loadSettings()
                    }
                ))
            }
            
            // Integrations & Access Section
            Section("Integrations & Access") {
                // Apple Health Sync Row
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                    Text("Apple Health Sync")
                    Spacer()
                    if healthKitManager.isAuthorized {
                        Text("Connected")
                            .foregroundStyle(.green)
                            .fontWeight(.medium)
                    } else {
                        Button("Connect") {
                            healthKitManager.requestPermission { _ in
                                loadSettings()
                            }
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .font(.caption)
                        .fontWeight(.bold)
                    }
                }
                
                // AI Assistant Access Row
                Button {
                    if let _ = settings.openAIApiKey {
                        showAPIKeySetup = true
                    } else if settings.hasActiveSubscription {
                        showPaywall = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        Text("AI Assistant Access")
                            .foregroundStyle(.primary)
                        Spacer()
                        if let apiKey = settings.openAIApiKey, !apiKey.isEmpty {
                            Text("Custom API Key")
                                .foregroundStyle(.secondary)
                        } else if settings.hasActiveSubscription {
                            Text("Unlimited (Premium)")
                                .foregroundStyle(.green)
                        } else {
                            Text("Free Plan (1 daily)")
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                if let apiKey = settings.openAIApiKey, !apiKey.isEmpty {
                    Button("Remove Custom API Key", role: .destructive) {
                        settings.openAIApiKey = nil
                        loadSettings()
                    }
                }
            }
            
            // Data Management Section
            Section("Data Management") {
                ShareLink(
                    item: CSVExporter(
                        foodEntries: foodEntries,
                        workoutEntries: workoutEntries,
                        targetLogs: targetLogs,
                        weightHistory: weightHistory,
                        useMetric: settings.useMetricSystem
                    ),
                    preview: SharePreview("QuickCalories Export", image: Image(systemName: "tablecells"))
                ) {
                    Label("Export Logs to CSV", systemImage: "square.and.arrow.up")
                }
            }
            
            // About Section
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
        .sheet(isPresented: $showAPIKeySetup) {
            APIKeyConfigView()
        }
        .sheet(isPresented: $showDeveloperConfig) {
            DeveloperConfigView()
        }
        .sheet(isPresented: $showDataSources) {
            DataSourcesView()
        }
        .sheet(isPresented: $showWeightGoalSetup) {
            WeightGoalSetupView()
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
            if HealthKitManager.shared.isAuthorized {
                HealthKitManager.shared.fetchWeightHistory(daysLimit: 365) { history in
                    if let history = history {
                        DispatchQueue.main.async {
                            self.weightHistory = history
                        }
                    }
                }
            }
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
        .onChange(of: weightAverageDays) { _, newValue in
            SettingsManager.shared.weightAverageDays = newValue
        }
    }
    
    private func loadSettings() {
        let settings = SettingsManager.shared
        calorieTarget = settings.dailyCalorieTarget
        proteinTarget = settings.proteinTarget
        carbsTarget = settings.carbsTarget
        fatTarget = settings.fatTarget
        dietMode = settings.dietMode
        weightAverageDays = settings.weightAverageDays
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
            .modelContainer(for: [FoodEntry.self, WorkoutEntry.self, DailyTargetLog.self], inMemory: true)
    }
}

// Lazy CSV Transferable Document
struct CSVExporter: Transferable {
    let foodEntries: [FoodEntry]
    let workoutEntries: [WorkoutEntry]
    let targetLogs: [DailyTargetLog]
    let weightHistory: [Date: Double]
    let useMetric: Bool
    
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
        let unitStr = useMetric ? "kg" : "lbs"
        var csv = "Date,Type,Name,Calories Consumed,Calories Burned,Protein (g),Carbs (g),Fat (g),Servings,Weight (\(unitStr)),Target Calories,Target Protein (g),Target Carbs (g),Target Fat (g)\n"
        
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
            let weight: Double
            let targetCalories: Int
            let targetProtein: Double
            let targetCarbs: Double
            let targetFat: Double
            
            static func < (lhs: ExportableItem, rhs: ExportableItem) -> Bool {
                lhs.date < rhs.date
            }
        }
        
        var items: [ExportableItem] = []
        
        // 1. Food Entries
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
                servings: food.servings,
                weight: 0,
                targetCalories: 0,
                targetProtein: 0,
                targetCarbs: 0,
                targetFat: 0
            ))
        }
        
        // 2. Workout Entries
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
                servings: 0,
                weight: 0,
                targetCalories: 0,
                targetProtein: 0,
                targetCarbs: 0,
                targetFat: 0
            ))
        }
        
        // 3. Weight Logs
        for (date, weightInKg) in weightHistory {
            let displayWeight = useMetric ? weightInKg : weightInKg.kgToLbs
            items.append(ExportableItem(
                date: date,
                type: "Weight",
                name: "Apple Health Weight Sync",
                caloriesConsumed: 0,
                caloriesBurned: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                servings: 0,
                weight: displayWeight,
                targetCalories: 0,
                targetProtein: 0,
                targetCarbs: 0,
                targetFat: 0
            ))
        }
        
        // 4. Target Logs
        for log in targetLogs {
            items.append(ExportableItem(
                date: log.date,
                type: "Daily Target",
                name: "Calorie & Macro Targets",
                caloriesConsumed: 0,
                caloriesBurned: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                servings: 0,
                weight: 0,
                targetCalories: log.calories,
                targetProtein: log.protein,
                targetCarbs: log.carbs,
                targetFat: log.fat
            ))
        }
        
        items.sort()
        
        for item in items {
            let dateStr = displayFormatter.string(from: item.date)
            let escapedName = item.name.replacingOccurrences(of: "\"", with: "\"\"")
            
            let row = "\"\(dateStr)\",\"\(item.type)\",\"\(escapedName)\",\(item.caloriesConsumed),\(item.caloriesBurned),\(item.protein),\(item.carbs),\(item.fat),\(item.servings),\(item.weight > 0 ? String(format: "%.1f", item.weight) : ""),\(item.targetCalories > 0 ? "\(item.targetCalories)" : ""),\(item.targetProtein > 0 ? String(format: "%.1f", item.targetProtein) : ""),\(item.targetCarbs > 0 ? String(format: "%.1f", item.targetCarbs) : ""),\(item.targetFat > 0 ? String(format: "%.1f", item.targetFat) : "")\n"
            
            csv.append(row)
        }
        
        return csv
    }
}

struct WeightGoalSetupView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var startWeight: Double
    @State private var targetWeight: Double
    @State private var targetDate: Date
    @State private var useAdaptiveCalorieTarget: Bool
    
    private var settings = SettingsManager.shared
    
    init() {
        let settings = SettingsManager.shared
        _startWeight = State(initialValue: settings.useMetricSystem ? settings.startWeight : settings.startWeight.kgToLbs)
        _targetWeight = State(initialValue: settings.useMetricSystem ? settings.targetWeight : settings.targetWeight.kgToLbs)
        _targetDate = State(initialValue: settings.targetDate)
        _useAdaptiveCalorieTarget = State(initialValue: settings.useAdaptiveCalorieTarget)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    HStack {
                        Text("Starting Weight")
                        Spacer()
                        TextField("141", value: $startWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(settings.useMetricSystem ? "kg" : "lbs")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Target Weight")
                        Spacer()
                        TextField("130", value: $targetWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(settings.useMetricSystem ? "kg" : "lbs")
                            .foregroundStyle(.secondary)
                    }
                    
                    DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                }
                
                Section {
                    Toggle(isOn: $useAdaptiveCalorieTarget) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Adaptive Calorie Target")
                            Text("Auto-adjusts your daily target based on your active metabolic rate.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Automation")
                } footer: {
                    Text("If enabled, the app will update your calorie target daily based on your weight logs and calorie intake. Macronutrient targets (Protein, Carbs, Fat) will automatically scale proportionally to preserve your preferred macro ratio.")
                }
            }
            .navigationTitle("Setup Weight Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                    }
                }
            }
        }
    }
    
    private func saveGoal() {
        settings.startWeight = settings.useMetricSystem ? startWeight : startWeight.lbsToKg
        settings.targetWeight = settings.useMetricSystem ? targetWeight : targetWeight.lbsToKg
        settings.targetDate = targetDate
        settings.useAdaptiveCalorieTarget = useAdaptiveCalorieTarget
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        dismiss()
    }
}
