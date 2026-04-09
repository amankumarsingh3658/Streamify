import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class UploadVideoService {
  final backendUrl = "http://10.0.2.2:8000/upload/video/";
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<Map<String, String>> _getCookieHeader() async {
    final accessToken = await secureStorage.read(key: "access_token");
    final userCognitoSub = await secureStorage.read(key: "user_cognito_sub");

    Map<String, String> headers = {"Content-Type": "application/json"};

    headers["Cookie"] = "access_token=$accessToken";
    headers["Cookie"] = "${headers["Cookie"]};user_cognito_sub=$userCognitoSub";
    return headers;
  }

  Future<Map<String, dynamic>> getPresignedUrlForThumbnail(
    String thumbnailId,
  ) async {
    final response = await http.get(
      Uri.parse("${backendUrl}url/thumbnail?thumbnail_id=$thumbnailId"),
      headers: await _getCookieHeader(),
    );

    if (response.statusCode != 200) {
      throw jsonDecode(response.body)["detail"] ?? "An error occurred";
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getPresignedUrlForVideo() async {
    final response = await http.get(
      Uri.parse("${backendUrl}url/"),
      headers: await _getCookieHeader(),
    );

    if (response.statusCode != 200) {
      throw jsonDecode(response.body)["detail"] ?? "An error occurred";
    }

    return jsonDecode(response.body);
  }

  Future<bool> uploadFile({
    required String presignedUrl,
    required File filePath,
    required bool isVideo,
  }) async {
    final response = await http.put(
      Uri.parse(presignedUrl),
      body: filePath.readAsBytesSync(),
      headers: {
        "Content-Type": isVideo ? "video/mp4" : "image/*",
        if (!isVideo) "x-amz-acl": "public-read",
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> uploadMetadata({
    required String title,
    required String description,
    required String visibility,
    required String videoS3Key,
  }) async {
    final response = await http.post(
      Uri.parse("${backendUrl}metadata"),
      headers: await _getCookieHeader(),
      body: jsonEncode({
        "title": title,
        "description": description,
        "visibility": visibility,
        "video_s3_key": videoS3Key,
        "video_id": videoS3Key,
      }),
    );

    if (response.statusCode != 200) {
      throw jsonDecode(response.body)["detail"] ?? "An error occurred";
    }

    return true;
  }
}
