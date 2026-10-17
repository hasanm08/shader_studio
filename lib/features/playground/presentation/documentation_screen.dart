import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shader_studio/app/theme/app_theme.dart';

/// Renders one documentation asset with a small Markdown subset.
///
/// Headings, paragraphs, bullet lists, fenced code, and pipe tables are
/// supported. That covers the sample guides. It is not a general Markdown
/// engine, and it does not fetch anything outside the asset bundle.
class DocumentationScreen extends StatelessWidget {
  /// Opens the markdown file at [assetPath].
  const DocumentationScreen({
    required this.title,
    required this.assetPath,
    super.key,
  });

  /// App bar title.
  final String title;

  /// Asset key, for example `docs/samples/LIQUID_AURORA.md`.
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not open $assetPath\n${snapshot.error}'),
            );
          }
          final text = snapshot.data;
          if (text == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }
          return SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              children: [MarkdownView(source: text)],
            ),
          );
        },
      ),
    );
  }
}

/// A readable subset of Markdown used by the in-app guides.
class MarkdownView extends StatelessWidget {
  /// Parses [source] once per build.
  const MarkdownView({required this.source, super.key});

  /// Markdown text.
  final String source;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _blocks(context, source),
    );
  }
}

List<Widget> _blocks(BuildContext context, String source) {
  final widgets = <Widget>[];
  final lines = source.split('\n');
  final paragraph = StringBuffer();
  final bullets = <String>[];
  final table = <List<String>>[];

  void flushParagraph() {
    final text = paragraph.toString().trim();
    paragraph.clear();
    if (text.isEmpty) {
      return;
    }
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  void flushBullets() {
    if (bullets.isEmpty) {
      return;
    }
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final bullet in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $bullet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
    bullets.clear();
  }

  void flushTable() {
    if (table.isEmpty) {
      return;
    }
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final row in table)
                if (!_isSeparator(row))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      row.join('   '),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
    table.clear();
  }

  var inCode = false;
  final code = StringBuffer();
  for (final line in lines) {
    if (line.startsWith('```')) {
      if (inCode) {
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              code.toString().trimRight(),
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.text,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        );
        code.clear();
        inCode = false;
      } else {
        flushParagraph();
        flushBullets();
        flushTable();
        inCode = true;
      }
      continue;
    }
    if (inCode) {
      code.writeln(line);
      continue;
    }
    if (line.startsWith('|')) {
      flushParagraph();
      flushBullets();
      table.add(_splitRow(line));
      continue;
    }
    flushTable();
    if (line.startsWith('# ')) {
      flushParagraph();
      flushBullets();
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Text(
            line.substring(2),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      );
      continue;
    }
    if (line.startsWith('## ')) {
      flushParagraph();
      flushBullets();
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Text(
            line.substring(3),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
      continue;
    }
    if (line.startsWith('### ')) {
      flushParagraph();
      flushBullets();
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line.substring(4),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
      continue;
    }
    if (line.startsWith('- ')) {
      flushParagraph();
      bullets.add(line.substring(2));
      continue;
    }
    if (line.trim().isEmpty) {
      flushParagraph();
      flushBullets();
      continue;
    }
    flushBullets();
    if (paragraph.isNotEmpty) {
      paragraph.write(' ');
    }
    paragraph.write(line.trim());
  }
  flushParagraph();
  flushBullets();
  flushTable();
  return widgets;
}

List<String> _splitRow(String line) {
  return line
      .split('|')
      .map((cell) => cell.trim())
      .where((cell) => cell.isNotEmpty)
      .toList();
}

bool _isSeparator(List<String> row) {
  if (row.isEmpty) {
    return false;
  }
  for (final cell in row) {
    if (!RegExp(r'^:?-+:?$').hasMatch(cell)) {
      return false;
    }
  }
  return true;
}
