import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/errorLog.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/statusBox.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ErrorLogsPage extends StatefulWidget {
  const ErrorLogsPage({super.key});

  @override
  State<ErrorLogsPage> createState() => _ErrorLogsPageState();
}

class _ErrorLogsPageState extends State<ErrorLogsPage> {
  final Set<int> _expandedIndices = {};
  String _selectedTag = "All";
  String _searchQuery = "";

  void _shareAllLogs() {
    final text = exportAllLogsAsText();
    Share.share(text, subject: "Xpenzi Diagnostic & Error Logs");
    HapticFeedback.mediumImpact();
  }

  void _copyAllLogs() {
    final text = exportAllLogsAsText();
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    openSnackbar(
      SnackbarMessage(
        title: "Logs Copied to Clipboard",
        description: "You can now paste and share this report.",
        icon: Icons.copy_rounded,
      ),
    );
  }

  void _clearLogs() {
    openPopup(
      context,
      title: "Clear Error Logs?",
      description: "This will remove all recorded runtime and sign-in diagnostics.",
      icon: Icons.delete_outline_rounded,
      onSubmitLabel: "Clear",
      onSubmit: () {
        popRoute(context);
        clearAppErrorLogs();
        setState(() {});
        openSnackbar(
          SnackbarMessage(
            title: "Logs Cleared",
            icon: Icons.delete_sweep_rounded,
          ),
        );
      },
      onCancelLabel: "Cancel",
      onCancel: () => popRoute(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = getAppErrorLogs();

    // Extract unique tags
    final tags = ["All", ...allLogs.map((e) => e.tag).toSet()];

    // Filter logs by tag and search query
    final logs = allLogs.where((log) {
      final matchesTag = _selectedTag == "All" || log.tag == _selectedTag;
      final matchesQuery = _searchQuery.isEmpty ||
          log.error.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.tag.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (log.extraInfo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesTag && matchesQuery;
    }).toList();

    return PageFramework(
      title: "error-logs".tr(),
      dragDownToDismiss: true,
      actions: [
        if (allLogs.isNotEmpty)
          IconButton(
            tooltip: "Share Logs",
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareAllLogs,
          ),
        if (allLogs.isNotEmpty)
          IconButton(
            tooltip: "copy-error-logs".tr(),
            icon: const Icon(Icons.copy_rounded),
            onPressed: _copyAllLogs,
          ),
        if (allLogs.isNotEmpty)
          IconButton(
            tooltip: "clear-error-logs".tr(),
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _clearLogs,
          ),
      ],
      listWidgets: [
        if (allLogs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: StatusBox(
              title: "No Errors Recorded",
              description:
                  "Everything is running cleanly. Any runtime exceptions or Google Sign-In issues will be captured here automatically.",
              icon: Icons.check_circle_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        else ...[
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search errors or tags...",
                hintStyle: TextStyle(
                  color: getColor(context, "textLight"),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
            ),
          ),
          // Tag Filter Chips
          if (tags.length > 2)
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: tags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final tag = tags[idx];
                  final isSelected = _selectedTag == tag;
                  return ChoiceChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTag = tag;
                        });
                        HapticFeedback.selectionClick();
                      }
                    },
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : getColor(context, "textLight"),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 6),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: StatusBox(
                title: "No Matching Logs",
                description: "Try adjusting your search query or tag filter.",
                icon: Icons.filter_alt_off_rounded,
                color: Theme.of(context).colorScheme.secondary,
              ),
            )
          else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final log = logs[index];
              final isExpanded = _expandedIndices.contains(index);

              Color tagColor = Theme.of(context).colorScheme.error;
              if (log.tag.contains("Google")) {
                tagColor = Colors.orange;
              } else if (log.tag.contains("Auto")) {
                tagColor = Colors.blue;
              }

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: tagColor.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextFont(
                              text: log.tag,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              textColor: tagColor,
                            ),
                          ),
                          const Spacer(),
                          TextFont(
                            text: DateFormat('HH:mm:ss · dd MMM')
                                .format(log.timestamp.toLocal()),
                            fontSize: 11,
                            textColor: getColor(context, "textLight"),
                          ),
                          IconButton(
                            iconSize: 18,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            tooltip: "Copy Error",
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: log.formatForClipboard()));
                              HapticFeedback.lightImpact();
                              openSnackbar(
                                SnackbarMessage(
                                  title: "Error details copied",
                                  icon: Icons.copy_rounded,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        log.error,
                        style: TextStyle(
                          fontFamily: appStateSettings["font"],
                          fontFamilyFallback: const ["Inter"],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (log.extraInfo != null && log.extraInfo!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SelectableText(
                          log.extraInfo!,
                          style: TextStyle(
                            fontFamily: appStateSettings["font"],
                            fontFamilyFallback: const ["Inter"],
                            fontSize: 12,
                            color: getColor(context, "textLight"),
                          ),
                        ),
                      ],
                      if (log.stackTrace != null && log.stackTrace!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Tappable(
                          color: Colors.transparent,
                          borderRadius: 8,
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedIndices.remove(index);
                              } else {
                                _expandedIndices.add(index);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                TextFont(
                                  text: isExpanded
                                      ? "Hide Stack Trace"
                                      : "View Stack Trace",
                                  fontSize: 11.5,
                                  textColor:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              log.stackTrace!,
                              style: const TextStyle(
                                fontFamily: "monospace",
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
