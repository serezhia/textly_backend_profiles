import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:logger/logger.dart';
import 'package:textly_core/textly_core.dart';
import 'package:textly_profiles/models/textly_response.dart';
import 'package:textly_profiles/models/user_id_model.dart';

FutureOr<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return await _get(context, id);
    case HttpMethod.post:
    case HttpMethod.put:
    case HttpMethod.delete:
    case HttpMethod.head:
    case HttpMethod.options:
    case HttpMethod.patch:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

FutureOr<Response> _get(RequestContext context, String id) async {
  final reqUserId = context.read<UserId>().userId;
  final userId = int.tryParse(id) ?? -1;

  final profileRepository = context.read<ProfileRepository>();

  final uuid = context.read<String>();
  final logger = context.read<Logger>();
  try {
    logger.d('$uuid: Searching profile, userId: $userId');
    final profile = await profileRepository.readProfile(
      userId: userId,
      reqUserId: reqUserId,
    );
    logger.d('$uuid: Profile not found, userId: $userId');
    if (profile == null) {
      return TextlyResponse.error(
        statusCode: 500,
        errorCode: 23000,
        uuid: uuid,
        message: 'Profile not found',
        error: 'Profile is null',
      );
    }
    if (profile.isUnavailable ?? false) {
      logger.e('$uuid: Error current profile unavailable, userId: $userId');
      return TextlyResponse.error(
        statusCode: 500,
        errorCode: 0,
        uuid: uuid,
        message: 'Current profile unavailable',
        error: 'Current profile unavailable',
      );
    }
    logger.d('$uuid: Successfully founded profile, userId: $userId');
    return TextlyResponse.success(
      uuid: uuid,
      message: 'Profile has been founded successfully, userId: $userId',
      data: {
        'profile': profile.toJson(),
      },
    );
  } catch (e) {
    logger.e('$uuid: Error founding profile, userId: $userId, error: $e');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: '',
      error: '$e',
    );
  }
}


/// Read Profile
