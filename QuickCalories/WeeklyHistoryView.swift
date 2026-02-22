//
//  WeeklyHistoryView.swift
//  QuickCalories
//
//  Created by John N on 2/17/26.
//

import SwiftUI
import SwiftData

struct WeeklyHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [FoodEntry]
    
    private var last7Days: [DaySummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var days: [DaySummary] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }
            
            let dayEntries = allEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            
            let totals = dayEntries.reduce((calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0)) { result, entry in
                (
                    calories: result.calories + entry.calories,
                    protein: result.protein + entry.protein,
                    carbs: result.carbs + entry.carbs,
                    fat: result.fat + entry.fat
                )
            }
            
            days.append(DaySummary(
                date: date,
                calories: totals.calories,
                protein: totals.protein,
                carbs: totals.carbs,
                fat: totals.fat
            ))
        }
        
        return days
    }
    
    var body: some View {
        List {
            ForEach(last7Days) { day in
                DayRow(summary: day)
            }
        }
        .navigationTitle("Weekly History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DaySummary: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct DayRow: View {
    let summary: DaySummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(summary.date, style: .date)
                    .font(.headline)
                
                if summary.isToday {
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Text("\(summary.calories) cal")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 16) {
                MacroLabel(name: "Protein", value: summary.protein, color: .red)
                MacroLabel(name: "Carbs", value: summary.carbs, color: .blue)
                MacroLabel(name: "Fat", value: summary.fat, color: .yellow)
            }
        }
        .padding(.vertical, 8)
    }
}

struct MacroLabel: View {
    let name: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("\(name):")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(Int(value))g")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        WeeklyHistoryView()
            .modelContainer(for: FoodEntry.self, inMemory: true)
    }
}
