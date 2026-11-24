import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../favorites/ui/favorite_event_button.dart';
import '../../trips/providers.dart';
import '../data/events_api.dart';
import '../domain/event_logic.dart';

/// Whether a person is signed in (a session that needs sign-in again still counts).
final eventsSignedInProvider = Provider<bool>((ref) => ref.watch(accountIdProvider) != null);

/// Tells a guest the action needs an account and offers to sign in. [next] is where to come back to.
Future<void> promptSignIn(BuildContext context, {String next = Routes.explore}) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('登入後使用'),
      content: const Text('申請、留言、按讚、舉報和建立揪團都需要先登入。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        FilledButton(
          key: const ValueKey('events-signin-confirm'),
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('登入'),
        ),
      ],
    ),
  );
  if (go == true && context.mounted) context.push(Routes.withQuery(Routes.login, {'next': next}));
}

/// Opens the create form, or asks a guest to sign in first.
Future<void> openCreateEvent(BuildContext context, WidgetRef ref) async {
  if (!ref.read(eventsSignedInProvider)) return promptSignIn(context);
  await context.push(Routes.eventNew);
}

/// Asks for a short text. Returns null when cancelled; the text may be empty unless [required].
Future<String?> askText(
  BuildContext context, {
  required String title,
  required String confirm,
  String? hint,
  String? message,
  int maxLength = 500,
  bool required = false,
  bool destructive = false,
  Key? fieldKey,
  Key? confirmKey,
}) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      var error = false;
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(message)),
              TextField(
                key: fieldKey,
                controller: c,
                autofocus: true,
                maxLength: maxLength,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(hintText: hint, errorText: error ? '請輸入內容' : null),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              key: confirmKey,
              style: FilledButton.styleFrom(
                minimumSize: const Size(88, 44),
                backgroundColor: destructive ? Theme.of(ctx).colorScheme.error : null,
                foregroundColor: destructive ? Theme.of(ctx).colorScheme.onError : null,
              ),
              onPressed: () {
                final t = c.text.trim();
                if (required && t.isEmpty) return setState(() => error = true);
                Navigator.pop(ctx, t);
              },
              child: Text(confirm),
            ),
          ],
        ),
      );
    },
  );
}

/// A yes/no question; the yes button is red when [destructive].
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  bool destructive = false,
  String cancel = '取消',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancel)),
        FilledButton(
          key: const ValueKey('confirm-yes'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(88, 44),
            backgroundColor: destructive ? Theme.of(ctx).colorScheme.error : null,
            foregroundColor: destructive ? Theme.of(ctx).colorScheme.onError : null,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Avatar (an emoji) with the name.
class PersonLine extends StatelessWidget {
  const PersonLine(this.person, {super.key, this.style});
  final EventPerson person;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          child: Text(person.avatar.isEmpty ? '🙂' : person.avatar, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(person.displayName, overflow: TextOverflow.ellipsis, style: style),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.warn = false});
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: warn ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: warn ? scheme.onErrorContainer : scheme.onSecondaryContainer),
      ),
    );
  }
}

/// Small tags of an event: category, my state, event state.
class EventTags extends StatelessWidget {
  const EventTags(this.event, {super.key, required this.today});
  final EventSummary event;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _Tag(event.category.label),
        if (event.isHost) const _Tag('我主辦'),
        if (!event.isHost && event.myStatus == ApplicationStatus.approved) const _Tag('已加入'),
        if (!event.isHost && event.myStatus == ApplicationStatus.pending) const _Tag('審核中'),
        if (event.status == EventStatus.cancelled)
          const _Tag('已取消', warn: true)
        else if (event.status == EventStatus.closed)
          const _Tag('報名已關閉', warn: true)
        else if (isExpired(event.startDate, today))
          const _Tag('已過期', warn: true)
        else if (isFull(event))
          const _Tag('已額滿', warn: true),
      ],
    );
  }
}

/// A row of the event list.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.today, required this.onTap});
  final EventSummary event;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: EventTags(event, today: today)),
                  FavoriteEventButton(eventId: event.id, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              Text(event.title, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                [
                  if (event.location.isNotEmpty) event.location,
                  formatEventDates(event.startDate, event.endDate),
                ].join('  ·  '),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: PersonLine(event.host, style: theme.textTheme.bodySmall)),
                  const Icon(Icons.group_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text(peopleLabel(event.approvedCount, event.maxMembers), style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Icon(event.liked ? Icons.favorite : Icons.favorite_border, size: 16),
                  const SizedBox(width: 4),
                  Text('${event.likeCount}', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  const Icon(Icons.chat_bubble_outline, size: 16),
                  const SizedBox(width: 4),
                  Text('${event.commentCount}', style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Message with a retry button, for failed loads.
class RetryMessage extends StatelessWidget {
  const RetryMessage({super.key, required this.text, required this.onRetry});
  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('重試')),
        ],
      ),
    );
  }
}
