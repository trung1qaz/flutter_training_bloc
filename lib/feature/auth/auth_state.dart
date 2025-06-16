import 'package:equatable/equatable.dart';
import '../../data/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? token;
  final User? currentUser;
  final List<User> recentUsers;
  final String? errorMessage;
  final String taxCode;
  final String username;
  final String password;

  const AuthState({
    this.status = AuthStatus.initial,
    this.token,
    this.currentUser,
    this.recentUsers = const [],
    this.errorMessage,
    this.taxCode = '',
    this.username = '',
    this.password = '',
  });

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    User? currentUser,
    List<User>? recentUsers,
    String? errorMessage,
    String? taxCode,
    String? username,
    String? password,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      currentUser: currentUser ?? this.currentUser,
      recentUsers: recentUsers ?? this.recentUsers,
      errorMessage: errorMessage ?? this.errorMessage,
      taxCode: taxCode ?? this.taxCode,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  @override
  List<Object?> get props => [
    status,
    token,
    currentUser,
    recentUsers,
    errorMessage,
    taxCode,
    username,
    password,
  ];
}
