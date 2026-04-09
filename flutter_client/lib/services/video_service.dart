import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class VideoService {
  final backendUrl = "http://10.0.2.2:8000/videos/";
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<Map<String, String>> _getCookieHeader() async {
    final accessToken = await secureStorage.read(key: "access_token");
    final userCognitoSub = await secureStorage.read(key: "user_cognito_sub");

    Map<String, String> headers = {"Content-Type": "application/json"};

    headers["Cookie"] = "access_token=$accessToken";
    headers["Cookie"] = "${headers["Cookie"]};user_cognito_sub=$userCognitoSub";
    return headers;
  }

  Future<List<Map<String, dynamic>>> getAllVideos() async {
    try {
      final response = await http.get(
        Uri.parse("${backendUrl}all"),
        headers: await _getCookieHeader(),
      );

      if (response.statusCode != 200) {
        throw jsonDecode(response.body)["detail"] ?? "An error occurred";
      }
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } catch (e) {
      throw e.toString();
    }
  }
}
