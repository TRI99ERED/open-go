abstract base class User {
  const User();

  User copyWith();
}

final class UnauthorizedUser extends User {
  const UnauthorizedUser();

  @override
  UnauthorizedUser copyWith() => this;
}

final class LocalOnlyUser extends User {
  final String name;

  const LocalOnlyUser({required this.name});

  @override
  LocalOnlyUser copyWith({String? name}) {
    return LocalOnlyUser(name: name ?? this.name);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LocalOnlyUser && name == other.name;
  }

  @override
  int get hashCode => Object.hash(runtimeType, name);
}

final class AuthorizedUser extends LocalOnlyUser {
  final String id;

  const AuthorizedUser({required this.id, required super.name});

  @override
  AuthorizedUser copyWith({String? id, String? name}) {
    return AuthorizedUser(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthorizedUser && id == other.id && name == other.name;
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name);
}
