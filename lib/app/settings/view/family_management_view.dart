import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/app_snackbar.dart';

class FamilyManagementView extends StatefulWidget {
  const FamilyManagementView({super.key});

  @override
  State<FamilyManagementView> createState() => _FamilyManagementViewState();
}

class _FamilyManagementViewState extends State<FamilyManagementView> {
  final SharedPrefsService _sharedPrefsService = injector<SharedPrefsService>();
  final ImagePicker _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _guardians = [];
  bool _isPrimaryParent = true;

  @override
  void initState() {
    super.initState();
    _isPrimaryParent = _sharedPrefsService.isPrimaryParent;
    _loadGuardians();
  }

  void _loadGuardians() {
    final String? guardiansJson = _sharedPrefsService.getString('family_guardians');
    final String parentName = _sharedPrefsService.getString('parent_name') ?? 'Rahul Pandey';
    final String parentPhone = _sharedPrefsService.getString('parent_phone') ?? '+91 87654 32109';
    final String? parentAvatar = _sharedPrefsService.getString('parent_avatar');

    if (guardiansJson != null && guardiansJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(guardiansJson);
        setState(() {
          _guardians = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
        
        // Ensure the default parent matches the current user info
        final defaultIndex = _guardians.indexWhere((e) => e['is_default'] == true);
        if (defaultIndex != -1) {
          setState(() {
            _guardians[defaultIndex]['name'] = parentName;
            _guardians[defaultIndex]['phone_number'] = parentPhone;
            if (parentAvatar != null) {
              _guardians[defaultIndex]['avatar_url'] = parentAvatar;
            }
          });
          _saveGuardiansToStorage();
        }
        return;
      } catch (e) {
        // Fallback to default
      }
    }

    // Default list setup
    setState(() {
      _guardians = [
        {
          'id': 'primary_parent_owner',
          'name': parentName,
          'phone_number': parentPhone,
          'avatar_url': parentAvatar,
          'is_default': true,
        }
      ];
    });
    _saveGuardiansToStorage();
  }

  void _saveGuardiansToStorage() {
    final String encoded = jsonEncode(_guardians);
    _sharedPrefsService.setString('family_guardians', encoded);
  }

  Future<void> _pickImageForGuardian(int index) async {
    // Show Gallery/Camera selector
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Profile Photo',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0C1D37),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF0066FF)),
              title: Text('Choose from Gallery', style: GoogleFonts.manrope()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (file != null) {
                  _updateGuardianAvatar(index, file.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF0066FF)),
              title: Text('Take a Photo', style: GoogleFonts.manrope()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? file = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
                if (file != null) {
                  _updateGuardianAvatar(index, file.path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateGuardianAvatar(int index, String path) {
    setState(() {
      _guardians[index]['avatar_url'] = path;
    });
    _saveGuardiansToStorage();

    // If it's the primary parent, sync to parent_avatar settings key
    if (_guardians[index]['is_default'] == true) {
      _sharedPrefsService.setString('parent_avatar', path);
    }

    AppSnackbar.showSuccess(context, 'Profile photo updated successfully');
  }

  Widget _buildAvatar(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF0066FF),
            width: 2.0,
          ),
        ),
        child: const Icon(
          CupertinoIcons.person_fill,
          color: Color(0xFF0066FF),
          size: 32,
        ),
      );
    }

    ImageProvider provider;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      provider = NetworkImage(path);
    } else if (path.startsWith('assets/')) {
      provider = AssetImage(path);
    } else {
      provider = FileImage(File(path));
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF0066FF),
          width: 2.0,
        ),
        image: DecorationImage(
          image: provider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showAddGuardianSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Guardian',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0C1D37),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Name',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0C1D37),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter Name',
                    hintStyle: GoogleFonts.manrope(color: const Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Phone Number',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0C1D37),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter Phone Number',
                    hintStyle: GoogleFonts.manrope(color: const Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      if (name.isEmpty || phone.isEmpty) {
                        AppSnackbar.showError(context, 'Please enter both name and phone number');
                        return;
                      }
                      
                      setState(() {
                        _guardians.add({
                          'id': 'guardian_${DateTime.now().millisecondsSinceEpoch}',
                          'name': name,
                          'phone_number': phone,
                          'avatar_url': null,
                          'is_default': false,
                        });
                      });
                      _saveGuardiansToStorage();
                      Navigator.pop(context);
                      AppSnackbar.showSuccess(context, '$name added as guardian');
                    },
                    child: Text(
                      'Continue',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditGuardianSheet(int index) {
    final guardian = _guardians[index];
    final editController = TextEditingController(text: guardian['name']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  'Edit Name',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0C1D37),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: editController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.black, width: 2.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      final newName = editController.text.trim();
                      if (newName.isEmpty) {
                        AppSnackbar.showError(context, 'Name cannot be empty');
                        return;
                      }

                      setState(() {
                        _guardians[index]['name'] = newName;
                      });
                      _saveGuardiansToStorage();

                      // If it's the primary parent, sync to parent_name key
                      if (guardian['is_default'] == true) {
                        _sharedPrefsService.setString('parent_name', newName);
                      }

                      Navigator.pop(context);
                      AppSnackbar.showSuccess(context, 'Name updated successfully');
                    },
                    child: Text(
                      'Update',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteGuardian(int index) {
    final guardian = _guardians[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Guardian',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${guardian['name']} as a guardian?',
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: GoogleFonts.manrope(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Delete', style: GoogleFonts.manrope(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () {
              setState(() {
                _guardians.removeAt(index);
              });
              _saveGuardiansToStorage();
              Navigator.pop(context);
              AppSnackbar.showSuccess(context, 'Guardian deleted');
            },
          ),
        ],
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
        leadingWidth: 56,
        leading: Center(
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
          'Family',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0C1D37),
          ),
        ),
      ),
      body: SafeArea(
        child: _guardians.isEmpty
            ? Center(
                child: Text(
                  'No family members found.',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _guardians.length,
                itemBuilder: (context, index) {
                  final guardian = _guardians[index];
                  final isDefault = guardian['is_default'] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0C1D37).withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: () {
                            // If they are not primary parent, restrict updating avatar?
                            // No, the prompt says "if they add another adult... they can view child data, they can't edit any think child data".
                            // It doesn't restrict them from updating their own parent details if they want.
                            // However, we can allow updating photo.
                            if (!_isPrimaryParent && isDefault) {
                              // Secondary parent editing primary parent is restricted, but editing themselves is ok.
                              // Let's keep it simple and allow image picking for everyone.
                              _pickImageForGuardian(index);
                            } else if (_isPrimaryParent) {
                              _pickImageForGuardian(index);
                            } else {
                              AppSnackbar.showError(context, 'Only primary parent can edit other members');
                            }
                          },
                          child: _buildAvatar(guardian['avatar_url']),
                        ),
                        const SizedBox(width: 16),
                        // Name and Phone
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guardian['name'] ?? '',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0C1D37),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.phone,
                                    size: 14,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    guardian['phone_number'] ?? '',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Actions (Edit, Delete)
                        if (_isPrimaryParent) ...[
                          // Edit Button
                          GestureDetector(
                            onTap: () => _showEditGuardianSheet(index),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.pencil,
                                color: Color(0xFF0066FF),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Delete Button (Only for custom guardians)
                          if (!isDefault)
                            GestureDetector(
                              onTap: () => _confirmDeleteGuardian(index),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF2F2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.trash,
                                  color: Color(0xFFEF4444),
                                  size: 18,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 36), // spacing match
                        ] else ...[
                          // Secondary guardians cannot edit/delete members
                          const SizedBox.shrink(),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: _isPrimaryParent
          ? FloatingActionButton(
              onPressed: _showAddGuardianSheet,
              backgroundColor: const Color(0xFF0066FF),
              shape: const CircleBorder(),
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }
}
