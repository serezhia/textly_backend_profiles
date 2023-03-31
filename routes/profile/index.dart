import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:logger/logger.dart';
import 'package:postgres/postgres.dart';
import 'package:textly_core/textly_core.dart';
import 'package:textly_profiles/models/textly_response.dart';
import 'package:textly_profiles/models/user_id_model.dart';
import 'package:textly_profiles/utils/string_extension.dart';

FutureOr<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.post:
      return await _post(context);
    case HttpMethod.put:
      return await _put(context);
    case HttpMethod.delete:
      return await _delete(context);
    case HttpMethod.head:
    case HttpMethod.get:
    case HttpMethod.options:
    case HttpMethod.patch:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

//Create Profile

FutureOr<Response> _post(RequestContext context) async {
  final profileRepository = context.read<ProfileRepository>();
  final body = jsonDecode(await context.request.body()) as Map<String, Object?>;
  final userId = context.read<UserId>().userId ?? -1;
  final username = body['username'] as String?;
  final profileName = body['profile_name'] as String?;
  var avatar = body['avatar'] as String?;
  final backgroundColor = body['background_color'] as String?;
  final description = body['description'] as String?;

  final uuid = context.read<String>();
  final logger = context.read<Logger>();

  if (username == null) {
    return TextlyResponse.needMoreData(
      uuid: uuid,
      type: TypeNeedData.body,
      nameData: 'username',
    );
  }
  if (profileName == null) {
    return TextlyResponse.needMoreData(
      uuid: uuid,
      type: TypeNeedData.body,
      nameData: 'profile_name',
    );
  }
  if (avatar == null) {
    return TextlyResponse.needMoreData(
      uuid: uuid,
      type: TypeNeedData.body,
      nameData: 'avatar',
    );
  }
  if (backgroundColor == null) {
    return TextlyResponse.needMoreData(
      uuid: uuid,
      type: TypeNeedData.body,
      nameData: 'background_color',
    );
  }
  if (description == null) {
    return TextlyResponse.needMoreData(
      uuid: uuid,
      type: TypeNeedData.body,
      nameData: 'description',
    );
  }

  if (profileName.length > 30) {
    return TextlyResponse.error(
      uuid: uuid,
      errorCode: 0,
      message: 'Incorrect profile_name',
      description:
          '''profile_name must have a length less than or equal to 30''',
      error: 'Incorrect profile_name',
      statusCode: 400,
    );
  }

  if (username[0].isFirstNumber()) {
    return TextlyResponse.error(
      uuid: uuid,
      errorCode: 0,
      message: 'Incorrect username',
      description: '''username must not start with a digit''',
      error: 'Incorrect username',
      statusCode: 400,
    );
  }
  if (username.length > 16) {
    return TextlyResponse.error(
      uuid: uuid,
      errorCode: 0,
      message: 'Incorrect username',
      description: '''username must have a length less than or equal to 16''',
      error: 'Incorrect username',
      statusCode: 400,
    );
  }

  if (description.length > 255) {
    return TextlyResponse.error(
      uuid: uuid,
      errorCode: 0,
      message: 'Incorrect description',
      description:
          '''Description must have a length less than or equal to 255''',
      error: 'Incorrect description',
      statusCode: 400,
    );
  }

  final emojiParser = EmojiParser();
  if (emojiParser.hasEmoji(avatar)) {
    avatar = emojiParser.parseEmojis(avatar).first;
  }

  if (!emojiParser.hasEmoji(avatar) && avatar.length > 3) {
    return TextlyResponse.error(
      uuid: uuid,
      errorCode: 0,
      message: 'Incorrect avatar',
      description:
          '''The avatar must consist of one emoji or have a length less than or equal to 3''',
      error: 'Incorrect avatar',
      statusCode: 400,
    );
  }

  try {
    logger.d('$uuid: Creating account, userId: $userId');
    final profile = await profileRepository.createProfile(
      profile: Profile(
        userId: userId,
        username: username,
        profileName: profileName,
        avatar: avatar,
        backgroundColor: backgroundColor,
        description: description,
        createdAt: DateTime.now(),
        followers: 0,
        following: 0,
        isPremium: false,
        isDelete: false,
        isFollow: false,
      ),
    );
    logger.d('$uuid: Successfully created profile, userId: $userId');
    return TextlyResponse.success(
      uuid: uuid,
      message: 'Profile has been created successfully, userId: $userId',
      data: {
        'profile': profile.toJson(),
      },
    );
  } on PostgreSQLException catch (e) {
    logger.e('$uuid: Error creating profile, userId: $userId, error: $e');
    if (e.code == '23505' && e.constraintName == 'profiles_pkey') {
      return TextlyResponse.error(
        statusCode: 500,
        errorCode: 23505,
        uuid: uuid,
        message: 'This user already has a profile',
        error: '$e',
      );
    }

    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 23000,
      uuid: uuid,
      message: 'PostgreSQLException',
      error: '$e',
    );
  } catch (e) {
    logger.e('$uuid: Error creating profile, userId: $userId, error: $e');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: '',
      error: '$e',
    );
  }
}

/// Delete Profile
FutureOr<Response> _delete(RequestContext context) async {
  final profileRepository = context.read<ProfileRepository>();

  final logger = context.read<Logger>();
  final uuid = context.read<String>();

  final userId = context.read<UserId>().userId ?? -1;

  try {
    logger.d('$uuid: Deleting account, userId: $userId');
    await profileRepository.deleteProfile(userId: userId);
    logger.d('$uuid: Successfully deleted profile, userId: $userId');
    return TextlyResponse.success(
      uuid: uuid,
      message: 'Profile has been deleted successfully',
      data: userId,
    );
  } on PostgreSQLException catch (e) {
    logger.e('$uuid: Error deleted profile, userId: $userId, error: $e');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 23000,
      uuid: uuid,
      message: 'PostgreSQLException',
      error: '$e',
    );
  } catch (e) {
    logger.e('$uuid: Error deleted profile, userId: $userId, error: $e');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: '',
      error: '$e',
    );
  }
}

/// Update Profile
FutureOr<Response> _put(RequestContext context) async {
  final profileRepository = context.read<ProfileRepository>();
  final body = jsonDecode(await context.request.body()) as Map<String, Object?>;
  final userId = context.read<UserId>().userId ?? -1;

  final profileName = body['profile_name'] as String?;
  final avatar = body['avatar'] as String?;
  final backgroundColor = body['background_color'] as String?;
  final description = body['description'] as String?;

  final uuid = context.read<String>();
  final logger = context.read<Logger>();

  if (profileName == null) {
    return TextlyResponse.needMoreData(
      uuid: uuid,
      type: TypeNeedData.body,
      nameData: 'profile_name',
    );
  }
  if (avatar == null) {
    return TextlyResponse.needMoreData(
      uuid: uuid,
      type: TypeNeedData.body,
      nameData: 'avatar',
    );
  }
  if (backgroundColor == null) {
    return TextlyResponse.needMoreData(
      uuid: uuid,
      type: TypeNeedData.body,
      nameData: 'background_color',
    );
  }
  if (description == null) {
    return TextlyResponse.needMoreData(
      uuid: uuid,
      type: TypeNeedData.body,
      nameData: 'description',
    );
  }
  final Profile oldProfile;

  try {
    final oldProfileFromDb =
        await profileRepository.readProfile(userId: userId);

    if (oldProfileFromDb == null) {
      return TextlyResponse.error(
        statusCode: 500,
        errorCode: 23505,
        uuid: uuid,
        message: 'Profile not found',
        error: 'Profile is null',
      );
    } else {
      oldProfile = oldProfileFromDb;
    }
  } catch (e) {
    logger.e('$uuid: Error searching profile, userId: $userId, error: $e');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: '',
      error: '$e',
    );
  }

  try {
    logger.d('$uuid: Updating account, userId: $userId');
    final profile = await profileRepository.updateProfile(
      profile: oldProfile.copyWith(
        profileName: profileName,
        avatar: avatar,
        backgroundColor: backgroundColor,
        description: description,
      ),
    );
    logger.d('$uuid: Successfully updated profile, userId: $userId');
    return TextlyResponse.success(
      uuid: uuid,
      message: 'Profile has been updated successfully, userId: $userId',
      data: {
        'profile': profile.toJson(),
      },
    );
  } catch (e) {
    logger.e('$uuid: Error updating profile, userId: $userId, error: $e');
    return TextlyResponse.error(
      statusCode: 500,
      errorCode: 0,
      uuid: uuid,
      message: '',
      error: '$e',
    );
  }
}
