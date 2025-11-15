# Unused Files and Code Report

## Summary

This report identifies unused files, classes, methods, and imports in the child_track Flutter project.

---

## 🗑️ Completely Unused Files

### 1. Authentication Views (Not Imported Anywhere)

- **`lib/app/auth/view/onboarding/forgot_password_view.dart`**

  - `ForgotPasswordView` class is never imported or used
  - No navigation to this screen exists

- **`lib/app/auth/view/onboarding/reset_password_view.dart`**

  - `ResetPasswordView` class is never imported or used
  - No navigation to this screen exists

- **`lib/app/auth/view/onboarding/enter_otp_view.dart`**
  - `EnterOtpView` class is never imported or used
  - No navigation to this screen exists

### 2. Settings Views (Not Imported Anywhere)

- **`lib/app/settings/view/about_view.dart`**

  - `AboutView` class is never imported
  - Settings view has empty `onTap: () {}` handler for "About app" tile

- **`lib/app/settings/view/account_view.dart`**

  - `AccountView` class is never imported
  - Settings view has empty `onTap: () {}` handler for "Account" tile

- **`lib/app/settings/view/devices_view.dart`**

  - `DevicesView` class is never imported
  - Settings view has empty `onTap: () {}` handler for "Device" tile

- **`lib/app/settings/view/subscription_view.dart`**

  - `SubscriptionView` class is never imported
  - Settings view has empty `onTap: () {}` handler for "Subscription" tile

- **`lib/app/settings/view/help_view.dart`**
  - `HelpView` class is never imported
  - Settings view has empty `onTap: () {}` handler for "Help" tile
  - Note: `HelpDetailView` is used from this file, but `HelpView` itself is not

### 3. Profile View (Not Imported Anywhere)

- **`lib/app/profile/view/profile_view.dart`**
  - `ProfileView` class is never imported or used
  - No navigation to this screen exists

### 4. Utility Files (Not Used)

- **`lib/core/utils/app_snackbar.dart`**
  - `AppSnackbar` class is never imported or used anywhere in the codebase
  - All methods (`showSuccess`, `showError`, `showWarning`, `showInfo`) are unused

### 5. Duplicate Model File

- **`lib/core/models/base_response.dart`**
  - Contains `BaseResponse` class that is duplicated in `lib/core/services/base_service.dart`
  - The version in `base_service.dart` is the one actually being used
  - `base_response.dart` is never imported (only `base_service.dart` is imported)

### 6. Empty Directory

- **`lib/app/home/model/`**
  - Empty directory with no files

---

## ⚠️ Potentially Unused Files

### 1. Home Page (Commented Out in Main)

- **`lib/app/home/view/home_page.dart`**
  - Imported in `main.dart` but commented out (line 34: `//  home:HomePage()`)
  - Used in `sos_view.dart` (line 92) but `HomeScreen` is the actual screen used in router
  - **Status**: May be legacy code - `HomeScreen` is the active implementation

---

## 🧹 Unused Code Within Files

### 1. Main.dart

- **`SplashScreen` class (lines 40-113)**

  - Complete class is never used
  - Not imported anywhere
  - Not referenced in router or main app

- **Unused imports in main.dart:**
  - `import 'package:child_track/app/home/view/home_page.dart';` (line 3) - Only used in commented code
  - `import 'package:child_track/app/auth/view_model/bloc/auth_state.dart';` (line 2) - Only used in commented `SplashScreen`

### 2. Settings View

- **`_linkTile` method (lines 334-352)**
  - Method is defined but never called
  - All navigation uses inline `MaterialPageRoute` instead

---

## 📊 Statistics

- **Total Unused Files**: 11 files
- **Potentially Unused Files**: 1 file
- **Unused Classes**: 1 (`SplashScreen`)
- **Unused Methods**: 1 (`_linkTile`)
- **Empty Directories**: 1 (`lib/app/home/model/`)

---

## 🔍 Recommendations

### High Priority (Safe to Delete)

1. Delete all unused authentication views (forgot_password, reset_password, enter_otp)
2. Delete unused settings views (about, account, devices, subscription, help)
3. Delete unused profile view
4. Delete `app_snackbar.dart` utility
5. Delete duplicate `base_response.dart` (keep the one in `base_service.dart`)
6. Remove `SplashScreen` class from `main.dart`
7. Remove unused `_linkTile` method from `settings_view.dart`
8. Remove empty `lib/app/home/model/` directory

### Medium Priority (Review Before Deleting)

1. Review `home_page.dart` - determine if it should be removed or if `sos_view.dart` should use `HomeScreen` instead

### Low Priority (Cleanup)

1. Remove unused imports from `main.dart`
2. Consider implementing navigation to the settings views if they're planned features

---

## 📝 Notes

- `SignInView` and `SignUpView` are used (via `onboarding_screen.dart`)
- `HelpDetailView` is used (from `help_view.dart`), but `HelpView` itself is not
- `AppLogger` is actively used throughout the codebase
- All core services (`dio_client`, `location_service`, `shared_prefs_service`) are in use
- `ApiEndpoints` is used in `auth_repository.dart`
