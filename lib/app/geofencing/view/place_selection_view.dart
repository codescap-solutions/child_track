import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:google_fonts/google_fonts.dart';
import 'location_selections.dart';

class PlaceSelectionScreen extends StatefulWidget {
  final String? childId;
  final String? parentId;

  const PlaceSelectionScreen({
    super.key,
    this.childId,
    this.parentId,
  });

  @override
  State<PlaceSelectionScreen> createState() => _PlaceSelectionScreenState();
}

class _PlaceSelectionScreenState extends State<PlaceSelectionScreen> {
  final TextEditingController _customPlaceController = TextEditingController();
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    _customPlaceController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _customPlaceController.removeListener(_onTextChanged);
    _customPlaceController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _canCreate = _customPlaceController.text.trim().isNotEmpty;
    });
  }

  void _navigateToMap({
    required String category,
    required String customName,
    bool isCurrentLocation = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSelectionScreen(
          childId: widget.childId,
          parentId: widget.parentId,
          selectedCategory: category,
          customName: customName,
          isCurrentLocation: isCurrentLocation,
        ),
      ),
    ).then((result) {
      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    });
  }

  Widget _buildPresetCard({
    required String label,
    required IconData icon,
    required Color circleBg,
    required String category,
    bool isCurrentLocation = false,
  }) {
    return GestureDetector(
      onTap: () => _navigateToMap(
        category: category,
        customName: label,
        isCurrentLocation: isCurrentLocation,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0C1D37).withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0C1D37),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leadingWidth: 72,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Geofencing',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0C1D37),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.35,
                children: [
                  _buildPresetCard(
                    label: "School",
                    icon: Icons.school_rounded,
                    circleBg: const Color(0xFF22C55E),
                    category: "school",
                  ),
                  _buildPresetCard(
                    label: "Coaching",
                    icon: Icons.school_outlined,
                    circleBg: const Color(0xFFF59E0B),
                    category: "tuition",
                  ),
                  _buildPresetCard(
                    label: "Grandma's",
                    icon: Icons.face_retouching_natural_rounded,
                    circleBg: const Color(0xFFEF4444),
                    category: "other",
                  ),
                  _buildPresetCard(
                    label: "Temple/Masjid",
                    icon: Icons.account_balance_rounded,
                    circleBg: const Color(0xFF8B5CF6),
                    category: "other",
                  ),
                  _buildPresetCard(
                    label: "Sports Ground",
                    icon: Icons.sports_cricket_rounded,
                    circleBg: const Color(0xFF0066FF),
                    category: "other",
                  ),
                  _buildPresetCard(
                    label: "Current Location",
                    icon: Icons.location_on_rounded,
                    circleBg: const Color(0xFF64748B),
                    category: "other",
                    isCurrentLocation: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Add Custom Place Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0C1D37).withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _customPlaceController,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0C1D37),
                  ),
                  decoration: InputDecoration(
                    hintText: "Add Custom Place",
                    hintStyle: GoogleFonts.manrope(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Create Button Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _canCreate
                        ? () {
                            _navigateToMap(
                              category: "other",
                              customName: _customPlaceController.text.trim(),
                            );
                          }
                        : null,
                    child: Text(
                      "Create",
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
