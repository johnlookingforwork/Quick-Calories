# Swipe Actions Fix

## Problem
Swipe actions on Today's Meals and Today's Workouts weren't working after adding the workout feature.

## Root Cause
SwiftUI's `.swipeActions()` modifier only works on list items inside a `List` or `Form`. The items were inside a `ForEach` within a `ScrollView`, which doesn't support swipe gestures.

## Solution
Wrapped the `ForEach` items in a `List` with proper styling to maintain the visual design:

### Before (Not Working):
```swift
ScrollView {
    VStack {
        ForEach(todayEntries) { entry in
            FoodEntryRow(entry: entry)
                .swipeActions { ... } // ❌ Doesn't work
        }
    }
}
```

### After (Working):
```swift
ScrollView {
    VStack {
        List {
            ForEach(todayEntries) { entry in
                FoodEntryRow(entry: entry)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions { ... } // ✅ Works!
            }
        }
        .listStyle(.plain)
        .frame(height: CGFloat(entries.count) * 130)
        .scrollDisabled(true)
    }
}
```

## Key Modifiers Applied

### `.listRowInsets(EdgeInsets())`
- Removes default list padding
- Keeps custom padding from FoodEntryRow

### `.listRowBackground(Color.clear)`
- Removes default list background
- Shows custom card backgrounds

### `.listRowSeparator(.hidden)`
- Hides list divider lines
- Maintains clean card design

### `.listStyle(.plain)`
- Uses plain list style (no grouped appearance)
- Matches original design

### `.frame(height: ...)`
- Fixed height based on item count
- Prevents list from expanding infinitely

### `.scrollDisabled(true)`
- Disables List's internal scrolling
- Parent ScrollView handles all scrolling

## Applied To
1. ✅ Today's Meals (height: 130 per entry)
2. ✅ Today's Workouts (height: 100 per entry)

## Result
- Swipe actions now work on both meals and workouts
- Visual design remains identical
- Maintains smooth scrolling in parent ScrollView
- Consistent with Saved Foods behavior

## Why Saved Foods Still Worked
SavedFoodsView uses a proper `List` from the start:
```swift
struct SavedFoodsView: View {
    var body: some View {
        List { // ✅ Already using List
            ForEach(savedFoods) { food in
                // Swipe actions work here
            }
        }
    }
}
```
