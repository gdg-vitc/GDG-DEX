import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/http_helper.dart';
import '../widgets/gdg_logo.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();

  bool _rememberDevice = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _regNoController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    try {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final regNo = _regNoController.text.trim();

    if (email.isEmpty) {
      const msg = 'Please enter your campus email';
      setState(() => _errorMessage = msg);
      _showToast(msg);
      return;
    }

    if (regNo.isEmpty) {
      const msg = 'Please enter your Student ID (Guild Card)';
      setState(() => _errorMessage = msg);
      _showToast(msg);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await httpPost(
        '/api/login',
        body: {'email': email, 'reg_no': regNo},
      );

      // Save token if returned by backend
      if (response is Map) {
        final dynamic rawToken = response['token'] ??
            response['access_token'] ??
            response['jwt'] ??
            response['session_token'] ??
            (response['data'] is Map ? (response['data']['token'] ?? response['data']['access_token']) : null);
        if (rawToken != null && rawToken.toString().trim().isNotEmpty) {
          HttpHelper.setToken(rawToken.toString().trim());
        }
      }

      final sessionToken = HttpHelper.token;

      // Extract role if returned by backend API
      String? userRole;
      if (response is Map) {
        final dynamic rawRole = response['role'] ??
            response['club_role'] ??
            response['user_role'] ??
            response['member_role'] ??
            response['role_name'] ??
            (response['user'] is Map ? response['user']['role'] : null) ??
            (response['trainer'] is Map ? response['trainer']['role'] : null) ??
            (response['data'] is Map ? response['data']['role'] : null) ??
            response['club'] ??
            response['designation'] ??
            response['position'];

        if (rawRole is List && rawRole.isNotEmpty) {
          userRole = rawRole.first?.toString().trim();
        } else if (rawRole != null) {
          userRole = rawRole.toString().trim();
        }
      }

      // If role wasn't directly in response JSON, check if token contains role claims
      if ((userRole == null || userRole.isEmpty) && sessionToken != null) {
        userRole = HomeScreen.extractRoleFromJwt(sessionToken);
      }

      if (userRole != null && userRole.trim().isNotEmpty) {
        HttpHelper.role = userRole.trim();
      }

      // Extract user name if returned by backend API
      String? userName;
      if (response is Map) {
        final dynamic rawName = response['name'] ??
            (response['user'] is Map ? response['user']['name'] : null) ??
            (response['trainer'] is Map ? response['trainer']['name'] : null) ??
            (response['data'] is Map ? response['data']['name'] : null);
        if (rawName != null && rawName.toString().trim().isNotEmpty) {
          userName = rawName.toString().trim();
        }
      }

      if (userName != null && userName.trim().isNotEmpty) {
        HttpHelper.userName = userName.trim();
      }

      // Extract passkey if returned by backend API
      String? userPasskey;
      if (response is Map) {
        final dynamic rawPasskey = response['passkey'] ??
            (response['user'] is Map ? response['user']['passkey'] : null) ??
            (response['trainer'] is Map ? response['trainer']['passkey'] : null) ??
            (response['data'] is Map ? response['data']['passkey'] : null);
        if (rawPasskey != null && rawPasskey.toString().trim().isNotEmpty) {
          userPasskey = rawPasskey.toString().trim();
        }
      }

      if (userPasskey != null && userPasskey.trim().isNotEmpty) {
        HttpHelper.passkey = userPasskey.trim();
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            email: email,
            regNo: regNo,
            token: sessionToken,
            role: userRole,
            name: userName,
            passkey: userPasskey,
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      _showToast(e.message);
    } catch (e) {
      final msg = 'An unexpected error occurred: $e';
      setState(() {
        _errorMessage = msg;
      });
      _showToast(msg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Brand Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GdgLogo(size: 34),
                      const SizedBox(width: 12),
                      Text(
                        'GDG-DEX',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Club Pokédex Portal',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Login Form Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campus Email Label & Required
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Campus Email',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            Text(
                              'Required',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Campus Email TextField
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isLoading,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                            hintText: 'Sagnik_is_evil@vitstudent.ac.in',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 14.5,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2DD4BF),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Student ID Label & Guild Card
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Student ID',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            Text(
                              'Guild Card',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Student ID TextField
                        TextField(
                          controller: _regNoController,
                          enabled: !_isLoading,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                            hintText: '25BAI1234',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 14.5,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2DD4BF),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Remember this device & Need help?
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (!_isLoading) {
                                    setState(
                                      () => _rememberDevice = !_rememberDevice,
                                    );
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _rememberDevice
                                            ? const Color(0xFF2DD4BF)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _rememberDevice
                                              ? const Color(0xFF2DD4BF)
                                              : const Color(0xFFCBD5E1),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _rememberDevice
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Remember this device',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFF475569),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Text(
                                      'Need Help?',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Enter your registered campus email and student registration number (e.g. 21BCE0001 or STU-08429) to enter the Club Pokédex.',
                                      style: GoogleFonts.inter(fontSize: 14),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Got it'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                'Need help?',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0D9488),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Error Message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Color(0xFFDC2626),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: const Color(0xFFB91C1C),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],



                        const SizedBox(height: 20),

                        // Enter Club Pokédex Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF26C28F),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF86E3C3),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    children: [
                                      const Icon(
                                        Icons.bolt,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Enter Club Pokédex',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.control_camera,
                                          color: Colors.white,
                                          size: 17,
                                        ),
                                      ),
                                    ],
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
        ),
      ),
    );
  }
}
