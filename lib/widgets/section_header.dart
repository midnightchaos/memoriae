import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_extensions.dart';

/// Consistent section header widget.
///
/// Replaces all `_buildSectionHeader` private methods scattered across
/// settings, profile, and other screens.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? emoji;
  final IconData? icon;
  final Widget? trailing;
  final bool showDivider;

  const SectionHeader({
    super.key,
    required this.title,
    this.emoji,
    this.icon,
    this.trailing,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final pageStyle = Theme.of(context).extension<AppPageStyle>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider)
          Divider(
            color: pageStyle.subtitleColor.withOpacity(0.15),
            height: AppSpacing.xl,
          ),
        Row(
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.sm + 4),
            ] else if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: pageStyle.iconBackgroundColor,
                  borderRadius: AppRadius.sm,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: pageStyle.iconAccentColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
            ],
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: pageStyle.sectionHeaderColor,
                      fontSize: 20,
                    ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ],
    );
  }
}
