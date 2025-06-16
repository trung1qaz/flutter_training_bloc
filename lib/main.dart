import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sds_mobile_training_p2/data/user.dart';
import 'feature/auth/auth_bloc.dart';
import 'feature/auth/auth_event.dart';
import 'feature/auth/auth_state.dart';
import 'feature/auth/login_screen.dart';
import 'feature/product/home_screen.dart';
import 'feature/product/product_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  await Hive.openBox('authBox');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc()..add(AuthInitialized()),
        ),
        BlocProvider(
          create: (context) => ProductCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter BLoC Demo',
        theme: ThemeData(
          primarySwatch: Colors.orange,
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            switch (state.status) {
              case AuthStatus.authenticated:
              // Initialize product data when authenticated
                context.read<ProductCubit>().fetchData();
                return const HomeScreen();
              case AuthStatus.unauthenticated:
              case AuthStatus.initial:
              default:
                return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
