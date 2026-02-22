# Security Policy

## 🔒 Security Best Practices

### **For Contributors**

When contributing to QuickCalories, please follow these security guidelines:

#### **1. Never Commit Secrets**
- ❌ Do NOT commit API keys
- ❌ Do NOT commit the `Secrets.swift` file
- ❌ Do NOT commit authentication tokens
- ❌ Do NOT commit Vercel environment variables

#### **2. Use Environment-Based Configuration**
- ✅ Use `Secrets.swift` (gitignored) for local development
- ✅ Keep API keys in Vercel environment variables
- ✅ Use the provided `Secrets.swift.example` template
- ✅ Document any new secret requirements in README

#### **3. API Security**
The app uses a Vercel proxy to protect the OpenAI API key:
- App sends requests to Vercel proxy (not directly to OpenAI)
- Vercel validates `x-app-secret` header
- Vercel forwards to OpenAI with stored API key
- This prevents key extraction from the app binary

---

## 🐛 Reporting a Vulnerability

If you discover a security vulnerability, please:

### **DO:**
1. Email the maintainer directly (not public issue)
2. Provide detailed reproduction steps
3. Allow reasonable time for a fix (90 days)
4. Coordinate disclosure timing

### **DO NOT:**
1. Publicly disclose the vulnerability
2. Exploit the vulnerability
3. Access other users' data

---

## 🛡️ Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

---

## 🔐 Security Features

### **Implemented**
- ✅ API key stored in Vercel (not in app)
- ✅ App secret authentication
- ✅ Local-only data storage (SwiftData)
- ✅ No cloud sync (user data stays on device)
- ✅ Rate limiting for free tier
- ✅ HTTPS for all network requests

### **User Data**
- All food logs stored locally on device
- No personal data sent to servers
- Only food descriptions sent to OpenAI API
- No analytics or tracking
- No third-party SDKs

---

## 📋 Security Checklist for PRs

Before submitting a PR, ensure:

- [ ] No secrets in code
- [ ] No API keys in comments
- [ ] `Secrets.swift` not committed
- [ ] `.gitignore` includes all secret files
- [ ] HTTPS used for all requests
- [ ] User input properly validated
- [ ] No hardcoded credentials

---

## 🔑 API Key Management

### **For End Users**
Users have two options:
1. **Default**: Use app's free tier (1 request/day)
2. **Custom**: Provide their own OpenAI API key in Settings

Custom API keys:
- Stored in local `UserDefaults`
- Never sent to app's servers
- Used directly for OpenAI requests
- Bypass rate limiting

### **For Developers**
Development requires:
1. Vercel account with deployed proxy
2. OpenAI API key in Vercel env vars
3. App secret in local `Secrets.swift`

---

## 📞 Contact

For security concerns, contact:
- Email: security@example.com (update this)
- PGP: [Key ID] (optional)

Response time: Within 48 hours

---

**Last Updated**: February 18, 2026
