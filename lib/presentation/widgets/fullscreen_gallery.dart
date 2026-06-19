import 'package:flutter/material.dart';
import 'encrypted_image.dart';

void openFullscreenGallery(
  BuildContext context,
  List<(String, String)> pages,
  int initialIndex,
) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => _FullscreenGallery(pages: pages, initialIndex: initialIndex),
  ));
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({required this.pages, required this.initialIndex});
  final List<(String, String)> pages;
  final int initialIndex;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.pages[_current].$1),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.pages.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, i) {
          final (_, path) = widget.pages[i];
          return InteractiveViewer(
            child: Center(
              child: EncryptedImage(path: path, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
