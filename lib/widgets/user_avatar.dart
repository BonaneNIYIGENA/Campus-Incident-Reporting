import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/image_upload_service.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 44});
  final AppUser? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = user?.displayName.trim() ?? '';
    final initials = name.isEmpty
        ? '?'
        : name
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: colors.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: size * .36,
        ),
      ),
    );
    final url = user?.photoUrl;
    return ClipOval(
      child: url == null
          ? fallback
          : Image.network(
              cloudinaryThumb(url, size: (size * 3).round()),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}
