import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Whether [name] is a picture the app can show (by its extension).
bool isImageName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0) return false;
  return const {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'}.contains(name.substring(dot + 1).toLowerCase());
}

/// A picture over the whole window: pinch or the wheel zooms, dragging moves it; the ✕, Esc or a tap
/// outside it closes.
Future<void> showImageViewer(BuildContext context, File file) => showDialog<void>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: 0.9),
  builder: (context) => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.pop(context)},
    child: Focus(
      autofocus: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                maxScale: 8,
                child: Center(
                  child: GestureDetector(
                    // A tap on the picture itself keeps it open.
                    onTap: () {},
                    child: Image.file(file, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    ),
  ),
);
