# Workout Edit & History Integration

## Changes Made

### 1. ✅ Edit Workout Functionality

#### Created `EditWorkoutView`
Added to `LogWorkoutView.swift`:
```swift
struct EditWorkoutView: View {
    let workout: WorkoutEntry
    @State private var workoutName: String
    @State private var caloriesBurned: String
    // ... editable form
}
```

**Features:**
- Edit workout name
- Edit calories burned
- Keyboard dismissal
- Validation (name required, calories > 0)
- Saves changes directly to SwiftData model

### 2. ✅ Dashboard Swipe Actions

#### Added Edit Swipe:
```swift
.swipeActions(edge: .leading) {
    Button {
        selectedWorkout = workout
    } label: {
        Label("Edit", systemImage: "pencil")
    }
    .tint(.blue)
}
```

#### Added Tap to Edit:
```swift
.onTapGesture {
    selectedWorkout = workout
}
```

#### Added Sheet Presentation:
```swift
.sheet(item: $selectedWorkout) { workout in
    EditWorkoutView(workout: workout)
}
```

**Result:**
- Swipe left → Edit (blue)
- Swipe right → Delete (red)
- Tap workout → Opens edit sheet
- Consistent with food entries

### 3. ✅ Monthly History Integration

#### Added Workout Query:
```swift
@Query private var allWorkouts: [WorkoutEntry]
```

#### New Helper Functions:
```swift
private func workoutsForDate(_ date: Date) -> [WorkoutEntry]
private func workoutCaloriesForDate(_ date: Date) -> Int
```

#### Updated Goal Calculation:
```swift
private func metGoalForDate(_ date: Date) -> Bool {
    let totals = totalsForDate(date)
    let workoutCals = workoutCaloriesForDate(date)
    let netCalories = totals.calories - workoutCals  // ✅ Net calories
    // Check if within 90-110% of target
}
```

### 4. ✅ History Day Details

#### Updated Daily Summary:
Shows workout calories deduction:
```
Calories
2000
-400 workout  (in green if workouts exist)
```

#### Added Workouts Section:
Shows all workouts for selected day:
```
Workouts
─────────────────────────
Morning Run        8:30 AM
-400 cal

Evening Walk       7:00 PM
-150 cal
```

#### Styling:
- Green text for workout calories
- Light green background (`Color.green.opacity(0.1)`)
- Minus sign (-) to indicate calories burned
- Separate section below meals

#### Empty State:
Updated to:
```
"No meals or workouts logged"
```

## Visual Design

### Today's Workouts (Dashboard):
```
Today's Workouts          +400 cal
─────────────────────────────────
🏃 Morning Run         8:30 AM
   🔥 400 cal burned      →
   ← Swipe: Edit | Delete →
```

### History Calendar:
```
Calendar shows green/orange dots based on NET calories:
Net Calories = Food Consumed - Workouts Burned

Green dot = Net within 90-110% of target ✅
Orange dot = Has entries but goal not met
```

### Selected Day Details:
```
March 15, 2026

Calories              Protein  Carbs  Fat
2000                 150g     200g   67g
-400 workout (green)

Meals
─────────────────────
Breakfast  8:00 AM
300 cal

Workouts
─────────────────────
Morning Run  8:30 AM
-400 cal (green bg)
```

## User Experience

### Editing Workouts:
1. **Swipe left** on workout → Edit
2. **Swipe right** on workout → Delete
3. **Tap** workout → Edit
4. Edit form opens with current values
5. Change name or calories
6. Tap "Save"
7. Changes reflected immediately

### History View:
1. Open calendar (top right icon)
2. Tap any day
3. See meals AND workouts
4. Net calories consider workouts
5. Goal indicators accurate with workouts

## Files Modified

1. ✅ `LogWorkoutView.swift` - Added `EditWorkoutView`
2. ✅ `DashboardView.swift` - Added edit swipe & sheet
3. ✅ `MonthlyHistoryView.swift` - Added workout queries & display

## Benefits

✅ Full CRUD for workouts (Create, Read, Update, Delete)
✅ Consistent with food entry UX
✅ Workouts fully integrated in history
✅ Accurate goal tracking with net calories
✅ Clear visual distinction (green for workouts)
✅ Complete activity picture per day
