import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../providers.dart';

/// Who is coming, as overlapping avatars (nothing while the person travels alone).
class MemberStack extends ConsumerWidget {
  const MemberStack({super.key, required this.tripId});
  final String tripId;

  static const _shown = 3;
  static const _size = 32.0;
  static const _step = 22.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final members = ref.watch(tripMembersProvider(tripId)).value ?? const <TripMember>[];
    if (members.length < 2) return const SizedBox.shrink();
    final faces = [
      for (final m in members.take(_shown)) m.avatar.isNotEmpty ? m.avatar : (m.displayName.isEmpty ? '?' : m.displayName.characters.first),
      if (members.length > _shown) '+${members.length - _shown}',
    ];
    final tints = [scheme.tertiaryContainer, scheme.primaryContainer, scheme.secondaryContainer, scheme.surfaceContainerHigh];
    return Semantics(
      label: '${members.length} 位成員',
      excludeSemantics: true,
      child: SizedBox(
        width: _size + _step * (faces.length - 1),
        height: _size,
        child: Stack(
          children: [
            for (var i = 0; i < faces.length; i++)
              Positioned(
                left: _step * i,
                child: Container(
                  width: _size,
                  height: _size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tints[i % tints.length],
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surfaceContainerLowest, width: 2),
                  ),
                  child: Text(faces[i], textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
