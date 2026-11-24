import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'open_link.dart';

final _urlPattern = RegExp(r'https?://[^\s<>"　-〿＀-￯]+');

/// The web addresses found in [text], without trailing punctuation.
List<({int start, int end, String url})> findLinks(String text) => [
  for (final m in _urlPattern.allMatches(text))
    (start: m.start, end: m.start + _trimmed(m.group(0)!).length, url: _trimmed(m.group(0)!)),
];

String _trimmed(String url) => url.replaceFirst(RegExp(r'[.,;:!?)\]}]+$'), '');

/// Text in which every web address can be tapped; it opens in the phone's browser.
/// Use it wherever people can type free text (descriptions, comments, notes) or data carries links.
class LinkText extends ConsumerStatefulWidget {
  const LinkText(this.text, {super.key, this.style, this.maxLines, this.overflow, this.linkLabel});
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Replaces the shown address (e.g. with the site's name); the tap still opens the full address.
  final String Function(String url)? linkLabel;

  @override
  ConsumerState<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends ConsumerState<LinkText> {
  final _recognizers = <TapGestureRecognizer>[];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final theme = Theme.of(context);
    final base = widget.style ?? DefaultTextStyle.of(context).style;
    final linkStyle = base.copyWith(color: theme.colorScheme.primary, decoration: TextDecoration.underline);
    final spans = <InlineSpan>[];
    var at = 0;
    for (final link in findLinks(widget.text)) {
      if (link.start > at) spans.add(TextSpan(text: widget.text.substring(at, link.start)));
      final recognizer = TapGestureRecognizer()
        ..onTap = () async {
          final messenger = ScaffoldMessenger.of(context);
          final opened = await ref.read(linkOpenerProvider)(Uri.parse(link.url));
          if (!opened) {
            messenger.showSnackBar(const SnackBar(content: Text('無法開啟這個連結')));
          }
        };
      _recognizers.add(recognizer);
      spans.add(TextSpan(text: widget.linkLabel?.call(link.url) ?? link.url, style: linkStyle, recognizer: recognizer));
      at = link.end;
    }
    if (at < widget.text.length) spans.add(TextSpan(text: widget.text.substring(at)));
    return Text.rich(TextSpan(children: spans), style: widget.style, maxLines: widget.maxLines, overflow: widget.overflow);
  }
}

/// A short readable name for a source address: the site, e.g. `zh.wikipedia.org`.
String siteName(String url) => Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? url;
