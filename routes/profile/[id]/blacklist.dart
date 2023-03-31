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
  final userId = context.read<UserId>().userId ?? -1;
  final params = context.request.uri.queryParameters;

  final limit = int.tryParse(params['limit'] ?? '');
  final offset = int.tryParse(params['offset'] ?? '');

  final profileRepository = context.read<ProfileRepository>();

  final uuid = context.read<String>();
  final logger = context.read<Logger>();

  if (int.tryParse(id) != userId) {
    return TextlyResponse.notAuth(message: 'You dont have access');
  }

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
    logger.d('$uuid: Searching blacklist, userId: $userId');
    final profiles = await profileRepository.readBacklist(
      userId: userId,
      offset: offset,
      limit: limit,
    );

    logger.d('$uuid: Successfully founded blacklist, userId: $userId');
    return TextlyResponse.success(
      uuid: uuid,
      message: 'Blacklist has been founded successfully, userId: $userId',
      data: {
        'profiles': profiles.map((e) => e.toJson()).toList(),
      },
    );
  } catch (e) {
    logger.e('$uuid: Error founding blacklist, userId: $userId, error: $e');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: '',
      error: '$e',
    );
  }
}




/// readBacklist
