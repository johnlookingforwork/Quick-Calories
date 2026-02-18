# QuickCalories

**AI-Powered Calorie Counter for iOS**

A minimalist, high-performance iOS calorie tracking app that prioritizes speed and simplicity. Track your food intake and workouts with natural language AI, saved foods, and a clean 7-day history view.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blue)
![SwiftData](https://img.shields.io/badge/Data-SwiftData-blue)

---

## ✨ Features

### **Quick Logging**

- **AI-Powered Entry**: Describe meals in natural language (e.g., "3 scrambled eggs and sourdough toast")
- **Saved Foods Library**: Create custom foods for instant logging without AI
- **Workout Tracking**: Log exercises with calories burned

### **Visual Dashboard**

- **7-Day Scrollable History**: See progress at a glance with color-coded indicators
  - 🟢 Green: Goal met (90-110%)
  - 🟠 Orange: Almost there (75-90%)
  - 🔴 Red: Goal missed
  - ⚪ Gray: No data
- **Daily Progress**: Real-time calorie and macro tracking
- **Today's Meals & Workouts**: Organized lists with swipe actions

### **Calendar History**

- **Monthly View**: Visual calendar with goal indicators
- **Tap Any Day**: See detailed breakdown of meals, workouts, and macros
- **Retroactive Logging**: Add entries for past dates via FAB menu

### **Flexible Actions**

- **Floating Action Button (FAB)**: Quick access to:
  - ✨ Log with AI
  - 📚 Saved Foods
  - 🏃 Log Workout
- **Swipe to Edit/Delete**: Manage entries with intuitive gestures
- **Date-Aware Logging**: Log for today or any past date

### **Smart Calculations**

- Net calories: Food consumed - Workouts burned
- Macro breakdown: Protein, Carbs, Fat
- Daily targets with visual progress indicators
- Auto-reset at midnight

---

## 🚀 Getting Started

### **Prerequisites**

- Xcode 15.0+
- iOS 17.0+ deployment target
- Apple Developer account (for device testing)
- OpenAI API key (or use your own Vercel proxy)

### **Setup**

1. **Clone the repository**

```bash
git clone https://github.com/yourusername/QuickCalories.git
cd QuickCalories
```

2. **Configure secrets**

```bash
# Copy the example file
cp Secrets.swift.example Secrets.swift

# Edit Secrets.swift and add your app secret
# This must match the APP_SECRET in your Vercel proxy
```

3. **Deploy Vercel Proxy (Required)**

The app uses a Vercel serverless function to securely proxy OpenAI API requests.

Create `api/proxy.js` in your Vercel project:

```javascript
export default async function handler(req, res) {
  // Verify app secret
  const appSecret = req.headers["x-app-secret"];
  if (appSecret !== process.env.APP_SECRET) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  // Forward to OpenAI
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
    },
    body: JSON.stringify(req.body),
  });

  const data = await response.json();
  res.status(response.status).json(data);
}
```

Set environment variables in Vercel:

```
APP_SECRET=your-random-secret-here
OPENAI_API_KEY=sk-your-openai-key
```

4. **Open in Xcode**

```bash
open QuickCalories.xcodeproj
```

5. **Build and Run**

- Select your device/simulator
- Press ⌘R to build and run

---

## 🏗️ Architecture

### **Technology Stack**

- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Data**: SwiftData (iOS 17+)
- **AI**: OpenAI GPT-4o-mini via Vercel proxy
- **Payments**: StoreKit 2 (placeholder implementation)

### **Key Components**

#### **Views**

- `DashboardView`: Main screen with 7-day history and FAB
- `MonthlyHistoryView`: Calendar view with day details
- `AILogView`: Natural language food logging
- `SavedFoodsView`: Custom foods library
- `LogWorkoutView`: Workout logging
- `WeekScrollView`: 7-day horizontal scroll component

#### **Models**

- `FoodEntry`: Logged meals with macros
- `WorkoutEntry`: Exercise with calories burned
- `SavedFood`: User-defined food templates

#### **Services**

- `OpenAIService`: Handles AI API calls via proxy
- `SettingsManager`: User preferences & rate limiting

---

## 🔒 Security

### **API Key Protection**

- ✅ API keys **never** stored in code
- ✅ Secrets file **excluded** from Git (.gitignore)
- ✅ Vercel proxy with app secret authentication
- ✅ Rate limiting for free tier (1 request/day)

### **What's Public**

- ✅ App structure and UI code
- ✅ SwiftData models
- ✅ View logic

### **What's Private**

- ❌ OpenAI API key (in Vercel env vars)
- ❌ App secret (in Secrets.swift - gitignored)
- ❌ User data (stored locally on device)

---

## 📱 Screenshots

[Add screenshots here]

---

## 🛣️ Roadmap

### **Implemented ✅**

- [x] AI-powered food logging
- [x] Saved foods library
- [x] Workout tracking
- [x] 7-day scrollable history
- [x] Monthly calendar view
- [x] Swipe to edit/delete
- [x] Retroactive logging
- [x] Date-aware system
- [x] Floating action button

### **Planned 🚧**

- [ ] StoreKit 2 subscription implementation
- [ ] Barcode scanner
- [ ] Photo food recognition
- [ ] Export to CSV
- [ ] Widgets
- [ ] Apple Health integration
- [ ] Weekly/monthly statistics

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### **Development Setup**

- Follow the setup instructions above
- Ensure you have your own Vercel proxy deployed
- Never commit secrets or API keys
- Test on real device before submitting PR

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- OpenAI for GPT-4o-mini API
- Apple for SwiftUI & SwiftData frameworks
- Community contributors

---

## 📧 Contact

John Nguyen - [https://www.linkedin.com/in/john-n-009221171/]

Project Link: [https://github.com/johnlookingforwork/QuickCalories](https://github.com/johnlookingforwork/QuickCalories)

---

## ⚠️ Disclaimer

This app is for tracking purposes only. Nutritional data from AI is approximate and may not be 100% accurate. Always consult with a healthcare professional for dietary advice.
