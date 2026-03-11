// // main.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:provider/provider.dart';
// import 'package:smac/utils/responsive.dart';
// import 'package:smac/utils/routes.dart';
// import 'package:smac/utils/theme_manager.dart';
// import 'package:smac/viewmodels/auth_viewmodel.dart';
// import 'package:smac/viewmodels/chat_viewmodel.dart';
// import 'package:smac/viewmodels/course_viewmodel.dart';
// import 'package:smac/viewmodels/home_viewmodel.dart';
// import 'package:smac/viewmodels/profile_viewmodel.dart';
// import 'package:smac/viewmodels/theme_viewmodel.dart';
// import 'package:smac/views/splash/splash_view.dart';
// import 'package:smac/views/home/home_view.dart';
// import 'package:smac/views/auth/login_view.dart';
// import 'package:smac/viewmodels/service_viewmodel.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ScreenUtilInit(
//       designSize: const Size(411.4, 914.3), // iPhone X design size
//       minTextAdapt: true,
//       splitScreenMode: true,
//       builder: (context, child) {
//         return MultiProvider(
//           providers: [
//             ChangeNotifierProvider(create: (_) => ThemeViewModel()),
//             ChangeNotifierProvider(create: (_) => AuthViewModel()),
//             ChangeNotifierProvider(create: (_) => ProfileViewModel()),
//             ChangeNotifierProvider(create: (_) => HomeViewModel()),
//             ChangeNotifierProvider(create: (_) => ChatViewModel()),
//             ChangeNotifierProvider(create: (_) => CourseViewModel()),
//             ChangeNotifierProvider(
//               create: (_) => ServiceViewModel(),
//             ), // Add ServiceViewModel provider
//           ],
//           child: Consumer<ThemeViewModel>(
//             builder: (context, themeViewModel, child) {
//               return MaterialApp(
//                 title: 'SMAC - Social Media & Communication',
//                 debugShowCheckedModeBanner: false,
//                 theme: ThemeManager.lightTheme,
//                 darkTheme: ThemeManager.darkTheme,
//                 themeMode: themeViewModel.themeMode,
//                 home: const AuthWrapper(),
//                 onGenerateRoute: Routes.generateRoute,
//                 builder: (context, child) {
//                   Responsive().init(context);
//                   return child!;
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }

// class AuthWrapper extends StatefulWidget {
//   const AuthWrapper({super.key});

//   @override
//   State<AuthWrapper> createState() => _AuthWrapperState();
// }

// class _AuthWrapperState extends State<AuthWrapper> {
//   bool _hasInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }

//   void _initializeApp() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted && !_hasInitialized) {
//         _hasInitialized = true;
//         context.read<AuthViewModel>().initializeAuth();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthViewModel>(
//       builder: (context, authViewModel, child) {
//         // Show splash while initializing or loading
//         if (authViewModel.authState == AuthState.initial ||
//             authViewModel.authState == AuthState.loading) {
//           return const SplashView();
//         }

//         // Navigate based on authentication state
//         switch (authViewModel.authState) {
//           case AuthState.authenticated:
//             // User is logged in - show home screen
//             return const HomeScreen();

//           case AuthState.unauthenticated:
//             // User is not logged in - show login screen
//             return const LoginView();

//           case AuthState.error:
//             // Authentication error - show login with error handling
//             return const LoginView();

//           default:
//             // Fallback - show splash
//             return const SplashView();
//         }
//       },
//     );
//   }
// }
