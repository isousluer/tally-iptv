import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import 'theme.dart';

String initials(String name) {
  final words = name
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, words.first.length.clamp(1, 2)).toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}

/// Square channel logo with an initials fallback.
class ChannelLogo extends StatelessWidget {
  const ChannelLogo({super.key, required this.name, this.url, this.size = 48});
  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(initials(name), style: Theme.of(context).textTheme.labelLarge!.copyWith(color: AppColors.tally)),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.raised, borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(5),
      child: url == null
          ? fallback
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.contain,
              memCacheWidth: (size * 3).round(),
              fadeInDuration: Duration.zero,
              placeholder: (_, _) => fallback,
              errorWidget: (_, _, _) => fallback,
            ),
    );
  }
}

/// 2:3 poster with a title fallback.
class Poster extends StatelessWidget {
  const Poster({super.key, required this.title, this.url, this.aspectRatio = 2 / 3});
  final String title;
  final String? url;

  /// Null fills the available space instead of keeping a fixed ratio.
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AppColors.raised,
      padding: const EdgeInsets.all(10),
      alignment: Alignment.bottomLeft,
      child: Text(
        title,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700),
      ),
    );
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null
          ? fallback
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              memCacheWidth: 360,
              fadeInDuration: const Duration(milliseconds: 120),
              placeholder: (_, _) => fallback,
              errorWidget: (_, _, _) => fallback,
            ),
    );
    return aspectRatio == null ? image : AspectRatio(aspectRatio: aspectRatio!, child: image);
  }
}

/// Thin amber progress line, the visual signature of the app.
class TallyBar extends StatelessWidget {
  const TallyBar({super.key, required this.value, this.height = 2});
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: height,
          backgroundColor: AppColors.border,
          color: AppColors.tally,
        ),
      ),
    );
  }
}

class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: AppColors.live, borderRadius: BorderRadius.circular(99)),
      child: Text('Live', style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.white, height: 1.2)),
    );
  }
}

/// Screen header with title, a muted subtitle and trailing actions.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle, this.actions = const []});
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
      // Top-aligned so the title sits in the same place on every tab,
      // with or without a subtitle.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.headlineMedium),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall!.copyWith(color: AppColors.muted),
                    ),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Inline search field that replaces the header while searching.
class SearchBarField extends StatelessWidget {
  const SearchBarField({super.key, required this.hint, required this.onChanged, required this.onClose});
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              autofocus: true,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                isDense: true,
              ),
            ),
          ),
          IconButton(tooltip: 'Close search', onPressed: onClose, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.muted),
              const SizedBox(height: 14),
              Text(title, style: t.titleLarge, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  style: t.bodyMedium!.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.error_outline,
    title: 'Something went wrong',
    message: '$error',
    action: onRetry == null ? null : OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
  );
}

String formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

/// Playback position like `0:12`, `12:05` or `1:05:30`.
String formatClock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

String compactCount(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 840;

/// Side margin that keeps settings-style lists at a readable width on wide
/// screens. Used as list padding, so the margins still scroll the list.
double readableInset(double width, [double maxWidth = 640]) => width > maxWidth ? (width - maxWidth) / 2 : 0;
