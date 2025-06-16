import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/base_ui.dart';
import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taxController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void dispose() {
    _taxController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.status == AuthStatus.authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đăng nhập thành công'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Update form fields when recent user is selected
          if (state.taxCode.isNotEmpty && _taxController.text != state.taxCode) {
            _taxController.text = state.taxCode;
          }
          if (state.username.isNotEmpty && _userController.text != state.username) {
            _userController.text = state.username;
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset('assets/icon/logo.svg'),
                    const SizedBox(height: 20),
                    BaseInputField(
                      label: "Mã số thuế",
                      controller: _taxController,
                      hintText: 'Điền mã số thuế',
                      validator: context.read<AuthBloc>().validateTaxCode,
                      keyboardType: TextInputType.number,
                    ),
                    BaseInputField(
                      label: "Tài khoản",
                      controller: _userController,
                      hintText: 'Điền tài khoản',
                      validator: context.read<AuthBloc>().validateUsername,
                    ),
                    BaseInputField(
                      label: "Mật khẩu",
                      controller: _passController,
                      hintText: 'Điền mật khẩu',
                      isPassword: true,
                      validator: context.read<AuthBloc>().validatePassword,
                    ),
                    BaseButton(
                      text: "Đăng nhập",
                      onPressed: state.status == AuthStatus.loading
                          ? null
                          : () => _onLoginPressed(context),
                      isLoading: state.status == AuthStatus.loading,
                    ),
                    const Spacer(),
                    BaseButton(
                      text: "Tài khoản gần đây",
                      onPressed: () => _showRecentLoginsDialog(context, state),
                      backgroundColor: Colors.white,
                      textColor: BaseUI.primaryColor,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              SvgPicture.asset('assets/icon/headphone.svg', width: 18),
                              const SizedBox(width: 1),
                              const Text('Trợ giúp'),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Expanded(
                          child: Row(
                            children: [
                              SvgPicture.asset('assets/icon/social_link.svg', width: 18),
                              const SizedBox(width: 2),
                              const Text('Group'),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Expanded(
                          child: Row(
                            children: [
                              SvgPicture.asset('assets/icon/vector.svg', width: 18),
                              const SizedBox(width: 2),
                              const Text('Tra cứu'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onLoginPressed(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          taxCode: _taxController.text,
          username: _userController.text,
          password: _passController.text,
        ),
      );
    }
  }

  void _showRecentLoginsDialog(BuildContext context, AuthState state) {
    if (state.recentUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có tài khoản nào trước đó'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chọn tài khoản'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: state.recentUsers.length,
            itemBuilder: (context, index) {
              final user = state.recentUsers[index];
              return ListTile(
                title: Text(user.userCtrl),
                subtitle: Text(user.taxCtrl.toString()),
                trailing: IconButton(
                  icon: const Icon(Icons.backspace_outlined),
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthRecentUserRemoved(index: index));
                  },
                ),
                onTap: () {
                  context.read<AuthBloc>().add(AuthRecentUserSelected(user: user));
                  Navigator.of(dialogContext).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
