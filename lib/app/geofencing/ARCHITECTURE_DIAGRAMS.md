# Implementation Architecture Diagram

## System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         GEOFENCING FEATURE FLOW                             │
└─────────────────────────────────────────────────────────────────────────────┘

                          ┌──────────────────────┐
                          │  GeoFencingView     │
                          │  (Main Screen)      │
                          └──────┬───────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
        ┌───────────▼──────────────┐  ┌───────▼──────────────────┐
        │   Radius Management      │  │  Geofence List Display  │
        │   (Upper Section)        │  │  (Tab 3)                │
        └───────────┬──────────────┘  └───────┬──────────────────┘
                    │                         │
        ┌───────────▼────────────────┐        │
        │  Display:                   │        │
        │  "30mtr radius...   [edit]" │        │
        └───────────┬────────────────┘        └─────────┬─────────┐
                    │                               │         │
           User taps "edit"              Lock/Unlock  Delete  Update
                    │                         │        │        │
        ┌───────────▼──────────────────┐     └────────┴────┬───┘
        │  _showRadiusEditDialog()     │                   │
        │                              │        ┌──────────▼────────┐
        │  Shows AlertDialog with:     │        │ Delete Geofence   │
        │  • Current radius input      │        │ Confirmation      │
        │  • Cancel button             │        │ Dialog            │
        │  • Save button               │        └───────────────────┘
        └───────────┬──────────────────┘
                    │
    ┌───────────────┴──────────────────┐
    │                                   │
 Cancel Tapped                    Save Tapped
    │                                   │
 Close Dialog            int.tryParse(text)
    │                                   │
    │                    ┌──────────────▼──────────────┐
    │                    │ Validate (> 0 && is int)   │
    │                    └──────────────┬──────────────┘
    │                                   │
    │                    ┌──────────────▼──────────────┐
    │                    │ setState(() {               │
    │                    │   _defaultRadius = newVal;  │
    │                    │ })                           │
    │                    └──────────────┬──────────────┘
    │                                   │
    │                    ┌──────────────▼──────────────┐
    │                    │ Show SnackBar confirmation  │
    │                    │ "Radius changed to 50m"    │
    │                    └──────────────┬──────────────┘
    │                                   │
    │                    ┌──────────────▼──────────────┐
    │                    │ _buildRadiusInfo() rebuilds │
    │                    │ "50mtr radius...    [edit]" │
    │                    └──────────────────────────────┘
    │
    └──────────────────────────────────────────────────────────┐


┌─────────────────────────────────────────────────────────────────────────────┐
│              LOCATION SELECTION SCREEN FLOW                                  │
└─────────────────────────────────────────────────────────────────────────────┘

            ┌────────────────────────────────┐
            │  LocationSelectionScreen       │
            │  (Map-based location picker)   │
            └────────────────┬───────────────┘
                             │
            ┌────────────────┴────────────────┐
            │                                 │
   ┌────────▼──────────────┐    ┌────────────▼────────────┐
   │  Search Bar           │    │  Google Map             │
   │  (Top of screen)      │    │  (Full screen)          │
   └────────┬──────────────┘    └────────────┬────────────┘
            │                                 │
   User types location      Tap on map (any position)
            │                                 │
   ┌────────▼──────────────────────┐        │
   │ context.read<GeofenceBloc>()  │        │
   │   .add(                         │        │
   │  SearchLocationSuggestionsREQ  │        │
   │   )                             │        │
   └────────┬──────────────────────┘        │
            │                                 │
   ┌────────▼──────────────────────┐        │
   │ BlocBuilder<GeofenceBloc>()    │        │
   │ Shows suggestions dropdown     │        │
   │ (max 200px height)             │        │
   └────────┬──────────────────────┘        │
            │                                 │
   ┌────────▼──────────────────────┐        │
   │ User selects from suggestions  │        │
   │          OR                    │        │
   │ Direct tap on map              │        │
   └────────┬──────────────────────┘        │
            │                                 │
   ┌────────▼──────────────────────┐────────▼────────────────┐
   │                                │                        │
   │  _addMarker(LatLng pos):       │  Direct tap handler:   │
   │  • _markers.clear()           │  • _addMarker(pos)     │
   │  • Add red Marker             │  • setState() to       │
   │  • Update _selectedPosition   │    close keyboard      │
   │  • setState()                 │                        │
   │                                │                        │
   └────────┬──────────────────────┘────────┬─────────────────┘
            │                               │
            │           ┌───────────────────┘
            │           │
   ┌────────▼───────────▼────────────────────┐
   │ MapViewWidget rebuilds with markers     │
   │ _markers parameter passed               │
   │                                          │
   │ Red marker displays on map:             │
   │ • Position: selected LatLng             │
   │ • Color: Red                            │
   │ • InfoWindow: "Selected Location"       │
   └────────┬─────────────────────────────────┘
            │
   ┌────────▼──────────────────────────────────┐
   │ if (_isMapReady) {                        │
   │   controller.animateCamera(               │
   │     CameraUpdate.newLatLngZoom(pos, 16)  │
   │   )                                       │
   │ }                                         │
   │ Otherwise: Don't animate                 │
   └────────┬──────────────────────────────────┘
            │
   ┌────────▼──────────────────────────────────┐
   │ showModalBottomSheet() for form entry     │
   │ GeoFenceFormSheet appears                 │
   │ (User enters name, category, radius)     │
   └────────┬──────────────────────────────────┘
            │
   ┌────────▼──────────────────────────────────┐
   │ User fills form and taps Save              │
   │ CreateGeofenceRequested event             │
   │ API POST /parent/geofences                │
   └─────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│              KEYBOARD HANDLING (Camera Fix)                                  │
└─────────────────────────────────────────────────────────────────────────────┘

BEFORE (Broken):
  Map initializes → Camera animates to position A
  User types in search → Keyboard appears
  setState() triggered → Map rebuilds
  onMapCreated called AGAIN → Camera re-animates
  User stops typing → Keyboard hides
  Screen rebuilds again → Camera repositions
  ❌ Result: Erratic camera jumping

AFTER (Fixed):
  Map initializes → _isMapReady = false
  onMapCreated runs → Completes controller
  500ms delay
  Camera animates to position A
  _isMapReady = true
  
  User types in search → Keyboard appears
  setState() triggered → Map rebuilds
  onMapCreated NOT called → if (!_controller.isCompleted) skips
  Camera stays at position A ✅
  
  User stops typing → Keyboard hides
  setState() triggered → Map rebuilds
  onMapCreated NOT called → still skipped
  Camera stays at position A ✅
  
  User selects new location → _addMarker() runs
  if (_isMapReady) → true, so camera animates
  New animation happens correctly ✅

KEY: if (!_controller.isCompleted) ensures onMapCreated only runs ONCE


┌─────────────────────────────────────────────────────────────────────────────┐
│              STATE VARIABLES REFERENCE                                       │
└─────────────────────────────────────────────────────────────────────────────┘

GeoFencingView State:
  int _selectedTabIndex = 1;           // Current tab (0, 1, or 2)
  PageController _pageController;      // Manages PageView animation
  List<Geofence> _geofences = [];      // List of geofences from API
  int _defaultRadius = 30;             // ✨ NEW: Editable default radius

LocationSelectionScreenState:
  Completer<GoogleMapController> _controller;     // Map controller
  TextEditingController _searchController;        // Search input
  late LatLng _selectedPosition;                   // Last tapped position
  bool _showSuggestions = false;                   // Show/hide dropdown
  Set<Marker> _markers = {};                       // ✨ NEW: Location markers
  bool _isMapReady = false;                        // ✨ NEW: Map initialization flag


┌─────────────────────────────────────────────────────────────────────────────┐
│              USER SCENARIOS                                                  │
└─────────────────────────────────────────────────────────────────────────────┘

Scenario 1: User changes default radius
  1. See "30mtr radius will be locked [edit]"
  2. Tap "edit"
  3. Dialog shows with "30"
  4. Clear and type "50"
  5. Tap "Save"
  6. Toast: "Default radius changed to 50m"
  7. See "50mtr radius will be locked [edit]"
  ✅ Complete

Scenario 2: User creates geofence via direct tap
  1. See map with search bar
  2. Tap map at desired location
  3. Red marker appears at that spot
  4. Form sheet opens (Name, Category, Radius)
  5. Default radius (50m) is pre-filled
  6. User can change it in the form
  7. Tap Save
  8. Geofence created with custom radius
  ✅ Complete

Scenario 3: User creates geofence via search
  1. Type "Park" in search
  2. See suggestions dropdown
  3. Tap "Central Park, NYC"
  4. Red marker appears at park location
  5. Map animates to park
  6. Keyboard closes
  7. Form sheet opens
  8. User fills details and saves
  ✅ Complete + Smooth UX

Scenario 4: User interacts with keyboard
  1. Map showing selected location
  2. Start typing in search
  3. Keyboard appears
  4. Map DOES NOT jump around ✅
  5. Clear search field
  6. Keyboard disappears
  7. Map still shows same location ✅
  8. No unwanted camera movements
  ✅ Complete + Keyboard-proof

```

---

## Component Interaction Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      App Architecture                           │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────────┐
                    │   GeoFencingView │
                    │   (Main Screen)  │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
    ┌─────────▼────────┐ ┌──▼────┐ ┌──────▼──────────┐
    │ _buildRadiusInfo │ │ Tabs  │ │ _buildGeofence │
    │ GestureDetector  │ │       │ │ ListViewList    │
    │ onTap→dialog     │ │       │ │ (Display List)  │
    └──────────────────┘ └───────┘ └─────────────────┘
              │                              │
    ┌─────────▼──────────────┐    ┌──────────▼─────────────┐
    │ _showRadiusEditDialog()│    │ GeoPlaceCard x N       │
    │ AlertDialog            │    │ • Name, Category       │
    │ • TextField input      │    │ • Radius display       │
    │ • Save/Cancel buttons  │    │ • Toggle switch        │
    └───────────────────────┘    │ • Delete menu          │
                                 └────────────────────────┘
                                         │
              ┌──────────────────────────▼──────────────────────┐
              │       LocationSelectionScreen                    │
              │       (Map Mode - Separate Route)                │
              └─────────────┬──────────────────────────────────┘
                            │
           ┌────────────────┬────────────────┐
           │                │                │
    ┌──────▼─────┐  ┌──────▼──────┐  ┌─────▼────────┐
    │ Search Bar  │  │ Map Widget  │  │ Marker Layer │
    │ TextField   │  │ GoogleMaps  │  │ (Red Dots)   │
    │ Suggestions │  │ Tap Handler │  │ _addMarker() │
    │ Dropdown    │  │             │  │              │
    └──────┬──────┘  └──────┬──────┘  └──────────────┘
           │                │
           │ User selection │ User tap
           │                │
           └────┬───────────┘
                │
         ┌──────▼──────────────┐
         │  _addMarker(pos)    │
         │ • Clear old marker  │
         │ • Add red marker    │
         │ • Update position   │
         │ • setState()        │
         └──────┬──────────────┘
                │
         ┌──────▼──────────────────────┐
         │ if (_isMapReady)             │
         │  animateCamera(pos)          │
         │ else                         │
         │  wait for ready              │
         └──────┬──────────────────────┘
                │
         ┌──────▼──────────────────┐
         │ showModalBottomSheet()   │
         │ GeoFenceFormSheet        │
         │ • Name input             │
         │ • Category dropdown      │
         │ • Radius input (default) │
         │ • Create button          │
         └──────┬──────────────────┘
                │
         ┌──────▼──────────────────┐
         │ CreateGeofenceRequested  │
         │ → GeofenceBloc           │
         │ → GeofenceRepository     │
         │ → API POST /parent/...   │
         └──────────────────────────┘
```

All components are connected through BLoC state management! 🎉
