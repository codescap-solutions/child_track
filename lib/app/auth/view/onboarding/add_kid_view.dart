import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/app/home/view_model/home_repo.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/navigation/route_names.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/widgets/common_textfield.dart';

class AddKidView extends StatefulWidget {
  const AddKidView({super.key});

  @override
  State<AddKidView> createState() => _AddKidViewState();
}

class _AddKidViewState extends State<AddKidView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _childRepo = injector<ChildRepo>();
  final _homeRepo = injector<HomeRepository>();
  final _sharedPrefsService = SharedPrefsService();
  bool _isLoading = false;

  // Selected avatar state (Boy 1 as default)
  String _selectedAvatar = '👦';

  // Selected travel mode state (Van as default)
  String _selectedTravelMode = '🚐';

  // Selected birth date details
  int? _selectedYear;
  String? _selectedMonth;

  // Static options matching Figma
  final List<int> _years = List.generate(18, (index) => DateTime.now().year - index);
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.spacingS),
                  _buildCustomAppBar(),
                  const SizedBox(height: AppSizes.spacingL),
                  _buildHeader(),
                  const SizedBox(height: AppSizes.spacingXL),
                  _buildAvatarSelector(),
                  const SizedBox(height: AppSizes.spacingXL),
                  _buildDetailsSection(),
                  const SizedBox(height: AppSizes.spacingXL),
                  _buildTravelModeSelector(),
                  const SizedBox(height: AppSizes.spacingXXL),
                  _buildSubmitButton(),
                  const SizedBox(height: AppSizes.spacingXL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.textPrimary,
            size: 32,
          ),
        ),
        const Spacer(),
        Text(
          'Add Kid',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 48), // Align text to center by balancing the Back button size
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHILD DETAILS',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0066FF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about your child',
          style: GoogleFonts.oswald(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D293C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This personalises tracking alerts for their age & routine.',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF62748E),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSelector() {
    final avatars = ['👦', '👧', '👧🏻', '+'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Avatar',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7C8BA0),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: avatars.map((avatar) {
            final isSelected = _selectedAvatar == avatar;
            final isAddButton = avatar == '+';
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  if (isAddButton) {
                    AppSnackbar.showInfo(context, 'Custom avatar uploads coming soon!');
                  } else {
                    setState(() {
                      _selectedAvatar = avatar;
                    });
                  }
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0066FF).withValues(alpha: 0.1) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0066FF) : AppColors.borderColor,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isAddButton
                      ? const Icon(Icons.add_rounded, color: Color(0xFF7C8BA0), size: 24)
                      : Text(avatar, style: const TextStyle(fontSize: 26)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Details',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7C8BA0),
          ),
        ),
        const SizedBox(height: 16),
        // Name field
        Text(
          'Name of the Kid',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7C8BA0),
          ),
        ),
        const SizedBox(height: 8),
        CommonTextField(
          controller: _nameController,
          hintText: 'Enter child name',
          keyboardType: TextInputType.name,
          prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF7C8BA0)),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter child name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Birthday Selection Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birth Year',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF7C8BA0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    hint: Text(
                      'Year',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C8BA0),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7C8BA0)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    items: _years.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedYear = val;
                      });
                    },
                    validator: (val) => val == null ? 'Year required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birth Month',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF7C8BA0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMonth,
                    hint: Text(
                      'Month',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C8BA0),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7C8BA0)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    items: _months.map((month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedMonth = val;
                      });
                    },
                    validator: (val) => val == null ? 'Month required' : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTravelModeSelector() {
    final modes = [
      {'emoji': '🚐', 'label': 'Van'},
      {'emoji': '🚌', 'label': 'Bus'},
      {'emoji': '🚶', 'label': 'Walk'},
      {'emoji': '🚗', 'label': 'Car'},
      {'emoji': '🛺', 'label': 'Auto'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How does your child travel to school?',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7C8BA0),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: modes.map((mode) {
            final emoji = mode['emoji']!;
            final label = mode['label']!;
            final isSelected = _selectedTravelMode == emoji;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTravelMode = emoji;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 62,
                height: 72,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0066FF).withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0066FF) : AppColors.borderColor,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF62748E),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return InkWell(
      onTap: _isLoading ? null : _onSubmit,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: _isLoading
              ? const Color(0xFF0066FF).withValues(alpha: 0.5)
              : const Color(0xFF0066FF),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
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

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedYear == null) {
        AppSnackbar.showError(context, 'Please select child\'s birth year');
        return;
      }
      if (_selectedMonth == null) {
        AppSnackbar.showError(context, 'Please select child\'s birth month');
        return;
      }
      _createChild();
    }
  }

  Future<void> _createChild() async {
    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final age = DateTime.now().year - _selectedYear!;

      String travelOption;
      switch (_selectedTravelMode) {
        case '🚐':
          travelOption = 'Van';
          break;
        case '🚌':
          travelOption = 'Bus';
          break;
        case '🚶':
          travelOption = 'Walk';
          break;
        case '🚗':
          travelOption = 'Car';
          break;
        case '🛺':
          travelOption = 'Auto';
          break;
        default:
          travelOption = 'Van';
      }

      final response = await _childRepo.createChild(
        name: name,
        age: age,
        travelOption: travelOption,
      );

      if (response.isSuccess && response.data != null) {
        final childData = response.data!['child'] as Map<String, dynamic>?;
        final childCode = childData?['child_code'] as String?;
        final childId = childData?['child_id'] as String?;

        if (childId != null) {
          await _sharedPrefsService.setString('child_id', childId);
          final currentCount = _sharedPrefsService.getInt('children_count') ?? 0;
          await _sharedPrefsService.setInt('children_count', currentCount + 1);

          if (childCode != null) {
            await _sharedPrefsService.setString('child_code', childCode);

            AppLogger.info('Linking child to parent with code: $childCode');
            final linkResponse = await _homeRepo.linkChild(childCode: childCode);
            
            if (linkResponse.isSuccess) {
              AppLogger.info('Child linked to parent successfully');
            } else {
              AppLogger.warning('Failed to link child to parent: ${linkResponse.message}');
            }
          }

          AppLogger.info('Child created successfully. ID: $childId, Code: $childCode');

          if (mounted && childCode != null) {
            Navigator.of(context).pushReplacementNamed(
              RouteNames.childCode,
              arguments: {
                'childCode': childCode,
                'childId': childId,
              },
            );
          } else if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              RouteNames.home,
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            AppSnackbar.showError(context, 'Child ID not received');
          }
        }
      } else {
        if (mounted) {
          AppSnackbar.showError(context, response.message);
        }
      }
    } catch (e) {
      AppLogger.error('Error creating child: ${e.toString()}');
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to create child: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

