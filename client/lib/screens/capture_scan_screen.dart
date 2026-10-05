import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/http_helper.dart';
import '../widgets/pokeball_icon.dart';

class CaptureScanScreen extends StatefulWidget {
  const CaptureScanScreen({super.key});

  @override
  State<CaptureScanScreen> createState() => _CaptureScanScreenState();
}

class _CaptureScanScreenState extends State<CaptureScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  MobileScannerController? _cameraController;
  bool _isTorchOn = false;
  bool _isFrontCamera = false;
  bool _isSubmitting = false;
  bool _hasCameraError = false;
  bool _hasScanned = false;

  bool get _isLiveCameraSupported {
    if (kIsWeb) return true;
    return !Platform.isLinux && !Platform.isWindows;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      _laserController.forward();
    } else {
      _laserController.repeat(reverse: true);
    }

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    if (_isLiveCameraSupported) {
      _initCameraController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed && !_isSubmitting && !_hasScanned) {
      _resumeCamera();
    }
  }

  void _initCameraController() {
    try {
      _cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
        autoStart: true,
      );
    } catch (_) {
      setState(() {
        _hasCameraError = true;
      });
    }
  }

  Future<void> _stopCamera() async {
    try {
      if (_cameraController != null) {
        await _cameraController!.stop();
      }
    } catch (_) {}
  }

  Future<void> _resumeCamera() async {
    setState(() {
      _hasScanned = false;
      _isSubmitting = false;
    });
    try {
      if (_cameraController != null) {
        await _cameraController!.start();
      }
    } catch (_) {}
  }

  Future<void> _handleBack() async {
    await _stopCamera();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laserController.dispose();
    try {
      _cameraController?.stop();
    } catch (_) {}
    try {
      _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;
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

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isSubmitting || _hasScanned) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue ?? barcode.displayValue;
      if (code != null && code.trim().isNotEmpty) {
        _hasScanned = true;
        try {
          HapticFeedback.mediumImpact();
        } catch (_) {}

        // Immediately stop and turn off the camera after detecting QR code
        await _stopCamera();
        await _submitQrData(code.trim());
        break;
      }
    }
  }

  /// POST /api/connect/qr with `{"qr_data": "<data>"}`
  Future<void> _submitQrData(String qrData) async {
    final cleanQr = qrData.trim();
    if (cleanQr.isEmpty) {
      _showToast('Please provide valid QR data');
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Ensure camera is stopped during submission
    await _stopCamera();

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

      _showCaptureSuccessDialog(message);
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

  /// POST /api/connect with `{"email": "<email>", "passkey": "<passkey>"}`
  Future<void> _submitManualConnect({
    required String email,
    required String passkey,
  }) async {
    final cleanEmail = email.trim();
    final cleanPasskey = passkey.trim();

    if (cleanEmail.isEmpty) {
      _showToast('Please enter trainer campus email');
      return;
    }

    if (cleanPasskey.isEmpty) {
      _showToast('Please enter passkey / QR details');
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Stop camera while processing
    await _stopCamera();

    try {
      final response = await httpPost(
        '/api/connect',
        body: {
          'email': cleanEmail,
          'passkey': cleanPasskey,
        },
      );

      if (!mounted) return;

      String message = 'Connected with $cleanEmail successfully!';
      if (response is Map && response['message'] != null) {
        message = response['message'].toString();
      }

      _showCaptureSuccessDialog(message);
    } on ApiException catch (e) {
      _showToast(e.message);
    } catch (e) {
      _showToast('Failed to connect: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _toggleTorch() async {
    if (_cameraController == null) return;
    try {
      await _cameraController!.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (e) {
      _showToast('Torch unavailable: $e');
    }
  }

  void _switchCamera() async {
    if (_cameraController == null) return;
    try {
      await _cameraController!.switchCamera();
      setState(() => _isFrontCamera = !_isFrontCamera);
    } catch (e) {
      _showToast('Cannot switch camera: $e');
    }
  }

  void _showCaptureSuccessDialog(String message, {String? details}) {
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
            if (details != null && details.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  details,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _handleBack();
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
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resumeCamera();
              },
              child: Text(
                'Scan Another Trainer',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualEntrySheet() {
    final emailController = TextEditingController();
    final passkeyController = TextEditingController();

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
                  Row(
                    children: [
                      const PokeballIcon(size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Manual Trainer Connect',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Enter trainer campus email and passkey (QR details) to connect.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),

              // 1. Trainer Email
              Text(
                'Trainer Email',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('manual_email_field'),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. trainer@campus.edu',
                  prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20, color: Color(0xFF94A3B8)),
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
              const SizedBox(height: 14),

              // 2. Passkey / QR Details
              Text(
                'Passkey (QR Code Details)',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('manual_passkey_field'),
                controller: passkeyController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. mlnokamc or trainer token',
                  prefixIcon: const Icon(Icons.key_rounded, size: 20, color: Color(0xFF94A3B8)),
                  suffixIcon: IconButton(
                    tooltip: 'Paste from clipboard',
                    icon: const Icon(Icons.content_paste_rounded, color: Color(0xFF26C28F)),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text?.isNotEmpty == true) {
                        passkeyController.text = data!.text!.trim();
                      }
                    },
                  ),
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

              // Submit Button: POST /api/connect
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  key: const Key('manual_submit_button'),
                  onPressed: () {
                    final email = emailController.text;
                    final passkey = passkeyController.text;
                    Navigator.pop(ctx);
                    _submitManualConnect(email: email, passkey: passkey);
                  },
                  icon: const Icon(Icons.link_rounded, size: 20),
                  label: const Text('Connect with Trainer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26C28F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option to submit raw QR token directly
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    final passkey = passkeyController.text.trim();
                    if (passkey.isNotEmpty) {
                      Navigator.pop(ctx);
                      _submitQrData(passkey);
                    } else {
                      _showToast('Enter QR details above to submit as token');
                    }
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFF64748B)),
                  label: Text(
                    'Or Submit Directly as QR Token',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
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
    final useLiveCamera = _isLiveCameraSupported && !_hasCameraError && _cameraController != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0F1D),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: _handleBack,
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
            if (useLiveCamera) ...[
              IconButton(
                tooltip: 'Torch',
                icon: Icon(
                  _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: _isTorchOn ? const Color(0xFFFDE047) : Colors.white70,
                ),
                onPressed: _toggleTorch,
              ),
              IconButton(
                tooltip: 'Flip Camera',
                icon: Icon(
                  _isFrontCamera ? Icons.camera_front_rounded : Icons.camera_rear_rounded,
                  color: Colors.white70,
                ),
                onPressed: _switchCamera,
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  useLiveCamera
                      ? 'Align trainer QR code within the camera frame'
                      : 'Desktop Mode: Use camera on Android/Web, or paste QR code',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Scanner Area (Live Camera or Desktop Scanner Reticle)
              Expanded(
                child: Center(
                  child: Container(
                    width: 290,
                    height: 290,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF26C28F).withValues(alpha: 0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF26C28F).withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          // 1. Live Camera Viewfinder (Android & Web)
                          if (useLiveCamera)
                            Positioned.fill(
                              child: MobileScanner(
                                controller: _cameraController!,
                                onDetect: _onBarcodeDetected,
                                errorBuilder: (context, error) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 40),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Camera access error: ${error.errorCode.name}',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton(
                                            onPressed: _showManualEntrySheet,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF26C28F),
                                            ),
                                            child: const Text('Enter Code Manually'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            // Desktop Background (Linux)
                            Positioned.fill(
                              child: Container(
                                color: const Color(0xFF0F172A),
                                child: Center(
                                  child: Opacity(
                                    opacity: 0.2,
                                    child: const PokeballIcon(size: 120),
                                  ),
                                ),
                              ),
                            ),

                          // 2. Animated Laser Scan Line
                          AnimatedBuilder(
                            animation: _laserAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: _laserAnimation.value * 270 + 10,
                                left: 14,
                                right: 14,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF34D399),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF34D399).withValues(alpha: 0.9),
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

                          // 3. Viewfinder Corner Markers
                          _buildCorner(Alignment.topLeft),
                          _buildCorner(Alignment.topRight),
                          _buildCorner(Alignment.bottomLeft),
                          _buildCorner(Alignment.bottomRight),

                          // 4. Loading Overlay when submitting
                          if (_isSubmitting)
                            Container(
                              color: Colors.black54,
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
              ),

              const SizedBox(height: 16),

              // Action Button at bottom: Enter Manually
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const Key('manual_entry_button'),
                    onPressed: _isSubmitting ? null : _showManualEntrySheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26C28F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_outlined, size: 20),
                    label: Text(
                      'Enter Details Manually',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
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
