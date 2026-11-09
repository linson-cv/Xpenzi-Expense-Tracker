import 'dart:convert';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReleaseNoteItem {
  final String version;
  final String releaseName;
  final String releasedDate;
  final List<String> majorChanges;
  final List<String> notes;

  ReleaseNoteItem({
    required this.version,
    required this.releaseName,
    required this.releasedDate,
    required this.majorChanges,
    required this.notes,
  });

  factory ReleaseNoteItem.fromJson(Map<String, dynamic> json) {
    return ReleaseNoteItem(
      version: json['version'] ?? '',
      releaseName: json['releaseName'] ?? '',
      releasedDate: json['releasedDate'] ?? '',
      majorChanges: (json['majorChanges'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      notes: (json['notes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

Future<ReleaseNoteItem?> loadLatestReleaseNotes() async {
  try {
    final String jsonString =
        await rootBundle.loadString('assets/release_notes.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    return ReleaseNoteItem.fromJson(data);
  } catch (e) {
    print('Error loading release_notes.json: $e');
    return null;
  }
}

bool showChangelog(
  BuildContext context, {
  bool forceShow = false,
  bool majorChangesOnly = false,
  Widget? extraWidget,
}) {
  final String currentVersion = packageInfoGlobal?.version ?? "1.3.9";
  final int currentVersionInt = parseVersionInt(currentVersion);
  final int lastLoginVersionInt =
      parseVersionInt(appStateSettings["lastLoginVersion"]);

  final bool shouldShow = forceShow ||
      (lastLoginVersionInt != currentVersionInt &&
          (appStateSettings["numLogins"] ?? 0) > 1);

  if (!shouldShow) return false;

  updateSettings(
    "lastLoginVersion",
    currentVersion,
    pagesNeedingRefresh: [],
    updateGlobalState: false,
  );

  openBottomSheet(
    context,
    PopupFramework(
      title: "What's New in Xpenzi",
      subtitle: getVersionString(),
      showCloseButton: true,
      child: FutureBuilder<ReleaseNoteItem?>(
        future: loadLatestReleaseNotes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final release = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (extraWidget != null) extraWidget,
              buildReleaseContent(context, release),
            ],
          );
        },
      ),
    ),
    showScrollbar: true,
  );
  return true;
}

Widget buildReleaseContent(BuildContext context, ReleaseNoteItem release) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Release Header Badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.new_releases_rounded,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            TextFont(
              text: "${release.releaseName} • ${release.releasedDate}",
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),

      // Major Highlights
      if (release.majorChanges.isNotEmpty) ...[
        TextFont(
          text: "Major Highlights",
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 10),
        ...release.majorChanges.map((text) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF131D36)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.star_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: TextFont(
                          text: text,
                          fontSize: 14.5,
                          maxLines: 4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 12),
      ],

      // Regular Notes / Fixes
      if (release.notes.isNotEmpty) ...[
        TextFont(
          text: "Improvements & Fixes",
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 8),
        ...release.notes.map((note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFont(
                      text: note,
                      fontSize: 14,
                      maxLines: 4,
                    ),
                  ),
                ],
              ),
            )),
      ],
      const SizedBox(height: 16),
    ],
  );
}

int parseVersionInt(String versionString) {
  try {
    String cleaned = versionString.trim().split(" ")[0].replaceAll(".", "");
    int parsedVersion = int.parse(cleaned);
    return parsedVersion;
  } catch (e) {
    return 0;
  }
}

String getVersionString() {
  String version = packageInfoGlobal?.version ?? "";
  String buildNumber = packageInfoGlobal?.buildNumber ?? "";
  return "v$version+$buildNumber, db-v$schemaVersionGlobal";
}
