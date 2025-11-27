import 'dart:io';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/app/childapp/view_model/device_info_service.dart';
import 'package:child_track/app/social_apps/model/installed_app_model.dart';
import '../../settings/view/settings_view.dart';
import 'widgets/social_app_item.dart';

class SocialAppsView extends StatefulWidget {
  const SocialAppsView({super.key});

  @override
  State<SocialAppsView> createState() => _SocialAppsViewState();
}

class _SocialAppsViewState extends State<SocialAppsView> {
  final ChildInfoService _deviceInfoService = ChildInfoService();
  List<InstalledApp> _apps = [];
  bool _isLoading = true;
  String? _error;
  int _totalApps = 0;
  int _loadedApps = 0;
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure the first frame is rendered before starting the async operation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApps();
    });
  }

  Future<void> _loadApps() async {
    debugPrint('_loadApps called - setting loading to true');

    // Ensure loading state is set immediately
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
        _loadedApps = 0;
        _totalApps = 0;
        _loadingMessage = 'Initializing...';
      });
    }

    // Add a small delay to ensure the loader is visible
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      debugPrint('Starting to fetch apps...');

      if (mounted) {
        setState(() {
          _loadingMessage = 'Fetching installed apps...';
        });
      }

      final apps = await _deviceInfoService.getInstalledApps();
      debugPrint('Apps fetched: ${apps.length}');

      if (mounted) {
        setState(() {
          _totalApps = apps.length;
          _loadingMessage = 'Processing apps...';
        });
      }

      // Process apps in batches to show progress
      if (apps.isNotEmpty) {
        const batchSize = 10;
        final processedApps = <InstalledApp>[];

        for (int i = 0; i < apps.length; i += batchSize) {
          final end = (i + batchSize < apps.length)
              ? i + batchSize
              : apps.length;
          final batch = apps.sublist(i, end);
          processedApps.addAll(batch);

          if (mounted) {
            setState(() {
              _loadedApps = processedApps.length;
              _loadingMessage = 'Loading apps...';
            });
          }

          // Small delay to show progress animation
          await Future.delayed(const Duration(milliseconds: 50));
        }

        if (mounted) {
          setState(() {
            _apps = processedApps;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _apps = [];
            _isLoading = false;
          });
        }
      }

      debugPrint('Loading set to false');
    } catch (e) {
      debugPrint('Error loading apps: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print loading state
    debugPrint(
      'SocialAppsView build - isLoading: $_isLoading, apps count: ${_apps.length}',
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Scroll', style: AppTextStyles.headline3),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingView()
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizes.spacingM),
                    AdvancedSegmentedTab(),
                    //onst _PeriodTabs(),
                    const SizedBox(height: AppSizes.spacingM),
                    const _ScreenTimeHeader(),
                    const SizedBox(height: AppSizes.spacingM),
                    const FilterTabs(),
                    const SizedBox(height: AppSizes.spacingS),
                    Expanded(child: _buildAppsList()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingView() {
    final progress = _totalApps > 0 ? (_loadedApps / _totalApps) : 0.0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor,
                ),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: AppSizes.spacingL),
            Text(
              _loadingMessage,
              style: AppTextStyles.headline6.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.spacingM),
            // Progress bar
            if (_totalApps > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingXL,
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.borderColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                    Text(
                      '$_loadedApps / $_totalApps apps loaded',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.subtitle2.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                ),
                child: Text(
                  'Fetching installed apps from your device',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),
              Text(
                'This may take a few moments',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppsList() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading apps',
              style: AppTextStyles.subtitle2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingS),
            Text(
              _error!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingM),
            CommonButton(text: 'Retry', onPressed: _loadApps),
          ],
        ),
      );
    }

    if (_apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No apps found',
              style: AppTextStyles.subtitle2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingS),
            CommonButton(text: 'Refresh', onPressed: _loadApps),
          ],
        ),
      );
    }

    return ListView(
      children: [
        ..._apps.map((app) {
          // Determine icon
          ImageProvider? iconProvider;
          if (app.iconPath != null && File(app.iconPath!).existsSync()) {
            iconProvider = FileImage(File(app.iconPath!));
          } else {
            // Use default icon
            iconProvider = const AssetImage('assets/images/device.png');
          }

          return SocialAppItem(
            icon: iconProvider,
            name: app.appName,
            usage:
                _getRandomUsage(), // Placeholder - you can implement real usage tracking later
            isLocked:
                false, // Placeholder - you can implement lock state management
          );
        }),
        const SizedBox(height: AppSizes.spacingL),
        CommonButton(
          text: 'Next',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsView()),
          ),
        ),
      ],
    );
  }

  String _getRandomUsage() {
    // Placeholder - replace with actual usage data when available
    final minutes = (DateTime.now().millisecond % 120) + 5;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '$hours hr $mins min' : '$hours hr';
    }
    return '$minutes min';
  }
}

class _ScreenTimeHeader extends StatelessWidget {
  const _ScreenTimeHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Screentime',
                      style: AppTextStyles.subtitle2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('02 hrs', style: AppTextStyles.headline5),
                  ],
                ),
                const SizedBox(width: AppSizes.spacingM),
                Text(
                  textAlign: TextAlign.end,
                  '40% lesser this last week',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingM),
            CommonButton(
              width: double.infinity,
              text: 'Block Everything temporarily',
              onPressed: () {},
              height: 50,
            ),
          ],
        ),
      ),
    );
  }
}

class FilterTabs extends StatefulWidget {
  const FilterTabs({super.key});

  @override
  State<FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends State<FilterTabs> {
  int selectedIndex = 0;

  final tabs = ["All", "Active", "Blocked (0)"];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = index == selectedIndex;

        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            onTap: () => setState(() => selectedIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xffE8EEFF)
                    : const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class AdvancedSegmentedTab extends StatefulWidget {
  const AdvancedSegmentedTab({super.key});

  @override
  State<AdvancedSegmentedTab> createState() => _AdvancedSegmentedTabState();
}

class _AdvancedSegmentedTabState extends State<AdvancedSegmentedTab>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  final tabs = ["Yesterday", "Today", "Week"];

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: tabs.length, vsync: this);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xffEEF3FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Sliding animation background
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: _alignmentForIndex(_controller.index),
            child: Container(
              width: MediaQuery.of(context).size.width / 3 - 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Actual tabs
          TabBar(
            controller: _controller,
            indicatorColor: Colors.transparent,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black87,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            tabs: tabs.map((e) => Tab(text: e)).toList(),
          ),
        ],
      ),
    );
  }

  /// Converts index to alignment for sliding animation
  Alignment _alignmentForIndex(int index) {
    switch (index) {
      case 0:
        return Alignment.centerLeft;
      case 1:
        return Alignment.center;
      case 2:
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }
}
