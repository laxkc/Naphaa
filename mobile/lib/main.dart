import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/core/config/environment_loader.dart';
import 'package:sme_digital/core/providers/app_providers.dart';

import 'app.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final environment = await EnvironmentLoader.load();
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://b0d19d349a705089d8ac1aaf992cc3f6@o4509746385256448.ingest.us.sentry.io/4510942116642816';
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = true;
      options.enableLogs = true;
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
      // Configure Session Replay
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;
    },
    appRunner: () {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        final stack = details.stack ?? StackTrace.current;
        developer.log(
          'FlutterError: ${details.exceptionAsString()}',
          name: 'app.flutter',
          error: details.exception,
          stackTrace: stack,
        );
        if (kDebugMode) {
          debugPrint('FlutterError exception: ${details.exceptionAsString()}');
          debugPrintStack(stackTrace: stack);
        }
        Sentry.captureException(details.exception, stackTrace: stack);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        developer.log(
          'PlatformDispatcher error: $error',
          name: 'app.flutter',
          error: error,
          stackTrace: stack,
        );
        if (kDebugMode) {
          debugPrint('Platform error: $error');
          debugPrintStack(stackTrace: stack);
        }
        Sentry.captureException(error, stackTrace: stack);
        return true;
      };

      runApp(
        SentryWidget(
          child: ProviderScope(
            overrides: [
              environmentConfigProvider.overrideWithValue(environment),
            ],
            child: const SmeDigitalApp(),
          ),
        ),
      );
    },
  );
  // TODO: Remove this line after sending the first sample event to sentry.
  await Sentry.captureException(StateError('This is a sample exception.'));
}
