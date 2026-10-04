import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:client/screens/capture_scan_screen.dart';
import 'package:client/screens/home_screen.dart';
import 'package:client/screens/leaderboard_screen.dart';
import 'package:client/screens/login_screen.dart';
import 'package:client/services/http_helper.dart';
import 'package:client/widgets/pokeball_icon.dart';

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
    HttpHelper.token = 'PKMN-7749-X9';
    HttpHelper.enableLogging = false;
  });

  testWidgets(
    'HomeScreen renders GDGDEX header, trainer card, dynamic token, and QR code',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(
            email: 'ash@kanto.org',
            regNo: 'STU-08429',
            token: 'PKMN-7749-X9',
          ),
        ),
      );

      // Header
      expect(find.text('GDGDEX'), findsOneWidget);

      // Trainer Profile
      expect(find.text('Trainer Ash'), findsOneWidget);
      expect(find.text('Kanto Club'), findsOneWidget);
      expect(find.text('ID: STU-08429'), findsOneWidget);

      // Token Section
      expect(find.text('TRAINER TOKEN'), findsOneWidget);
      expect(find.text('PKMN-7749-X9'), findsOneWidget);

      // QR Code with token inside
      expect(find.byType(QrImageView), findsOneWidget);

      // Cards
      expect(find.text('MEMBER SCANNER'), findsOneWidget);
      expect(find.text('Capture'), findsOneWidget);
      expect(find.text('Launch Scanner'), findsOneWidget);
      expect(find.byType(PokeballIcon), findsOneWidget);

      expect(find.text('CLUB STANDINGS'), findsOneWidget);
      expect(find.text('View\nLeaderboard'), findsOneWidget);
      expect(find.text('Open Standings'), findsOneWidget);
    },
  );

  testWidgets('HomeScreen displays dynamic role passed from API', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          email: 'sagnik@campus.edu',
          regNo: '23BCE1234',
          role: 'Lead Organizer',
        ),
      ),
    );

    expect(find.text('Lead Organizer'), findsOneWidget);
    expect(find.text('Trainer Sagnik'), findsOneWidget);
    expect(find.text('ID: 23BCE1234'), findsOneWidget);
  });

  testWidgets(
    'Tapping Capture card opens the QR scanning screen (CaptureScanScreen)',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      await tester.tap(find.byKey(const Key('capture_card_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CaptureScanScreen), findsOneWidget);
      expect(find.text('Scan QR to Capture'), findsOneWidget);
    },
  );

  testWidgets('Tapping View Leaderboard card opens LeaderboardScreen', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    final leaderboardBtn = find.byKey(const Key('leaderboard_card_button'));
    await tester.ensureVisible(leaderboardBtn);
    await tester.pumpAndSettle();

    await tester.tap(leaderboardBtn);
    await tester.pumpAndSettle();

    expect(find.byType(LeaderboardScreen), findsOneWidget);
    expect(find.text('Club Leaderboard'), findsOneWidget);
  });

  testWidgets(
    'Tapping Back/Logout button clears token and redirects to LoginScreen',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(HttpHelper.token, isNotNull);

      await tester.tap(find.byTooltip('Logout'));
      await tester.pumpAndSettle();

      expect(HttpHelper.token, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets('Tapping token copies it to clipboard and shows feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen(token: 'TEST-TOKEN-42')),
    );

    await tester.tap(find.text('TEST-TOKEN-42'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboardData?.text, equals('TEST-TOKEN-42'));
    expect(find.text('Trainer token copied to clipboard!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets(
    'Tapping trainer container opens modal with full unclipped token and large QR code',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(
            name: 'Bob Iyer',
            role: 'Tech Lead',
            regNo: '23BCE0002',
            token: 'FULL-UNCLIPPED-TRAINER-TOKEN-VALUE-12345',
          ),
        ),
      );

      // Tap on the trainer card
      await tester.tap(find.byKey(const Key('trainer_token_card')));
      await tester.pumpAndSettle();

      // Modal elements should be visible
      expect(find.text('FULL TRAINER TOKEN'), findsOneWidget);
      expect(find.text('Copy Full Token'), findsOneWidget);
      expect(
        find.text('FULL-UNCLIPPED-TRAINER-TOKEN-VALUE-12345'),
        findsNWidgets(2),
      );
      expect(find.text('Tech Lead'), findsNWidgets(2));
      expect(find.text('ID: 23BCE0002'), findsNWidgets(2));
    },
  );
}
