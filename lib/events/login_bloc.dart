import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:sds_mobile_training_p2/data/user.dart';

import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final Dio _dio = Dio();
  final Box _authBox = Hive.box('authBox');

  LoginBloc() : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RecentLoginsRequested>(_onRecentLoginsRequested);
    on<RecentLoginSelected>(_onRecentLoginSelected);
    on<RecentLoginDeleted>(_onRecentLoginDeleted);
  }

  Future<void> _onLoginSubmitted(
      LoginSubmitted event,
      Emitter<LoginState> emit,
      ) async {
    emit(LoginLoading());

    try {
      final url = "https://training-api-unrp.onrender.com/login2";
      final body = jsonEncode({
        "tax_code": int.tryParse(event.taxCode),
        "user_name": event.username.trim(),
        "password": event.password.trim(),
      });

      final response = await _dio.post(url, data: body);
      final data = response.data;

      if (response.statusCode == 200 && data["success"] == true) {
        final token = data["data"]["token"];

        List<User> userList = _authBox.get('userList', defaultValue: []).cast<User>();

        final newUser = User(
          taxCtrl: int.parse(event.taxCode),
          userCtrl: event.username,
        );

        userList.removeWhere((u) =>
        u.taxCtrl == newUser.taxCtrl && u.userCtrl == newUser.userCtrl);
        userList.add(newUser);

        await _authBox.put('userList', userList);
        await _authBox.put('authToken', token);

        final currentUser = {
          'tax_code': int.parse(event.taxCode),
          'user_name': event.username,
        };
        await _authBox.put('currentUser', currentUser);

        emit(LoginSuccess(token: token, currentUser: currentUser));
      } else {
        emit(LoginFailure(message: "Đăng nhập thất bại, sai tên đăng nhập hoặc mật khẩu"));
      }
    } catch (e) {
      emit(LoginFailure(message: "Lỗi kết nối: ${e.toString()}"));
    }
  }

  void _onRecentLoginsRequested(
      RecentLoginsRequested event,
      Emitter<LoginState> emit,
      ) {
    List<User> userList = List<User>.from(_authBox.get('userList', defaultValue: []));

    if (userList.isEmpty) {
      emit(RecentLoginsEmpty());
    } else {
      emit(RecentLoginsLoaded(users: userList));
    }
  }

  void _onRecentLoginSelected(
      RecentLoginSelected event,
      Emitter<LoginState> emit,
      ) {
    emit(UserSelected(user: event.user));
  }

  Future<void> _onRecentLoginDeleted(
      RecentLoginDeleted event,
      Emitter<LoginState> emit,
      ) async {
    List<User> userList = List<User>.from(_authBox.get('userList', defaultValue: []));

    if (event.index >= 0 && event.index < userList.length) {
      userList.removeAt(event.index);
      await _authBox.put('userList', userList);

      if (userList.isEmpty) {
        emit(RecentLoginsEmpty());
      } else {
        emit(RecentLoginsLoaded(users: userList));
      }
    }
  }

  @override
  Future<void> close() {
    _dio.close();
    return super.close();
  }
}