import 'package:dio/dio.dart';

import '../network/models/sync_models.dart';
import '../network/session_service.dart';

enum SyncErrorCategory {
  conflict,
  validation,
  auth,
  network,
  server,
}

class SyncErrorPresentation {
  const SyncErrorPresentation({
    required this.category,
    required this.userMessage,
    required this.developerDetail,
  });

  final SyncErrorCategory category;
  final String userMessage;
  final String developerDetail;
}

class SyncErrorMapper {
  static SyncErrorPresentation fromFailedEvent(SyncPushFailure failure) {
    final code = failure.code.toUpperCase();
    if (code == 'CONFLICT_STALE_EVENT') {
      return SyncErrorPresentation(
        category: SyncErrorCategory.conflict,
        userMessage: 'Server has newer data. Pull latest changes and retry.',
        developerDetail:
            '${failure.code}: ${failure.message} (${failure.entity ?? 'unknown'} ${failure.operation ?? ''})',
      );
    }
    if (code.startsWith('INVALID_') ||
        code.endsWith('_NOT_FOUND') ||
        code == 'PAYMENT_TOTAL_MISMATCH' ||
        code == 'CUSTOMER_REQUIRED_FOR_CREDIT_SALE' ||
        code == 'INSUFFICIENT_STOCK') {
      return SyncErrorPresentation(
        category: SyncErrorCategory.validation,
        userMessage: 'Some offline changes are invalid and could not be synced.',
        developerDetail:
            '${failure.code}: ${failure.message} (${failure.entity ?? 'unknown'} ${failure.operation ?? ''})',
      );
    }
    if (code == 'TOKEN_REVOKED' || code == 'INVALID_TOKEN' || code == 'INVALID_TOKEN_TYPE') {
      return SyncErrorPresentation(
        category: SyncErrorCategory.auth,
        userMessage: 'Your session expired. Please sign in again.',
        developerDetail: '${failure.code}: ${failure.message}',
      );
    }
    return SyncErrorPresentation(
      category: SyncErrorCategory.server,
      userMessage: 'Sync failed on server. We will retry automatically.',
      developerDetail:
          '${failure.code}: ${failure.message} (${failure.entity ?? 'unknown'} ${failure.operation ?? ''})',
    );
  }

  static SyncErrorPresentation fromException(Object error) {
    if (error is SessionAuthException) {
      return SyncErrorPresentation(
        category: SyncErrorCategory.auth,
        userMessage: error.message,
        developerDetail: error.toString(),
      );
    }
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        return SyncErrorPresentation(
          category: SyncErrorCategory.auth,
          userMessage: 'Your session expired. Please sign in again.',
          developerDetail: error.toString(),
        );
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return SyncErrorPresentation(
          category: SyncErrorCategory.network,
          userMessage: 'Network issue while syncing. We will retry automatically.',
          developerDetail: error.toString(),
        );
      }
    }
    final raw = error.toString();
    return SyncErrorPresentation(
      category: SyncErrorCategory.server,
      userMessage: 'Sync failed. We will retry automatically.',
      developerDetail: raw,
    );
  }
}
