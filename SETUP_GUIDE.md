# QuickCalories Setup Guide

Complete setup instructions for developers who want to run QuickCalories.

---

## 📋 Prerequisites

Before you begin, ensure you have:
- macOS with Xcode 15.0 or later
- iOS 17.0+ deployment target
- Apple Developer account (for device testing)
- OpenAI account with API access
- Vercel account (free tier works)

---

## 🚀 Quick Start (5 Minutes)

### **Step 1: Clone the Repository**

```bash
git clone https://github.com/yourusername/QuickCalories.git
cd QuickCalories
```

### **Step 2: Set Up Secrets**

```bash
# Copy the example file
cp Secrets.swift.example Secrets.swift

# Generate a random secret
# On macOS:
openssl rand -base64 32

# Or use any random string generator
```

Edit `Secrets.swift`:
```swift
struct Secrets {
    static let appSecret = "YOUR_GENERATED_SECRET_HERE"
}
```

**Important**: Keep this secret safe! It must match your Vercel deployment.

### **Step 3: Deploy Vercel Proxy**

#### **Option A: Deploy Button (Easiest)**

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/yourusername/quickcalories-proxy)

#### **Option B: Manual Deployment**

1. Create a new Vercel project
2. Create `api/proxy.js`:

```javascript
export default async function handler(req, res) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-app-secret, Authorization');

  // Handle preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Verify app secret
  const appSecret = req.headers['x-app-secret'];
  if (appSecret !== process.env.APP_SECRET) {
    return res.status(401).json({ error: { message: 'Unauthorized' } });
  }

  // Get API key (user's own or default)
  const userApiKey = req.headers['authorization'];
  const apiKey = userApiKey || `Bearer ${process.env.OPENAI_API_KEY}`;

  try {
    // Forward to OpenAI
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': apiKey
      },
      body: JSON.stringify(req.body)
    });

    const data = await response.json();
    res.status(response.status).json(data);
  } catch (error) {
    res.status(500).json({ error: { message: error.message } });
  }
}
```

3. Set environment variables in Vercel dashboard:

```
APP_SECRET=your-secret-from-step-2
OPENAI_API_KEY=sk-your-openai-key-here
```

4. Deploy:
```bash
vercel deploy --prod
```

5. Note your deployment URL (e.g., `https://your-app.vercel.app`)

### **Step 4: Update OpenAIService**

If your Vercel URL is different, update `OpenAIService.swift`:

```swift
private let proxyURL = "https://your-app.vercel.app/api/proxy"
```

### **Step 5: Build and Run**

```bash
# Open in Xcode
open QuickCalories.xcodeproj

# Or use command line
xcodebuild -scheme QuickCalories -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## 🔧 Detailed Configuration

### **OpenAI API Key**

1. Go to [platform.openai.com](https://platform.openai.com)
2. Create an account / Sign in
3. Navigate to API Keys
4. Create a new secret key
5. Copy and save it (you won't see it again)
6. Add it to Vercel environment variables

**Cost**: GPT-4o-mini is very cheap (~$0.15 per 1M tokens). Typical food description: ~$0.001

### **App Secret Security**

The app secret prevents unauthorized use of your Vercel proxy:
- Should be long and random (32+ characters)
- Must match between `Secrets.swift` and Vercel
- Never commit to Git
- Rotate periodically

### **Rate Limiting**

Free tier configuration (in `SettingsManager.swift`):
```swift
func canMakeAIRequest() -> Bool {
    // Free tier: 1 request per day
    return dailyAIRequestCount < 1
}
```

To change:
```swift
return dailyAIRequestCount < 10  // 10 requests per day
```

---

## 🧪 Testing

### **Test AI Logging**

1. Run app in simulator
2. Tap FAB (+)
3. Select "Log with AI"
4. Type: "3 scrambled eggs and sourdough toast"
5. Tap "Log"

**Expected**: Food entry appears with ~400 calories

### **Test Free Tier Limit**

1. Log one meal with AI
2. Try to log another
3. Should see paywall prompt (or success if you have subscription logic)

### **Test Saved Foods**

1. Tap FAB → Saved Foods
2. Tap + to add
3. Fill in details
4. Save
5. Tap food to log

---

## 🐛 Troubleshooting

### **"Daily AI request limit reached"**

**Cause**: Free tier limit (1 request/day)

**Solutions**:
- Wait until midnight (local time)
- Provide your own API key in Settings
- Update rate limit in code
- Implement subscription

### **"Network error" or "Unauthorized"**

**Cause**: Vercel proxy not configured correctly

**Check**:
1. Vercel deployment is live
2. `APP_SECRET` matches `Secrets.swift`
3. `OPENAI_API_KEY` is set in Vercel
4. Proxy URL is correct in `OpenAIService.swift`

### **"Unable to parse nutritional data"**

**Cause**: OpenAI response format issue

**Solutions**:
- Check your OpenAI account has credits
- Verify GPT-4o-mini model access
- Test proxy endpoint directly

### **Build Errors**

**"Cannot find 'Secrets' in scope"**

**Solution**: Create `Secrets.swift` from template:
```bash
cp Secrets.swift.example Secrets.swift
```

---

## 🔄 Updating

### **Pull Latest Changes**

```bash
git pull origin main
```

### **After Pulling**

1. Check if `Secrets.swift.example` changed
2. Update your `Secrets.swift` if needed
3. Rebuild project

---

## 📊 Monitoring

### **Vercel Logs**

View API requests in Vercel dashboard:
1. Go to your Vercel project
2. Click "Logs"
3. Filter by function: `api/proxy`

### **OpenAI Usage**

Check costs at [platform.openai.com/usage](https://platform.openai.com/usage)

---

## 🚢 Production Deployment

### **Before App Store Submission**

- [ ] Remove all placeholder API keys
- [ ] Implement real StoreKit 2 subscriptions
- [ ] Add privacy policy URL
- [ ] Add terms of service URL
- [ ] Test on multiple devices
- [ ] Test rate limiting
- [ ] Test subscription flow
- [ ] Enable app analytics (if desired)

### **Environment Variables**

Production Vercel environment:
```
APP_SECRET=different-from-dev
OPENAI_API_KEY=production-key
NODE_ENV=production
```

---

## 💡 Tips

### **Development Best Practices**

1. **Use Git branches** for features
2. **Never commit secrets** (check with `git diff`)
3. **Test on real device** before shipping
4. **Monitor API costs** regularly

### **Cost Optimization**

1. Use `temperature: 0.3` for consistent responses
2. Limit `max_tokens: 200` for food parsing
3. Cache common foods locally
4. Consider batch processing

---

## 📞 Need Help?

- **Issues**: [GitHub Issues](https://github.com/yourusername/QuickCalories/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/QuickCalories/discussions)
- **Email**: support@example.com

---

## 🎉 You're Ready!

Your QuickCalories setup is complete. Start tracking calories with AI!

**Next Steps**:
1. Customize onboarding defaults
2. Adjust macro percentages
3. Add your own saved foods
4. Style the UI to your preference
