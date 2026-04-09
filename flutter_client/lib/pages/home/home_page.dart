import 'package:flutter/material.dart';
import 'package:flutter_client/pages/home/upload_page.dart';
import 'package:flutter_client/pages/home/video_player_page.dart';
import 'package:flutter_client/services/video_service.dart';

class HomePage extends StatefulWidget {
  static MaterialPageRoute<dynamic> route() =>
      MaterialPageRoute(builder: (context) => HomePage());
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final videoService = VideoService();
  Future<List<Map<String, dynamic>>> getAllVideos() async {
    return videoService.getAllVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Streamify"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, UploadPage.route());
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder(
        future: getAllVideos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("An error occurred"));
          } else {
            final videos = snapshot.data;
            return ListView.builder(
              itemCount: videos?.length ?? 0,
              itemBuilder: (context, index) {
                final video = videos?[index];
                final thumbnail =
                    "https://d2fnni7pu6hf87.cloudfront.net/${video?['video_s3_key'].replaceAll(".mp4", "").replaceAll("videos/", "thumbnails/")}";
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, VideoPlayerPage.route(video!));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              thumbnail,
                              headers: {"Content-Type": "image/*"},
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            video?['title'] ?? "",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
