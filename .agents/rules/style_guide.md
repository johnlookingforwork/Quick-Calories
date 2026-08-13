# QuickCalories UI & Visual Style Guide

This style guide outlines the layout, typography, colors, and styling rules for daily meal logs and list layouts to maintain visual cohesion across the application.

---

## 1. Core Card & List Aesthetic
To prevent layout clutter and keep lists clean, items are grouped into cohesive bounding box card sections using native iOS grouped lists.

* **List Layouts**:
  * Use standard grouped lists (`Form` or `.listStyle(.insetGrouped)`) for all logging hub lists, edit screens, and builders.
  * Avoid drawing individual card borders or custom backgrounds per cell. Instead, let them share the section's unified bounding box background.
  * Separate cells inside each section using native horizontal line dividers.
* **Dashboard Feed Exception**:
  * On the dashboard main feed, elements are rendered as individual, floating charcoal-colored cards with:
    * Background: `Color(red: 0.11, green: 0.11, blue: 0.12)`
    * Corner Radius: `14`
    * Padding: `.vertical, 12`, `.horizontal, 16`
    * Row Height Budget: `115pt`

---

## 2. Typography & Contrast Hierarchy
Ensure clean readability in lists and builders by maintaining the following font styles:

| Element | Font Style | Color | Details |
| :--- | :--- | :--- | :--- |
| **Primary Title (Food Name)** | `.font(.headline)` | `.primary` | Bold weight. |
| **Secondary Stats (Calories)** | `.font(.subheadline).fontWeight(.semibold)` | `.secondary` (gray) | Flame icon (`Image(systemName: "flame.fill")`) in `.orange`. |
| **Tertiary Stats (Macros)** | `.font(.footnote)` | `.secondary` (gray) | Custom macro circle indicators (size 6) in an HStack. |
| **Time & Disclosures** | `.font(.footnote)` | `.secondary` (gray) | Aligned to the right edge of the card row. |
| **Helper Subtitles / Recipe ingredients** | `.font(.caption2).italic()` | `.secondary` (gray) | Shows ingredient summaries below indicators. |

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
* **Row vertical spacing padding**: `.padding(.vertical, 4)` for standard list row cards to keep cells spacious but slim.

---

## 5. Interaction Styles & Swipe Gestures
Maintain consistent swipe actions for items in lists:

* **Swipe Left (Trailing Edge)**:
  * **Action**: Delete (role: `.destructive`, red)
* **Swipe Right (Leading Edge)**:
  * **Action 1**: Edit (tint: `.blue`, icon: `"pencil"`)
  * **Action 2**: Share (tint: `.purple`, icon: `"qrcode"`)
