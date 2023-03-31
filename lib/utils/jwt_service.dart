// ignore_for_file: public_member_api_docs

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:textly_profiles/utils/env_utils.dart';

abstract class JwtService {
  Future<String> generateAccessToken({required int userId});
  Future<String> generateRefreshToken({required int userId});
  Future<bool> verifyToken(
    RequestContext context, {
    bool isRefreshToken,
  });

  Future<JWT?> getToken(
    RequestContext context, {
    bool isRefreshToken = false,
  });
}

class JwtServiceImpl extends JwtService {
  @override
  Future<String> generateAccessToken({required int userId}) async {
    final jwt = JWT(
      {
        'iat': DateTime.now(),
      },
      issuer: 'textly_auth',
      subject: '$userId',
    );

    return jwt.sign(
      SecretKey(secretKey()),
      expiresIn: const Duration(minutes: 15),
    );
  }

  @override
  Future<String> generateRefreshToken({required int userId}) async {
    final jwt = JWT(
      {
        'iat': DateTime.now(),
      },
      issuer: 'textly_auth_refresh',
      subject: '$userId',
    );

    return jwt.sign(
      SecretKey(secretKey()),
      expiresIn: const Duration(days: 30),
    );
  }

  @override
  Future<bool> verifyToken(
    RequestContext context, {
    bool isRefreshToken = false,
  }) async {
    try {
      final headers = context.request.headers;
      final token = await _validateHeadersAndGetToken(headers);
      if (token != null) {
        JWT.verify(
          token,
          SecretKey(secretKey()),
          issuer: isRefreshToken ? 'textly_auth_refresh' : 'textly_auth',
        );

        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<String?> _validateHeadersAndGetToken(
    Map<String, dynamic> headers,
  ) async {
    String? token;
    if (headers.containsKey('authorization')) {
      final header = headers['authorization'].toString().split(' ');
      if (header[0].contains('Bearer')) {
        token = header[1];
      }
    }
    return token;
  }

  @override
  Future<JWT?> getToken(
    RequestContext context, {
    bool isRefreshToken = false,
  }) async {
    final headers = context.request.headers;
    final token = await _validateHeadersAndGetToken(headers);
    try {
      if (token != null) {
        return JWT.verify(
          token,
          SecretKey(secretKey()),
          issuer: isRefreshToken ? 'textly_auth_refresh' : 'textly_auth',
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
