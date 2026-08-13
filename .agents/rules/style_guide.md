# QuickCalories UI & Visual Style Guide

This style guide outlines the layout, typography, colors, and styling rules for daily meal logs and lists to maintain visual cohesion across the application.

---

## 1. Core Card Aesthetic
All food, recent logs, and recipe items must be rendered as premium, charcoal-colored rounded cards inset from screen edges.

* **Card Background**: `Color(red: 0.11, green: 0.11, blue: 0.12)` (Charcoal gray)
* **Corner Radius**: `14` (Soft rounded edges)
* **Card Shadow**: `shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1.5)`
* **Margins & Insets**:
  * **Card Row Insets** (within List): `.listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))`
  * **Card Internal Padding**: `.padding(.vertical, 12).padding(.horizontal, 16)`
  * **List Background & Separators**: Always hide borders and separators on lists containing these cards:
    ```swift
    .listStyle(.plain)
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)
    ```

---

## 2. Typography & Contrast Hierarchy
To ensure content is readable and not cluttered, always use the following font sizes and weights:

| Element | Font Style | Color | Visual Spacing / Details |
| :--- | :--- | :--- | :--- |
| **Primary Title (Food Name)** | `.font(.headline)` | `.primary` (white) | Top item; bold by default. |
| **Secondary Stats (Calories)** | `.font(.subheadline).fontWeight(.semibold)` | `.secondary` (gray) | Flame icon (`Image(systemName: "flame.fill")`) in `.orange` (caption font size). |
| **Tertiary Stats (Macros)** | `.font(.footnote)` | `.secondary` (gray) | Custom macro circle indicators (size 6) aligned in an HStack. |
| **Time & Disclosures** | `.font(.footnote)` | `.secondary` (gray) | Positioned on the right edge of the card. |
| **Helper Subtitles / Recipe ingredients** | `.font(.caption2).italic()` | `.secondary` (gray) | Shows ingredient summary below macro indicators. |

---

## 3. Macro Color Indicators
Always use solid circle SF Symbols for macro values to avoid emoji scale inconsistencies:

* 🔴 **Protein Indicator**: `Image(systemName: "circle.fill")` colored `.red` next to value (e.g. `26g`)
* 🔵 **Carbs Indicator**: `Image(systemName: "circle.fill")` colored `.blue` next to value (e.g. `8g`)
* 🟡 **Fat Indicator**: `Image(systemName: "circle.fill")` colored `.yellow` next to value (e.g. `2g`)

---

## 4. Spacing Layout
Avoid wide margins between rows and content stacks:

* **VStack Internal Spacing**: `4` (between Title, Calories, and Macros)
* **Macro HStack spacing**: `12` (between Protein, Carbs, and Fat groups)
* **HStack Macro internal spacing**: `3` (between colored dot and gram text)

---

## 5. Interaction Styles & Swipe Gestures
Maintain consistent swipe actions for items in lists:

* **Swipe Left (Trailing Edge)**:
  * **Action**: Delete (role: `.destructive`, red)
* **Swipe Right (Leading Edge)**:
  * **Action 1**: Edit (tint: `.blue`, icon: `"pencil"`)
  * **Action 2**: Share (tint: `.purple`, icon: `"qrcode"`)
