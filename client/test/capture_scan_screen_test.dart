import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:client/screens/capture_scan_screen.dart';
import 'package:client/services/http_helper.dart';

void main() {
  String mockClipboardText = '';

  setUp(() {
    mockClipboardText = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData') {
        mockClipboardText = (methodCall.arguments as Map)['text'] ?? '';
        return null;
      }
      if (methodCall.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': mockClipboardText};
      }
      return null;
    });
    HttpHelper.baseUrl = 'https://sponge-romantic-pangolin.ngrok-free.app';
    HttpHelper.token = 'dummy_token';
    HttpHelper.enableLogging = false;
  });

  testWidgets('CaptureScanScreen renders title, laser viewfinder, paste and manual buttons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaptureScanScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Scan QR to Capture'), findsOneWidget);
    expect(find.byKey(const Key('paste_capture_button')), findsOneWidget);
    expect(find.byKey(const Key('manual_entry_button')), findsOneWidget);
    expect(find.byKey(const Key('simulate_capture_button')), findsOneWidget);
  });

  testWidgets('Tapping manual entry button opens modal sheet with email, passkey and connect button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaptureScanScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('manual_entry_button')));
    await tester.pumpAndSettle();

    expect(find.text('Manual Trainer Connect'), findsOneWidget);
    expect(find.text('Trainer Email'), findsOneWidget);
    expect(find.text('Passkey (QR Code Details)'), findsOneWidget);
    expect(find.byKey(const Key('manual_email_field')), findsOneWidget);
    expect(find.byKey(const Key('manual_passkey_field')), findsOneWidget);
    expect(find.byKey(const Key('manual_submit_button')), findsOneWidget);
  });

  testWidgets('Manual connect sends POST /api/connect with email and passkey', (tester) async {
    bool apiCalled = false;

    HttpHelper.client = MockClient((request) async {
      if (request.url.path == '/api/connect' && request.method == 'POST') {
        apiCalled = true;
        final body = jsonDecode(request.body);
        expect(body['email'], equals('carol@example.com'));
        expect(body['passkey'], equals('mlnokamc'));
        expect(request.headers['Authorization'], equals('Bearer dummy_token'));

        return http.Response(
          jsonEncode({'message': 'Connected with carol@example.com successfully!'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not found', 404);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: CaptureScanScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('manual_entry_button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('manual_email_field')), 'carol@example.com');
    await tester.enterText(find.byKey(const Key('manual_passkey_field')), 'mlnokamc');

    await tester.tap(find.byKey(const Key('manual_submit_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(apiCalled, isTrue);
    expect(find.text('Captured!'), findsOneWidget);
  });

  testWidgets('QR capture sends POST /api/connect/qr with qr_data', (tester) async {
    bool qrApiCalled = false;

    HttpHelper.client = MockClient((request) async {
      if (request.url.path == '/api/connect/qr' && request.method == 'POST') {
        qrApiCalled = true;
        final body = jsonDecode(request.body);
        expect(body['qr_data'], equals('PKMN-SECRET-QR-123'));
        expect(request.headers['Authorization'], equals('Bearer dummy_token'));

        return http.Response(
          jsonEncode({'message': 'Trainer connection captured successfully!'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not found', 404);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: CaptureScanScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Simulate paste / capture
    mockClipboardText = 'PKMN-SECRET-QR-123';
    await tester.tap(find.byKey(const Key('paste_capture_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(qrApiCalled, isTrue);
    expect(find.text('Captured!'), findsOneWidget);
  });

  testWidgets('Pasting from clipboard handles empty clipboard gracefully', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaptureScanScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Clear clipboard
    mockClipboardText = '';

    await tester.tap(find.byKey(const Key('paste_capture_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Clipboard is empty or has no text'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Tapping back button in AppBar navigates back', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CaptureScanScreen()),
              ),
              child: const Text('Open Scanner'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Scanner'));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureScanScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureScanScreen), findsNothing);
  });
}
