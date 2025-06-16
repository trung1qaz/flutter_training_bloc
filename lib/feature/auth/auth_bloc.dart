import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../../core/constants.dart';
import '../../data/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<AuthInitialized>(_onInitialized);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthRecentUserSelected>(_onRecentUserSelected);
    on<AuthRecentUserRemoved>(_onRecentUserRemoved);
    on<AuthFormCleared>(_onFormCleared);
  }

  void _onInitialized(AuthInitialized event, Emitter<AuthState> emit) {
    try {
      final box = Hive.box('authBox');
      final savedToken = box.get('authToken');
      final userList = box.get('userList', defaultValue: []);
      final currentUserData = box.get('currentUser');

      User? currentUser;
      if (currentUserData != null) {
        currentUser = User(
          taxCtrl: currentUserData['tax_code'],
          userCtrl: currentUserData['user_name'],
        );
      }

      emit(state.copyWith(
        status: savedToken != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        token: savedToken,
        currentUser: currentUser,
        recentUsers: List<User>.from(userList),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error initializing auth: $e',
      ));
    }
  }

  void _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      final dio = Dio();
      final url = AppConstants.baseUrl + AppConstants.loginEndpoint;
      final body = jsonEncode({
        "tax_code": int.tryParse(event.taxCode),
        "user_name": event.username.trim(),
        "password": event.password.trim(),
      });

      final response = await dio.post(url, data: body);
      final data = response.data;

      if (response.statusCode == 200 && data["success"] == true) {
        final token = data["data"]["token"];
        final newUser = User(
          taxCtrl: int.parse(event.taxCode),
          userCtrl: event.username,
        );

        final updatedRecentUsers = List<User>.from(state.recentUsers);
        updatedRecentUsers.removeWhere((u) =>
        u.taxCtrl == newUser.taxCtrl && u.userCtrl == newUser.userCtrl);
        updatedRecentUsers.add(newUser);

        final box = Hive.box('authBox');
        box.put('userList', updatedRecentUsers);
        box.put('authToken', token);
        box.put('currentUser', {
          'tax_code': int.parse(event.taxCode),
          'user_name': event.username,
        });

        emit(state.copyWith(
          status: AuthStatus.authenticated,
          token: token,
          currentUser: newUser,
          recentUsers: updatedRecentUsers,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: "Đăng nhập thất bại, sai tên đăng nhập hoặc mật khẩu",
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: "Lỗi kết nối: ${e.toString()}",
      ));
    }
  }

  void _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) {
    final box = Hive.box('authBox');
    box.delete('authToken');
    box.delete('currentUser');

    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      token: null,
      currentUser: null,
    ));
  }

  void _onRecentUserSelected(AuthRecentUserSelected event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      taxCode: event.user.taxCtrl.toString(),
      username: event.user.userCtrl,
    ));
  }

  void _onRecentUserRemoved(AuthRecentUserRemoved event, Emitter<AuthState> emit) {
    final updatedRecentUsers = List<User>.from(state.recentUsers);
    updatedRecentUsers.removeAt(event.index);

    final box = Hive.box('authBox');
    box.put('userList', updatedRecentUsers);

    emit(state.copyWith(recentUsers: updatedRecentUsers));
  }

  void _onFormCleared(AuthFormCleared event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      taxCode: '',
      username: '',
      password: '',
      errorMessage: null,
    ));
  }

  String? validateTaxCode(String? value) {
    if (value == null || value.trim().length != AppConstants.taxCodeLength) {
      return "Mã số thuế phải có ${AppConstants.taxCodeLength} chữ số";
    }
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Tên đăng nhập không được để trống";
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null ||
        value.trim().length < AppConstants.minPasswordLength ||
        value.trim().length > AppConstants.maxPasswordLength) {
      return "Mật khẩu phải từ ${AppConstants.minPasswordLength} đến ${AppConstants.maxPasswordLength} ký tự";
    }
    return null;
  }
}
