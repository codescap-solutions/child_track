import 'package:child_track/app/social_apps/model/app_usage_model.dart';
import 'package:child_track/app/social_apps/view_model/bloc/social_apps_bloc.dart';
import 'package:child_track/app/social_apps/view_model/bloc/app_lock_bloc.dart';
import 'package:child_track/app/social_apps/view_model/bloc/app_lock_state.dart';
import 'package:child_track/app/social_apps/view_model/bloc/app_lock_event.dart';
import 'package:child_track/core/di/injector.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:child_track/core/widgets/social_apps_shimmer.dart';
import 'widgets/social_app_item.dart';

class SocialAppsView extends StatefulWidget {
  const SocialAppsView({super.key});

  @override
  State<SocialAppsView> createState() => _SocialAppsViewState();
}

class _SocialAppsViewState extends State<SocialAppsView> {
  late SocialAppsBloc _bloc;
  late AppLockBloc _appLockBloc;
  int _selectedTabIndex = 1; // Default to Today (index 1)
  int _selectedFilterIndex = 0; // Default to All (index 0)

  @override
  void initState() {
    super.initState();
    _bloc = injector<SocialAppsBloc>();
    _appLockBloc = injector<AppLockBloc>();
    _fetchDataForIndex(_selectedTabIndex);
  }

  void _fetchDataForIndex(int index) {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];

    if (index == 0) {
      // Yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final dateStr = yesterday.toIso8601String().split('T')[0];
      _bloc.add(FetchAppUsage(date: dateStr));
    } else if (index == 1) {
      // Today
      _bloc.add(FetchAppUsage(date: todayStr));
    } else {
      // Week — last 7 days (today to 6 days ago)
      final weekStart = now.subtract(const Duration(days: 6));
      final startDateStr = weekStart.toIso8601String().split('T')[0];
      _bloc.add(
        FetchAppUsage(
          date: todayStr,
          startDate: startDateStr,
          endDate: todayStr,
        ),
      );
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => _bloc),
        BlocProvider.value(value: _appLockBloc..add(FetchLockedApps())),
      ],
      child: Scaffold(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.spacingM),
                AdvancedSegmentedTab(
                  onTabChanged: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                    _fetchDataForIndex(index);
                  },
                ),
                const SizedBox(height: AppSizes.spacingM),
                BlocBuilder<AppLockBloc, AppLockState>(
                  builder: (context, lockState) {
                    final lockedPackages = lockState is AppLockLoaded
                        ? lockState.lockedPackages
                        : const <String>{};
                    return BlocBuilder<SocialAppsBloc, SocialAppsState>(
                      builder: (context, state) {
                        // Collect all package names visible right now
                        List<String> allPackages = [];
                        if (state is SocialAppsLoaded) {
                          final data = _selectedTabIndex == 2
                              ? state.data.summaryApps
                              : state.data.dailyUsage[state.selectedDate] ?? [];
                          allPackages = data.map((a) => a.packageName).toList();
                        }
                        return _ScreenTimeHeader(
                          totalTime: state is SocialAppsLoaded
                              ? state.data.totalUsageTimeFormatted
                              : '--',
                          allPackages: allPackages,
                          lockedPackages: lockedPackages,
                          appLockBloc: _appLockBloc,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSizes.spacingM),
                BlocBuilder<AppLockBloc, AppLockState>(
                  builder: (context, lockState) {
                    final lockedPackages = lockState is AppLockLoaded
                        ? lockState.lockedPackages
                        : const <String>{};
                    
                    return BlocBuilder<SocialAppsBloc, SocialAppsState>(
                      builder: (context, state) {
                        int blockedCount = 0;
                        if (state is SocialAppsLoaded) {
                          final data = _selectedTabIndex == 2
                              ? state.data.summaryApps
                              : state.data.dailyUsage[state.selectedDate] ?? [];
                          blockedCount = data.where((a) => lockedPackages.contains(a.packageName)).length;
                        }

                        return FilterTabs(
                          selectedIndex: _selectedFilterIndex,
                          blockedCount: blockedCount,
                          onFilterChanged: (index) {
                            setState(() {
                              _selectedFilterIndex = index;
                            });
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSizes.spacingS),
                Expanded(child: _buildAppsList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppsList() {
    return BlocBuilder<SocialAppsBloc, SocialAppsState>(
      builder: (context, state) {
        if (state is SocialAppsLoading) {
          return const SocialAppsShimmer();
        } else if (state is SocialAppsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message, style: AppTextStyles.body1),
                const SizedBox(height: AppSizes.spacingS),
                CommonButton(
                  text: 'Retry',
                  onPressed: () => _fetchDataForIndex(_selectedTabIndex),
                ),
              ],
            ),
          );
        } else if (state is SocialAppsLoaded) {
          // For Week tab (index 2), merge all days into one combined list
          List<AppUsageItem> dailyData;
          if (_selectedTabIndex == 2) {
            // Summary is provided pre-aggregated by the backend
            dailyData = state.data.summaryApps;
          } else {
            dailyData = state.data.dailyUsage[state.selectedDate] ?? [];
          }

          if (dailyData.isEmpty) {
            return Center(
              child: Text(
                'No usage data for this period',
                style: AppTextStyles.textSecondary,
              ),
            );
          }

          // Apply Filter
          return BlocBuilder<AppLockBloc, AppLockState>(
            builder: (context, lockState) {
              final lockedPackages = lockState is AppLockLoaded
                  ? lockState.lockedPackages
                  : const <String>{};

              final filteredData = dailyData.where((app) {
                if (_selectedFilterIndex == 0) return true; // All
                final isLocked = lockedPackages.contains(app.packageName);
                if (_selectedFilterIndex == 1) return !isLocked; // Active
                if (_selectedFilterIndex == 2) return isLocked; // Blocked
                return true;
              }).toList();

              if (filteredData.isEmpty) {
                return Center(
                  child: Text(
                    _selectedFilterIndex == 1
                        ? 'No active apps'
                        : _selectedFilterIndex == 2
                            ? 'No blocked apps'
                            : 'No apps found',
                    style: AppTextStyles.textSecondary,
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredData.length + 1, // +1 for spacing
                itemBuilder: (context, index) {
                  if (index == filteredData.length) {
                    return Column(
                      children: [const SizedBox(height: AppSizes.spacingL)],
                    );
                  }

                  final app = filteredData[index];

              // Detect iOS entries: they use opaque tokens like "usage_cat_XXX"
              final isIOSEntry =
                  app.platform == 'ios' ||
                  app.packageName.startsWith('usage_cat_') ||
                  app.packageName.startsWith('usage_app_');

              ImageProvider iconProvider;
              if (isIOSEntry) {
                // iOS entries can't have real icons — use default
                iconProvider = const AssetImage(
                  'assets/images/APK_format_icon_(2014-2019).png',
                );
              } else if (app.iconUrl?.isNotEmpty ?? false) {
                iconProvider = NetworkImage(app.iconUrl!);
              } else if (app.iconBase64?.isNotEmpty ?? false) {
                try {
                  iconProvider = MemoryImage(base64Decode(app.iconBase64!));
                } catch (e) {
                  iconProvider = const AssetImage(
                    'assets/images/APK_format_icon_(2014-2019).png',
                  );
                }
              } else {
                iconProvider = const AssetImage(
                  'assets/images/APK_format_icon_(2014-2019).png',
                );
              }

              // Clean display name for iOS entries
              String displayName;
              if (isIOSEntry) {
                // Use the resolved name from backend (written by Swift Label resolver)
                // If it still looks like a hash placeholder, use numbered fallback
                final backendName = app.appName;
                if (backendName.isNotEmpty &&
                    !backendName.startsWith('Tracked') &&
                    !backendName.contains('(') &&
                    backendName.length > 2) {
                  displayName = backendName;
                } else {
                  // Fallback: "Category 1" / "App 1" based on type
                  final isCategory = app.packageName.startsWith('usage_cat_');
                  displayName = isCategory
                      ? 'Category ${index + 1}'
                      : 'App ${index + 1}';
                }
              } else {
                displayName = app.appName.isNotEmpty
                    ? app.appName
                    : app.packageName;
              }

              return BlocBuilder<AppLockBloc, AppLockState>(
                builder: (context, lockState) {
                  final isLocked =
                      lockState is AppLockLoaded &&
                      lockState.lockedPackages.contains(app.packageName);

                  return SocialAppItem(
                    icon: iconProvider,
                    name: displayName,
                    usage: app.usageTimeFormatted,
                    isLocked: isLocked,
                    onLockToggle: (isLocked, duration) {
                      _appLockBloc.add(
                        ToggleAppLock(
                          packageName: app.packageName,
                          appName: displayName,
                          isLocked: isLocked,
                          durationMinutes: duration,
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    }
    return const SizedBox.shrink();
  },
);
}
}

class _ScreenTimeHeader extends StatelessWidget {
  final String totalTime;
  final List<String> allPackages;
  final Set<String> lockedPackages;
  final AppLockBloc? appLockBloc;

  const _ScreenTimeHeader({
    required this.totalTime,
    this.allPackages = const [],
    this.lockedPackages = const {},
    this.appLockBloc,
  });

  /// True when every visible app is already locked
  bool get _allBlocked =>
      allPackages.isNotEmpty &&
      allPackages.every((p) => lockedPackages.contains(p));

  Future<void> _onBlockAll(BuildContext context) async {
    if (allPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No apps to block')),
      );
      return;
    }

    // Show duration picker dialog
    final Duration? duration = await showDialog<Duration>(
      context: context,
      builder: (ctx) => _BlockAllDurationDialog(appCount: allPackages.length),
    );
    if (duration == null) return; // user cancelled

    appLockBloc?.add(
      BlockAllApps(
        packageNames: allPackages,
        durationMinutes: duration.inMinutes,
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Blocking ${allPackages.length} apps'
            '${duration.inMinutes > 0 ? ' for ${duration.inMinutes} min' : ''}...',
          ),
        ),
      );
    }
  }

  void _onUnblockAll(BuildContext context) {
    for (final pkg in allPackages) {
      if (lockedPackages.contains(pkg)) {
        appLockBloc?.add(
          ToggleAppLock(packageName: pkg, isLocked: false),
        );
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unblocking ${allPackages.length} apps...'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBlocked = _allBlocked;

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
                    Text(totalTime, style: AppTextStyles.headline5),
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: allBlocked
                  ? SizedBox(
                      key: const ValueKey('unblock'),
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusM),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.lock_open_rounded, size: 20),
                        label: Text(
                          'Unblock All Apps',
                          style: AppTextStyles.button,
                        ),
                        onPressed: () => _onUnblockAll(context),
                      ),
                    )
                  : SizedBox(
                      key: const ValueKey('block'),
                      width: double.infinity,
                      child: CommonButton(
                        width: double.infinity,
                        text: 'Block Everything temporarily',
                        onPressed: allPackages.isEmpty
                            ? null
                            : () => _onBlockAll(context),
                        height: 50,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Duration picker dialog for Block All ───

class _BlockAllDurationDialog extends StatefulWidget {
  final int appCount;
  const _BlockAllDurationDialog({required this.appCount});

  @override
  State<_BlockAllDurationDialog> createState() => _BlockAllDurationDialogState();
}

class _BlockAllDurationDialogState extends State<_BlockAllDurationDialog> {
  int _hours = 0;
  int _minutes = 30;

  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minCtrl;

  @override
  void initState() {
    super.initState();
    _hourCtrl = FixedExtentScrollController(initialItem: _hours);
    _minCtrl = FixedExtentScrollController(initialItem: _minutes ~/ 5);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  String get _description {
    if (_hours == 0 && _minutes == 0) return 'Select a duration';
    if (_hours == 0) return '${widget.appCount} apps will be locked for $_minutes min';
    if (_minutes == 0) return '${widget.appCount} apps will be locked for $_hours hr';
    return '${widget.appCount} apps will be locked for $_hours hr $_minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Block All ${widget.appCount} Apps',
                      style: AppTextStyles.headline6.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                children: [
                  // Description chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryColor),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _description,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Scroll pickers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWheel(
                        label: 'Hrs',
                        count: 24,
                        selected: _hours,
                        controller: _hourCtrl,
                        onChanged: (i) => setState(() => _hours = i),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          ' : ',
                          style: AppTextStyles.headline4.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      _buildWheel(
                        label: 'Min',
                        count: 12,
                        selected: _minutes ~/ 5,
                        controller: _minCtrl,
                        valueLabel: (i) => (i * 5).toString().padLeft(2, '0'),
                        onChanged: (i) => setState(() => _minutes = i * 5),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  CommonButton(
                    text: 'Block All Apps',
                    onPressed: (_hours == 0 && _minutes == 0)
                        ? null
                        : () => Navigator.pop(
                              context,
                              Duration(hours: _hours, minutes: _minutes),
                            ),
                    width: double.infinity,
                    height: 50,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel({
    required String label,
    required int count,
    required int selected,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onChanged,
    String Function(int)? valueLabel,
  }) {
    const itemH = 52.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.overline.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 90,
          height: itemH * 3,
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: itemH,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: itemH,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.10),
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: AppColors.primaryColor.withOpacity(0.25),
                        ),
                      ),
                    ),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: controller,
                  itemExtent: itemH,
                  diameterRatio: 1.4,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: onChanged,
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (ctx, i) {
                      if (i < 0 || i >= count) return null;
                      final isSel = i == selected;
                      final lbl = valueLabel != null
                          ? valueLabel(i)
                          : i.toString().padLeft(2, '0');
                      return Center(
                        child: Text(
                          lbl,
                          style: isSel
                              ? AppTextStyles.headline4.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                )
                              : AppTextStyles.body1.copyWith(
                                  color: AppColors.textHint,
                                ),
                        ),
                      );
                    },
                    childCount: count,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FilterTabs extends StatelessWidget {
  final int selectedIndex;
  final int blockedCount;
  final ValueChanged<int> onFilterChanged;

  const FilterTabs({
    super.key,
    required this.selectedIndex,
    required this.blockedCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = ["All", "Active", "Blocked ($blockedCount)"];

    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = index == selectedIndex;

        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            onTap: () => onFilterChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xffE8EEFF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primaryColor.withOpacity(0.3) : Colors.transparent,
                ),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.primaryColor : Colors.black87,
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
  final ValueChanged<int>? onTabChanged;
  const AdvancedSegmentedTab({super.key, this.onTabChanged});

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
    _controller = TabController(
      initialIndex: 1,
      length: tabs.length,
      vsync: this,
    );
    _controller.addListener(() {
      if (!_controller.indexIsChanging) {
        widget.onTabChanged?.call(_controller.index);
        setState(() {});
      }
    });
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
            dividerHeight: 0,
            controller: _controller,
            indicatorColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
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
            onTap: (index) {
              // Handled by listener
            },
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
