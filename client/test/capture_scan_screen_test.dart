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
    HttpHelper.baseUrl = 'https://gdg-dex.onrender.com';
    HttpHelper.token = 'dummy_token';
    HttpHelper.enableLogging = false;
  });

  testWidgets('CaptureScanScreen renders title, laser viewfinder, and manual entry button without clipboard/test buttons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaptureScanScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Scan QR to Capture'), findsOneWidget);
    expect(find.byKey(const Key('manual_entry_button')), findsOneWidget);
    expect(find.text('Enter Details Manually'), findsOneWidget);
    expect(find.byKey(const Key('paste_capture_button')), findsNothing);
    expect(find.byKey(const Key('simulate_capture_button')), findsNothing);
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
