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
    logger.e('$uuid: Error follow user $reqUserId to user $userId');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: 'You cant follow yourself',
      error: 'You cant follow yourself',
    );
  }

  try {
    logger.d('$uuid: We subscribe user $reqUserId to user $userId');
    await profileRepository.followProfile(
      userId: userId,
      reqUserId: reqUserId,
    );
    return TextlyResponse.success(
      uuid: uuid,
      message:
          '''$uuid: Profile has been followed successfully, userId: $userId, reqUserId: $reqUserId''',
      data: null,
    );
  } on PostgreSQLException catch (e) {
    logger.e('$uuid: Error subscribe user $reqUserId to user $userId');

    if (e.code == '23505' && e.constraintName == 'un_reading_publishing') {
      logger.e('$uuid: Error Already follow this user');
      return TextlyResponse.error(
        statusCode: 400,
        errorCode: 23505,
        uuid: uuid,
        message: 'Already follow this user',
        error: '$e',
      );
    }

    if (e.code == '23503' && e.constraintName == 'publishing_user_id_fk' ||
        e.code == '42P01') {
      logger.e('$uuid: Error Not found user');
      return TextlyResponse.error(
        statusCode: 400,
        errorCode: 23503,
        uuid: uuid,
        message: 'Not found user',
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
    logger.e('$uuid: Error subscribe user $reqUserId to user $userId');
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
    logger.e('$uuid: Error unfollow user $reqUserId to user $userId');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: 'You cant unfollow yourself',
      error: 'You cant unfollow yourself',
    );
  }

  try {
    logger.d('$uuid: We unsubscribe user $reqUserId to user $userId');
    await profileRepository.unFollowProfile(
      userId: userId,
      reqUserId: reqUserId,
    );
    return TextlyResponse.success(
      uuid: uuid,
      message:
          '''$uuid: Profile has been unfollowed successfully, userId: $userId, reqUserId: $reqUserId''',
      data: null,
    );
  } on PostgreSQLException catch (e) {
    if (e.code == '23503' && e.constraintName == 'publishing_user_id_fk') {
      logger.e('$uuid: Error Not found user');
      return TextlyResponse.error(
        statusCode: 400,
        errorCode: 23503,
        uuid: uuid,
        message: 'Not found user',
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
    logger.e('$uuid: Error unsubscribe user $reqUserId to user $userId');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: '',
      error: '$e',
    );
  }
}

///Follow Profile
///UnFollow Profile
