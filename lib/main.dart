import 'package:flutter/material.dart';
import 'package:lms_flutter/providers/auth_provider.dart';
import 'package:lms_flutter/screens/login_screen.dart';
import 'package:lms_flutter/screens/customer_home.dart';
import 'package:lms_flutter/screens/driver_home.dart';
import 'package:lms_flutter/screens/register_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LMS App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/customer': (context) => const CustomerHomeScreen(),
        '/driver': (context) => const DriverHomeScreen(),
      },
    );
  }
}
