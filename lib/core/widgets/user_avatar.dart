import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'avatar_initials.dart';

class UserAvatar extends StatefulWidget {
  final String? photoPath;
  final String name;
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.photoPath,
    required this.name,
    this.size = 50,
    this.onTap,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _resolvedFullPath;

  @override
  void initState() {
    super.initState();
    _resolvePath();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoPath != widget.photoPath) {
      _resolvePath();
    }
  }

  void _resolvePath() async {
    if (widget.photoPath == null || widget.photoPath!.trim().isEmpty) {
      if (mounted) setState(() => _resolvedFullPath = null);
      return;
    }

    final p = widget.photoPath!.trim();
    if (p.startsWith('/') || p.contains(':\\')) {
      // Absolute path
      if (mounted) setState(() => _resolvedFullPath = p);
    } else {
      // Relative file name stored in DB, resolve relative to app docs directory
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final fullPath = '${docsDir.path}/$p';
        if (mounted) setState(() => _resolvedFullPath = fullPath);
      } catch (_) {
        if (mounted) setState(() => _resolvedFullPath = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.size / 2;
    Widget avatarWidget;

    if (_resolvedFullPath != null && File(_resolvedFullPath!).existsSync()) {
      avatarWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(_resolvedFullPath!),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return AvatarInitials(name: widget.name, radius: radius);
          },
        ),
      );
    } else {
      avatarWidget = AvatarInitials(name: widget.name, radius: radius);
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}
