import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:easy_localization/easy_localization.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  String _faqContent = "Loading FAQ...";

  @override
  void initState() {
    super.initState();
    _loadFAQ();
  }

  Future<void> _loadFAQ() async {
    try {
      final String content = await rootBundle.loadString('assets/faq.md');
      setState(() {
        _faqContent = content;
      });
    } catch (e) {
      setState(() {
        _faqContent = "Failed to load FAQ content.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "guide-and-faq".tr(),
      dragDownToDismiss: true,
      listWidgets: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: MarkdownBody(
            data: _faqContent,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h1: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              h2: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, height: 2.0),
              p: Theme.of(context).textTheme.bodyLarge,
              listBullet: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}
