import 'package:child_track/app/auth/view/onboarding/sign_in_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';

class ParentProfileSetupView extends StatefulWidget {
  final String phoneNumber;

  const ParentProfileSetupView({super.key, required this.phoneNumber});

  @override
  State<ParentProfileSetupView> createState() => _ParentProfileSetupViewState();
}

class _ParentProfileSetupViewState extends State<ParentProfileSetupView> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 Selection: Your Family Structure
  int _selectedFamilyStructureIndex = -1;

  // Step 2 Selection: About Your Lifestyle
  int _selectedLifestyleIndex = -1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedFamilyStructureIndex == -1) return;
      setState(() {
        _currentStep = 1;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      if (_selectedLifestyleIndex == -1) return;
      // Complete flow: navigate to SignInView
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SignInView(phoneNumber: widget.phoneNumber),
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isContinueEnabled = _currentStep == 0
        ? _selectedFamilyStructureIndex != -1
        : _selectedLifestyleIndex != -1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFBFCFE),
              Color(0xFFEDF4FE),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.spacingS),
              _buildCustomAppBar(),
              _buildProgressBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildFamilyStructureStep(),
                    _buildLifestyleStep(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: _buildContinueButton(isContinueEnabled),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousStep,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textPrimary,
              size: 32,
            ),
          ),
          const Spacer(),
          Text(
            'Parent profile',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance spacing with Back button
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingL,
        vertical: AppSizes.paddingS,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                color: _currentStep >= 1
                    ? const Color(0xFF0066FF)
                    : const Color(0xFF0066FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyStructureStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.spacingM),
          Text(
            'Your Family Structure',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0066FF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How would you describe your parenting situation?',
            style: GoogleFonts.oswald(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D293C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll customise sharing settings and support features around your family.",
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF62748E),
            ),
          ),
          const SizedBox(height: AppSizes.spacingXL),
          ParentOptionCard(
            emoji: '👫',
            title: 'Co-Parenting',
            subtitle: 'You share parenting with a partner or co-parent',
            detailText: 'Shared dashboards & coordinated schedule visibility.',
            tipText: "💡 Co-parents save 30 min/day by eliminating 'where are the kids?' check-in calls.",
            themeColor: const Color(0xFF0066FF),
            isSelected: _selectedFamilyStructureIndex == 0,
            onTap: () {
              setState(() {
                _selectedFamilyStructureIndex = 0;
              });
            },
          ),
          const SizedBox(height: 16),
          ParentOptionCard(
            emoji: '👩',
            title: 'Single Mom',
            subtitle: "You're raising your children independently",
            detailText: 'Dedicated emergency SOS & trusted contact shortcuts.',
            tipText: "💡 Single parents rely on quick-glance safety updates — we've designed every feature with you in mind.",
            themeColor: const Color(0xFF0066FF),
            isSelected: _selectedFamilyStructureIndex == 1,
            onTap: () {
              setState(() {
                _selectedFamilyStructureIndex = 1;
              });
            },
          ),
          const SizedBox(height: 16),
          ParentOptionCard(
            emoji: '👨',
            title: 'Single Dad',
            subtitle: "You're the primary caregiver for your children",
            detailText: 'Quick SOS, school pick-up alerts & after-school zones.',
            tipText: '💡 Dads who use location tools report 40% less daily stress about child safety.',
            themeColor: const Color(0xFF0066FF),
            isSelected: _selectedFamilyStructureIndex == 2,
            onTap: () {
              setState(() {
                _selectedFamilyStructureIndex = 2;
              });
            },
          ),
          const SizedBox(height: 16),
          ParentOptionCard(
            emoji: '👨',
            title: 'Guardian',
            subtitle: "You're the primary caretaker for your children",
            detailText: 'Quick SOS, school pick-up alerts & after-school zones.',
            tipText: '💡 Dads who use location tools report 40% less daily stress about child safety.',
            themeColor: const Color(0xFF0066FF),
            isSelected: _selectedFamilyStructureIndex == 3,
            onTap: () {
              setState(() {
                _selectedFamilyStructureIndex = 3;
              });
            },
          ),
          const SizedBox(height: AppSizes.spacingL),
        ],
      ),
    );
  }

  Widget _buildLifestyleStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.spacingM),
          Text(
            'About Your Lifestyle',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0066FF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What best describes your daily routine?',
            style: GoogleFonts.oswald(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D293C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalise your notification schedule and safety alerts.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF62748E),
            ),
          ),
          const SizedBox(height: AppSizes.spacingXL),
          ParentOptionCard(
            emoji: '🏠',
            title: 'Homemaker Parent',
            subtitle: "You're at home full-time — the heart of the household.",
            badgeText: 'Full-time caregiver',
            badgeColor: const Color(0xFFFFEAD5),
            badgeTextColor: const Color(0xFFD35F00),
            detailText: "We'll set up home-zone alerts & routine check-ins tailored to your day.",
            tipText: '💡 Homemaker parents are often the first responders in their household. SafeNest helps you stay aware without hovering — giving you peace of mind while letting kids build independence.',
            themeColor: const Color(0xFFD35F00),
            stat1Value: '76%',
            stat1Label: 'feel safer with real-time location awareness',
            stat2Value: '3×',
            stat2Label: 'faster response to unexpected departures',
            isSelected: _selectedLifestyleIndex == 0,
            onTap: () {
              setState(() {
                _selectedLifestyleIndex = 0;
              });
            },
          ),
          const SizedBox(height: 16),
          ParentOptionCard(
            emoji: '💼',
            title: 'Working Parent',
            subtitle: 'You balance a career while raising your children every day.',
            badgeText: 'Career + family',
            badgeColor: const Color(0xFFE8DDFC),
            badgeTextColor: const Color(0xFF7A4AF6),
            detailText: 'Priority alerts between meetings & school hours — no noise, just what matters.',
            tipText: '💡 Working parents often feel the tension between being present at work and being present for their kids. SafeNest bridges that gap with smart, quiet alerts — only buzzing when it truly matters.',
            themeColor: const Color(0xFF7A4AF6),
            stat1Value: '8×',
            stat1Label: 'average daily location checks by working parents',
            stat2Value: '62%',
            stat2Label: 'report reduced work-day anxiety about child safety',
            isSelected: _selectedLifestyleIndex == 1,
            onTap: () {
              setState(() {
                _selectedLifestyleIndex = 1;
              });
            },
          ),
          const SizedBox(height: AppSizes.spacingL),
        ],
      ),
    );
  }

  Widget _buildContinueButton(bool isEnabled) {
    return InkWell(
      onTap: isEnabled ? _nextStep : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isEnabled
              ? const Color(0xFF0066FF)
              : const Color(0xFF0066FF).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          'Continue',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class ParentOptionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final String detailText;
  final String tipText;
  final Color themeColor;
  final String? stat1Value;
  final String? stat1Label;
  final String? stat2Value;
  final String? stat2Label;
  final bool isSelected;
  final VoidCallback onTap;

  const ParentOptionCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    required this.detailText,
    required this.tipText,
    required this.themeColor,
    this.stat1Value,
    this.stat1Label,
    this.stat2Value,
    this.stat2Label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor.withValues(alpha: 0.03)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? themeColor : AppColors.borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1D293C),
                              ),
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeText!,
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: badgeTextColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF62748E),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: AppColors.borderColor,
                        ),
                        const SizedBox(height: 16),
                        // Detail Text Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.arrow_right_alt_rounded,
                              color: themeColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                detailText,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: themeColor,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Optional Stats Block
                        if (stat1Value != null && stat2Value != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: themeColor.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stat1Value!,
                                        style: GoogleFonts.oswald(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: themeColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        stat1Label!,
                                        style: GoogleFonts.manrope(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF62748E),
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: themeColor.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stat2Value!,
                                        style: GoogleFonts.oswald(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: themeColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        stat2Label!,
                                        style: GoogleFonts.manrope(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF62748E),
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Expanded Tip / Info Section
                        _WhyThisMattersSection(
                          tipText: tipText,
                          themeColor: themeColor,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhyThisMattersSection extends StatefulWidget {
  final String tipText;
  final Color themeColor;

  const _WhyThisMattersSection({
    required this.tipText,
    required this.themeColor,
  });

  @override
  State<_WhyThisMattersSection> createState() => _WhyThisMattersSectionState();
}

class _WhyThisMattersSectionState extends State<_WhyThisMattersSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              Icon(
                _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF7C8BA0),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Why this matters',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7C8BA0),
                ),
              ),
              const Spacer(),
              Text(
                'How is this used?',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7C8BA0),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.themeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.tipText,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: widget.themeColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
