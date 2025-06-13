import '../data/user.dart';

abstract class LoginEvent {}

class LoginSubmitted extends LoginEvent {
  final String taxCode;
  final String username;
  final String password;

  LoginSubmitted({
    required this.taxCode,
    required this.username,
    required this.password,
  });
}

class RecentLoginsRequested extends LoginEvent {}

class RecentLoginSelected extends LoginEvent {
  final User user;

  RecentLoginSelected({required this.user});
}

class RecentLoginDeleted extends LoginEvent {
  final int index;

  RecentLoginDeleted({required this.index});
}