import 'package:budget/functions.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class MarkdownPage extends StatefulWidget {
  const MarkdownPage({
    super.key,
    required this.url,
    this.title,
  });

  final String url;
  final String? title;

  @override
  State<MarkdownPage> createState() => _MarkdownPageState();
}

class _MarkdownPageState extends State<MarkdownPage> {
  String _content = "";
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  Future<void> _loadMarkdown() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Local asset check for faq.md
      if (widget.url.contains("faq.md") || widget.url.toLowerCase().endsWith("assets/faq.md")) {
        try {
          String localData = await rootBundle.loadString("assets/faq.md");
          if (localData.isNotEmpty) {
            setState(() {
              _content = localData;
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          print("Local asset load error: $e");
        }
      }

      // Convert GitHub web link to raw link if necessary
      String targetUrl = widget.url;
      if (targetUrl.contains("github.com") && targetUrl.contains("/blob/")) {
        targetUrl = targetUrl.replaceAll("github.com", "raw.githubusercontent.com").replaceAll("/blob/", "/");
      }

      final response = await http.get(Uri.parse(targetUrl));
      if (response.statusCode == 200) {
        setState(() {
          _content = response.body;
          _isLoading = false;
        });
      } else {
        // Fallback to local asset if available
        String localData = await rootBundle.loadString("assets/faq.md");
        setState(() {
          _content = localData;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Offline fallback
      try {
        String localData = await rootBundle.loadString("assets/faq.md");
        setState(() {
          _content = localData;
          _isLoading = false;
        });
      } catch (_) {
        setState(() {
          _error = "Unable to load document. Please check your internet connection.";
          _isLoading = false;
        });
      }
    }
  }

  String _deriveTitle() {
    if (widget.title != null && widget.title!.isNotEmpty) {
      return widget.title!;
    }
    if (widget.url.contains("faq.md")) return "FAQ & Guide";
    if (widget.url.contains("PRIVACY.md")) return "Privacy Policy";
    if (widget.url.contains("LICENSE")) return "License";
    if (widget.url.contains("README")) return "Documentation";
    return "Document Viewer";
  }

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: _deriveTitle(),
      dragDownToDismiss: true,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _isLoading
                ? const SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _error != null
                    ? Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: 12),
                          TextFont(text: _error!, textAlign: TextAlign.center, fontSize: 14),
                          const SizedBox(height: 20),
                          Tappable(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: 12,
                            onTap: _loadMarkdown,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              child: TextFont(text: "Retry", fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      )
                    : MarkdownBodyWidget(content: _content),
          ),
        ),
      ],
    );
  }
}

class MarkdownBodyWidget extends StatelessWidget {
  const MarkdownBodyWidget({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final List<String> lines = content.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trimRight();

      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Headers
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: TextFont(
            text: line.substring(2).trim(),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: TextFont(
            text: line.substring(3).trim(),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: TextFont(
            text: line.substring(4).trim(),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ));
      }
      // Bullet points
      else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        String bulletText = line.trim().substring(2);
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 3, bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextFont(text: "• ", fontSize: 15, fontWeight: FontWeight.bold),
              Expanded(
                child: _buildRichText(context, bulletText),
              ),
            ],
          ),
        ));
      }
      // Code blocks
      else if (line.startsWith('```')) {
        List<String> codeLines = [];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        widgets.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFont(
            text: codeLines.join('\n'),
            fontSize: 12,
            textColor: Theme.of(context).colorScheme.onSurface,
          ),
        ));
      }
      // Paragraph text
      else {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _buildRichText(context, line),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichText(BuildContext context, String text) {
    List<InlineSpan> spans = [];

    // Simple markdown inline parser for **bold** and [link](url)
    final RegExp exp = RegExp(r'(\*\*(.*?)\*\*)|(\[(.*?)\]\((.*?)\))');
    int lastMatchEnd = 0;

    for (final Match match in exp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
        ));
      }

      String? fullMatch = match.group(0);
      if (fullMatch != null && fullMatch.startsWith('**')) {
        // Bold
        String boldText = match.group(2) ?? "";
        spans.add(TextSpan(
          text: boldText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
        ));
      } else if (fullMatch != null && fullMatch.startsWith('[')) {
        // Link
        String linkText = match.group(4) ?? "";
        String linkUrl = match.group(5) ?? "";
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () {
              openUrl(linkUrl, context: context);
            },
            child: TextFont(
              text: linkText,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              textColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
