import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:ns_transport/providers/auth_provider.dart';
import 'package:ns_transport/providers/theme_provider.dart';
import 'package:ns_transport/widgets/app_drawer.dart';
import 'package:ns_transport/providers/locale_provider.dart';
import 'package:ns_transport/core/localization/app_translations.dart';
import 'package:ns_transport/core/theme/app_theme.dart';
import 'package:ns_transport/routes/app_routes.dart';
import 'package:ns_transport/core/constants/api_constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _updateProfilePicture(ImageSource source) async {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    final XFile? image = await _picker.pickImage(source: source, imageQuality: 50);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await image.readAsBytes();
      final fileExt = image.name.contains('.') ? image.name.split('.').last : 'jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '${user.id}/profile/$fileName';

      await Supabase.instance.client.storage
          .from(ApiConstants.profileImagesBucket)
          .uploadBinary(
            filePath, 
            bytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );

      final imageUrl = Supabase.instance.client.storage
          .from(ApiConstants.profileImagesBucket)
          .getPublicUrl(filePath);

      await Supabase.instance.client
          .from('users')
          .update({'avatar_url': imageUrl})
          .eq('id', user.id);

      // ignore: unused_result
      ref.refresh(authProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTranslations.get('profile_updated', ref.read(localeProvider)))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppTranslations.get('failed_update', ref.read(localeProvider))}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _removeProfilePicture() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    setState(() => _isUploading = true);
    try {
      await Supabase.instance.client
          .from('users')
          .update({'avatar_url': null})
          .eq('id', user.id);

      // ignore: unused_result
      ref.refresh(authProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTranslations.get('profile_removed', ref.read(localeProvider)))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppTranslations.get('failed_remove', ref.read(localeProvider))}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showProfilePhotoOptions(String? currentAvatarUrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final locale = ref.watch(localeProvider);
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    AppTranslations.get('profile_photo', locale),
                    style: AppTheme.getFont(locale,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
                ),
                title: Text(AppTranslations.get('take_photo', locale)),
                onTap: () {
                  Navigator.pop(context);
                  _updateProfilePicture(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3EDF7),
                  child: Icon(Icons.photo_library, color: Color(0xFF1565C0)),
                ),
                title: Text(AppTranslations.get('choose_gallery', locale)),
                onTap: () {
                  Navigator.pop(context);
                  _updateProfilePicture(ImageSource.gallery);
                },
              ),
              if (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty) ...[
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3E5F5),
                    child: Icon(Icons.person, color: Color(0xFF8E24AA)),
                  ),
                  title: Text(AppTranslations.get('view_photo', locale)),
                  onTap: () {
                    Navigator.pop(context); // close bottom sheet
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(16),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            InteractiveViewer(
                              panEnabled: true,
                              boundaryMargin: const EdgeInsets.all(20),
                              minScale: 0.5,
                              maxScale: 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  currentAvatarUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.delete, color: Color(0xFFC62828)),
                  ),
                  title: Text(AppTranslations.get('remove_photo', locale), style: const TextStyle(color: Color(0xFFC62828))),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePicture();
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final locale = ref.watch(localeProvider);
    final primaryColor = const Color(0xFF1565C0);
    final avatarUrl = user?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppTranslations.get('settings', locale),
          style: AppTheme.getFont(locale, fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _isUploading ? null : () => _showProfilePhotoOptions(avatarUrl),
                      borderRadius: BorderRadius.circular(36),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: primaryColor.withValues(alpha: 0.1),
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Icon(Icons.person, size: 40, color: primaryColor)
                                : null,
                          ),
                          if (_isUploading)
                            const CircularProgressIndicator(),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.camera_alt, size: 16, color: primaryColor),
                            ),
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
                            user?.name ?? AppTranslations.get('loading_name', locale),
                            style: AppTheme.getFont(locale,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? AppTranslations.get('loading_email', locale),
                            style: AppTheme.getFont(locale,
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (user?.role == 'owner' ? AppTranslations.get('owner', locale) : AppTranslations.get('driver', locale)).toUpperCase(),
                              style: AppTheme.getFont(locale,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: Profile Info
            Text(
              AppTranslations.get('account_information', locale),
              style: AppTheme.getFont(locale,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  if (user?.role == 'driver') ...[
                    ListTile(
                      leading: const Icon(Icons.edit_document),
                      title: Text(AppTranslations.get('edit_profile_id', locale)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.driverProfileEdit);
                      },
                    ),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: Text(AppTranslations.get('phone_number', locale)),
                    subtitle: Text(user?.phone ?? AppTranslations.get('not_set', locale)),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text(AppTranslations.get('driver_id', locale)),
                    subtitle: Text(user?.id ?? 'N/A'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Preferences
            Text(
              AppTranslations.get('preferences', locale),
              style: AppTheme.getFont(locale,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(AppTranslations.get('dark_mode', locale)),
                    value: ref.watch(themeProvider) == ThemeMode.dark,
                    onChanged: (val) {
                      ref.read(themeProvider.notifier).toggleTheme(val);
                    },
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(AppTranslations.get('language', locale)),
                    trailing: DropdownButton<String>(
                      value: locale,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(localeProvider.notifier).setLocale(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Actions
            Text(
              AppTranslations.get('actions', locale),
              style: AppTheme.getFont(locale,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(AppTranslations.get('about_ns_transport', locale)),
                    subtitle: const Text('v1.0.0 (Production)'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(AppTranslations.get('sign_out', locale)),
                    textColor: Colors.red,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppTranslations.get('sign_out', locale)),
                          content: Text(AppTranslations.get('sign_out_confirm', locale)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(AppTranslations.get('cancel', locale)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              child: Text(AppTranslations.get('logout', locale)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final nav = Navigator.of(context);
                        await ref.read(authProvider.notifier).signOut();
                        nav.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
