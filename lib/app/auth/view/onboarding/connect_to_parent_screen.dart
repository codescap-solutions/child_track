import 'package:child_track/app/childapp/view/sos_view.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/services/location_service.dart';
import 'package:child_track/core/services/background_location_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/widgets/common_textfield.dart';

class ConnectToParentScreen extends StatefulWidget {
  const ConnectToParentScreen({super.key});

  @override
  State<ConnectToParentScreen> createState() => _ConnectToParentScreenState();
}

class _ConnectToParentScreenState extends State<ConnectToParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childCodeController = TextEditingController();
  final _childRepo = injector<ChildRepo>();
  bool _isLoading = false;

  @override
  void dispose() {
    _childCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  _buildHeader(),
                  const SizedBox(height: AppSizes.spacingXL),
                  _buildChildCodeField(),
                  const SizedBox(height: AppSizes.spacingL),
                  _buildInfoText(),
                  const Spacer(),
                  CommonButton(
                    text: 'Connect',
                    onPressed: _isLoading ? null : _connectToParent,
                    isLoading: _isLoading,
                  ),
                  // const SizedBox(height: AppSizes.spacingM),
                  // CommonButton(
                  //   text: 'Skip for now',
                  //   onPressed: _isLoading ? null : _skipConnection,
                  //   isOutlined: true,
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
          ),
          child: const Icon(
            Icons.family_restroom,
            size: 50,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: AppSizes.spacingL),
        Text(
          'Connect to Parent',
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingS),
        Text(
          'Enter your child code to connect and share your location and screen time',
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildChildCodeField() {
    return CommonTextField(
      fillColor: AppColors.containerBackground,
      controller: _childCodeController,
      hintText: 'Enter child code',
      labelText: 'Child Code',
      textInputAction: TextInputAction.done,
      inputFormatters: [UpperCaseTextFormatter()],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter child code';
        }
        if (value.length < 4) {
          return 'Child code must be at least 4 characters';
        }
        return null;
      },
      onSubmitted: (_) => _connectToParent(),
    );
  }

  Widget _buildInfoText() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const SizedBox(width: AppSizes.spacingS),
          Expanded(
            child: Text(
              'By connecting, you allow your parent to view your location and screen time.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToParent() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final childCode = _childCodeController.text.trim().toUpperCase();

        AppLogger.info('Logging in with child code: $childCode');

        // Call child login API
        final response = await _childRepo.childLogin(childCode: childCode);

        if (response.isSuccess) {
          AppLogger.info('Child login successful');

          // Ensure location permission is set to "always allow"
          final locationService = LocationService();
          bool hasAlwaysPermission = await _ensureAlwaysAllowPermission(
            context,
            locationService,
          );

          if (!mounted) return;

          if (!hasAlwaysPermission) {
            // Permission not granted - show error and don't proceed
            AppSnackbar.showError(
              context,
              'Location permission must be set to "Always Allow" to track your location in background.',
            );
            setState(() => _isLoading = false);
            return;
          }

          // Wait a moment after permission is granted to ensure system has updated
          await Future.delayed(const Duration(milliseconds: 500));

          // Verify permission one more time before starting service
          final finalPermission = await locationService.checkPermission();
          if (finalPermission != LocationPermission.always) {
            if (mounted) {
              AppSnackbar.showError(
                context,
                'Please ensure "Always Allow" permission is enabled in Settings.',
              );
              setState(() => _isLoading = false);
            }
            return;
          }

          // Start background location service for continuous tracking
          try {
            await BackgroundLocationService().start();
            AppLogger.info('Background location service started');
          } catch (e, stackTrace) {
            AppLogger.error('Failed to start background service: $e');
            AppLogger.error('Stack trace: $stackTrace');
            if (mounted) {
              AppSnackbar.showError(
                context,
                'Failed to start location tracking. Please try again.',
              );
              setState(() => _isLoading = false);
              return;
            }
          }

          if (mounted) {
            AppSnackbar.showSuccess(context, 'Connected successfully!');

            // Navigate to SOS view (child app main screen)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SosView()),
            );
          }
        } else {
          if (mounted) {
            AppSnackbar.showError(context, response.message);
          }
        }
      } catch (e) {
        AppLogger.error('Error connecting to parent: ${e.toString()}');
        if (mounted) {
          AppSnackbar.showError(context, 'Failed to connect: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  /// Ensure location permission is set to "always allow"
  /// Shows dialog repeatedly until user grants "always allow" permission
  Future<bool> _ensureAlwaysAllowPermission(
    BuildContext context,
    LocationService locationService,
  ) async {
    int maxAttempts = 5; // Prevent infinite loop
    int attempts = 0;

    while (attempts < maxAttempts) {
      attempts++;

      // Request "always allow" permission
      final result = await locationService.requestAlwaysAllowPermission();
      final hasAlwaysPermission = result['granted'] as bool;
      final needsSettings = result['needsSettings'] as bool;

      if (hasAlwaysPermission) {
        AppLogger.info('Always allow permission granted');
        return true;
      }

      // Check current permission status
      final currentPermission = await locationService.checkPermission();

      if (!mounted) return false;

      // Show dialog explaining why "always allow" is needed
      // If needsSettings is true, it means user needs to go to Settings to enable "Always allow"
      final shouldRetry = await _showLocationPermissionDialog(
        context,
        needsSettings || currentPermission == LocationPermission.deniedForever,
        currentPermission == LocationPermission.whileInUse,
      );

      if (!shouldRetry) {
        // User cancelled or doesn't want to grant permission
        return false;
      }

      // If needs settings or permanently denied, try to open settings
      if (needsSettings ||
          currentPermission == LocationPermission.deniedForever) {
        final openedSettings = await locationService.openLocationSettings();
        if (openedSettings) {
          // Wait longer for user to change settings and return to app
          // The app might be resumed when user returns from Settings
          await Future.delayed(const Duration(seconds: 3));

          // Check if app is still mounted after returning from Settings
          if (!mounted) return false;

          // Re-check permission after returning from Settings
          final recheckPermission = await locationService.checkPermission();
          if (recheckPermission == LocationPermission.always) {
            AppLogger.info(
              'Always allow permission granted after returning from Settings',
            );
            return true;
          }

          continue;
        }
      }
    }

    // Max attempts reached
    return false;
  }

  /// Show dialog explaining why "always allow" permission is needed
  Future<bool> _showLocationPermissionDialog(
    BuildContext context,
    bool needsSettings,
    bool hasWhileInUsePermission,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
            ),
            title: Text(
              'Location Permission Required',
              style: AppTextStyles.headline6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This app needs "Always Allow" location permission to track your location in the background, even when the app is closed.',
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: AppSizes.spacingM),
                if (needsSettings)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasWhileInUsePermission
                            ? 'You have granted "While using the app" permission. To enable background tracking, please:'
                            : 'Please enable "Always Allow" location permission in your device settings.',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasWhileInUsePermission) ...[
                        const SizedBox(height: AppSizes.spacingS),
                        Text(
                          '1. Tap "Open Settings" below\n2. Go to "Permissions" → "Location"\n3. Select "Allow all the time"',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Text(
                    'Please select "Always Allow" when prompted.',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            actions: [
              if (needsSettings)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  needsSettings ? 'Open Settings' : 'Grant Permission',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
