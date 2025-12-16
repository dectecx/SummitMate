import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class MapViewerScreen extends StatelessWidget {
  const MapViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('嘉明湖步道導覽圖', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: PhotoView(
        imageProvider: const AssetImage('assets/images/trail_map.jpg'),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3.0,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        heroAttributes: const PhotoViewHeroAttributes(tag: 'trail_map'),
      ),
    );
  }
}
