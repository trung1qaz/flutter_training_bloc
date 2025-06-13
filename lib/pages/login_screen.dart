import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../events/login_bloc.dart';
import '../events/login_event.dart';
import '../events/login_state.dart';
import 'package:sds_mobile_training_p2/data/user.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final taxCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
        LoginSubmitted(
          taxCode: taxCtrl.text,
          username: userCtrl.text,
          password: passCtrl.text,
        ),
      );
    } else {
      setState(() {
        _autovalidateMode = AutovalidateMode.always;
      });
    }
  }

  void _showRecentLoginsDialog() {
    context.read<LoginBloc>().add(RecentLoginsRequested());
  }

  void _showRecentLoginsDialogContent(List<User> userList) {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Chọn tài khoản'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: userList.length,
              itemBuilder: (context, index) {
                final user = userList[index];
                return ListTile(
                  title: Text(user.userCtrl),
                  subtitle: Text(user.taxCtrl.toString()),
                  trailing: IconButton(
                    icon: Icon(Icons.backspace_outlined),
                    onPressed: () {
                      context.read<LoginBloc>().add(RecentLoginDeleted(index: index));
                    },
                  ),
                  onTap: () {
                    context.read<LoginBloc>().add(RecentLoginSelected(user: user));
                    Navigator.pop(dialogContext);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    taxCtrl.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is RecentLoginsEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không có tài khoản nào trước đó')),
            );
          } else if (state is RecentLoginsLoaded) {
            _showRecentLoginsDialogContent(state.users);
          } else if (state is UserSelected) {
            setState(() {
              taxCtrl.text = state.user.taxCtrl.toString();
              userCtrl.text = state.user.userCtrl;
            });
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset('assets/icon/logo.svg'),
                  const SizedBox(height: 20),

                  CustomInputField(
                    label: "Mã số thuế",
                    controller: taxCtrl,
                    hintText: 'Điền mã số thuế',
                    validator: (value) {
                      if (value == null || value.trim().length != 10) {
                        return "Mã số thuế phải có 10 chữ số";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                  ),
                  CustomInputField(
                    label: "Tài khoản",
                    controller: userCtrl,
                    hintText: 'Điền tài khoản',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Tên đăng nhập không được để trống";
                      }
                      return null;
                    },
                  ),
                  CustomInputField(
                    label: "Mật khẩu",
                    controller: passCtrl,
                    hintText: 'Điền mật khẩu',
                    isPassword: true,
                    validator: (value) {
                      if (value == null ||
                          value.trim().length < 6 ||
                          value.trim().length > 50) {
                        return "Mật khẩu phải từ 6 đến 50 ký tự";
                      }
                      return null;
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state is LoginLoading ? null : _onLoginPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: state is LoginLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Đăng nhập",
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                  ),
                  Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showRecentLoginsDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Tài khoản gần đây",
                        style: TextStyle(fontSize: 18, color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Help Row
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            SvgPicture.asset(
                              'assets/icon/headphone.svg',
                              width: 18,
                            ),
                            SizedBox(width: 1),
                            Text('Trợ giúp'),
                          ],
                        ),
                      ),
                      Spacer(),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            SvgPicture.asset(
                              'assets/icon/social_link.svg',
                              width: 18,
                            ),
                            SizedBox(width: 2),
                            Text('Group'),
                          ],
                        ),
                      ),
                      Spacer(),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            SvgPicture.asset('assets/icon/vector.svg', width: 18),
                            SizedBox(width: 2),
                            Text('Tra cứu'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Keep the CustomInputField widget as is - no changes needed
class CustomInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?) validator;
  final bool isPassword;
  final TextInputType keyboardType;

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.validator,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _showSuffix = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    Widget? suffixIcon;
    if (widget.isPassword && _showSuffix) {
      suffixIcon = IconButton(
        icon: _showPassword
            ? SvgPicture.asset('assets/icon/eye_slash.svg')
            : SvgPicture.asset('assets/icon/eye.svg'),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      );
    } else if (_showSuffix) {
      suffixIcon = IconButton(
        icon: SvgPicture.asset('assets/icon/delete.svg'),
        onPressed: () {
          widget.controller.clear();
          setState(() => _showSuffix = false);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? !_showPassword : false,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: (value) {
            setState(() {
              _showSuffix = value.isNotEmpty;
            });
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orangeAccent),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}