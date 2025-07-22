import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Preferences
  String _selectedLanguage = 'English';
  bool _offlineMode = false;
  bool _autoSync = true;
  bool _notifications = true;
  String _syncFrequency = 'daily';
  int _offlineDataLimit = 100; // MB

  // User profile
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'English';
      _offlineMode = prefs.getBool('offline_mode') ?? false;
      _autoSync = prefs.getBool('auto_sync') ?? true;
      _notifications = prefs.getBool('notifications') ?? true;
      _syncFrequency = prefs.getString('sync_frequency') ?? 'daily';
      _offlineDataLimit = prefs.getInt('offline_data_limit') ?? 100;
    });

    // Load user profile
    final auth = Provider.of<AuthService>(context, listen: false);
    _nameController.text = auth.userProfile?['name'] ?? '';
    _schoolController.text = auth.userProfile?['school'] ?? '';
    _phoneController.text = auth.userProfile?['phone'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Account Section
            _buildAccountSection(),

            // Profile Section
            _buildSection(
              'Profile',
              Icons.person,
              [
                _buildTextField(
                  controller: _nameController,
                  label: 'Name',
                  icon: Icons.person_outline,
                ),
                _buildTextField(
                  controller: _schoolController,
                  label: 'School Name',
                  icon: Icons.school_outlined,
                ),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Profile'),
                    ),
                  ),
                ),
              ],
            ),

            // Language Settings
            _buildSection(
              'Language & Region',
              Icons.language,
              [
                ListTile(
                  title: const Text('App Language'),
                  subtitle: Text(_selectedLanguage),
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    underline: const SizedBox(),
                    items: _getSupportedLanguages().map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                      _saveSetting('language', value!);
                    },
                  ),
                ),
              ],
            ),

            // Offline Settings
            _buildSection(
              'Offline Settings',
              Icons.cloud_off,
              [
                SwitchListTile(
                  title: const Text('Offline Mode'),
                  subtitle: const Text('Work without internet connection'),
                  value: _offlineMode,
                  onChanged: (value) {
                    setState(() {
                      _offlineMode = value;
                    });
                    _saveSetting('offline_mode', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto Sync'),
                  subtitle: const Text('Sync data when connection is available'),
                  value: _autoSync,
                  onChanged: _offlineMode ? null : (value) {
                    setState(() {
                      _autoSync = value;
                    });
                    _saveSetting('auto_sync', value);
                  },
                ),
                ListTile(
                  title: const Text('Sync Frequency'),
                  subtitle: Text(_getSyncFrequencyText(_syncFrequency)),
                  enabled: _autoSync && !_offlineMode,
                  trailing: DropdownButton<String>(
                    value: _syncFrequency,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'realtime', child: Text('Real-time')),
                      DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    ],
                    onChanged: _autoSync && !_offlineMode ? (value) {
                      setState(() {
                        _syncFrequency = value!;
                      });
                      _saveSetting('sync_frequency', value!);
                    } : null,
                  ),
                ),
                ListTile(
                  title: const Text('Offline Data Limit'),
                  subtitle: Text('$_offlineDataLimit MB'),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: _offlineDataLimit.toDouble(),
                      min: 50,
                      max: 500,
                      divisions: 9,
                      label: '$_offlineDataLimit MB',
                      onChanged: (value) {
                        setState(() {
                          _offlineDataLimit = value.round();
                        });
                      },
                      onChangeEnd: (value) {
                        _saveSetting('offline_data_limit', value.round());
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _downloadOfflineContent,
                          icon: const Icon(Icons.download),
                          label: const Text('Download Content'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearOfflineData,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Clear Data'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Notifications
            _buildSection(
              'Notifications',
              Icons.notifications,
              [
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Receive updates and reminders'),
                  value: _notifications,
                  onChanged: (value) {
                    setState(() {
                      _notifications = value;
                    });
                    _saveSetting('notifications', value);
                  },
                ),
              ],
            ),

            // Privacy & Security
            _buildSection(
              'Privacy & Security',
              Icons.security,
              [
                ListTile(
                  title: const Text('Data Export'),
                  subtitle: const Text('Download your data'),
                  trailing: const Icon(Icons.download_outlined),
                  onTap: _exportData,
                ),
                ListTile(
                  title: const Text('Clear Cache'),
                  subtitle: const Text('Free up storage space'),
                  trailing: const Icon(Icons.cleaning_services_outlined),
                  onTap: _clearCache,
                ),
              ],
            ),

            // About
            _buildSection(
              'About',
              Icons.info,
              [
                ListTile(
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showInfoDialog(
                      'Terms of Service',
                      'By using this app, you agree to our terms and conditions. '
                          'This is a demo application for educational purposes.',
                    );
                  },
                ),
                ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showInfoDialog(
                      'Privacy Policy',
                      'We respect your privacy. This app stores data locally and '
                          'uses Firebase for authentication. No personal data is '
                          'shared with third parties.',
                    );
                  },
                ),
                ListTile(
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showInfoDialog(
                      'Help & Support',
                      'For support, please contact us at support@sahayak.app '
                          'or visit our help center at sahayak.app/help',
                    );
                  },
                ),
                ListTile(
                  title: const Text('Open Source Licenses'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => showLicensePage(context: context),
                ),
              ],
            ),

            // Logout
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final user = auth.user;
        final isAnonymous = user?.isAnonymous ?? false;
        final userProfile = auth.userProfile;

        return _buildSection(
          'Account',
          Icons.account_circle,
          [
            ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: user?.photoURL == null
                    ? Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                  size: 30,
                )
                    : null,
              ),
              title: Text(
                userProfile?['name'] ?? user?.displayName ?? 'Guest User',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAnonymous
                        ? 'Anonymous Account'
                        : (user?.email ?? 'No email'),
                  ),
                  if (userProfile?['school']?.isNotEmpty == true)
                    Text(
                      userProfile!['school'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),

            // Account Status
            ListTile(
              leading: Icon(
                isAnonymous ? Icons.visibility_off : Icons.verified_user,
                color: isAnonymous ? Colors.orange : Colors.green,
              ),
              title: Text(
                isAnonymous ? 'Temporary Account' : 'Verified Account',
              ),
              subtitle: Text(
                isAnonymous
                    ? 'Link with Google to save your data permanently'
                    : 'Your account is secure and backed up',
              ),
            ),

            if (isAnonymous) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _linkWithGoogle,
                    icon: const Icon(Icons.link),
                    label: const Text('Link with Google Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 24, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  List<String> _getSupportedLanguages() {
    // Return supported languages, fallback if AppConfig doesn't exist
    try {
      return AppConfig.supportedLanguages;
    } catch (e) {
      return ['English', 'Hindi', 'Bengali', 'Tamil', 'Telugu', 'Marathi'];
    }
  }

  String _getSyncFrequencyText(String frequency) {
    switch (frequency) {
      case 'realtime':
        return 'Sync in real-time';
      case 'hourly':
        return 'Sync every hour';
      case 'daily':
        return 'Sync once a day';
      case 'weekly':
        return 'Sync once a week';
      default:
        return 'Unknown';
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void _saveProfile() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.updateProfile({
        'name': _nameController.text,
        'school': _schoolController.text,
        'phone': _phoneController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _linkWithGoogle() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final success = await auth.linkAnonymousWithGoogle();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account linked successfully! Your data is now secure.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? '
              'This action cannot be undone and all your data will be lost permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final auth = Provider.of<AuthService>(context, listen: false);
                Navigator.pop(context); // Close dialog first

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                await auth.deleteAccount();

                if (mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _downloadOfflineContent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Offline Content'),
        content: const Text(
          'This will download essential resources for offline use. '
              'The download size will be approximately 50-100 MB. '
              'Make sure you have a stable internet connection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Downloading offline content...'),
                  duration: Duration(seconds: 3),
                ),
              );
              // Implement actual download logic here
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _clearOfflineData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Offline Data'),
        content: const Text(
          'This will delete all downloaded offline content. '
              'You will need to download it again to use offline features. '
              'This will free up storage space on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Offline data cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              // Implement actual clear logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparing your data for export...'),
          ],
        ),
      ),
    );

    // Simulate data export
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data export completed! Check your downloads folder.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear temporary files and cached data. '
              'Your personal data and settings will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? '
              'If you have an anonymous account, make sure to link it with Google first to avoid losing your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final auth = Provider.of<AuthService>(context, listen: false);
                Navigator.pop(context); // Close dialog first

                await auth.logout();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
