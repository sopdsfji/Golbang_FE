import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:golbang/pages/home/splash_screen.dart';
import 'package:golbang/pages/logins/widgets/login_widgets.dart';
import 'package:golbang/pages/logins/widgets/social_login_widgets.dart';
import 'package:golbang/services/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:local_auth/local_auth.dart';

import '../../global/LoginInterceptor.dart';
import '../../repoisitory/secure_storage.dart';

class TokenCheck extends ConsumerStatefulWidget {
  const TokenCheck({super.key});

  @override
  _TokenCheckState createState() => _TokenCheckState();
}

class _TokenCheckState extends ConsumerState<TokenCheck> {
  var dioClient = DioClient();
  bool isTokenExpired = true; // 초기값 설정
  bool? isAuthenticated; // 생체 인증 성공 여부

  @override
  void initState() {
    super.initState();
    _checkTokenStatus(); // 비동기 작업 호출
  }

  Future<void> _checkTokenStatus() async {
    bool tokenStatus = await dioClient.isAccessTokenExpired();
    setState(() {
      isTokenExpired = tokenStatus; // 상태 업데이트
    });
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: isTokenExpired ? const LoginPage() : const SplashScreen(),
    );
  }
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();




  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    // 전달된 메시지를 읽음
    final String? message = Get.arguments?['message'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LoginTitle(),
              const SizedBox(height: 32),
              EmailField(controller: _emailController),
              const SizedBox(height: 16),
              PasswordField(controller: _passwordController),
              const SizedBox(height: 64),
              LoginButton(onPressed: _login),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loginWithBiometrics,
                icon: const Icon(Icons.fingerprint,
                  color: Colors.white,
                ),
                label: const Text('지문 인식',
                  style:TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 48),
              const SignUpLink() ,
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _loginWithBiometrics() async {
    final auth = LocalAuthentication();
    final canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();

    if (!canAuthenticate) {
      _showErrorDialog('이 기기에서는 생체 인증을 사용할 수 없습니다.');
      return;
    }

    final authenticated = await auth.authenticate(
      localizedReason: '생체 인증으로 로그인',
      options: const AuthenticationOptions(biometricOnly: true),
    );

    if (authenticated) {
      log('생체인증 성공');
      final storage = ref.read(secureStorageProvider);
      try {

        final savedEmail = await storage.readLoginId();  // 저장된 이메일 불러오기
        final savedPassword = await storage.readPassword(); // 저장된 비밀번호 불러오기

        setState(() {
          _emailController.text = savedEmail; // 이메일 필드에 자동완성
          _passwordController.text = savedPassword;
        });


        if (savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
          _login();

        } else {
          _showErrorDialog('저장된 로그인 정보가 없습니다.\n이메일과 비밀번호로 먼저 로그인해주세요.');
        }
      } catch (e) {
        _showErrorDialog('로그인 정보 불러오기 실패: $e');
      }
    } else {
      _showErrorDialog('생체 인증에 실패했습니다.');
    }
  }


  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    String? fcmToken;
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      fcmToken = await messaging.getToken();
    } catch (e) {
      log('FCM 토큰 가져오기 실패: $e');
    }

    if (_validateInputs(email, password)) {
      try {
        final response = await AuthService.login(
          username: email,
          password: password,
          fcm_token: fcmToken ?? '',
        );
        await _handleLoginResponse(response, email, password);
      } catch (e) {
        _showErrorDialog('An error occurred. Please try again.');
      }
    } else {
      _showErrorDialog('Please fill in all fields');
    }
  }

  bool _validateInputs(String email, String password) {
    return email.isNotEmpty && password.isNotEmpty;
  }

  Future<void> _handleLoginResponse(http.Response response, String email, String password) async {
    if (response.statusCode == 200) {
      // 로그인 성공 시 이메일 저장
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 성공!')),
      );

      final body = json.decode(response.body);
      var accessToken = body['data']['access_token'];

      final storage = ref.watch(secureStorageProvider);
      await storage.saveLoginId(email);
      await storage.savePassword(password);
      await storage.saveAccessToken(accessToken);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    } else {
      _showErrorDialog('Invalid email or password');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}