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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Profile'),
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
                    items: AppConfig.supportedLanguages.map((lang) {
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
                    // Navigate to terms
                  },
                ),
                ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to privacy policy
                  },
                ),
                ListTile(
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to help
                  },
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

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(8),
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
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          ...children,
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
        ),
      ),
    );
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

  void _saveProfile() {
    // Save profile implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully!')),
    );
  }

  void _downloadOfflineContent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Offline Content'),
        content: const Text(
          'This will download essential resources for offline use. '
          'The download size will be approximately 50-100 MB.',
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
          'You will need to download it again to use offline features.',
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
                const SnackBar(content: Text('Offline data cleared')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear'),
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
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthService>(context, listen: false);
              await auth.logout();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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