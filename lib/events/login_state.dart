import '../data/user.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final String token;
  final Map<String, dynamic> currentUser;

  LoginSuccess({
    required this.token,
    required this.currentUser,
  });
}

class LoginFailure extends LoginState {
  final String message;

  LoginFailure({required this.message});
}

class RecentLoginsLoaded extends LoginState {
  final List<User> users;

  RecentLoginsLoaded({required this.users});
}

class RecentLoginsEmpty extends LoginState {}

class UserSelected extends LoginState {
  final User user;

  UserSelected({required this.user});
}
