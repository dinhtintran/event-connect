import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:event_connect/features/profile/data/api/profile_api.dart';
import 'package:event_connect/features/profile/data/models/user_profile.dart';
import 'package:event_connect/features/authentication/presentation/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final _profileApi = ProfileApi();

  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await _storage.read(key: 'auth_access');

      if (accessToken == null) {
        setState(() {
          _errorMessage = 'Not logged in';
          _isLoading = false;
        });
        return;
      }

      final result = await _profileApi.getProfile(accessToken: accessToken);

      if (result['status'] == 200 && result['body'] != null) {
        final data = result['body'];
        if (data['ok'] == true && data['user'] != null) {
          setState(() {
            _userProfile = UserProfile.fromJson(data['user']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load profile';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = result['body']?['detail'] ?? 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final accessToken = await _storage.read(key: 'auth_access');
      final refreshToken = await _storage.read(key: 'auth_refresh');

      if (accessToken != null && refreshToken != null) {
        // Call logout API
        await _profileApi.logout(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      // Clear all tokens
      await _storage.delete(key: 'auth_access');
      await _storage.delete(key: 'auth_refresh');

      if (mounted) {
        // Navigate to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadProfile,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _userProfile == null
                  ? const Center(child: Text('No profile data'))
                  : RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Header
                            Center(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: Text(
                                      _userProfile!.username.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 48,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _userProfile!.username,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(_userProfile!.role),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      _getRoleLabel(_userProfile!.role),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Profile Information
                            _buildInfoCard(
                              'Thông tin tài khoản',
                              [
                                _buildInfoRow(Icons.email, 'Email', _userProfile!.email),
                                _buildInfoRow(Icons.person, 'Username', _userProfile!.username),
                                _buildInfoRow(Icons.badge, 'Vai trò', _getRoleLabel(_userProfile!.role)),
                                _buildInfoRow(
                                  Icons.check_circle,
                                  'Trạng thái',
                                  _userProfile!.isActive ? 'Đang hoạt động' : 'Không hoạt động',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Additional Info
                            _buildInfoCard(
                              'Thông tin bổ sung',
                              [
                                if (_userProfile!.firstName != null && _userProfile!.firstName!.isNotEmpty)
                                  _buildInfoRow(Icons.person_outline, 'Tên', _userProfile!.firstName!),
                                if (_userProfile!.lastName != null && _userProfile!.lastName!.isNotEmpty)
                                  _buildInfoRow(Icons.person_outline, 'Họ', _userProfile!.lastName!),
                                _buildInfoRow(Icons.calendar_today, 'Ngày tạo', _formatDate(_userProfile!.dateJoined)),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _handleLogout,
                                icon: const Icon(Icons.logout),
                                label: const Text('Đăng xuất'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'club_admin':
        return Colors.purple;
      case 'student':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Quản trị viên';
      case 'club_admin':
        return 'Quản lý CLB';
      case 'student':
        return 'Sinh viên';
      default:
        return role;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

