// ignore_for_file: public_member_api_docs

import 'package:dart_frog/dart_frog.dart';

class TextlyResponse {
  TextlyResponse._();
  static Response success({
    required String? uuid,
    required String? message,
    required Object? data,
    Map<String, Object> headers = const <String, Object>{},
  }) {
    return Response.json(
      body: {
        'uuid': uuid,
        'status': 'Success',
        'message': message,
        if (data != null) 'data': data,
      },
      headers: headers,
    );
  }

  static Response error({
    required String? uuid,
    required int errorCode,
    required String message,
    required String error,
    required int statusCode,
    String? description,
    Map<String, Object> headers = const <String, Object>{},
  }) {
    return Response.json(
      statusCode: statusCode,
      body: {
        'uuid': uuid,
        'status': 'Error',
        'error_code': errorCode,
        'message': message,
        'description': description,
        'error': error,
      },
      headers: headers,
    );
  }

  static Response notAuth({
    required String message,
    String? description,
    Map<String, Object> headers = const <String, Object>{},
  }) {
    return Response.json(
      statusCode: 401,
      body: {
        'status': 'Not authorized',
        'message': message,
        'description': description,
      },
      headers: headers,
    );
  }

  static Response needMoreData({
    required String? uuid,
    required TypeNeedData type,
    required String nameData,
    String? description,
    Map<String, Object> headers = const <String, Object>{},
  }) {
    return Response.json(
      statusCode: 401,
      body: {
        'uuid': uuid,
        'status': 'Need more data',
        'message':
            '''Need "$nameData" in ${type == TypeNeedData.body ? 'body' : type == TypeNeedData.param ? 'query params' : 'autorization header'}''',
        'description': description,
      },
      headers: headers,
    );
  }
}

enum TypeNeedData {
  param,
  auth,
  body,
}
