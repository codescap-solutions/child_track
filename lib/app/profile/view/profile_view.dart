import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:child_track/core/models/child_profile.dart';
import 'package:child_track/app/home/view_model/bloc/homepage_bloc.dart';
import 'widgets/profile_form.dart';

class ProfileView extends StatefulWidget {
  final VoidCallback onNavigateToHome;

  const ProfileView({
    super.key,
    required this.onNavigateToHome,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final SharedPrefsService _sharedPrefsService;
  List<ChildProfile> _children = [];

  @override
  void initState() {
    super.initState();
    _sharedPrefsService = injector<SharedPrefsService>();
    _loadChildren();
  }

  void _loadChildren() {
    final list = _sharedPrefsService.getChildren();
    if (list.isEmpty) {
      // Initialize with mock kids for high-fidelity demo mapping
      final mockAnanya = ChildProfile(
        childId: 'ananya_mock_id',
        childCode: 'ANANYA123',
        childName: 'Ananya Pandey',
        authToken: 'mock_token_ananya',
        lastActiveAt: DateTime.now(),
      );
      final mockRohan = ChildProfile(
        childId: 'rohan_mock_id',
        childCode: 'ROHAN123',
        childName: 'Rohan Sharma',
        authToken: 'mock_token_rohan',
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      _sharedPrefsService.saveChildren([mockAnanya, mockRohan]);
      setState(() {
        _children = [mockAnanya, mockRohan];
      });
      // Set default active if not set
      if (_sharedPrefsService.getString('child_id') == null) {
        _sharedPrefsService.setString('child_id', 'ananya_mock_id');
        _sharedPrefsService.setString('child_name', 'Ananya Pandey');
      }
    } else {
      setState(() {
        _children = list;
      });
    }
  }

  Future<void> _setActiveChild(ChildProfile child) async {
    // 1. Switch child profile identity in local preferences
    await _sharedPrefsService.switchChild(child.childId);
    
    // 2. Fetch fresh homepage data/sockets for the newly selected child
    injector<HomepageBloc>().add(GetHomepageData());

    setState(() {});

    if (mounted) {
      AppSnackbar.showSuccess(context, 'Switched active profile to ${child.childName}');
      // Return to home map tab after brief delay
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onNavigateToHome();
      });
    }
  }

  void _showMoreActions(ChildProfile child) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text('Edit profile of ${child.childName}'),
                onTap: () async {
                  Navigator.pop(context);
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: Text('Edit Profile - ${child.childName}'),
                          backgroundColor: const Color(0xFF48546A),
                        ),
                        body: SafeArea(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: ProfileForm(
                              isEdit: true,
                              initialName: child.childName,
                              initialCode: child.childCode,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  if (updated == true) {
                    _loadChildren();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: Text('Delete profile of ${child.childName}', style: const TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final list = _sharedPrefsService.getChildren();
                  list.removeWhere((c) => c.childId == child.childId);
                  await _sharedPrefsService.saveChildren(list);
                  
                  // If we deleted the active child, switch to another child or clear
                  final activeChildId = _sharedPrefsService.getString('child_id');
                  if (activeChildId == child.childId) {
                    if (list.isNotEmpty) {
                      await _sharedPrefsService.switchChild(list.first.childId);
                      injector<HomepageBloc>().add(GetHomepageData());
                    } else {
                      await _sharedPrefsService.removeChildId();
                      await _sharedPrefsService.setString('child_name', '');
                    }
                  }
                  
                  _loadChildren();
                  if (mounted) {
                    AppSnackbar.showInfo(context, 'Profile of ${child.childName} deleted');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color(0xFF48546A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leadingWidth: 72,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: GestureDetector(
              onTap: widget.onNavigateToHome,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  color: Color(0xFF0C1D37),
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Profiles',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () async {
                  final added = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Add Profile'),
                          backgroundColor: const Color(0xFF48546A),
                        ),
                        body: const SafeArea(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(20),
                            child: ProfileForm(isEdit: false),
                          ),
                        ),
                      ),
                    ),
                  );
                  if (added == true) {
                    _loadChildren();
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF0C1D37),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<HomepageBloc, HomepageState>(
        builder: (context, state) {
          final activeChildId = _sharedPrefsService.getString('child_id') ?? '';

          // Fetch active child metrics dynamically if homepage sync has loaded
          String activeScreenTime = '02 hrs';
          String activeAvgSpeed = '65 km/hr';
          String activeEntireRoute = '26.6 km';

          if (state is HomepageSuccess) {
            if (state.screentimeToday != null) {
              activeScreenTime = state.screentimeToday!.formattedTotalTime;
              if (activeScreenTime.isEmpty || activeScreenTime == '0m') {
                activeScreenTime = '02 hrs';
              }
            }
            if (state.yesterdayTripSummary != null && state.yesterdayTripSummary!.maxSpeedKmph > 0) {
              activeAvgSpeed = '${state.yesterdayTripSummary!.maxSpeedKmph.toStringAsFixed(0)} km/hr';
            }
            if (state.todayRoute != null && state.todayRoute!.totalDistanceKm > 0) {
              activeEntireRoute = '${state.todayRoute!.totalDistanceKm.toStringAsFixed(1)} km';
            }
          }

          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _children.length,
              itemBuilder: (context, index) {
                final child = _children[index];
                final isActive = child.childId == activeChildId;

                // Status info
                String status;
                if (child.childName.contains('Ananya')) {
                  status = 'at school since 09:40 am';
                } else if (child.childName.contains('Rohan')) {
                  status = 'at home since 03:15 pm';
                } else {
                  status = isActive ? 'online & tracking' : 'last active: just now';
                }

                // Stats calculation
                String screenTime = isActive ? activeScreenTime : (child.childName.contains('Rohan') ? '01 hrs' : '00 hrs');
                String avgSpeed = isActive ? activeAvgSpeed : (child.childName.contains('Rohan') ? '42 km/hr' : '0 km/hr');
                String entireRoute = isActive ? activeEntireRoute : (child.childName.contains('Rohan') ? '18.3 km' : '0.0 km');

                return _buildProfileCard(
                  name: child.childName,
                  status: status,
                  screenTime: screenTime,
                  avgSpeed: avgSpeed,
                  entireRoute: entireRoute,
                  isActive: isActive,
                  onTap: () => _setActiveChild(child),
                  onMorePressed: () => _showMoreActions(child),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String status,
    required String screenTime,
    required String avgSpeed,
    required String entireRoute,
    required bool isActive,
    required VoidCallback onTap,
    required VoidCallback onMorePressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C1D37).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Top Section (Blue Gradient)
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF5F9EFA),
                    Color(0xFF3B82F6),
                    Color(0xFF1D4ED8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative Circle 1
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  // Decorative Circle 2
                  Positioned(
                    bottom: -60,
                    left: -20,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  // Active Badge
                  if (isActive)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'active',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF15803D),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // More Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: onMorePressed,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Avatar & Carousels & Text info
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Avatar Row with chevron indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.chevron_left,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Profile Avatar image/placeholder
                            GestureDetector(
                              onTap: onTap,
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: Colors.blue.shade300,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.chevron_right,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Name text
                        Text(
                          name,
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Status text
                        Text(
                          status,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Page indicator dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 16,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Section (Stats Row)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.access_time_outlined,
                        value: screenTime,
                        label: 'screen time',
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 1,
                      color: const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.bolt_rounded,
                        value: avgSpeed,
                        label: 'avg speed',
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 1,
                      color: const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.location_on_outlined,
                        value: entireRoute,
                        label: 'entire route',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF0C1D37),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0C1D37),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
