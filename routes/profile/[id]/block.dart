import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:logger/logger.dart';
import 'package:postgres/postgres.dart';
import 'package:textly_core/textly_core.dart';
import 'package:textly_profiles/models/textly_response.dart';
import 'package:textly_profiles/models/user_id_model.dart';

FutureOr<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.post:
      return await _post(context, id);
    case HttpMethod.delete:
      return await _delete(context, id);
    case HttpMethod.get:
    case HttpMethod.put:
    case HttpMethod.head:
    case HttpMethod.options:
    case HttpMethod.patch:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

FutureOr<Response> _post(RequestContext context, String id) async {
  final reqUserId = context.read<UserId>().userId ?? -1;
  final userId = int.tryParse(id) ?? -1;

  final profileRepository = context.read<ProfileRepository>();

  final uuid = context.read<String>();
  final logger = context.read<Logger>();

  if (reqUserId == userId) {
    logger.e('$uuid: Error block user $reqUserId to user $userId');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: 'You cant block yourself',
      error: 'You cant block yourself',
    );
  }

  try {
    logger.d('$uuid: We block user $reqUserId to user $userId');
    await profileRepository.unFollowProfile(
      userId: userId,
      reqUserId: reqUserId,
    );
  } catch (e) {
    logger.e('$uuid: Error block user $reqUserId to user $userId');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: '',
      error: '$e',
    );
  }
  try {
    logger.d('$uuid: We block user $reqUserId to user $userId');
    await profileRepository.blockProfile(
      userId: userId,
      reqUserId: reqUserId,
    );
    return TextlyResponse.success(
      uuid: uuid,
      message:
          '''$uuid: Profile has been blocked successfully, userId: $userId, reqUserId: $reqUserId''',
      data: null,
    );
  } on PostgreSQLException catch (e) {
    logger.e('$uuid: Error block user $reqUserId to user $userId');

    if (e.code == '23505' &&
        e.constraintName == 'requster_blocked_user_id_un') {
      return TextlyResponse.error(
        statusCode: 400,
        errorCode: 23505,
        uuid: uuid,
        message: 'Current user already blocked',
        error: '$e',
      );
    }
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: 'PostgreSQLException',
      error: '$e',
    );
  } catch (e) {
    logger.e('$uuid: Error block user $reqUserId to user $userId');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: '',
      error: '$e',
    );
  }
}

FutureOr<Response> _delete(RequestContext context, String id) async {
  final reqUserId = context.read<UserId>().userId ?? -1;
  final userId = int.tryParse(id) ?? -1;

  final profileRepository = context.read<ProfileRepository>();

  final uuid = context.read<String>();
  final logger = context.read<Logger>();

  if (reqUserId == userId) {
    logger.e('$uuid: Error unblock user $reqUserId to user $userId');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: 'You cant unblock yourself',
      error: 'You cant unblock yourself',
    );
  }
  try {
    logger.d('$uuid: We unblock user $reqUserId to user $userId');
    await profileRepository.unBlockProfile(
      userId: userId,
      reqUserId: reqUserId,
    );
    return TextlyResponse.success(
      uuid: uuid,
      message:
          '''$uuid: Profile has been unblock successfully, userId: $userId, reqUserId: $reqUserId''',
      data: null,
    );
  } catch (e) {
    logger.e('$uuid: Error unblock user $reqUserId to user $userId');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: '',
      error: '$e',
    );
  }
}



/// block profile
/// unBlock profile
