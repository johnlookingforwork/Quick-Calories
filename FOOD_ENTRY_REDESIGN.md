# Food Entry Row Redesign

## Before (Plain Text):
```
Chicken Breast
200 cal  P: 30g  C: 0g  F: 5g
                        3:45 PM
```

## After (Icon-Enhanced):
```
🍴  Chicken Breast
    🔥 200 cal
    🔴 30g  🔵 0g  🟡 5g
                        3:45 PM →
```

## Visual Improvements:

### 1. **Food Icon (Left)**
- `fork.knife.circle.fill` with orange gradient
- Immediately identifies the item as food
- Adds visual interest to the list

### 2. **Calories with Flame Icon**
- `flame.fill` icon in orange
- Visually represents energy/calories
- Stands out as the primary metric
- Larger, bolder text (`.subheadline` + `.fontWeight(.medium)`)

### 3. **Macro Icons (Color-Coded Dots)**
- **Protein:** 🔴 Red circle
- **Carbs:** 🔵 Blue circle  
- **Fat:** 🟡 Yellow circle
- Matches the color scheme from the daily progress circles
- No more "P:", "C:", "F:" labels needed
- Clean, minimal, consistent

### 4. **Servings Icon**
- `number.circle.fill` icon
- Only appears when servings ≠ 1.0
- Provides visual context

### 5. **Chevron Indicator (Right)**
- Small right-facing chevron (`chevron.right`)
- Subtle hint that tapping opens details
- Placed below timestamp

## Visual Hierarchy:
```
Priority 1: Food name (semibold)
Priority 2: Calories (flame icon, medium weight)
Priority 3: Macros (colored dots, smaller text)
Priority 4: Time + servings (smallest, secondary)
```

## Color Palette:
- Orange gradient: Food icon & flame
- Red: Protein dot
- Blue: Carbs dot
- Yellow: Fat dot
- Secondary: Supporting text
- Tertiary: Chevron hint

## Layout:
```
┌─────────────────────────────────────────┐
│ 🍴  Food Name                3:45 PM    │
│     🔥 200 cal                    →     │
│     🔴 30g  🔵 0g  🟡 5g               │
│     🔢 1.5 servings (if not 1.0)       │
└─────────────────────────────────────────┘
```

## Benefits:
✅ More visually appealing
✅ Icons provide instant recognition
✅ Color-coded macros are easier to scan
✅ Better visual hierarchy
✅ Cleaner, more modern design
✅ Consistent with iOS design language
✅ Less text clutter
