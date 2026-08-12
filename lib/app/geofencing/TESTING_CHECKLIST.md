# Geofencing Features - Testing Checklist

## ✅ Feature 1: Radius Management (Edit Functionality)

### Basic Functionality
- [ ] **Display Test**
  - [ ] Geofencing view shows "30mtr radius will be locked [edit]" on load
  - [ ] Default radius is 30 meters
  - [ ] "edit" text is displayed in blue (#0070F0)
  - [ ] "edit" text is tappable

- [ ] **Dialog Opening**
  - [ ] Tapping "edit" opens AlertDialog
  - [ ] Dialog title shows "Edit Default Radius"
  - [ ] TextField contains current radius value (30)
  - [ ] TextField keyboard type is number
  - [ ] TextField placeholder is "Enter radius in meters"
  - [ ] Dialog has "Cancel" button
  - [ ] Dialog has "Save" button
  - [ ] Cancel button closes dialog without changes
  - [ ] Dialog is dismissible by tapping outside

- [ ] **User Input**
  - [ ] User can clear current value
  - [ ] User can type new integer value
  - [ ] User can type values like "50", "100", "200"
  - [ ] User types decimal values (e.g., "50.5") - should truncate to "50"
  - [ ] User types negative value (e.g., "-10") - should be rejected
  - [ ] User types "0" - should be rejected
  - [ ] User types text/symbols - should be ignored by keyboard

- [ ] **Save Button**
  - [ ] Clicking Save with valid value updates display
  - [ ] Updated text shows "50mtr radius will be locked [edit]"
  - [ ] SnackBar shows "Default radius changed to 50m"
  - [ ] SnackBar disappears after 2 seconds
  - [ ] Dialog closes after save
  - [ ] New radius persists on widget rebuild
  - [ ] Multiple edits work (30 → 50 → 100 → etc)

- [ ] **Validation**
  - [ ] Saving with empty field shows error SnackBar
  - [ ] Saving with negative value shows error SnackBar
  - [ ] Saving with "0" shows error SnackBar
  - [ ] Saving with text shows error SnackBar
  - [ ] Error messages are clear and helpful

### Advanced Scenarios
- [ ] **Multiple Edits**
  - [ ] Edit radius from 30 → 50 ✓
  - [ ] Edit radius from 50 → 75 ✓
  - [ ] Edit radius from 75 → 30 (back to original) ✓
  - [ ] Radius correctly displays after each change

- [ ] **Edge Cases**
  - [ ] Edit with very large number (9999) ✓
  - [ ] Edit with very small number (1) ✓
  - [ ] Rapidly tap edit multiple times → only one dialog should show
  - [ ] Edit while search suggestions are open (if applicable)
  - [ ] Edit while keyboard is visible → dialogs should appear over keyboard

- [ ] **State Persistence**
  - [ ] Change radius to 50
  - [ ] Navigate to different tab
  - [ ] Return to radius section → Still shows 50 ✓
  - [ ] Radius used in new geofence creation defaults to 50 (check form)

---

## ✅ Feature 2: Map Markers (Location Selection)

### Marker Appearance
- [ ] **Initial State**
  - [ ] No markers visible on map load
  - [ ] Map defaults to Bengaluru (12.9716, 77.5946)
  - [ ] Map zoom level is 14

- [ ] **Tap to Create Marker**
  - [ ] Tapping anywhere on map creates red marker
  - [ ] Marker appears at exact tap location
  - [ ] Marker color is RED (BitmapDescriptor.hueRed)
  - [ ] Marker shows info window "Selected Location" on tap
  - [ ] Marker has unique ID "selected_location"

- [ ] **Single Marker Limitation**
  - [ ] First tap creates marker at location A
  - [ ] Second tap at location B removes marker from A
  - [ ] Only one marker visible at any time
  - [ ] Previous marker completely disappears

### Search Feature Integration
- [ ] **Search Suggestions Display**
  - [ ] Type location name (e.g., "park")
  - [ ] Suggestions appear in dropdown (max 200px height)
  - [ ] List shows multiple results
  - [ ] Each suggestion shows main_text and description

- [ ] **Select from Suggestions**
  - [ ] Tap on suggestion from list
  - [ ] Red marker appears at suggested location
  - [ ] Search bar auto-fills with location name
  - [ ] Suggestions dropdown closes after selection
  - [ ] Previous marker (if any) is cleared
  - [ ] Map animates smoothly to new location (if map is ready)

- [ ] **Marker Position Accuracy**
  - [ ] Marker appears at correct latitude/longitude
  - [ ] Marker position matches search result coordinates
  - [ ] Marker position matches tap coordinates

### Camera Animation
- [ ] **Initial Animation**
  - [ ] Map animates to initial position (Bengaluru) on load
  - [ ] Animation is smooth
  - [ ] Takes ~1 second to complete

- [ ] **Search Result Animation**
  - [ ] After selecting from search, camera animates to location
  - [ ] Animation zoom level is 16
  - [ ] Animation is smooth and not jerky
  - [ ] Animation completes within reasonable time

- [ ] **Camera Fix (Keyboard Handling)**
  - [ ] Tap map to add marker at location A
  - [ ] Map shows location A
  - [ ] Click search field → Keyboard appears
  - [ ] Map DOES NOT relocate (stays at A)
  - [ ] Type search query
  - [ ] Map still at location A
  - [ ] Clear search field
  - [ ] Keyboard hides
  - [ ] Map still at location A (no unwanted jumps)
  - [ ] Tap suggestion → Camera animates to new location (intentional)

---

## ✅ Feature 3: Fixed Camera Relocation

### Problem Scenario (Should be FIXED)
- [ ] **Before Fix (Would Be Broken):**
  - [ ] Keyboard appears → Map relocates ❌
  - [ ] Keyboard disappears → Map relocates ❌
  - [ ] Any state change → Map relocates ❌

- [ ] **After Fix (Should Work Correctly):**
  - [ ] Keyboard appears → Map STAYS in place ✅
  - [ ] Keyboard disappears → Map STAYS in place ✅
  - [ ] State changes → Map STAYS in place ✅

### Specific Test Cases
- [ ] **Test 1: Keyboard Appearance**
  1. Go to Location Selection Screen
  2. Tap map to place marker at location A
  3. Click search bar → Keyboard appears
  4. Map location should NOT change ✅
  5. Screenshot map position before and after

- [ ] **Test 2: Keyboard Disappearance**
  1. Search bar is active with keyboard shown
  2. Tap outside search bar or press back
  3. Keyboard disappears
  4. Map should NOT jump ✅

- [ ] **Test 3: Rapid State Changes**
  1. Tap search bar
  2. Type "p"
  3. Keyboard appears
  4. Suggestions might appear/disappear
  5. Map should remain stable throughout ✅

- [ ] **Test 4: Widget Rebuild During Search**
  1. Tap map (creates marker)
  2. Type in search while marker visible
  3. Suggestions dropdown appears/updates
  4. Map should not relocate ✅

### Technical Verification
- [ ] **onMapCreated Call Count**
  - [ ] onMapCreated called exactly ONCE during screen lifetime
  - Not called on keyboard appearance
  - Not called on keyboard disappearance
  - Not called on search input changes
  - Not called on screen rotations (if applicable)

- [ ] **_isMapReady Flag**
  - [ ] Starts as `false`
  - [ ] Set to `true` after first camera animation
  - [ ] Remains `true` throughout screen lifecycle

- [ ] **_controller Completion**
  - [ ] _controller completes only once
  - [ ] if (!_controller.isCompleted) prevents re-completion
  - [ ] No "Future already completed" errors in logs

---

## 🧪 Integration Tests

### Test 1: Full User Journey (Radius + Map + Create)
```
1. Open GeoFencingView
2. Edit radius from 30 → 50 minutes
3. Tap "Add Place" button
4. Go to LocationSelectionScreen
5. Search for "Coffee Shop"
6. Select from suggestions
7. Red marker appears
8. Form sheet opens
9. See radius field pre-filled with 50
10. User can override it if needed
11. Fill in Name: "My Coffee Shop"
12. Select Category: "Shop"
13. Tap Save
14. Return to GeoFencingView
15. See new geofence in list with 50m radius
✅ Complete flow works
```

### Test 2: Multiple Geofence Creation
```
1. Create geofence 1 (Home, 30m)
2. Create geofence 2 (School, 50m)
3. Create geofence 3 (Office, 75m)
4. All three visible in list
5. Edit radius to 100
6. Create geofence 4 (Park, 100m)
7. New geofence has 100m radius
8. Edit radius back to 30
9. Old geofences keep their radiuses
✅ Radius only affects new geofences
```

### Test 3: Error Scenarios
```
1. Location without coordinates
   → Error handling in _addMarker check
   
2. API failure during geofence creation
   → Error SnackBar should appear
   
3. Network timeout
   → Loading indicator shown
   → Error message displayed
   
4. Invalid input in radius dialog
   → Show error, stay in dialog
   → User can correct and save
✅ Error handling works smoothly
```

---

## 🔍 Visual Verification

### Colors & Styling
- [ ] **Radius Display**
  - [ ] Text color matches app theme (check app_colors.dart)
  - [ ] "edit" text is bright blue (#0070F0)
  - [ ] Font sizes are correct (13px)
  - [ ] Alignment is centered

- [ ] **Map Markers**
  - [ ] Marker color is distinctly RED
  - [ ] Marker is clearly visible on map
  - [ ] Marker doesn't interfere with map controls
  - [ ] Info window text is readable

- [ ] **Dialog & Forms**
  - [ ] Dialog has proper shadow/elevation
  - [ ] TextField has proper borders
  - [ ] Buttons are properly sized and spaced
  - [ ] Text is readable on all devices

### Responsiveness
- [ ] Test on different screen sizes:
  - [ ] Small phone (narrow width)
  - [ ] Regular phone
  - [ ] Large phone
  - [ ] Tablet (if applicable)
- [ ] All elements properly visible
- [ ] No text overflow
- [ ] No UI cutoffs

---

## ⚡ Performance Tests

- [ ] Map doesn't lag when adding marker
- [ ] Marker addition is instant (< 100ms)
- [ ] Camera animation is smooth (60 fps)
- [ ] Dialog opens without delay (< 200ms)
- [ ] Search suggestions load quickly
- [ ] No memory leaks after multiple edits
- [ ] No memory leaks after multiple marker placements

---

## 🐛 Bug Checklist

### Potential Issues to Watch For
- [ ] Double tapping edit opens multiple dialogs
- [ ] Marker doesn't clear when tapping new location
- [ ] Camera jumps when keyboard appears
- [ ] TextField input allows non-numeric values
- [ ] Save button doesn't work after canceling once
- [ ] Selected position not updated when marker added
- [ ] Search suggestions don't show correctly
- [ ] Animation doesn't complete to new location
- [ ] Info window doesn't appear on marker tap
- [ ] Previous marker visible behind new marker

---

## 📋 Final Sign-Off

| Feature | Status | Date | Tester |
|---------|--------|------|--------|
| Radius Edit Dialog | ⬜ | ______ | _______ |
| Radius Validation | ⬜ | ______ | _______ |
| Map Markers | ⬜ | ______ | _______ |
| Camera Fix | ⬜ | ______ | _______ |
| Full Integration | ⬜ | ______ | _______ |
| Visual Check | ⬜ | ______ | _______ |
| Performance | ⬜ | ______ | _______ |

**Overall Status:** 🔴 Not Tested | 🟡 In Progress | 🟢 Passed

---

## Notes & Issues Found

```
[Space for tester notes]




```

---

## Rollback Instructions (If Needed)

If issues are found:

1. **Revert geo_fencing_view.dart changes:**
   - Remove `int _defaultRadius = 30;`
   - Remove `_showRadiusEditDialog()` method
   - Change `_buildRadiusInfo(context)` back to `_buildRadiusInfo()`

2. **Revert location_selections.dart changes:**
   - Remove `Set<Marker> _markers = {};` and `bool _isMapReady = false;`
   - Remove `_addMarker()` method
   - Change back to original `onMapCreated` and `onMapTap`

3. **Git Command:**
   ```bash
   git checkout HEAD~1 -- lib/app/geofencing/view/*
   ```

---

Happy Testing! 🚀
