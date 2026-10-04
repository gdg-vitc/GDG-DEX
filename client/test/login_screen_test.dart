import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:client/screens/home_screen.dart';
import 'package:client/screens/login_screen.dart';
import 'package:client/services/http_helper.dart';
import 'package:client/widgets/gdg_logo.dart';

void main() {
  setUp(() {
    HttpHelper.baseUrl = 'https://sponge-romantic-pangolin.ngrok-free.app';
    HttpHelper.clearToken();
    HttpHelper.enableLogging = false;
  });

  testWidgets('LoginScreen renders fields, labels, checkbox, and button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('GDG-DEX'), findsOneWidget);
    expect(find.byType(GdgLogo), findsOneWidget);
    expect(find.text('Campus Email'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Student ID'), findsOneWidget);
    expect(find.text('Guild Card'), findsOneWidget);
    expect(find.text('Remember this device'), findsOneWidget);
    expect(find.text('Need help?'), findsOneWidget);
    expect(find.text('Enter Club Pokédex'), findsOneWidget);
  });

  testWidgets('LoginScreen shows validation error when fields are empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.tap(find.text('Enter Club Pokédex'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your campus email'), findsAtLeastNWidgets(1));
  });

  testWidgets('LoginScreen sends POST /api/login with email and reg_no', (tester) async {
    bool apiCalled = false;

    HttpHelper.client = MockClient((request) async {
      if (request.url.path == '/api/login' && request.method == 'POST') {
        apiCalled = true;
        final body = jsonDecode(request.body);
        expect(body['email'], equals('alex@campus.edu'));
        expect(body['reg_no'], equals('STU-08429'));

        return http.Response(
          jsonEncode({'token': 'jwt_secret_token_123', 'message': 'Welcome!'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not found', 404);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'alex@campus.edu');
    await tester.enterText(find.byType(TextField).at(1), 'STU-08429');

    // Tap submit button
    await tester.tap(find.text('Enter Club Pokédex'));
    await tester.pumpAndSettle();

    expect(apiCalled, isTrue);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(HttpHelper.token, equals('jwt_secret_token_123'));
  });

  testWidgets('LoginScreen displays server error message on 422/400 failure', (tester) async {
    HttpHelper.client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'detail': [
            {'msg': 'value is not a valid email address'}
          ]
        }),
        422,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'invalid@campus.edu');
    await tester.enterText(find.byType(TextField).at(1), 'STU-08429');

    await tester.tap(find.text('Enter Club Pokédex'));
    await tester.pumpAndSettle();

    expect(find.text('value is not a valid email address'), findsAtLeastNWidgets(1));
  });

  testWidgets('LoginScreen extracts role from login API response and passes it to HomeScreen', (tester) async {
    HttpHelper.client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'token': 'jwt_secret_token_123',
          'role': 'General Secretary',
          'message': 'Welcome!'
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'alex@campus.edu');
    await tester.enterText(find.byType(TextField).at(1), 'STU-08429');

    await tester.tap(find.text('Enter Club Pokédex'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(HttpHelper.role, equals('General Secretary'));
    expect(find.text('General Secretary'), findsOneWidget);
  });

  testWidgets('LoginScreen decodes role from JWT when not in response body', (tester) async {
    final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}')).replaceAll('=', '');
    final payload = base64Url.encode(utf8.encode('{"sub":"alex","role":"Core Member"}')).replaceAll('=', '');
    final jwt = '$header.$payload.fake_signature';

    HttpHelper.client = MockClient((request) async {
      return http.Response(
        jsonEncode({'token': jwt, 'message': 'Welcome!'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'alex@campus.edu');
    await tester.enterText(find.byType(TextField).at(1), 'STU-08429');

    await tester.tap(find.text('Enter Club Pokédex'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(HttpHelper.role, equals('Core Member'));
    expect(find.text('Core Member'), findsOneWidget);
  });
}
