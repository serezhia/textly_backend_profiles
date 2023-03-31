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

  final params = context.request.uri.queryParameters;
  final limit = int.tryParse(params['limit'] ?? '');
  final offset = int.tryParse(params['offset'] ?? '');

  final profileRepository = context.read<ProfileRepository>();

  final uuid = context.read<String>();
  final logger = context.read<Logger>();

  if (limit == null) {
    return TextlyResponse.needMoreData(
      uuid: uuid,
      type: TypeNeedData.param,
      nameData: 'limit',
    );
  }

  if (offset == null) {
    return TextlyResponse.needMoreData(
      uuid: uuid,
      type: TypeNeedData.param,
      nameData: 'offset',
    );
  }

  try {
    logger.d(
      '$uuid: Searching followers, userId: $userId, reqUserId: $reqUserId',
    );
    final profiles = await profileRepository.readFollowers(
      userId: userId,
      reqUserId: reqUserId,
      offset: offset,
      limit: limit,
    );

    logger.d('$uuid: Successfully founded followers, userId: $userId');
    return TextlyResponse.success(
      uuid: uuid,
      message:
          '''Followers has been founded successfully, userId: $userId, reqUserId: $reqUserId''',
      data: {
        'profiles': profiles.map((e) => e.toJson()).toList(),
      },
    );
  } catch (e) {
    logger.e(
      '''$uuid: Error founding followers, userId: $userId, reqUserId: $reqUserId , error: $e''',
    );
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: '',
      error: '$e',
    );
  }
}

///Read followers
