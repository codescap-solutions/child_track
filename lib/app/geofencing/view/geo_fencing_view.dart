import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../social_apps/view/social_apps_view.dart';
import 'location_selections.dart';

ValueNotifier<List<Map<String, String>>> locationList = ValueNotifier([]);

class GeoFencingView extends StatefulWidget {
  const GeoFencingView({super.key});

  @override
  State<GeoFencingView> createState() => _GeoFencingViewState();
}

class _GeoFencingViewState extends State<GeoFencingView> {
  int _selectedTabIndex = 1;
  PageController _pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Geofencing', style: AppTextStyles.headline3),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
        child: Column(
          children: [
            const SizedBox(height: AppSizes.spacingM),
            AdvancedSegmentedTab(
              onTabChanged: (index) {
                setState(() {
                  _selectedTabIndex = index;
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              },
            ),
            const SizedBox(height: 10),
            _buildRadiusInfo(),
            const SizedBox(height: 10),
            ValueListenableBuilder(
              valueListenable: locationList,
              builder: (context, value, child) {
                return Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ListView(
                        children: const [
                          GeoPlaceCard(
                            title: "Add Home",
                            subtitle: "given radius will be marked",
                            isPrimary: true,
                          ),
                          GeoPlaceCard(
                            title: "Add School",
                            subtitle: "given radius will be marked",
                            isPrimary: true,
                          ),
                          GeoPlaceCard(title: "Add Place"),
                        ],
                      ),
                      ListView(
                        children: const [
                          GeoPlaceCard(
                            title: "Add Home",
                            subtitle: "given radius will be marked",
                            isPrimary: true,
                          ),
                          GeoPlaceCard(
                            title: "Add School",
                            subtitle: "given radius will be marked",
                            isPrimary: true,
                          ),
                          GeoPlaceCard(title: "Add Place"),
                        ],
                      ),
                      ListView(
                        children: const [
                          GeoPlaceCard(
                            title: "Home",
                            subtitle: "26hrs spend last week",
                            isPrimary: true,
                            toggleValue: true,
                          ),
                          GeoPlaceCard(
                            title: "School",
                            subtitle: "12 hrs spend last week",
                            isPrimary: true,
                            toggleValue: true,
                          ),
                          GeoPlaceCard(
                            title: "Office",
                            subtitle: "8 hrs spend last week",
                            isPrimary: true,
                            toggleValue: false,
                          ),
                          GeoPlaceCard(
                            title: "Park",
                            subtitle: "2 hrs spend last week",
                            isPrimary: true,
                            toggleValue: false,
                          ),
                          GeoPlaceCard(
                            title: "Shop",
                            subtitle: "1 hr spend last week",
                            isPrimary: true,
                            toggleValue: true,
                          ),
                          GeoPlaceCard(
                            title: "Gym",
                            subtitle: "30 mins spend last week",
                            isPrimary: true,
                            toggleValue: false,
                          ),
                          GeoPlaceCard(
                            title: "Mosque",
                            subtitle: "1 hr spend last week",
                            isPrimary: true,
                            toggleValue: true,
                          ),
                          GeoPlaceCard(
                            title: "Church",
                            subtitle: "30 mins spend last week",
                            isPrimary: true,
                            toggleValue: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildRadiusInfo() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "30mtr radius will be locked",
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () {},
          child: const Text(
            "edit",
            style: TextStyle(
              color: Color(0xFF0070F0),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class GeoPlaceCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isPrimary;
  final bool toggleValue;

  const GeoPlaceCard({
    super.key,
    required this.title,
    this.subtitle,
    this.toggleValue = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title.contains('Add')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LocationSelectionScreen()),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.04),
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPrimary
                    ? const Color(0xFF0C5391)
                    : const Color(0xFF666363),
              ),
              child: Container(
                decoration: isPrimary && !title.contains('Add')
                    ? null
                    : BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                child: Icon(
                  isPrimary && !title.contains('Add')
                      ? getIconByName(title)
                      : Icons.add,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFF0070F0),
                      ),
                    ),
                  ),
              ],
            ),
            if (!title.contains('Add')) ...[
              Spacer(),
              CustomToggleSwitch(value: toggleValue, onChanged: (value) {}),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomToggleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomToggleSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<CustomToggleSwitch> createState() => _CustomToggleSwitchState();
}

class _CustomToggleSwitchState extends State<CustomToggleSwitch> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.value;
  }

  void toggle() {
    setState(() {
      isOn = !isOn;
    });
    widget.onChanged(isOn);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 58,
        height: 33,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isOn ? const Color(0xFF0070F0) : Color(0xFF898C8E),

          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 23,
            height: 25,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData getIconByName(String name) {
  switch (name.toLowerCase()) {
    case 'home':
      return Icons.home;
    case 'school':
      return Icons.school;
    case 'office':
      return Icons.business;
    case 'hospital':
      return Icons.local_hospital;
    case 'park':
      return Icons.park;
    case 'shop':
      return Icons.store;
    case 'gym':
      return Icons.fitness_center;
    case 'mosque':
      return Icons.mosque;
    case 'church':
      return Icons.church;
    default:
      return Icons.location_on; // default fallback
  }
}
