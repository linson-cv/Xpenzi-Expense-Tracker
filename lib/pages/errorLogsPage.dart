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

class ErrorLogsPage extends StatefulWidget {
  const ErrorLogsPage({super.key});

  @override
  State<ErrorLogsPage> createState() => _ErrorLogsPageState();
}

class _ErrorLogsPageState extends State<ErrorLogsPage> {
  final Set<int> _expandedIndices = {};

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
    final logs = getAppErrorLogs();

    return PageFramework(
      title: "Diagnostic & Error Logs",
      dragDownToDismiss: true,
      actions: [
        if (logs.isNotEmpty)
          IconButton(
            tooltip: "Copy All Logs",
            icon: const Icon(Icons.copy_rounded),
            onPressed: _copyAllLogs,
          ),
        if (logs.isNotEmpty)
          IconButton(
            tooltip: "Clear Logs",
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _clearLogs,
          ),
      ],
      listWidgets: [
        if (logs.isEmpty)
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
    );
  }
}
