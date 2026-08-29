import 'package:flutter/material.dart';

Widget platformImage(String url, {double? width, double? height, BoxFit? fit, Widget Function()? errorBuilder}) {
  return Image.network(
    url,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder != null ? (context, error, stackTrace) => errorBuilder() : null,
  );
}
