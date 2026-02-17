# Geofencing API Integration Guide

## Overview
This guide explains how to use the Geofencing feature in the NaviQ Mobile App. The feature allows users to create, manage, and monitor geofences for their children.

## Architecture

### Components

1. **Model** (`geofence_model.dart`)
   - `Geofence`: Main model representing a geofence
   - `CreateGeofenceRequest`: Request model for creating geofences
   - `UpdateGeofenceRequest`: Request model for updating geofences
   - `PlaceAutocompleteResult`: Model for location suggestions

2. **Repository** (`geofence_repository.dart`)
   - `GeofenceRepository`: Handles all API calls for geofence operations
   - Methods:
     - `createGeofence()`: Create a new geofence
     - `getGeofences()`: Fetch all geofences for a child
     - `updateGeofence()`: Update an existing geofence
     - `toggleGeofenceLock()`: Lock/unlock a geofence
     - `deleteGeofence()`: Delete a geofence

3. **BLoC** (`geofence_bloc.dart`)
   - `GeofenceBloc`: Business logic component
   - Events:
     - `GetGeofencesRequested`: Fetch geofences
     - `CreateGeofenceRequested`: Create a geofence
     - `UpdateGeofenceRequested`: Update a geofence
     - `DeleteGeofenceRequested`: Delete a geofence
     - `ToggleGeofenceLockRequested`: Lock/unlock a geofence
     - `SearchLocationSuggestionsRequested`: Search for location suggestions
   - States:
     - `GeofenceLoading`: Loading state
     - `GeofencesLoaded`: Geofences loaded successfully
     - `GeofenceCreated`: Geofence created successfully
     - `GeofenceUpdated`: Geofence updated successfully
     - `GeofenceDeleted`: Geofence deleted successfully
     - `GeofenceLockToggled`: Geofence lock status toggled
     - `LocationSuggestionsLoaded`: Location suggestions loaded
     - `LocationSuggestionsCleared`: Suggestions cleared
     - `GeofenceError`: Error state with message

4. **Views**
   - `GeoFencingView`: Main geofencing management screen
   - `LocationSelectionScreen`: Map-based location selection screen
   - `GeoFenceFormSheet`: Modal form for creating/editing geofences

## API Endpoints

Base URL: `https://naviq-server.codescap.com/api/v1/`

### Create Geofence
- **Endpoint**: `POST /parent/geofences`
- **Request Body**:
  ```json
  {
    "name": "School",
    "category": "Education",
    "radius": 30,
    "child_id": "string",
    "parent_id": "string",
    "latitude": 11.258753,
    "longitude": 75.780410,
    "is_locked": false
  }
  ```
- **Response**: 201 Created with geofence object

### Get Geofences List
- **Endpoint**: `GET /parent/geofences?child_id={child_id}`
- **Response**: 200 OK with array of geofences

### Update Geofence
- **Endpoint**: `PUT /parent/geofences/{id}`
- **Request Body**: Same as create (partial update allowed)
- **Response**: 200 OK with updated geofence

### Lock/Unlock Geofence
- **Endpoint**: `PATCH /parent/geofences/{id}/lock`
- **Request Body**:
  ```json
  {
    "is_locked": true
  }
  ```
- **Response**: 200 OK with updated geofence

### Delete Geofence
- **Endpoint**: `DELETE /parent/geofences/{id}`
- **Response**: 200 OK

## Usage Examples

### 1. Initialize BLoC in a Widget

```dart
@override
void initState() {
  super.initState();
  // Load geofences when the screen initializes
  context.read<GeofenceBloc>().add(
    GetGeofencesRequested(childId: widget.childId),
  );
}
```

### 2. Create a Geofence

```dart
final request = CreateGeofenceRequest(
  name: "School",
  category: "Education",
  radius: 30,
  childId: "child123",
  parentId: "parent456",
  latitude: 11.258753,
  longitude: 75.780410,
  isLocked: false,
);

context.read<GeofenceBloc>().add(
  CreateGeofenceRequested(request: request),
);
```

### 3. Handle BLoC States

```dart
BlocListener<GeofenceBloc, GeofenceState>(
  listener: (context, state) {
    if (state is GeofencesLoaded) {
      setState(() {
        _geofences = state.geofences;
      });
    } else if (state is GeofenceError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: // your widget
)
```

### 4. Search for Location Suggestions

```dart
context.read<GeofenceBloc>().add(
  SearchLocationSuggestionsRequested(query: "New York"),
);
```

### 5. Toggle Geofence Lock

```dart
context.read<GeofenceBloc>().add(
  ToggleGeofenceLockRequested(
    id: geofenceId,
    isLocked: true,
  ),
);
```

### 6. Delete a Geofence

```dart
context.read<GeofenceBloc>().add(
  DeleteGeofenceRequested(id: geofenceId),
);
```

## Location Search Feature

The location search feature uses the `geocoding` package to provide location suggestions:

1. User types in the search field
2. `SearchLocationSuggestionsRequested` event is dispatched
3. BLoC uses the geocoding package to get location results
4. Results are displayed as a dropdown list
5. User selects a location and the map animates to that location

## Integration with UI

### GeoFencingView
- Displays three tabs (Add Places, Add Places, View Places)
- Shows list of geofences with toggle switches
- Handles creation, deletion, and lock/unlock operations

### LocationSelectionScreen
- Shows an interactive map centered on Bengaluru
- Search bar with location suggestions
- Users can tap on map to select location
- Opens form sheet for entering geofence details

### GeoFenceFormSheet
- Form inputs for:
  - Geofence name
  - Category (Home, School, Office, etc.)
  - Radius (in meters)
- Validates inputs before creating geofence
- Shows loading indicator during API call

## Error Handling

All operations include error handling:
- Network errors
- Validation errors
- Server errors

Errors are displayed using SnackBar notifications to the user.

## Dependencies

The geofencing feature depends on:
- `flutter_bloc`: State management
- `geocoding`: Location suggestion and reverse geocoding
- `google_maps_flutter`: Map display and interaction
- `http`: HTTP client (for potential custom API calls)

## Best Practices

1. Always provide `childId` and `parentId` when creating geofences
2. Validate location data before creating geofences
3. Use appropriate categories for better organization
4. Set reasonable radius values (typically 30-500 meters)
5. Handle error states gracefully
6. Provide user feedback for all operations

## Future Enhancements

- Real-time geofence notifications
- Geofence activity history
- Batch geofence operations
- Custom category creation
- Geofence overlapping detection
- Geofence statistics and analytics
