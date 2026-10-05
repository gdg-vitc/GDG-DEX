import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:client/screens/capture_scan_screen.dart';
import 'package:client/screens/leaderboard_screen.dart';
import 'package:client/services/http_helper.dart';

void main() {
  setUp(() {
    HttpHelper.baseUrl = 'https://gdg-dex.onrender.com';
    HttpHelper.token = 'MOCK-TOKEN-XYZ';
    HttpHelper.enableLogging = false;
  });

  testWidgets(
    'LeaderboardScreen fetches /api/leaderboard and renders Top 3 podium, YOU card and strictly API feed',
    (tester) async {
      HttpHelper.client = MockClient((request) async {
        if (request.url.path == '/api/leaderboard') {
          return http.Response(
            jsonEncode({
              'leaderboard': [
                {
                  'name': 'Sagnik Sen',
                  'role': 'General Secretary',
                  'connections': 2,
                },
                {
                  'name': 'Alice Rao',
                  'role': 'Member',
                  'connections': 1,
                },
                {
                  'name': 'Bob Iyer',
                  'role': 'Tech Lead',
                  'connections': 1,
                },
                {
                  'name': 'Charlie Day',
                  'role': 'Developer',
                  'connections': 1,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: LeaderboardScreen(
            currentUserName: 'Bob Iyer',
            currentUserRole: 'Tech Lead',
            currentUserRegNo: '23BCE0002',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top Header
      expect(find.text('POKÉDEX CLUB'), findsOneWidget);
      expect(find.text('Leaderboard'), findsOneWidget);

      // Top 3 Podium
      expect(find.text('Sagnik Sen'), findsOneWidget);
      expect(find.text('General Secretary'), findsOneWidget);
      expect(find.text('LEADER'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);

      expect(find.text('Alice Rao'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);

      expect(find.text('#3'), findsNWidgets(2)); // On Podium and on YOU avatar

      // User's "YOU" card for Bob Iyer (who is in the API)
      expect(find.text('YOU'), findsOneWidget);
      expect(find.text('Bob Iyer'), findsNWidgets(2)); // On Podium + In YOU card
      expect(find.text('Rank #3'), findsOneWidget);
      expect(find.text('Dex Encounters'), findsOneWidget);
      expect(find.text('Next Milestone: Top 2'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);

      // Club Encounters Feed: Charlie Day (Rank #4) from API
      expect(find.text('Club Encounters Feed'), findsOneWidget);
      expect(find.text('Charlie Day'), findsOneWidget);
      expect(find.text('Developer'), findsOneWidget);
      expect(find.text('#4'), findsOneWidget);
    },
  );

  testWidgets(
    'Unranked user whose name is not in API receives make a connection first prompt',
    (tester) async {
      HttpHelper.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'leaderboard': [
              {
                'name': 'Sagnik Sen',
                'role': 'General Secretary',
                'connections': 2,
              },
              {
                'name': 'Alice Rao',
                'role': 'Member',
                'connections': 1,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: LeaderboardScreen(
            currentUserName: 'Trainer Ash',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Prompt to make a connection first
      expect(
        find.text('Make a connection first to get ranked'),
        findsOneWidget,
      );
      expect(find.text('Make a connection first'), findsOneWidget);
      expect(find.text('to appear on the leaderboard'), findsOneWidget);
      expect(find.text('Unranked'), findsOneWidget);
      expect(find.text('-'), findsNWidgets(2)); // YOU avatar (-) and Podium slot 3 (-)

      // Connect button
      final connectBtn = find.text('Connect');
      expect(connectBtn, findsOneWidget);

      await tester.tap(connectBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CaptureScanScreen), findsOneWidget);
    },
  );

  testWidgets('Leaderboard shows error banner on 500 failure with retry', (
    tester,
  ) async {
    HttpHelper.client = MockClient((request) async {
      return http.Response('Server Error', 500);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LeaderboardScreen(
          currentUserName: 'Trainer Ash',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.text('Could not refresh leaderboard. Check connection.'),
      findsOneWidget,
    );
  });
}
