import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:client/services/http_helper.dart';

void main() {
  setUp(() {
    HttpHelper.baseUrl = 'https://api.example.com';
    HttpHelper.clearToken();
    HttpHelper.enableLogging = false;
  });

  test('httpGet successfully fetches and decodes JSON', () async {
    HttpHelper.client = MockClient((request) async {
      expect(request.method, equals('GET'));
      expect(request.url.path, equals('/users'));
      expect(request.url.queryParameters['page'], equals('1'));

      return http.Response(
        jsonEncode([
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final data = await httpGet<List<dynamic>>('/users', queryParams: {'page': 1});
    expect(data.length, equals(2));
    expect(data[0]['name'], equals('Alice'));
  });

  test('httpPost automatically encodes body and attaches token', () async {
    HttpHelper.setToken('test-secret-token');

    HttpHelper.client = MockClient((request) async {
      expect(request.method, equals('POST'));
      expect(request.headers['Authorization'], equals('Bearer test-secret-token'));
      expect(request.headers['Content-Type'], equals('application/json'));

      final body = jsonDecode(request.body);
      expect(body['title'], equals('New Post'));

      return http.Response(
        jsonEncode({'id': 101, 'title': 'New Post'}),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    final res = await httpPost<Map<String, dynamic>>(
      '/posts',
      body: {'title': 'New Post'},
    );

    expect(res['id'], equals(101));
  });

  test('ApiException is thrown on 404 response with server message', () async {
    HttpHelper.client = MockClient((request) async {
      return http.Response(
        jsonEncode({'detail': 'User not found'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    });

    expect(
      () => httpGet('/users/999'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', equals(404))
          .having((e) => e.message, 'message', equals('User not found'))),
    );
  });

  test('ApiException extracts message from nested detail map (FastAPI format)', () async {
    HttpHelper.client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'detail': {'message': 'Invalid email or registration number'}
        }),
        404,
        headers: {'content-type': 'application/json'},
      );
    });

    expect(
      () => httpPost('/api/login', body: {'email': 'bad@example.com'}),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', equals(404))
          .having(
            (e) => e.message,
            'message',
            equals('Invalid email or registration number'),
          )),
    );
  });
}
