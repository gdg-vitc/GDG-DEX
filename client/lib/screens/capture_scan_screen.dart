import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/http_helper.dart';
import '../widgets/pokeball_icon.dart';

class CaptureScanScreen extends StatefulWidget {
  const CaptureScanScreen({super.key});

  @override
  State<CaptureScanScreen> createState() => _CaptureScanScreenState();
}

class _CaptureScanScreenState extends State<CaptureScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  bool _isTorchOn = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = true}) {
    try {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF10B981),
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
          backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _submitQrData(String qrData) async {
    final cleanQr = qrData.trim();
    if (cleanQr.isEmpty) {
      _showToast('Please provide valid QR data');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await httpPost(
        '/api/connect/qr',
        body: {'qr_data': cleanQr},
      );

      if (!mounted) return;

      String message = 'Trainer connection captured successfully!';
      if (response is Map && response['message'] != null) {
        message = response['message'].toString();
      }

      _showCaptureSuccessDialog(cleanQr, message);
    } on ApiException catch (e) {
      _showToast(e.message);
    } catch (e) {
      _showToast('Failed to process QR: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showCaptureSuccessDialog(String qrData, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
              ),
              child: const Center(
                child: PokeballIcon(size: 44),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Captured!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                qrData,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Return to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26C28F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Back to Pokédex',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualEntrySheet() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manual QR Code Entry',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Enter or paste the trainer QR token below to capture.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. TRAINER-QR-98214',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF26C28F), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final text = controller.text;
                    Navigator.pop(ctx);
                    _submitQrData(text);
                  },
                  icon: const PokeballIcon(size: 20),
                  label: const Text('Capture with Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26C28F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan QR to Capture',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? const Color(0xFFFDE047) : Colors.white70,
            ),
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Align trainer QR code within the frame',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),

            // Viewfinder Scanner Box
            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF26C28F).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Pokéball watermark in center
                      Center(
                        child: Opacity(
                          opacity: 0.15,
                          child: const PokeballIcon(size: 110),
                        ),
                      ),

                      // Animated Laser Scan Line
                      AnimatedBuilder(
                        animation: _laserAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: _laserAnimation.value * 260 + 10,
                            left: 14,
                            right: 14,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFF34D399),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF34D399).withValues(alpha: 0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      ),

                      // Corner indicators
                      _buildCorner(Alignment.topLeft),
                      _buildCorner(Alignment.topRight),
                      _buildCorner(Alignment.bottomLeft),
                      _buildCorner(Alignment.bottomRight),

                      // Loading Overlay
                      if (_isSubmitting)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF26C28F),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons at bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Test/Simulate QR Scan button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitQrData('GDG-POKEMON-TRAINER-${DateTime.now().millisecondsSinceEpoch % 10000}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26C28F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const PokeballIcon(size: 22),
                      label: Text(
                        'Simulate QR Capture',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Manual Entry Link
                  TextButton.icon(
                    onPressed: _isSubmitting ? null : _showManualEntrySheet,
                    icon: const Icon(Icons.keyboard_outlined, color: Colors.white70, size: 18),
                    label: Text(
                      'Enter QR code manually',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? const BorderSide(color: Color(0xFF26C28F), width: 3.5)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? const BorderSide(color: Color(0xFF26C28F), width: 3.5)
                : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? const BorderSide(color: Color(0xFF26C28F), width: 3.5)
                : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? const BorderSide(color: Color(0xFF26C28F), width: 3.5)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
