import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class CarenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showProfileButton;
  final PreferredSizeWidget? bottom;

  const CarenAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showProfileButton = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTypography.titleLarge.copyWith(color: AppColors.primaryDark),
      ),
      leading: leading,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      bottom: bottom,
      actions: [
        ...?actions,
        if (showProfileButton)
          IconButton(
            tooltip: 'Profile & Privacy Settings',
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryContainer,
              child: Icon(Icons.person_outline, size: 20, color: AppColors.primary),
            ),
            onPressed: () => context.push('/profile'),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

