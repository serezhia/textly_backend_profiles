import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:logger/logger.dart';
import 'package:postgres/postgres.dart';
import 'package:textly_core/textly_core.dart';
import 'package:textly_profiles/data_sources/postgres_profile_data_sourec.dart';
import 'package:textly_profiles/utils/env_utils.dart';
import 'package:textly_profiles/utils/jwt_service.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  final logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      noBoxingByDefault: true,
    ),
  );

  /// Подключаемся к БД
  final dbConection = PostgreSQLConnection(
    dbHost(),
    // '0.0.0.0',
    dbPort(),
    dbName(),
    username: dbUsername(),
    password: dbPassword(),
  );

  try {
    await dbConection.open();
    logger.i('Database connect success');
  } catch (e) {
    logger.e('Error connecting to database');
    Future.delayed(
      const Duration(seconds: 3),
      () => exit(1),
    );
  }

  final profileRepository = PostgresProfileDataSource(dbConection);
  final jwtService = JwtServiceImpl();

  final newHandler = handler
      .use(
        provider<ProfileRepository>(
          (context) => profileRepository,
        ),
      )
      .use(
        provider<Logger>(
          (context) => logger,
        ),
      )
      .use(
        provider<JwtService>(
          (context) => jwtService,
        ),
      );

  return serve(newHandler, serviceHost(), servicePort());
}
