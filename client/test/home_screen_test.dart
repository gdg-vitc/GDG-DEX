import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:client/screens/capture_scan_screen.dart';
import 'package:client/screens/home_screen.dart';
import 'package:client/screens/leaderboard_screen.dart';
import 'package:client/screens/login_screen.dart';
import 'package:client/services/http_helper.dart';
import 'package:client/widgets/gdg_logo.dart';
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
    HttpHelper.baseUrl = 'https://gdg-dex.onrender.com';
    HttpHelper.token = 'PKMN-7749-X9';
    HttpHelper.passkey = 'lgpvdlen';
    HttpHelper.enableLogging = false;
  });

  testWidgets(
    'HomeScreen renders GDGDEX header, trainer card, dynamic passkey, and QR code',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(
            email: 'ash@kanto.org',
            regNo: 'STU-08429',
            token: 'PKMN-7749-X9',
            passkey: 'lgpvdlen',
          ),
        ),
      );

      // Header: GDG Logo, title, and logout button
      expect(find.byType(GdgLogo), findsOneWidget);
      expect(find.text('GDGDEX'), findsOneWidget);
      expect(find.byTooltip('Logout'), findsOneWidget);

      // Trainer Profile
      expect(find.text('Trainer Ash'), findsOneWidget);
      expect(find.text('Kanto Club'), findsOneWidget);
      expect(find.text('ID: STU-08429'), findsOneWidget);

      // Passkey Section (only passkey is visible to user)
      expect(find.text('TRAINER PASSKEY'), findsOneWidget);
      expect(find.text('lgpvdlen'), findsOneWidget);

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
    expect(find.text('Leaderboard'), findsOneWidget);
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

  testWidgets('Tapping passkey copies it to clipboard and shows feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen(passkey: 'lgpvdlen')),
    );

    await tester.tap(find.text('lgpvdlen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboardData?.text, equals('lgpvdlen'));
    expect(find.text('Trainer passkey copied to clipboard!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets(
    'Tapping trainer container opens modal with full passkey and large QR code',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(
            name: 'Bob Iyer',
            role: 'Tech Lead',
            regNo: '23BCE0002',
            token: 'MODAL-QR-TOKEN-VALUE',
            passkey: 'lgpvdlen',
          ),
        ),
      );

      // Tap on the trainer card
      await tester.tap(find.byKey(const Key('trainer_token_card')));
      await tester.pumpAndSettle();

      // Modal elements should be visible - only passkey is visible to user
      expect(find.text('FULL TRAINER PASSKEY'), findsOneWidget);
      expect(find.text('Copy Passkey'), findsOneWidget);
      expect(
        find.text('lgpvdlen'),
        findsNWidgets(2),
      );
      expect(find.text('MODAL-QR-TOKEN-VALUE'), findsNothing);
      expect(find.text('Tech Lead'), findsNWidgets(2));
      expect(find.text('ID: 23BCE0002'), findsNWidgets(2));

      // QR Code encodes token and is rendered in both card and modal
      expect(find.byType(QrImageView), findsNWidgets(2));
    },
  );
}
