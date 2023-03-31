import 'package:dart_frog/dart_frog.dart';
import 'package:logger/logger.dart';
import 'package:textly_profiles/models/textly_response.dart';
import 'package:textly_profiles/models/user_id_model.dart';
import 'package:textly_profiles/utils/jwt_service.dart';
import 'package:uuid/uuid.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final jwtService = context.read<JwtService>();

    if (context.request.method != HttpMethod.get &&
        !(await jwtService.verifyToken(context))) {
      return TextlyResponse.notAuth(
        message: 'Incorrect token',
      );
    }
    final token = await jwtService.getToken(context);

    final userId = UserId(int.tryParse(token?.subject ?? ''));

    final uuid = const Uuid().v4();
    final newHanler = handler
        .use(
          requestLogger(
            logger: (message, isError) {
              final logger = context.read<Logger>();
              if (isError) {
                logger.e(message);
              } else {
                logger.i('$uuid: $message');
              }
            },
          ),
        )
        .use(provider<String>((context) => uuid))
        .use(provider<UserId>((context) => userId));

    return newHanler(context);
  };
}
