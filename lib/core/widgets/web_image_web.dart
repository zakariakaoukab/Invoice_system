import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'dart:html' as html;

final Map<String, bool> _registeredUrls = {};

Widget platformImage(String url, {double? width, double? height, BoxFit? fit, Widget Function()? errorBuilder}) {
  final viewType = 'image-view-${url.hashCode}';
  
  if (!_registeredUrls.containsKey(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final img = html.ImageElement()
          ..src = url
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.pointerEvents = 'none'
          ..style.objectFit = (fit == BoxFit.cover) ? 'cover' : (fit == BoxFit.contain ? 'contain' : 'fill');
        return img;
      },
    );
    _registeredUrls[viewType] = true;
  }

  return SizedBox(
    width: width,
    height: height,
    child: IgnorePointer(child: HtmlElementView(viewType: viewType)),
  );
}
