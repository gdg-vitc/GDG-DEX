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

  const HomeScreen({
    super.key,
    this.email,
    this.regNo,
    this.token,
  });

  void _handleLogout(BuildContext context) {
    HttpHelper.clearToken();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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

  @override
  Widget build(BuildContext context) {
    final activeToken = _resolveToken();
    final trainerName = _getTrainerName();
    final trainerId = _getTrainerId();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SafeArea(
        child: Stack(
          children: [
            // Soft organic background curves matching the mockup
            Positioned.fill(
              child: CustomPaint(
                painter: _BackgroundCurvesPainter(),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F766E), size: 20),
            onPressed: () => _handleLogout(context),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'Pokédex',
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

  Widget _buildTrainerTokenCard(
    BuildContext context, {
    required String trainerName,
    required String trainerId,
    required String token,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Trainer Info
          Row(
            children: [
              _buildTrainerAvatar(),
              const SizedBox(width: 16),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Kanto Club',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0D9488),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        'Show QR code to fellow trainers to initiate meetup encounter',
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

                // Right: Generated QR Code with just the token inside it
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
                      size: 78.0,
                      padding: const EdgeInsets.all(3),
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
    );
  }

  Widget _buildTrainerAvatar() {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2DD4BF),
              width: 3.5,
            ),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '20',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                  Text(
                    'MP',
                    style: GoogleFonts.inter(
                      fontSize: 7.5,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF065F46),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Lv.14',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                      color: Colors.white.withValues(alpha: 0.7),
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
                      const SizedBox(width: 100), // Reserve clear space for Pokéball on right
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
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
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
                              color: const Color(0xFFFEE2E2).withValues(alpha: 0.6),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      const SizedBox(width: 80), // Reserve clear space for peach circles on right
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
