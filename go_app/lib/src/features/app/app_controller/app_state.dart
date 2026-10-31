part of 'app_controller.dart';

sealed class AppState extends BaseState {
  final User user;
  final SgfCollection tsumegos;

  const AppState({
    required super.message,
    required this.user,
    required this.tsumegos,
  });

  const factory AppState.idle({
    required String message,
    required User user,
    required SgfCollection tsumegos,
  }) = AppStateIdle;
  const factory AppState.processing({
    required String message,
    required User user,
    required SgfCollection tsumegos,
  }) = AppStateProcessing;
  const factory AppState.failed({
    required String message,
    required User user,
    required SgfCollection tsumegos,
    Object? error,
    StackTrace? stackTrace,
  }) = AppStateFailed;

  @override
  bool get isIdle => this is AppStateIdle;

  @override
  bool get isProcessing => this is AppStateProcessing;

  @override
  bool get isFailed => this is AppStateFailed;

  @override
  Object? get error => switch (this) {
    AppStateFailed(:final message) => message,
    _ => null,
  };

  bool get isAuthorized => user is AuthorizedUser;

  bool get isLocalAuthorized => user is LocalOnlyUser;

  AppState copyWith({String? message, User? user});
}

final class AppStateIdle extends AppState {
  const AppStateIdle({
    required super.message,
    required super.user,
    required super.tsumegos,
  });

  @override
  String get type => 'idle';

  @override
  AppStateIdle copyWith({
    String? message,
    User? user,
    SgfCollection? tsumegos,
  }) {
    return AppStateIdle(
      message: message ?? this.message,
      user: user ?? this.user,
      tsumegos: tsumegos ?? this.tsumegos,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppStateIdle &&
            message == other.message &&
            user == other.user &&
            tsumegos == other.tsumegos;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, user, tsumegos);
}

final class AppStateProcessing extends AppState {
  const AppStateProcessing({
    required super.message,
    required super.user,
    required super.tsumegos,
  });

  @override
  String get type => 'processing';

  @override
  AppStateProcessing copyWith({
    String? message,
    User? user,
    SgfCollection? tsumegos,
  }) {
    return AppStateProcessing(
      message: message ?? this.message,
      user: user ?? this.user,
      tsumegos: tsumegos ?? this.tsumegos,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppStateProcessing &&
            message == other.message &&
            user == other.user &&
            tsumegos == other.tsumegos;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, user, tsumegos);
}

final class AppStateFailed extends AppState {
  @override
  final Object? error;
  final StackTrace? stackTrace;

  const AppStateFailed({
    required super.message,
    required super.user,
    required super.tsumegos,
    this.error,
    this.stackTrace,
  });

  @override
  String get type => 'failed';

  @override
  AppStateFailed copyWith({
    String? message,
    User? user,
    SgfCollection? tsumegos,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppStateFailed(
      message: message ?? this.message,
      user: user ?? this.user,
      tsumegos: tsumegos ?? this.tsumegos,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppStateFailed &&
            message == other.message &&
            user == other.user &&
            tsumegos == other.tsumegos &&
            error == other.error;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, user, tsumegos, error);
}
