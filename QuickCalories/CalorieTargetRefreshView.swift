//
//  CalorieTargetRefreshView.swift
//  QuickCalories
//
//  Created by John N on 10/5/26.
//

import SwiftUI
import SwiftData

struct CalorieTargetRefreshView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [FoodEntry]
    
    @State private var settings = SettingsManager.shared
    @State private var isRefreshing = false
    @State private var statusMessage: String? = nil
    @State private var showSuccessBadge = false
    
    var body: some View {
        Form {
            // Plan & Today's Target Card
            Section {
                VStack(spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Daily Target")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(settings.dailyCalorieTarget)")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text("cal")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Status badge
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: settings.isScheduledRefreshEnabled ? "clock.arrow.circlepath" : "hand.tap.fill")
                                    .font(.caption2)
                                Text(settings.isScheduledRefreshEnabled ? "Daily Schedule" : "Manual Only")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(settings.isScheduledRefreshEnabled ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                            .foregroundStyle(settings.isScheduledRefreshEnabled ? Color.green : Color.orange)
                            .clipShape(Capsule())
                            
                            if settings.useAdaptiveCalorieTarget {
                                Text(settings.adaptiveCalorieMode.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    HStack(spacing: 10) {
                        MacroTargetBadge(
                            name: "Protein",
                            amount: settings.proteinTarget,
                            color: .red,
                            isPreserved: settings.useAdaptiveCalorieTarget && settings.preservedMacroOption == .preserveProtein
                        )
                        MacroTargetBadge(
                            name: "Carbs",
                            amount: settings.carbsTarget,
                            color: .blue,
                            isPreserved: settings.useAdaptiveCalorieTarget && settings.preservedMacroOption == .preserveCarbs
                        )
                        MacroTargetBadge(
                            name: "Fat",
                            amount: settings.fatTarget,
                            color: .yellow,
                            isPreserved: settings.useAdaptiveCalorieTarget && settings.preservedMacroOption == .preserveFat
                        )
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Manual Refresh Action
            Section {
                Button {
                    performManualRefresh()
                } label: {
                    HStack {
                        Spacer()
                        if isRefreshing {
                            ProgressView()
                                .padding(.trailing, 6)
                            Text("Refreshing Targets...")
                                .fontWeight(.semibold)
                        } else if showSuccessBadge {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Target Refreshed")
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Refresh Target Now")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(isRefreshing)
                
                if let message = statusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
            } header: {
                Text("Manual Refresh")
            } footer: {
                Text("Immediately recalculates your calories and macros using your latest food logs, HealthKit weight data, and active strategy.")
            }
            
            // Scheduled Refresh Settings
            Section {
                Toggle(isOn: $settings.isScheduledRefreshEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scheduled Daily Refresh")
                            .font(.body)
                        Text("Refreshes calories once per day at a fixed time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if settings.isScheduledRefreshEnabled {
                    DatePicker(
                        "Refresh Time",
                        selection: Binding(
                            get: { settings.scheduledRefreshTime },
                            set: { settings.scheduledRefreshTime = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    
                    HStack {
                        Text("Next Refresh")
                        Spacer()
                        Text(settings.formattedNextRefresh)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    Text("Last Refreshed")
                    Spacer()
                    Text(settings.formattedLastRefresh)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Daily Schedule")
            } footer: {
                if settings.isScheduledRefreshEnabled {
                    Text("QuickCalories will recalculate your target once each day at \(settings.formattedRefreshTime). Unlike auto-updating throughout the day, this ensures your target remains stable and predictable as you log your meals.")
                } else {
                    Text("Scheduled refresh is turned off. Your daily target will stay fixed unless you tap 'Refresh Target Now'.")
                }
            }
            
            // Strategy Breakdown
            Section("Target Strategy") {
                HStack {
                    Text("Calculation Mode")
                    Spacer()
                    Text(settings.useAdaptiveCalorieTarget ? settings.adaptiveCalorieMode.rawValue : "Fixed Base Target")
                        .foregroundStyle(.secondary)
                }
                
                if settings.useAdaptiveCalorieTarget {
                    if settings.adaptiveCalorieMode == .calorieBudget {
                        HStack {
                            Text("Budget Style")
                            Spacer()
                            Text(settings.calorieBudgetStyle.rawValue)
                                .foregroundStyle(.secondary)
                        }
                    } else if settings.adaptiveCalorieMode == .weightTrend {
                        HStack {
                            Text("Metabolic Window")
                            Spacer()
                            Text("\(settings.metabolicWindowDays) Days")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Macro Scaling")
                        Spacer()
                        Text(settings.preservedMacroOption.rawValue)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack {
                        Text("Profile Baseline")
                        Spacer()
                        Text(settings.hasProfileData ? "Calculated from Profile" : "Manual Target")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Target Refresh Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func performManualRefresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        statusMessage = nil
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        settings.refreshCalorieTarget(allEntries: allEntries, force: true) { updated, message in
            DispatchQueue.main.async {
                self.isRefreshing = false
                self.statusMessage = message
                self.showSuccessBadge = true
                
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        self.showSuccessBadge = false
                    }
                }
            }
        }
    }
}
