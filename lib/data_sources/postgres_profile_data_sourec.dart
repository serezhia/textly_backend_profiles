// ignore_for_file: public_member_api_docs

import 'package:postgres/postgres.dart';
import 'package:textly_core/textly_core.dart';

class PostgresProfileDataSource implements ProfileRepository {
  PostgresProfileDataSource(this.connection);

  final PostgreSQLConnection connection;

  @override
  Future<void> blockProfile({
    required int reqUserId,
    required int userId,
  }) async {
    await connection.mappedResultsQuery(
      '''
        INSERT INTO blacklist_user (requester_user_id, blocked_user_id, created_at)
        VALUES (@requester_user_id, @blocked_user_id, @created_at)
        RETURNING *
        ''',
      substitutionValues: {
        'requester_user_id': reqUserId,
        'blocked_user_id': userId,
        'created_at': DateTime.now(),
      },
    );
  }

  @override
  Future<Profile> createProfile({required Profile profile}) async {
    final response = await connection.mappedResultsQuery(
      '''
        INSERT INTO profiles (user_id, username, profile_name, description, avatar, background_color, is_premium, is_delete, created_at, followers, following)
        VALUES (@user_id, @username, @profile_name, @description, @avatar, @background_color, @is_premium, @is_delete, @created_at, 0, 0)
        RETURNING *
        ''',
      substitutionValues: profile.toJson(),
    );

    return Profile.fromPostgres(
      response.first['profiles'] ??
          Profile(
            userId: -1,
            username: 'error',
            profileName: 'error',
            avatar: 'e',
            backgroundColor: '00000000',
            isPremium: false,
            isDelete: false,
          ).toJson(),
    );
  }

  @override
  Future<void> deleteProfile({required int userId}) async {
    await connection.query(
      '''
        DELETE 
        FROM profiles 
        WHERE user_id = @user_id
        ''',
      substitutionValues: {
        'user_id': userId,
      },
    );
  }

  @override
  Future<void> followProfile({
    required int reqUserId,
    required int userId,
  }) async {
    final profile = await readProfile(userId: userId, reqUserId: reqUserId);
    if (profile == null) {
      throw Exception('Profile not found');
    }
    if (profile.isFollow ?? false) {
      throw Exception('You already followed');
    }
    await connection.transaction((tranc) async {
      await tranc.mappedResultsQuery(
        '''
        INSERT INTO user_relationships (publishing_user_id, reading_user_id, created_at)
        VALUES (@publishing_user_id, @reading_user_id, @created_at)
        RETURNING *
        ''',
        substitutionValues: {
          'reading_user_id': reqUserId,
          'publishing_user_id': userId,
          'created_at': DateTime.now(),
        },
      );
      await tranc.mappedResultsQuery(
        '''
        UPDATE profiles
        SET following = following + 1
        WHERE user_id = @req_user_id
        ''',
        substitutionValues: {
          'req_user_id': reqUserId,
        },
      );
      await tranc.mappedResultsQuery(
        '''
        UPDATE profiles
        SET followers = followers + 1
        WHERE user_id = @user_id
        ''',
        substitutionValues: {
          'user_id': userId,
        },
      );
    });
    return;
  }

  @override
  Future<List<Profile>> readBacklist({
    required int userId,
    required int offset,
    required int limit,
  }) async {
    final responseFromBlackList = await connection.mappedResultsQuery(
      '''
        SELECT blocked_user_id
        FROM blacklist_user 
        WHERE requester_user_id = @user_id
        OFFSET @offset
        LIMIT @limit
      ''',
      substitutionValues: {
        'user_id': userId,
        'limit': limit,
        'offset': offset,
      },
    );
    if (responseFromBlackList.isEmpty) {
      return [];
    }

    final blockedprofiles = <Profile>[];

    for (final userId in responseFromBlackList) {
      final profile = await readProfile(
        userId: userId['blacklist_user']!['blocked_user_id'] as int,
      );
      if (profile != null) {
        blockedprofiles.add(profile);
      }
    }
    return blockedprofiles;
  }

  @override
  Future<List<Profile>> readFollowers({
    required int userId,
    required int offset,
    required int limit,
    int? reqUserId,
  }) async {
    final profile = await readProfile(userId: userId);
    if (profile == null) {
      throw Exception('Profile not found');
    }
    final response = await connection.mappedResultsQuery(
      '''
        SELECT reading_user_id
        FROM  user_relationships 
        WHERE user_relationships.publishing_user_id = @user_id
        OFFSET @offset
        LIMIT @limit
        ''',
      substitutionValues: {
        'offset': offset,
        'limit': limit,
        'user_id': userId,
      },
    );
    if (response.isEmpty) {
      return [];
    }

    final followers = <Profile>[];

    for (final userId in response) {
      final profile = await readProfile(
        userId: userId['user_relationships']!['reading_user_id'] as int,
        reqUserId: reqUserId,
      );
      if (profile != null) {
        followers.add(profile);
      }
    }
    return followers;
  }

  @override
  Future<List<Profile>> readFollowing({
    required int userId,
    required int offset,
    required int limit,
    int? reqUserId,
  }) async {
    final profile = await readProfile(userId: userId);
    if (profile == null) {
      throw Exception('Profile not found');
    }
    final response = await connection.mappedResultsQuery(
      '''
        SELECT publishing_user_id
        FROM  user_relationships 
        WHERE user_relationships.reading_user_id = @user_id
        OFFSET @offset
        LIMIT @limit
        ''',
      substitutionValues: {
        'offset': offset,
        'limit': limit,
        'user_id': userId,
      },
    );
    if (response.isEmpty) {
      return [];
    }

    final followers = <Profile>[];

    for (final userId in response) {
      final profile = await readProfile(
        userId: userId['user_relationships']!['publishing_user_id'] as int,
        reqUserId: reqUserId,
      );
      if (profile != null) {
        followers.add(profile);
      }
    }
    return followers;
  }

  @override
  Future<Profile?> readProfile({
    required int userId,
    int? reqUserId,
  }) async {
    final response = await connection.mappedResultsQuery(
      '''
        SELECT *
		      ${reqUserId == null ? '' : ', (SELECT EXISTS (SELECT * FROM user_relationships WHERE user_relationships.publishing_user_id = user_id AND user_relationships.reading_user_id = @req_user_id )) as  is_follow'}
		      ${reqUserId == null ? '' : ', (SELECT EXISTS (SELECT * FROM blacklist_user WHERE blacklist_user.requester_user_id = @req_user_id  AND blacklist_user.blocked_user_id = user_id)) as  is_blocked'}
		      ${reqUserId == null ? '' : ', (SELECT EXISTS (SELECT * FROM blacklist_user WHERE blacklist_user.requester_user_id = user_id AND blacklist_user.blocked_user_id = @req_user_id)) as  is_unavailable'}
        FROM profiles
        WHERE user_id = @user_id
        ''',
      substitutionValues: {
        'user_id': userId,
        'req_user_id': reqUserId,
      },
    );
    if (response.isEmpty) {
      return null;
    }
    final profile = Profile.fromPostgres(
      response.first['profiles'] ??
          Profile(
            userId: -1,
            username: 'error',
            profileName: 'error',
            avatar: 'e',
            backgroundColor: '00000000',
            isPremium: false,
            isDelete: false,
          ).toJson(),
    );

    final isFollow = (response.first[''])?['is_follow'] as bool?;
    final isBlocked = (response.first[''])?['is_blocked'] as bool?;
    final isUnavailable = (response.first[''])?['is_unavailable'] as bool?;

    if (isUnavailable ?? false) {
      return Profile(
        userId: userId,
        username: profile.username,
        profileName: profile.profileName,
        avatar: profile.avatar,
        backgroundColor: profile.backgroundColor,
        isPremium: profile.isPremium,
        isDelete: false,
        isUnavailable: isUnavailable,
        isBlocked: isBlocked,
      );
    }
    return profile.copyWith(
      isFollow: isFollow,
      isUnavailable: isUnavailable,
      isBlocked: isBlocked,
    );
  }

  @override
  Future<void> unBlockProfile({
    required int reqUserId,
    required int userId,
  }) async {
    await connection.mappedResultsQuery(
      '''
        DELETE 
        FROM blacklist_user
        WHERE requester_user_id = @requester_user_id AND blocked_user_id = @blocked_user_id
        ''',
      substitutionValues: {
        'requester_user_id': reqUserId,
        'blocked_user_id': userId,
      },
    );
  }

  @override
  Future<void> unFollowProfile({
    required int reqUserId,
    required int userId,
  }) async {
    final profile = await readProfile(userId: userId, reqUserId: reqUserId);
    if (profile == null) {
      throw Exception('Profile not found');
    }
    if (profile.isFollow == false) {
      throw Exception('You already unfollow');
    }

    await connection.transaction((tranc) async {
      await tranc.mappedResultsQuery(
        '''
        DELETE 
        FROM user_relationships 
        WHERE publishing_user_id = @publishing_user_id AND reading_user_id = @reading_user_id
        ''',
        substitutionValues: {
          'publishing_user_id': userId,
          'reading_user_id': reqUserId,
        },
      );
      await tranc.mappedResultsQuery(
        '''
        UPDATE profiles
        SET following = following - 1
        WHERE user_id = @req_user_id
        ''',
        substitutionValues: {
          'req_user_id': reqUserId,
        },
      );
      await tranc.mappedResultsQuery(
        '''
        UPDATE profiles
        SET followers = followers - 1
        WHERE user_id = @user_id
        ''',
        substitutionValues: {
          'user_id': userId,
        },
      );
    });
    return;
  }

  @override
  Future<Profile> updateProfile({required Profile profile}) async {
    final response = await connection.mappedResultsQuery(
      '''
        UPDATE profiles
        SET profile_name = @profile_name, description = @description, avatar = @avatar, background_color = @background_color, is_premium = @is_premium
        WHERE user_id = @user_id
        RETURNING *
        ''',
      substitutionValues: profile.toJson(),
    );
    return Profile.fromPostgres(
      response.first['profiles'] ??
          Profile(
            userId: -1,
            username: 'error',
            profileName: 'error',
            avatar: 'e',
            backgroundColor: '00000000',
            isPremium: false,
            isDelete: false,
          ).toJson(),
    );
  }
}
