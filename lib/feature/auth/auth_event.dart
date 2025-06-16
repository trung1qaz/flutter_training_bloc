import 'package:equatable/equatable.dart';
import '../../data/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String taxCode;
  final String username;
  final String password;

  const AuthLoginRequested({
    required this.taxCode,
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [taxCode, username, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthInitialized extends AuthEvent {}

class AuthRecentUserSelected extends AuthEvent {
  final User user;

  const AuthRecentUserSelected({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthRecentUserRemoved extends AuthEvent {
  final int index;

  const AuthRecentUserRemoved({required this.index});

  @override
  List<Object?> get props => [index];
}

class AuthFormCleared extends AuthEvent {}
