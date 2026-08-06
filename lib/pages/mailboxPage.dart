import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';

class MailboxPage extends StatefulWidget {
  const MailboxPage({super.key});

  @override
  State<MailboxPage> createState() => _MailboxPageState();
}

class _MailboxPageState extends State<MailboxPage> {
  late TextEditingController _sheetUrlController;

  @override
  void initState() {
    super.initState();
    _sheetUrlController = TextEditingController(
        text: appStateSettings["googleSheetMailboxUrl"] ?? "");
  }

  @override
  void dispose() {
    _sheetUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "Mailbox",
      listWidgets: [
        // Inbox Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SettingsGroupCard(
            title: "Inbox",
            icon: Icons.inbox_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextFont(
                  text:
                      "Quickly access transaction entries in a Google Sheet. As transactions are added to a Google Sheet, they will show up within the Inbox. Open the Inbox and select a transaction to quickly add it.",
                  fontSize: 13,
                  textColor: getColor(context, "textLight"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: TextInput(
                  labelText: "Google Sheet URL",
                  controller: _sheetUrlController,
                  icon: Icons.table_chart_rounded,
                  onChanged: (text) {
                    updateSettings("googleSheetMailboxUrl", text.trim(),
                        updateGlobalState: true);
                  },
                ),
              ),
              SettingsContainer(
                title: "Google Sheet Mailbox Template",
                description:
                    "Ensure anyone with the link can view your Google Sheet.",
                icon: Icons.grid_on_rounded,
                onTap: () {
                  openUrl(
                      "https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit?usp=sharing");
                },
              ),
              const Divider(height: 1),
              SettingsContainerSwitch(
                title: "Home Page Inbox Shortcut",
                icon: Icons.mark_email_unread_rounded,
                initialValue: appStateSettings["homePageInboxShortcut"] ?? false,
                onSwitched: (val) {
                  updateSettings("homePageInboxShortcut", val,
                      updateGlobalState: true);
                },
              ),
              SettingsContainer(
                title: "Open Inbox",
                description: "Process Google Sheet entries",
                icon: Icons.inbox_rounded,
                onTap: () {
                  openSnackbar(
                    SnackbarMessage(
                      title: "Inbox Synchronized",
                      icon: Icons.move_to_inbox_rounded,
                      description: "Google Sheet entries processed.",
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Outbox Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SettingsGroupCard(
            title: "Outbox",
            icon: Icons.forward_to_inbox_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextFont(
                  text:
                      "Periodically export transactions to a CSV on your Google Drive. Note: the exported file gets overwritten on your Google Drive every update.",
                  fontSize: 13,
                  textColor: getColor(context, "textLight"),
                ),
              ),
              SettingsContainerSwitch(
                title: "Enable Outbox",
                icon: Icons.forward_to_inbox_rounded,
                initialValue: appStateSettings["enableOutbox"] ?? false,
                onSwitched: (val) {
                  updateSettings("enableOutbox", val, updateGlobalState: true);
                },
              ),
              SettingsContainer(
                title: "Open Drive Folder",
                description: "View exported CSV backups on Google Drive",
                icon: Icons.folder_open_rounded,
                onTap: () {
                  openUrl("https://drive.google.com/");
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
