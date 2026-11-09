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
            child: FutureBuilder<ReleaseNoteItem?>(
              future: loadLatestReleaseNotes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return buildReleaseContent(context, snapshot.data!);
              },
            ),
          ),
        ),
      ],
    );
  }
}
