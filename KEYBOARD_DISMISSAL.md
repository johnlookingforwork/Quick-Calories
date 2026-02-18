# Keyboard Dismissal Improvements

## Problem
When the keyboard is visible and the user taps elsewhere on the screen, the keyboard doesn't dismiss automatically in several views, which is frustrating for users.

## Solutions Implemented

### 1. **DashboardView - AI Input Field**
Added a "Done" button above the keyboard:
```swift
.toolbar {
    ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") {
            isTextFieldFocused = false
        }
    }
}
```
**Result:** Users can tap "Done" to dismiss the keyboard while entering food descriptions.

### 2. **LogSavedFoodView - Servings Input**
Added both:
- `@FocusState` for the servings text field
- Keyboard toolbar with "Done" button
```swift
@FocusState private var isServingsFocused: Bool
```
**Result:** Users can dismiss keyboard when entering serving quantities.

### 3. **Form-Based Views (Settings, Add/Edit Saved Food)**
Added `.scrollDismissesKeyboard(.interactively)` modifier:
```swift
Form {
    // ... content
}
.scrollDismissesKeyboard(.interactively)
```
**Result:** Scrolling the form automatically dismisses the keyboard.

## Files Modified
- `DashboardView.swift` - Added keyboard toolbar
- `SavedFoodsView.swift` - Added keyboard toolbar to LogSavedFoodView, scroll dismiss to forms
- `SettingsView.swift` - Added scroll dismiss

## User Experience
✅ **Dashboard**: "Done" button appears above keyboard when typing food  
✅ **Log Saved Food**: "Done" button appears when entering servings  
✅ **Settings**: Scrolling dismisses keyboard  
✅ **Add/Edit Saved Food**: Scrolling dismisses keyboard  

## iOS Standard Behavior
These changes align with iOS standard patterns:
- Number pad keyboards don't have a built-in return key, so we add a "Done" button
- Forms with scrolling content should dismiss keyboard on scroll
- Tapping outside text fields in Forms automatically dismisses keyboard
