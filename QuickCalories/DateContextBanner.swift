//
//  DateContextBanner.swift
//  QuickCalories
//
//  Created by John N on 2/20/26.
//
//  NOTE: This component has been superseded by DateHeaderView in DashboardView.swift
//  as of 2/20/26 to eliminate empty space when viewing today.
//  Kept for reference but no longer used in the main UI.
//

import SwiftUI

struct DateContextBanner: View {
    let selectedDate: Date
    let onJumpToToday: () -> Void
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }
    
    private var isFuture: Bool {
        selectedDate > Date()
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedDate, format: .dateTime.month(.wide).day().year())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if isFuture {
                    Text("Logging for future date")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    // Reserve space even when not showing future warning
                    Text(" ")
                        .font(.caption2)
                        .opacity(0)
                }
            }
            
            Spacer()
            
            Button(action: onJumpToToday) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.caption2)
                    Text("Today")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .cornerRadius(16)
            }
            .disabled(isToday) // Disable interaction when hidden
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
        .opacity(isToday ? 0 : 1) // Fade in/out
        .animation(.easeInOut(duration: 0.25), value: isToday) // Smooth fade
    }
}

#Preview {
    VStack {
        DateContextBanner(selectedDate: Date().addingTimeInterval(-86400 * 3)) {
            print("Jump to today")
        }
        
        DateContextBanner(selectedDate: Date().addingTimeInterval(86400 * 2)) {
            print("Jump to today")
        }
        
        DateContextBanner(selectedDate: Date()) {
            print("Jump to today")
        }
    }
}
