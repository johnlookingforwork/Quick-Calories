# History View Swipe Actions

## Feature Added

### **Edit and Delete in History**

Users can now swipe on meals and workouts in the MonthlyHistoryView to:
- **Swipe left** → Edit (blue)
- **Swipe right** → Delete (red)
- **Tap** → Edit

Same UX as Dashboard and Saved Foods!

---

## Implementation

### **1. Added States**
```swift
@State private var selectedEntry: FoodEntry?
@State private var selectedWorkout: WorkoutEntry?
```

### **2. Wrapped ForEach in List**

#### **Meals:**
```swift
List {
    ForEach(entries...) { entry in
        // Meal row
        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        .listRowBackground(Color.secondarySystemBackground)
        .listRowSeparator(.hidden)
        .onTapGesture {
            selectedEntry = entry
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteEntry(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                selectedEntry = entry
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}
.listStyle(.plain)
.frame(height: CGFloat(entries.count) * 60)
.scrollDisabled(true)
```

#### **Workouts:**
Same pattern with:
- Green background tint
- Edit and delete swipe actions
- Tap to edit

### **3. Added Edit Sheets**
```swift
.sheet(item: $selectedEntry) { entry in
    EditEntryView(entry: entry)
}

.sheet(item: $selectedWorkout) { workout in
    EditWorkoutView(workout: workout)
}
```

### **4. Added Delete Functions**
```swift
private func deleteEntry(_ entry: FoodEntry) {
    withAnimation {
        modelContext.delete(entry)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

private func deleteWorkout(_ workout: WorkoutEntry) {
    withAnimation {
        modelContext.delete(workout)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
```

---

## User Experience

### **History View Day Details:**

```
March 14, 2026

Calories: 1800    P: 120g ...
-400 workout

Meals
─────────────────────────
Breakfast  8:00 AM  300 cal
  ← Edit | Delete →

Lunch  12:30 PM  500 cal
  ← Edit | Delete →

Workouts
─────────────────────────
Morning Run  8:30 AM  -400 cal
  ← Edit | Delete →
```

### **Actions:**

#### **Edit Food Entry:**
1. Swipe left on meal
2. Tap blue "Edit" button
3. EditEntryView opens
4. Adjust servings
5. Values recalculate
6. Tap "Save"
7. Calendar/totals update

#### **Delete Food Entry:**
1. Swipe right on meal
2. Red "Delete" button appears
3. Tap to confirm
4. Entry removed with animation
5. Haptic feedback
6. Totals recalculate
7. Calendar indicator updates

#### **Edit Workout:**
1. Swipe left on workout
2. Tap blue "Edit" button
3. EditWorkoutView opens
4. Change name or calories
5. Tap "Save"
6. Calendar updates

#### **Delete Workout:**
1. Swipe right on workout
2. Tap red "Delete"
3. Workout removed
4. Calories remaining decreases
5. Calendar updates

---

## Consistency

### **All Three Locations Now Have Swipe Actions:**

#### **1. Dashboard (Today's Meals/Workouts)**
- ✅ Swipe left → Edit
- ✅ Swipe right → Delete
- ✅ Tap → Edit

#### **2. History (Any Date's Meals/Workouts)**
- ✅ Swipe left → Edit
- ✅ Swipe right → Delete
- ✅ Tap → Edit

#### **3. Saved Foods Library**
- ✅ Swipe left → Edit
- ✅ Swipe right → Delete
- ✅ Tap → Log (different context)

---

## Benefits

### ✅ **Full CRUD Everywhere**
- Create: FAB menu
- Read: View in lists
- Update: Swipe to edit
- Delete: Swipe to delete

### ✅ **Consistent UX**
- Same gestures everywhere
- Same visual feedback
- Same haptic feedback
- No learning curve

### ✅ **Retroactive Editing**
- Edit past meals
- Correct mistakes
- Adjust servings
- Update workout calories

### ✅ **Immediate Feedback**
- Calendar indicators update
- Daily totals recalculate
- Progress circles change
- Goal status updates

---

## Technical Details

### **List Configuration:**
```swift
.listStyle(.plain)                    // No grouped appearance
.frame(height: entries.count * 60)    // Fixed height per entry
.scrollDisabled(true)                 // Parent handles scroll
```

### **List Row Styling:**
```swift
.listRowInsets(EdgeInsets(...))       // Custom padding
.listRowBackground(Color.clear)       // Keep custom backgrounds
.listRowSeparator(.hidden)            // No divider lines
```

### **Why List Instead of ForEach:**
SwiftUI's swipe actions only work inside `List` or `Form`. Regular `ForEach` in `VStack` doesn't support swipe gestures.

---

## Testing Checklist

- [ ] Swipe left on history meal → Edit appears
- [ ] Swipe right on history meal → Delete works
- [ ] Tap history meal → Edit opens
- [ ] Edit meal → Changes save
- [ ] Delete meal → Calendar updates
- [ ] Swipe left on history workout → Edit appears
- [ ] Swipe right on history workout → Delete works
- [ ] Tap history workout → Edit opens
- [ ] Edit workout → Changes save
- [ ] Delete workout → Calorie totals update
- [ ] Haptic feedback on delete
- [ ] Animations smooth
- [ ] List doesn't scroll (parent does)

---

**Build and test!** You can now edit and delete meals/workouts directly from the history view with the same intuitive swipe gestures! 🎯✨
