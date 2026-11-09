import 'dart:io';

import 'package:flutter/material.dart';

class RecordWidget extends StatelessWidget {
  /// The length of the diameter of the record.
  final double diameter;

  /// Path to the album cover, or null when there is none.
  final String? albumArt;
  final bool large;

  const RecordWidget({super.key, required this.diameter, this.albumArt})
      : large = false;

  const RecordWidget.largeImage(
      {super.key, required this.diameter, this.albumArt})
      : large = true;

  @override
  Widget build(BuildContext context) {
    final art = albumArt;
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        children: [
          Image(
            image: const AssetImage('assets/record2.png'),
            width: diameter,
            height: diameter,
            fit: BoxFit.fill,
          ),
          if (art != null && art.isNotEmpty)
            Center(
              child: ClipOval(
                child: Image.file(
                  File(art),
                  width: diameter / 2.5,
                  height: diameter / 2.5,
                  fit: BoxFit.cover,
                  cacheWidth: large ? 512 : 256,
                  // Missing or unreadable cover: just show the bare record.
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          Center(
            child: Container(
              width: diameter / 20,
              height: diameter / 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
