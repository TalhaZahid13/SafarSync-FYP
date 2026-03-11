import 'package:flutter/material.dart';
import 'package:safarsync_mobileapp/backend/views/auth/forgot_password_view.dart';
import 'package:safarsync_mobileapp/backend/views/auth/login_view.dart';
import 'package:safarsync_mobileapp/backend/views/auth/reset_password_view.dart';
import 'package:safarsync_mobileapp/backend/views/auth/signup_view.dart';
import 'package:safarsync_mobileapp/backend/views/home/home_view.dart';
import 'package:safarsync_mobileapp/backend/views/home/notification/notifications_view.dart';
import 'package:safarsync_mobileapp/backend/views/home/profile/profile_view.dart';
import 'package:safarsync_mobileapp/backend/views/splash/splash_view.dart';
import 'package:safarsync_mobileapp/backend/views/welcome/welcome_view.dart';

class Routes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password'; // ADD THIS
  static const String home = '/home';
  static const String gig = '/gig';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String personalInfo = '/personal-info';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashView());
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeView());
      case login:
        return MaterialPageRoute(builder: (_) => LoginView());
      case signup:
        return MaterialPageRoute(builder: (_) => SignUpView());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => ForgotPasswordView());
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordView());
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => NotificationsView());
      case personalInfo:
        return MaterialPageRoute(builder: (_) => ProfileView());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
