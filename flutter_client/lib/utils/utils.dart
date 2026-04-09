import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<File?> pickImage() async {
  final picker = ImagePicker();
  final xfile = await picker.pickImage(source: ImageSource.gallery);

  if (xfile != null) {
    File imageFile = File(xfile.path);
    return imageFile;
  }
  return null;
}

Future<File?> pickVideo() async {
  final picker = ImagePicker();
  final xfile = await picker.pickVideo(source: ImageSource.gallery);

  if (xfile != null) {
    File videoFile = File(xfile.path);
    return videoFile;
  }
  return null;
}
