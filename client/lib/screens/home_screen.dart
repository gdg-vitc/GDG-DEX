import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/http_helper.dart';
import '../widgets/pokeball_icon.dart';
import 'capture_scan_screen.dart';
import 'leaderboard_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String? email;
  final String? regNo;
  final String? token;
  final String? role;
  final String? name;

  const HomeScreen({
    super.key,
    this.email,
    this.regNo,
    this.token,
    this.role,
    this.name,
  });

  void _handleLogout(BuildContext context) {
    HttpHelper.clearToken();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _copyTokenToClipboard(BuildContext context, String tokenToCopy) {
    Clipboard.setData(ClipboardData(text: tokenToCopy));
    try {
      Fluttertoast.showToast(
        msg: 'Trainer token copied to clipboard!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        textColor: Colors.white,
        fontSize: 13.0,
      );
    } catch (_) {}

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Trainer token copied to clipboard!',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _resolveToken() {
    if (token != null && token!.trim().isNotEmpty) {
      return token!.trim();
    }
    final httpToken = HttpHelper.token;
    if (httpToken != null && httpToken.trim().isNotEmpty) {
      return httpToken.trim();
    }
    return 'PKMN-7749-X9';
  }

  String _getTrainerName() {
    if (name != null && name!.trim().isNotEmpty) {
      return name!.trim();
    }
    if (HttpHelper.userName != null && HttpHelper.userName!.trim().isNotEmpty) {
      return HttpHelper.userName!.trim();
    }
    if (email != null && email!.trim().isNotEmpty) {
      final namePart = email!.trim().split('@').first;
      if (namePart.isNotEmpty) {
        final capitalized = namePart[0].toUpperCase() + namePart.substring(1);
        return 'Trainer $capitalized';
      }
    }
    return 'Trainer Ash';
  }

  String _getTrainerId() {
    if (regNo != null && regNo!.trim().isNotEmpty) {
      return 'ID: ${regNo!.trim()}';
    }
    return 'ID: STU-08429';
  }

  String _resolveRole() {
    if (role != null && role!.trim().isNotEmpty) {
      return role!.trim();
    }
    if (HttpHelper.role != null && HttpHelper.role!.trim().isNotEmpty) {
      return HttpHelper.role!.trim();
    }
    final jwtRole = extractRoleFromJwt(token ?? HttpHelper.token);
    if (jwtRole != null && jwtRole.isNotEmpty) {
      return jwtRole;
    }
    return 'Kanto Club';
  }

  static String? extractRoleFromJwt(String? rawToken) {
    if (rawToken == null) return null;
    final parts = rawToken.split('.');
    if (parts.length != 3) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadString);
      if (payload is Map) {
        final dynamic val =
            payload['role'] ??
            payload['club_role'] ??
            payload['user_role'] ??
            payload['member_role'] ??
            payload['role_name'] ??
            payload['designation'] ??
            payload['position'] ??
            payload['club'] ??
            (payload['user'] is Map ? payload['user']['role'] : null) ??
            (payload['data'] is Map ? payload['data']['role'] : null);
        if (val is List && val.isNotEmpty) {
          final first = val.first?.toString().trim();
          if (first != null && first.isNotEmpty) return first;
        } else if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final activeToken = _resolveToken();
    final trainerName = _getTrainerName();
    final trainerId = _getTrainerId();
    final trainerRole = _resolveRole();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SafeArea(
        child: Stack(
          children: [
            // Soft organic background curves matching the mockup
            Positioned.fill(
              child: CustomPaint(painter: _BackgroundCurvesPainter()),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar: Back button and "Pokédex" title
                      _buildTopBar(context),
                      const SizedBox(height: 16),

                      // Card 1: Trainer Profile + Token & QR Code Card
                      _buildTrainerTokenCard(
                        context,
                        trainerName: trainerName,
                        trainerId: trainerId,
                        trainerRole: trainerRole,
                        token: activeToken,
                      ),
                      const SizedBox(height: 18),

                      // Card 2: "Capture" / Member Scanner Card
                      _buildCaptureCard(context),
                      const SizedBox(height: 18),

                      // Card 3: "View Leaderboard" / Club Standings Card
                      _buildLeaderboardCard(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF0F766E),
              size: 20,
            ),
            onPressed: () => _handleLogout(context),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'GDGDEX',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  void _showTrainerDetailsModal(
    BuildContext context, {
    required String trainerName,
    required String trainerRole,
    required String trainerId,
    required String token,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag indicator handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header: Avatar, Name & Role, ID
            Row(
              children: [
                _buildTrainerAvatar(trainerName: trainerName),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              trainerName,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F7F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              trainerRole,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0D9488),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trainerId,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Large Scannable QR Code (pure basic QR without pokemon logo)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: token,
                  version: QrVersions.auto,
                  size: 190.0,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0F172A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Full Token Section (word-wrapped so no text gets cutoff)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FULL TRAINER TOKEN',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: const Color(0xFF475569),
                  ),
                ),
                const Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: Color(0xFF0D9488),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SelectableText(
                token,
                style: GoogleFonts.robotoMono(
                  fontSize: 12.5,
                  color: const Color(0xFF0F766E),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Copy Full Token Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  _copyTokenToClipboard(context, token);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26C28F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(
                  'Copy Full Token',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerTokenCard(
    BuildContext context, {
    required String trainerName,
    required String trainerId,
    required String trainerRole,
    required String token,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          key: const Key('trainer_token_card'),
          borderRadius: BorderRadius.circular(26),
          onTap: () => _showTrainerDetailsModal(
            context,
            trainerName: trainerName,
            trainerId: trainerId,
            trainerRole: trainerRole,
            token: token,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Trainer Info
                Row(
                  children: [
                    _buildTrainerAvatar(trainerName: trainerName),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  trainerName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F7F2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    trainerRole,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF0D9488),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            trainerId,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.fullscreen_rounded,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Inner Container: Token Box + QR Code
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3F8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Column: TRAINER TOKEN header, token box, and helper text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'TRAINER TOKEN',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 13,
                                  color: Color(0xFF0D9488),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Interactive Token Pill
                            InkWell(
                              onTap: () => _copyTokenToClipboard(context, token),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        token,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F766E),
                                          letterSpacing: 0.6,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.copy_rounded,
                                      size: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              'Tap container to view full token & large QR',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                height: 1.3,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Right: Bigger basic QR Code without any center logo
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: QrImageView(
                            data: token,
                            version: QrVersions.auto,
                            size: 96.0,
                            padding: const EdgeInsets.all(2),
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0F172A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0F172A),
                            ),
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
    );
  }

  Widget _buildTrainerAvatar({String? trainerName}) {
    final initial = (trainerName != null && trainerName.trim().isNotEmpty)
        ? trainerName.trim().replaceAll('Trainer ', '').trim().characters.first.toUpperCase()
        : 'T';

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2DD4BF), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2DD4BF).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFE6F7F2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D9488),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38D39F), Color(0xFF1CB081)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E1CB081),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('capture_card_button'),
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CaptureScanScreen()),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Concentric circles with Pokéball on the right
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          const PokeballIcon(size: 54),
                        ],
                      ),
                    ),
                  ),
                ),

                // Card Content on the left
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'MEMBER SCANNER',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            Text(
                              'Capture',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),

                            Text(
                              'Encounter & scan a club member to add to your Dex',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.35,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 18),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Launch Scanner',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 100,
                      ), // Reserve clear space for Pokéball on right
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('leaderboard_card_button'),
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LeaderboardScreen(
                  currentUserName: _getTrainerName(),
                  currentUserRole: _resolveRole(),
                  currentUserRegNo: regNo,
                  currentUserEmail: email,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Soft peach/pink concentric circles on the right
                Positioned(
                  right: -15,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFEE2E2)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          Container(
                            width: 88,
                            height: 88,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFECEC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Card Content on the left
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'CLUB STANDINGS',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF991B1B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            Text(
                              'View\nLeaderboard',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              'Check top trainers & club encounter rankings',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.35,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 18),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Open Standings',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF991B1B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF991B1B),
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 80,
                      ), // Reserve clear space for peach circles on right
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter to draw the gentle organic background curves from the mockup
class _BackgroundCurvesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2F3EC).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round;

    final path1 = Path();
    path1.moveTo(-40, size.height * 0.16);
    path1.cubicTo(
      size.width * 0.2,
      size.height * 0.30,
      size.width * 0.7,
      size.height * 0.32,
      size.width + 60,
      size.height * 0.20,
    );
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(-50, size.height * 0.70);
    path2.cubicTo(
      size.width * 0.2,
      size.height * 0.58,
      size.width * 0.6,
      size.height * 0.68,
      size.width + 60,
      size.height * 0.88,
    );
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
