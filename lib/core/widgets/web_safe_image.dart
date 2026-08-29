import 'package:flutter/material.dart';
import 'web_image_stub.dart' if (dart.library.js_interop) 'web_image_web.dart';

/// A network image widget that works on both web (CanvasKit) and native.
///
/// On web, CanvasKit loads images via XHR which is blocked by CORS.
/// This widget bypasses CORS on web by using an HTML <img> element via
/// a custom PlatformView, while defaulting to standard Image.network on native.
class WebSafeImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Widget Function()? errorBuilder;
  final double? width;
  final double? height;

  const WebSafeImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return errorBuilder?.call() ?? const SizedBox.shrink();
    }

    return platformImage(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}

