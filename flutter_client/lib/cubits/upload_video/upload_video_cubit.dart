import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_client/services/upload_video_service.dart';
import 'package:path/path.dart' show dirname;
import 'package:path_provider/path_provider.dart';

part 'upload_video_state.dart';

class UploadVideoCubit extends Cubit<UploadVideoState> {
  UploadVideoCubit() : super(UploadVideoInitial());

  final uploadVideoService = UploadVideoService();

  void uploadVideo({
    required String title,
    required String description,
    required String visibility,
    required File thumbnailFile,
    required File videoFile,
  }) async {
    try {
      emit(UploadVideoLoading());
      final video = await uploadVideoService.getPresignedUrlForVideo();
      final thumbnail = await uploadVideoService.getPresignedUrlForThumbnail(
        video['video_id'],
      );

      final appDir = await getApplicationDocumentsDirectory();

      if (!appDir.existsSync()) {
        appDir.createSync();
      }

      final newthumbnailPath = "${appDir.path}/${thumbnail['thumbnail_id']}";
      final newVideoPath = "${appDir.path}/${video['video_id']}";

      final thumbnailDir = Directory(dirname(newthumbnailPath));
      final videoDir = Directory(dirname(newVideoPath));

      if (!thumbnailDir.existsSync()) {
        thumbnailDir.createSync(recursive: true);
      }

      if (!videoDir.existsSync()) {
        videoDir.createSync(recursive: true);
      }

      File newThumbnailFile = await thumbnailFile.copy(newthumbnailPath);
      File newVideoFile = await videoFile.copy(newVideoPath);

      final isThumbnailUploaded = await uploadVideoService.uploadFile(
        presignedUrl: thumbnail['url'],
        filePath: newThumbnailFile,
        isVideo: false,
      );
      final isVideoUploaded = await uploadVideoService.uploadFile(
        presignedUrl: video['url'],
        filePath: newVideoFile,
        isVideo: true,
      );

      if (isVideoUploaded && isThumbnailUploaded) {
        final isMetadataUploaded = await uploadVideoService.uploadMetadata(
          title: title,
          description: description,
          visibility: visibility,
          videoS3Key: video['video_id'],
        );
        if (isMetadataUploaded) {
          emit(UploadVideoSuccess());
        } else {
          emit(UploadVideoError("Failed to upload video metadata"));
        }
      } else {
        emit(UploadVideoError("Failed to upload video or thumbnail"));
      }
    } catch (e) {
      emit(UploadVideoError(e.toString()));
    }
  }
}
