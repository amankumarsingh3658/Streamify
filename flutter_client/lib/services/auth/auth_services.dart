import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthServices {
  final backendUrl = "http://10.0.2.2:8000/auth/";
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<void> _saveCookies(http.Response response) async {
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      final accessTokenMatch = RegExp(
        r'access_token=([^;]+)',
      ).firstMatch(cookies);

      if (accessTokenMatch != null) {
        final accessToken = accessTokenMatch.group(1);
        await secureStorage.write(key: "access_token", value: accessToken);
      }

      final refreshTokenMatch = RegExp(
        r'refresh_token=([^;]+)',
      ).firstMatch(cookies);

      if (refreshTokenMatch != null) {
        final refreshToken = refreshTokenMatch.group(1);
        await secureStorage.write(key: "refresh_token", value: refreshToken);
      }
    }
  }

  Future<Map<String, String>> _getCookieHeader() async {
    final accessToken = await secureStorage.read(key: "access_token");
    final refreshToken = await secureStorage.read(key: "refresh_token");
    final userCognitoSub = await secureStorage.read(key: "user_cognito_sub");

    Map<String, String> headers = {"Content-Type": "application/json"};

    headers["Cookie"] = "access_token=$accessToken";
    headers["Cookie"] = "${headers["Cookie"]};refresh_token=$refreshToken";
    headers["Cookie"] = "${headers["Cookie"]};user_cognito_sub=$userCognitoSub";
    return headers;
  }

  Future<String> signUpUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("${backendUrl}signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );

    if (response.statusCode != 200) {
      log(response.body);
      throw jsonDecode(response.body)["detail"] ?? "An error occurred";
    }

    return (jsonDecode(response.body))["message"] ?? "Signup Successful";
  }

  Future<String> confirmSignupUser({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse("${backendUrl}confirm-signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );

    if (response.statusCode != 200) {
      log(response.body);
      throw jsonDecode(response.body)["detail"] ?? "An error occurred";
    }

    return (jsonDecode(response.body))["message"] ?? "OTP Confirmed , Login";
  }

  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${backendUrl}login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      if (response.statusCode != 200) {
        throw jsonDecode(response.body)["detail"] ?? "An error occurred";
      }
      await _saveCookies(response);
      await isAuthenticated();
      return (jsonDecode(response.body))["message"] ?? "Login Successful";
    } catch (e) {
      log(e.toString());
      throw e.toString();
    }
  }

  Future<String> refreshToken() async {
    final cookieHeader = await _getCookieHeader();
    final response = await http.post(
      Uri.parse("${backendUrl}refresh"),
      headers: cookieHeader,
    );

    if (response.statusCode != 200) {
      throw jsonDecode(response.body)["detail"] ?? "An error occurred";
    }
    await _saveCookies(response);
    return (jsonDecode(response.body))["message"] ?? "Token Refreshed";
  }

  Future<bool> isAuthenticated({int count = 0}) async {
    if (count > 1) {
      return false;
    }
    final cookieHeader = await _getCookieHeader();
    final response = await http.get(
      Uri.parse("${backendUrl}me"),
      headers: cookieHeader,
    );

    if (response.statusCode != 200) {
      await refreshToken();
      return await isAuthenticated(count: count + 1);
    } else {
      await secureStorage.write(
        key: "user_cognito_sub",
        value: jsonDecode(response.body)["user"]["sub"],
      );
    }

    return response.statusCode == 200;
  }
}
