import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_client/cubits/upload_video/upload_video_cubit.dart';
import 'package:flutter_client/utils/utils.dart';

class UploadPage extends StatefulWidget {
  static MaterialPageRoute<dynamic> route() =>
      MaterialPageRoute(builder: (context) => UploadPage());
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String visibility = "PRIVATE";

  File? thumbnail;
  File? videoFile;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void selectThumbnail() async {
    final thumbnailImage = await pickImage();

    setState(() {
      thumbnail = thumbnailImage;
    });
  }

  void selectVideoFile() async {
    final video = await pickVideo();

    setState(() {
      videoFile = video;
    });
  }

  void uploadVideo() async {
    if (titleController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty &&
        thumbnail != null &&
        videoFile != null) {
      context.read<UploadVideoCubit>().uploadVideo(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        visibility: visibility,
        thumbnailFile: thumbnail!,
        videoFile: videoFile!,
      );
    } else {
      showSnackbar(context, "Please fill all the fields and select files");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Page")),
      body: BlocConsumer<UploadVideoCubit, UploadVideoState>(
        listener: (context, state) {
          if (state is UploadVideoSuccess) {
            showSnackbar(context, "Video uploaded successfully");
            Navigator.pop(context);
          } else if (state is UploadVideoError) {
            showSnackbar(context, state.error);
          }
        },
        builder: (context, state) {
          if (state is UploadVideoLoading) {
            return Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      selectThumbnail();
                    },
                    child: thumbnail != null
                        ? Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            height: 150,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(thumbnail!, fit: BoxFit.cover),
                            ),
                          )
                        : DottedBorder(
                            options: RoundedRectDottedBorderOptions(
                              strokeCap: StrokeCap.round,
                              dashPattern: [10, 4],
                              radius: Radius.circular(10),
                            ),
                            child: SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_open, size: 50),
                                  Text(
                                    "Select The Thumbnail for your video",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      selectVideoFile();
                    },
                    child: videoFile != null
                        ? Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            height: 150,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  videoFile!.path.split("/").last,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          )
                        : DottedBorder(
                            options: RoundedRectDottedBorderOptions(
                              strokeCap: StrokeCap.round,
                              dashPattern: [10, 4],
                              radius: Radius.circular(10),
                            ),
                            child: SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_file_outlined, size: 50),
                                  Text(
                                    "Select your video file",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                  SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton(
                      value: visibility,
                      padding: EdgeInsets.all(15),
                      underline: SizedBox(),
                      borderRadius: BorderRadius.circular(8),
                      items: ["PUBLIC", "PRIVATE", "UNLISTED"]
                          .map(
                            (elem) => DropdownMenuItem(
                              value: elem,
                              child: Text(elem),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          visibility = value ?? "PRIVATE";
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      uploadVideo();
                    },
                    child: Text(
                      "Upload",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
