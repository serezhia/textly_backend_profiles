# Official Dart image: https://hub.docker.com/_/dart
# Specify the Dart SDK base image version using dart:<version> (ex: dart:2.17)
FROM dart:stable AS build
# Настройка SSH для git
RUN mkdir ~/.ssh
RUN chmod 700 ~/.ssh
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
# Настройка на киатйский pub.dev
RUN export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
RUN export PUB_HOSTED_URL=https://pub.flutter-io.cn
WORKDIR /app

# Copy Dependencies

# Install Dependencies

# Resolve app dependencies.
COPY pubspec.* ./
RUN  --mount=type=ssh dart pub get

# Copy app source code and AOT compile it.
COPY . .
# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Build minimal serving image from AOT-compiled `/server` and required system
# libraries and configuration files stored in `/runtime/` from the build stage.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/


# Start server.
CMD ["/app/bin/server"]