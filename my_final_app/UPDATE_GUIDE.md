# ModSwap Update Guide

## What's Changed

### ✨ New Features
1. **English UI** - All screens now in English
2. **Email Verification** - Users must verify their email before logging in
3. **Dio HTTP Client** - Replaces `http` package (cleaner code, auto-token, logging)

### 📦 New Dependencies

Add Dio to your Flutter project:

```bash
flutter pub add dio
```

You can optionally remove `http` if it's no longer used:
```bash
flutter pub remove http
```

### 🔄 Files Changed

Replace these files in your `lib/` folder:

| File | Status | What changed |
|---|---|---|
| `config/api_config.dart` | Modified | Added `connectTimeout`, `receiveTimeout` |
| `models/user_profile.dart` | Modified | Added `photoURL` field |
| `services/auth_service.dart` | Modified | Added `sendEmailVerification()`, `reloadUser()`, English errors |
| `services/api_service.dart` | **Rewritten** | Now uses DioClient |
| `services/dio_client.dart` | **NEW** | HTTP client with interceptors |
| `screens/login_screen.dart` | Modified | English + email verification check |
| `screens/register_screen.dart` | Modified | English + send verification + modal |
| `screens/complete_profile_screen.dart` | Modified | English |
| `screens/profile_screen.dart` | Modified | English |
| `main.dart` | No change | Same as before |

## Backend
**No changes needed!** Backend already has:
- `email_verified` check in `auth.middleware.ts`
- Trigger that sets up users correctly

## How to Apply

1. Extract the zip and copy files to `lib/`:
```bash
unzip modswap_v2_lib.zip
cp -r modswap_v2/lib/* /path/to/my_final_app/lib/
```

2. Add Dio:
```bash
cd /path/to/my_final_app
flutter pub add dio
```

3. Run:
```bash
# Terminal 1: Backend Emulator
cd /path/to/modswap_backend/functions
npm run serve

# Terminal 2: Flutter
cd /path/to/my_final_app
flutter run -d chrome
```

## Testing the Flow

### Test 1: Register + Email Verification
1. Click "Sign Up"
2. Email: `test1@mail.kmutt.ac.th`, Password: `test1234`
3. Click "Sign Up"
4. ✅ Modal "Check Your Email" appears
5. Click "OK"
6. ✅ Redirected to Login screen (auto-logged out)

### Test 2: Try Login Before Verifying
1. From Login screen, enter `test1@mail.kmutt.ac.th` + `test1234`
2. Click "Login"
3. ✅ Modal "Email Not Verified" appears
4. Click "Resend Email"
5. ✅ Snackbar "Verification email sent again"

### Test 3: Verify Email (in Emulator)

Since Auth Emulator doesn't send real emails:

**Option A: Use Emulator UI (easiest)**
1. Go to http://127.0.0.1:4000/auth
2. Find your user → click ⋮ → Edit
3. Toggle "Email verified" to ON
4. Save

**Option B: Get link from terminal**
1. Look in the emulator terminal logs
2. Find: "To verify the email address... follow this link: http://..."
3. Copy the URL → paste in browser
4. Browser shows "Email verified successfully"

### Test 4: Login After Verifying
1. Go back to app
2. Login with same credentials
3. ✅ Goes to "Complete Your Profile" screen
4. Fill in: Display Name, Student ID (8-11 digits), Faculty, Line ID
5. Click "Save"
6. ✅ Goes to Profile screen with success message

### Test 5: Login Returning User
1. Click logout (top-right)
2. Login again
3. ✅ Goes directly to Profile screen (skips Complete Profile)

## Dio Benefits You'll Notice

### Before (http)
```dart
final headers = await _buildHeaders();
final response = await http.get(Uri.parse('${ApiConfig.apiBaseUrl}/auth/me'), headers: headers);
final data = _handleResponse(response);
return UserProfile.fromJson(data);
```

### After (Dio)
```dart
final data = await _client.get<Map<String, dynamic>>('/auth/me');
return UserProfile.fromJson(data);
```

Token attachment, error parsing, and logging happen automatically via interceptors.

## Debugging Tips

### See HTTP Request/Response Logs
With Dio's `LogInterceptor` enabled in debug mode, every request shows in console:

```
[Dio] *** Request ***
[Dio] uri: http://127.0.0.1:5001/.../api/auth/me
[Dio] method: GET
[Dio] *** Response ***
[Dio] uri: http://127.0.0.1:5001/.../api/auth/me
[Dio] statusCode: 200
[Dio] Response Text:
[Dio] {"success":true,"data":{...}}
```

### Common Issues

**"Cannot connect to server"**
- Check Backend Emulator is running
- Check `projectId` in `api_config.dart` matches your Firebase project

**"Email Not Verified" loop**
- In Emulator, manually toggle "Email verified" in Emulator UI
- Or click the verification link from terminal logs

**Android Emulator can't reach localhost**
- Code already handles this (`10.0.2.2`)
- If still issues, check no firewall is blocking
