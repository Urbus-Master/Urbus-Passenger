import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:urbus/core/constants/api_constants.dart';
import 'package:urbus/core/providers/auth_provider.dart';
import 'package:urbus/core/services/auth_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio dio;
  late AuthNotifier authNotifier;
  late AuthService authService;

  setUp(() {
    dio = MockDio();
    // Never touched by these tests — Dio always throws before AuthService
    // reaches _authNotifier.login(), so a bare instance is safe here.
    authNotifier = AuthNotifier();
    authService = AuthService(dio: dio, authNotifier: authNotifier);
  });

  DioException unauthorized() {
    final requestOptions = RequestOptions(path: ApiConstants.session);
    return DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: requestOptions, statusCode: 401),
    );
  }

  test('login() sends Basic-Auth form-encoded POST to /session', () async {
    when(dio.post(
      any,
      data: anyNamed('data'),
      options: anyNamed('options'),
    )).thenThrow(unauthorized());

    await expectLater(
      authService.login(email: 'user@example.com', password: 'secret'),
      throwsA(isA<AuthException>()),
    );

    final captured = verify(dio.post(
      captureAny,
      data: captureAnyNamed('data'),
      options: captureAnyNamed('options'),
    )).captured;

    expect(captured[0], ApiConstants.session);
    expect(captured[1], contains('email=user%40example.com'));
    expect(captured[1], contains('password=secret'));

    final options = captured[2] as Options;
    expect(options.contentType, ApiConstants.contentTypeForm);
    expect(
      options.headers?[ApiConstants.authorizationHeader],
      'Basic ${base64Encode(utf8.encode('user@example.com:secret'))}',
    );
  });

  test(
      'admin@urbus.com is no longer bypassed — hits Traccar like any '
      'other email and surfaces a real auth failure', () async {
    when(dio.post(
      any,
      data: anyNamed('data'),
      options: anyNamed('options'),
    )).thenThrow(unauthorized());

    await expectLater(
      authService.login(email: 'admin@urbus.com', password: 'wrong'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.type,
          'type',
          AuthExceptionType.invalidCredentials,
        ),
      ),
    );

    verify(dio.post(
      any,
      data: anyNamed('data'),
      options: anyNamed('options'),
    )).called(1);
  });
}
