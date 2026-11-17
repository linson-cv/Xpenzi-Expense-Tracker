import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/showChangelog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DetailedChangelogPage extends StatelessWidget {
  const DetailedChangelogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      dragDownToDismiss: true,
      title: "changelog".tr(),
      horizontalPaddingConstrained: true,
      getExtraHorizontalPadding: (_) => 20,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: FutureBuilder<List<ReleaseNoteItem>>(
              future: loadAllReleaseNotes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final releases = snapshot.data!;
                if (releases.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < releases.length; i++) ...[
                      if (i > 0) ...[
                        const Divider(height: 32),
                        const SizedBox(height: 4),
                      ],
                      buildReleaseContent(context, releases[i]),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
