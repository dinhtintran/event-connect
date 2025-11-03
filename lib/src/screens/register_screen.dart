import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_service.dart';
import '../routes.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../constants/roles.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  int _selectedRole = 2; // default to index of 'Người dùng thông thường'
  bool _loading = false;
  Map<String, String?> _errors = {};
  // roleOptions is defined in lib/src/constants/roles.dart
  // focus nodes and keys for scrolling to fields
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _emailKey = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();
  final GlobalKey _confirmKey = GlobalKey();

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final BuildContext localContext = context; // capture context to avoid use_build_context_synchronously lint
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;
    setState(() {
      _errors = {};
    });
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        if (name.isEmpty) _errors['display_name'] = 'Vui lòng nhập họ và tên';
        if (email.isEmpty) _errors['email'] = 'Vui lòng nhập email';
        if (password.isEmpty) _errors['password'] = 'Vui lòng nhập mật khẩu';
      });
      return;
    }
    if (password != confirm) {
      setState(() {
        _errors['password'] = 'Mật khẩu và xác nhận không khớp';
      });
      return;
    }
    setState(() => _loading = true);
    final payload = <String, dynamic>{
      'username': email,
      'email': email,
      'password': password,
      // send the backend role value, not the UI label
      'role': roleOptions[_selectedRole].value,
      'display_name': name,
    };
  // debug: print payload just before sending
  // ignore: avoid_print
  print('[RegisterScreen] payload: $payload');
  final resp = await auth.registerDetailed(payload: payload);
    if (!mounted) return;
    setState(() => _loading = false);
    final status = resp['status'] as int? ?? 0;
    final body = resp['body'] as Map<String, dynamic>? ?? {};
    // If server returned an unexpected status (e.g., 405, 500, connection error), show raw info to help debugging
    if (status != 200 && status != 201) {
      if (!mounted) return;
      // show a dialog with details for easier debugging
      try {
        await showDialog<void>(context: localContext, builder: (ctx) {
          return AlertDialog(
            title: Text('Lỗi server ($status)'),
            content: SingleChildScrollView(child: Text(body.toString())),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Đóng'))],
          );
        });
      } catch (_) {}
    }
    if ((status == 200 || status == 201) && body['access'] != null) {
      Navigator.of(localContext).pushReplacementNamed(Routes.home);
      return;
    }

    if (body.isNotEmpty) {
      setState(() {
        if (body.containsKey('display_name')) _errors['display_name'] = (body['display_name'] is List) ? (body['display_name'] as List).join(' ') : body['display_name'].toString();
        if (body.containsKey('name')) _errors['display_name'] = (body['name'] is List) ? (body['name'] as List).join(' ') : body['name'].toString();
        if (body.containsKey('email')) _errors['email'] = (body['email'] is List) ? (body['email'] as List).join(' ') : body['email'].toString();
        if (body.containsKey('password')) _errors['password'] = (body['password'] is List) ? (body['password'] as List).join(' ') : body['password'].toString();
        if (body.containsKey('student_id')) _errors['student_id'] = (body['student_id'] is List) ? (body['student_id'] as List).join(' ') : body['student_id'].toString();
        if (body.containsKey('club_name')) _errors['club_name'] = (body['club_name'] is List) ? (body['club_name'] as List).join(' ') : body['club_name'].toString();
        if (body.containsKey('school_code')) _errors['school_code'] = (body['school_code'] is List) ? (body['school_code'] as List).join(' ') : body['school_code'].toString();
        if (body.containsKey('detail')) _errors['non_field'] = body['detail'].toString();
        if (body.containsKey('non_field_errors')) _errors['non_field'] = (body['non_field_errors'] as List).join(' ');
      });
      // show non-field error as SnackBar or alert
      if (_errors['non_field'] != null && _errors['non_field']!.isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(localContext).showSnackBar(SnackBar(content: Text(_errors['non_field']!)));
      }
      // focus first field that has an error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusFirstError();
      });
    } else {
      setState(() {
        _errors['non_field'] = 'Đăng ký thất bại — kiểm tra thông tin';
      });
      if (mounted) ScaffoldMessenger.of(localContext).showSnackBar(const SnackBar(content: Text('Đăng ký thất bại — kiểm tra thông tin')));
    }
  }

  void _focusFirstError() {
    if (_errors['display_name'] != null) {
      _scrollToAndFocus(_nameKey, _nameFocus);
    } else if (_errors['email'] != null) {
      _scrollToAndFocus(_emailKey, _emailFocus);
    } else if (_errors['password'] != null) {
      _scrollToAndFocus(_passwordKey, _passwordFocus);
    } else if (_errors['non_field'] != null) {
      // no specific field, keep snackbar visible
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
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text('Tạo tài khoản', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text('Vai trò', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
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
                        color: selected ? Theme.of(context).colorScheme.primary.withAlpha(30) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(i == 0 ? Icons.location_city : (i == 1 ? Icons.group : Icons.person), size: 18, color: selected ? Theme.of(context).colorScheme.primary : Colors.black54),
                        const SizedBox(width: 8),
                        Text(roleOptions[i].label, style: TextStyle(color: selected ? Theme.of(context).colorScheme.primary : Colors.black87)),
                      ]),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Personal info card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thông tin cá nhân', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      const Text('Họ và tên', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      CustomTextField(key: _nameKey, controller: _name, hintText: 'Nhập họ và tên', icon: Icons.person, focusNode: _nameFocus),
                      if (_errors['display_name'] != null) ...[
                        const SizedBox(height: 6),
                        Text(_errors['display_name'] ?? '', style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                      const SizedBox(height: 12),
                      const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      CustomTextField(key: _emailKey, controller: _email, hintText: 'Nhập email', icon: Icons.email, focusNode: _emailFocus),
                      if (_errors['email'] != null) ...[
                        const SizedBox(height: 6),
                        Text(_errors['email'] ?? '', style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                      const SizedBox(height: 12),
                      const Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      CustomTextField(key: _passwordKey, controller: _password, hintText: 'Mật khẩu (>=6 ký tự)', obscure: true, icon: Icons.lock, focusNode: _passwordFocus),
                      if (_errors['password'] != null) ...[
                        const SizedBox(height: 6),
                        Text(_errors['password'] ?? '', style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                      const SizedBox(height: 12),
                      const Text('Xác nhận mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      CustomTextField(key: _confirmKey, controller: _confirm, hintText: 'Nhập lại mật khẩu', obscure: true, icon: Icons.lock, focusNode: _confirmFocus),
                      if (_errors['non_field'] != null) ...[
                        const SizedBox(height: 12),
                        Text(_errors['non_field'] ?? '', style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(text: 'Đăng ký', onPressed: _submit, loading: _loading),
              const SizedBox(height: 12),
              Center(child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Quay lại'))),
            ],
          ),
        ),
      ),
    );
  }
}
