import 'package:child_track/app/social_apps/view_model/bloc/social_apps_bloc.dart';
import 'package:child_track/core/di/injector.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import '../../settings/view/settings_view.dart';
import 'widgets/social_app_item.dart';

class SocialAppsView extends StatefulWidget {
  const SocialAppsView({super.key});

  @override
  State<SocialAppsView> createState() => _SocialAppsViewState();
}

class _SocialAppsViewState extends State<SocialAppsView> {
  late SocialAppsBloc _bloc;
  int _selectedTabIndex = 1; // Default to Today (index 1)

  @override
  void initState() {
    super.initState();
    _bloc = injector<SocialAppsBloc>();
    _fetchDataForIndex(_selectedTabIndex);
  }

  void _fetchDataForIndex(int index) {
    DateTime date;
    if (index == 0) {
      date = DateTime.now().subtract(const Duration(days: 1)); // Yesterday
    } else if (index == 1) {
      date = DateTime.now(); // Today
    } else {
      // Week - API doesn't seem to support range yet based on single date param, defaulting to today for now
      // Or maybe the user wants 7 days data? The API response example shows "2026-01-05": [...]
      // Let's assume Today for Week tab for now or handle it later.
      date = DateTime.now();
    }

    final dateStr = date.toIso8601String().split('T')[0];
    _bloc.add(FetchAppUsage(date: dateStr));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _bloc,
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
                BlocBuilder<SocialAppsBloc, SocialAppsState>(
                  builder: (context, state) {
                    if (state is SocialAppsLoaded) {
                      return _ScreenTimeHeader(
                        totalTime: state.data.totalUsageTimeFormatted,
                      );
                    }
                    return const _ScreenTimeHeader(totalTime: '--');
                  },
                ),
                const SizedBox(height: AppSizes.spacingM),
                const FilterTabs(),
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
          return const Center(child: CircularProgressIndicator());
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
          final dailyData = state.data.dailyUsage[state.selectedDate] ?? [];

          if (dailyData.isEmpty) {
            return Center(
              child: Text(
                'No usage data for this date',
                style: AppTextStyles.textSecondary,
              ),
            );
          }

          return ListView.builder(
            itemCount: dailyData.length + 1, // +1 for Next button
            itemBuilder: (context, index) {
              if (index == dailyData.length) {
                return Column(
                  children: [
                    const SizedBox(height: AppSizes.spacingL),
                    CommonButton(
                      text: 'Next',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsView()),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingL),
                  ],
                );
              }

              final app = dailyData[index];

              ImageProvider iconProvider;
              if (app.iconBase64 != null && app.iconBase64!.isNotEmpty) {
                try {
                  iconProvider = MemoryImage(base64Decode(app.iconBase64!));
                } catch (e) {
                  iconProvider = const AssetImage('assets/images/device.png');
                }
              } else {
                iconProvider = const AssetImage('assets/images/device.png');
              }

              return SocialAppItem(
                // We don't have icon path from API, native side sends it, but here we are fetching from server.
                // The server API doesn't seem to return iconUrl.
                // We might need to use a default icon or if we stored icons locally?
                // For now, use default.
                icon: iconProvider,
                name: app.appName.isNotEmpty ? app.appName : app.packageName,
                usage: app.usageTimeFormatted,
                isLocked: false,
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
  const _ScreenTimeHeader({required this.totalTime});

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
