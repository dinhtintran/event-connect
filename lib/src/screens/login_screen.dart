import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_service.dart';
import '../routes.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../constants/roles.dart';

// UI displays labels from `roleOptions` but sends `value` to API

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedRole = 2; // default index
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  Map<String, String?> _errors = {};
  // focus nodes and keys for auto-focus on errors
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final GlobalKey _emailKey = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _errors = {};
    });
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        if (email.isEmpty) _errors['email'] = 'Vui lòng nhập email';
        if (password.isEmpty) _errors['password'] = 'Vui lòng nhập mật khẩu';
      });
      return;
    }
    setState(() => _loading = true);
    final resp = await auth.loginDetailed(username: email, password: password);
    if (!mounted) return;
    setState(() => _loading = false);
    final status = resp['status'] as int? ?? 0;
    final body = resp['body'] as Map<String, dynamic>? ?? {};
    if ((status == 200 || status == 201) && body['access'] != null) {
      Navigator.of(context).pushReplacementNamed(Routes.home);
      return;
    }

    // parse errors
    if (body.isNotEmpty) {
      // field errors often come as lists
      setState(() {
        if (body.containsKey('username')) _errors['email'] = (body['username'] is List) ? (body['username'] as List).join(' ') : body['username'].toString();
        if (body.containsKey('email')) _errors['email'] = (body['email'] is List) ? (body['email'] as List).join(' ') : body['email'].toString();
        if (body.containsKey('password')) _errors['password'] = (body['password'] is List) ? (body['password'] as List).join(' ') : body['password'].toString();
        if (body.containsKey('detail')) _errors['non_field'] = body['detail'].toString();
        if (body.containsKey('non_field_errors')) _errors['non_field'] = (body['non_field_errors'] as List).join(' ');
      });
      // show non-field error and focus first error
      if (_errors['non_field'] != null && _errors['non_field']!.isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errors['non_field']!)));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusFirstError();
      });
    } else {
      setState(() {
        _errors['non_field'] = 'Đăng nhập thất bại — kiểm tra thông tin';
      });
    }
  }

  void _focusFirstError() {
    if (_errors['email'] != null) {
      _scrollToAndFocus(_emailKey, _emailFocus);
    } else if (_errors['password'] != null) {
      _scrollToAndFocus(_passwordKey, _passwordFocus);
    }
  }

  void _scrollToAndFocus(GlobalKey key, FocusNode node) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    node.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    // logo with fallback
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Image.asset(
                          'assets/logo.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, st) => Container(
                            decoration: BoxDecoration(color: theme.colorScheme.primary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.calendar_month, color: theme.colorScheme.primary, size: 36),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Chào mừng trở lại!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Đăng nhập vào tài khoản của bạn', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('Chọn loại tài khoản', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(roleOptions.length, (i) {
                  final selected = i == _selectedRole;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRole = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected ? theme.colorScheme.primary.withAlpha(20) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? theme.colorScheme.primary : Colors.grey[300]! ),
                      ),
                      child: Text(roleOptions[i].label, style: TextStyle(color: selected ? theme.colorScheme.primary : Colors.black)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              const Text('Email hoặc tên người dùng', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CustomTextField(key: _emailKey, controller: _email, hintText: 'Nhập email hoặc tên người dùng của bạn', icon: Icons.email, focusNode: _emailFocus),
              if (_errors['email'] != null) ...[
                const SizedBox(height: 6),
                Text(_errors['email'] ?? '', style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              const Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CustomTextField(key: _passwordKey, controller: _password, hintText: 'Nhập mật khẩu của bạn', obscure: true, icon: Icons.lock, focusNode: _passwordFocus),
              if (_errors['password'] != null) ...[
                const SizedBox(height: 6),
                Text(_errors['password'] ?? '', style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 18),
              PrimaryButton(text: 'Đăng nhập', onPressed: _submit, loading: _loading),
              const SizedBox(height: 12),
              Center(child: TextButton(onPressed: () {}, child: const Text('Quên mật khẩu?'))),
              const SizedBox(height: 18),
              Center(
                child: RichText(
                  text: TextSpan(text: 'Chưa có tài khoản? ', style: TextStyle(color: Colors.grey[700]), children: [
                    TextSpan(text: 'Đăng ký', style: TextStyle(color: theme.colorScheme.primary), recognizer: TapGestureRecognizer()..onTap = () => Navigator.of(context).pushNamed(Routes.register)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
