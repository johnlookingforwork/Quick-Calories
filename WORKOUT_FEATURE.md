# Workout Logging Feature

## Overview
Added comprehensive workout tracking that **adds** burned calories back to your daily remaining total, giving you more calories to eat when you exercise.

## New Data Model

### WorkoutEntry
```swift
@Model
final class WorkoutEntry {
    var id: UUID
    var workoutName: String
    var caloriesBurned: Int
    var timestamp: Date
}
```

Stored in SwiftData alongside food entries.

## Dashboard Redesign

### New Button Layout:
```
┌─────────────────────────────────────┐
│  ✨ Log with AI    📚 Saved         │
│  🏃 Log Workout (full width)         │
└─────────────────────────────────────┘
```

**3 Primary Actions:**
1. **✨ Log with AI** - Natural language food entry (blue)
2. **📚 Saved** - Quick access to saved foods (blue outline)
3. **🏃 Log Workout** - New workout logging (green outline)

## Workout Logging Flow

### LogWorkoutView
Simple 2-field form:
- **Workout Name**: Text input (e.g., "Morning Run", "Gym Session")
- **Calories Burned**: Number input (e.g., 350)

No complicated duration tracking or exercise databases — just name and calories.

### Example:
```
Workout name: Morning Run
Calories burned: 450
```

## Calorie Calculation

### Formula:
```
Remaining Calories = Target - (Food Consumed - Workouts Burned)
```

### Example:
- Daily target: 2000 cal
- Food eaten: 1500 cal
- Workout burned: 400 cal
- **Remaining = 2000 - (1500 - 400) = 900 cal** ✅

### Display:
```
┌─────────────────────┐
│       900           │
│  calories remaining │
│  🏃 +400 from workouts │ (in green)
└─────────────────────┘
```

## Today's Workouts Section

Only appears when workouts are logged for the day.

### Display:
```
Today's Workouts               +400 cal
───────────────────────────────────────
🏃 Morning Run              8:30 AM
   🔥 400 cal burned            →
   
🏃 Evening Walk             7:00 PM
   🔥 150 cal burned            →
```

### Features:
- Green gradient running icon
- Green flame icon for calories burned
- Total calories shown in header (green)
- Swipe right to delete
- Light green background tint

## Visual Design

### Workout Entry Card:
- **Icon**: `figure.run.circle.fill` with green gradient
- **Background**: Light green tint (`Color.green.opacity(0.1)`)
- **Calories**: Green flame icon + green text
- **Time**: Right side, gray text
- **Chevron**: Subtle tap indicator

### Color Scheme:
- 🟢 Green: All workout-related elements
- 🔴 Orange: Food entries
- 🔵 Blue: Navigation buttons

## Files Created/Modified

### New Files:
- `LogWorkoutView.swift` - Workout logging form

### Modified Files:
- `Item.swift` - Added `WorkoutEntry` model
- `QuickCaloriesApp.swift` - Updated schema
- `DashboardView.swift` - Added:
  - Workout queries
  - Workout button
  - Workout section
  - Updated calorie calculations
  - `WorkoutEntryRow` view
  - Delete workout function

## User Experience

### Logging a Workout:
1. Tap **"🏃 Log Workout"** button
2. Enter workout name
3. Enter calories burned
4. Tap **"Log"**
5. Haptic feedback ✓
6. Workout appears in "Today's Workouts"
7. Calories remaining increases

### Managing Workouts:
- **Swipe right** on any workout → Delete
- Workouts deleted = calories removed from total
- Section disappears if no workouts logged

## Benefits

✅ Simple, minimal input (just name + calories)
✅ Clear visual separation (green vs orange)
✅ Motivates users to exercise (see calories increase)
✅ No complex exercise database needed
✅ Consistent with existing food logging UX
✅ Swipe to delete like food entries
✅ Real-time calorie updates
✅ Clean, modern design

## Future Enhancements (Out of Scope)

- Exercise database with preset calories
- Duration tracking
- Exercise type categories
- Weekly workout statistics
- Workout history view
- Saved workout templates
