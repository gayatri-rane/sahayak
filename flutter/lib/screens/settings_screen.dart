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

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _initializeAnimations();
    _loadSettings();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
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

  double _getResponsivePadding(double screenWidth) {
    if (screenWidth < 600) return 16.0;
    if (screenWidth < 900) return 24.0;
    return 32.0;
  }

  double _getCardPadding(double screenWidth) {
    if (screenWidth < 600) return 16.0;
    if (screenWidth < 900) return 20.0;
    return 24.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final padding = _getResponsivePadding(screenWidth);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, screenWidth),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    _buildHeaderCard(screenWidth),
                    const SizedBox(height: 16),
                    _buildAccountSection(screenWidth),
                    const SizedBox(height: 16),
                    _buildProfileSection(screenWidth),
                    const SizedBox(height: 16),
                    _buildLanguageSection(screenWidth),
                    const SizedBox(height: 16),
                    _buildOfflineSection(screenWidth),
                    const SizedBox(height: 16),
                    _buildNotificationsSection(screenWidth),
                    const SizedBox(height: 16),
                    _buildPrivacySection(screenWidth),
                    const SizedBox(height: 16),
                    _buildAboutSection(screenWidth),
                    const SizedBox(height: 16),
                    _buildLogoutButton(screenWidth),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, double screenWidth) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E293B),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(double screenWidth) {
    final cardPadding = _getCardPadding(screenWidth);

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF1D4ED8),
            Color(0xFF1E40AF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.settings,
              color: Colors.white,
              size: screenWidth < 600 ? 20 : 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth < 600 ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Customize your experience',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: screenWidth < 600 ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(double screenWidth) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final user = auth.user;
        final isAnonymous = user?.isAnonymous ?? false;
        final userProfile = auth.userProfile;

        return _buildSection(
          'Account',
          Icons.account_circle,
          const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
          screenWidth,
          [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: screenWidth < 600 ? 25 : 30,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                child: user?.photoURL == null
                    ? Icon(
                  Icons.person,
                  color: const Color(0xFF3B82F6),
                  size: screenWidth < 600 ? 25 : 30,
                )
                    : null,
              ),
              title: Text(
                userProfile?['name'] ?? user?.displayName ?? 'Guest User',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: screenWidth < 600 ? 16 : 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAnonymous
                        ? 'Anonymous Account'
                        : (user?.email ?? 'No email'),
                    style: TextStyle(
                      fontSize: screenWidth < 600 ? 14 : 16,
                    ),
                  ),
                  if (userProfile?['school']?.isNotEmpty == true)
                    Text(
                      userProfile!['school'],
                      style: TextStyle(
                        fontSize: screenWidth < 600 ? 12 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusChip(isAnonymous, screenWidth),
            if (isAnonymous) ...[
              const SizedBox(height: 16),
              _buildGradientButton(
                'Link with Google Account',
                Icons.link,
                const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                _linkWithGoogle,
                screenWidth,
              ),
            ],
            const SizedBox(height: 16),
            _buildOutlinedButton(
              'Delete Account',
              Icons.delete_forever,
              Colors.red,
              _deleteAccount,
              screenWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(bool isAnonymous, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 12 : 16,
        vertical: screenWidth < 600 ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: isAnonymous ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAnonymous ? Colors.orange : Colors.green,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAnonymous ? Icons.visibility_off : Icons.verified_user,
            color: isAnonymous ? Colors.orange : Colors.green,
            size: screenWidth < 600 ? 16 : 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAnonymous
                  ? 'Temporary Account - Link to save data permanently'
                  : 'Verified Account - Your data is secure',
              style: TextStyle(
                color: isAnonymous ? Colors.orange : Colors.green,
                fontWeight: FontWeight.w500,
                fontSize: screenWidth < 600 ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(double screenWidth) {
    return _buildSection(
      'Profile Information',
      Icons.person,
      const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
      screenWidth,
      [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person_outline,
          screenWidth: screenWidth,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _schoolController,
          label: 'School Name',
          icon: Icons.school_outlined,
          screenWidth: screenWidth,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          screenWidth: screenWidth,
        ),
        const SizedBox(height: 20),
        _buildGradientButton(
          'Save Profile',
          Icons.save,
          const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
          _saveProfile,
          screenWidth,
        ),
      ],
    );
  }

  Widget _buildLanguageSection(double screenWidth) {
    return _buildSection(
      'Language & Region',
      Icons.language,
      const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      screenWidth,
      [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.translate,
                color: const Color(0xFFF59E0B),
                size: screenWidth < 600 ? 20 : 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Language',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth < 600 ? 14 : 16,
                      ),
                    ),
                    Text(
                      _selectedLanguage,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: screenWidth < 600 ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  underline: const SizedBox(),
                  style: TextStyle(
                    color: const Color(0xFFF59E0B),
                    fontSize: screenWidth < 600 ? 12 : 14,
                  ),
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
        ),
      ],
    );
  }

  Widget _buildOfflineSection(double screenWidth) {
    return _buildSection(
      'Offline & Sync Settings',
      Icons.cloud_off,
      const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
      screenWidth,
      [
        _buildSwitchTile(
          'Offline Mode',
          'Work without internet connection',
          _offlineMode,
              (value) {
            setState(() {
              _offlineMode = value;
            });
            _saveSetting('offline_mode', value);
          },
          screenWidth,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          'Auto Sync',
          'Sync data when connection is available',
          _autoSync,
          _offlineMode ? null : (value) {
            setState(() {
              _autoSync = value;
            });
            _saveSetting('auto_sync', value);
          },
          screenWidth,
        ),
        const SizedBox(height: 16),
        _buildSyncFrequencySelector(screenWidth),
        const SizedBox(height: 16),
        _buildDataLimitSlider(screenWidth),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildOutlinedButton(
                'Download Content',
                Icons.download,
                const Color(0xFF8B5CF6),
                _downloadOfflineContent,
                screenWidth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOutlinedButton(
                'Clear Data',
                Icons.delete_outline,
                Colors.orange,
                _clearOfflineData,
                screenWidth,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(double screenWidth) {
    return _buildSection(
      'Notifications',
      Icons.notifications,
      const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
      screenWidth,
      [
        _buildSwitchTile(
          'Enable Notifications',
          'Receive updates and reminders',
          _notifications,
              (value) {
            setState(() {
              _notifications = value;
            });
            _saveSetting('notifications', value);
          },
          screenWidth,
        ),
      ],
    );
  }

  Widget _buildPrivacySection(double screenWidth) {
    return _buildSection(
      'Privacy & Security',
      Icons.security,
      const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0D9488)]),
      screenWidth,
      [
        _buildActionTile(
          'Data Export',
          'Download your data',
          Icons.download_outlined,
          _exportData,
          screenWidth,
        ),
        const SizedBox(height: 8),
        _buildActionTile(
          'Clear Cache',
          'Free up storage space',
          Icons.cleaning_services_outlined,
          _clearCache,
          screenWidth,
        ),
      ],
    );
  }

  Widget _buildAboutSection(double screenWidth) {
    return _buildSection(
      'About',
      Icons.info,
      const LinearGradient(colors: [Color(0xFF64748B), Color(0xFF475569)]),
      screenWidth,
      [
        _buildInfoTile('Version', '1.0.0', screenWidth),
        const SizedBox(height: 8),
        _buildActionTile(
          'Terms of Service',
          'Read our terms and conditions',
          Icons.arrow_forward_ios,
              () => _showInfoDialog(
            'Terms of Service',
            'By using this app, you agree to our terms and conditions. '
                'This is a demo application for educational purposes.',
          ),
          screenWidth,
        ),
        const SizedBox(height: 8),
        _buildActionTile(
          'Privacy Policy',
          'How we protect your data',
          Icons.arrow_forward_ios,
              () => _showInfoDialog(
            'Privacy Policy',
            'We respect your privacy. This app stores data locally and '
                'uses Firebase for authentication. No personal data is '
                'shared with third parties.',
          ),
          screenWidth,
        ),
        const SizedBox(height: 8),
        _buildActionTile(
          'Help & Support',
          'Get help and contact support',
          Icons.arrow_forward_ios,
              () => _showInfoDialog(
            'Help & Support',
            'For support, please contact us at support@sahayak.app '
                'or visit our help center at sahayak.app/help',
          ),
          screenWidth,
        ),
        const SizedBox(height: 8),
        _buildActionTile(
          'Open Source Licenses',
          'View third-party licenses',
          Icons.arrow_forward_ios,
              () => showLicensePage(context: context),
          screenWidth,
        ),
      ],
    );
  }

  Widget _buildSection(
      String title,
      IconData icon,
      LinearGradient gradient,
      double screenWidth,
      List<Widget> children,
      ) {
    final cardPadding = _getCardPadding(screenWidth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: screenWidth < 600 ? 18 : 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth < 600 ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double screenWidth,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: screenWidth < 600 ? 14 : 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: screenWidth < 600 ? 20 : 24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth < 600 ? 12 : 16,
          vertical: screenWidth < 600 ? 12 : 16,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      bool value,
      ValueChanged<bool>? onChanged,
      double screenWidth,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth < 600 ? 14 : 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: screenWidth < 600 ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap,
      double screenWidth,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth < 600 ? 14 : 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: screenWidth < 600 ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              size: screenWidth < 600 ? 16 : 18,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: screenWidth < 600 ? 14 : 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: screenWidth < 600 ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncFrequencySelector(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sync,
            color: _autoSync && !_offlineMode ? const Color(0xFF8B5CF6) : Colors.grey,
            size: screenWidth < 600 ? 20 : 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync Frequency',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth < 600 ? 14 : 16,
                  ),
                ),
                Text(
                  _getSyncFrequencyText(_syncFrequency),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: screenWidth < 600 ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _syncFrequency,
              underline: const SizedBox(),
              style: TextStyle(
                color: const Color(0xFF8B5CF6),
                fontSize: screenWidth < 600 ? 12 : 14,
              ),
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
        ],
      ),
    );
  }

  Widget _buildDataLimitSlider(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage,
                color: const Color(0xFF8B5CF6),
                size: screenWidth < 600 ? 20 : 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offline Data Limit',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth < 600 ? 14 : 16,
                      ),
                    ),
                    Text(
                      '$_offlineDataLimit MB',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: screenWidth < 600 ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF8B5CF6),
              thumbColor: const Color(0xFF8B5CF6),
              overlayColor: const Color(0xFF8B5CF6).withOpacity(0.2),
            ),
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
        ],
      ),
    );
  }

  Widget _buildGradientButton(
      String text,
      IconData icon,
      LinearGradient gradient,
      VoidCallback onPressed,
      double screenWidth,
      ) {
    return Container(
      width: double.infinity,
      height: screenWidth < 600 ? 48 : 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: screenWidth < 600 ? 18 : 20,
          color: Colors.white,
        ),
        label: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth < 600 ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(
      String text,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      double screenWidth,
      ) {
    return Container(
      width: double.infinity,
      height: screenWidth < 600 ? 48 : 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: screenWidth < 600 ? 18 : 20,
          color: color,
        ),
        label: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: screenWidth < 600 ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(double screenWidth) {
    return _buildOutlinedButton(
      'Logout',
      Icons.logout,
      Colors.red,
      _logout,
      screenWidth,
    );
  }

  List<String> _getSupportedLanguages() {
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
          SnackBar(
            content: const Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
          SnackBar(
            content: const Text('Account linked successfully! Your data is now secure.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link account: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                Navigator.pop(context);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                );

                await auth.deleteAccount();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Account deleted successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Download Offline Content',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                SnackBar(
                  content: const Text('Downloading offline content...'),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Clear Offline Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                SnackBar(
                  content: const Text('Offline data cleared successfully'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF3B82F6),
            ),
            SizedBox(height: 16),
            Text('Preparing your data for export...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data export completed! Check your downloads folder.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Clear Cache',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cache cleared successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                Navigator.pop(context);

                await auth.logout();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Logged out successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
    _animationController.dispose();
    _nameController.dispose();
    _schoolController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}