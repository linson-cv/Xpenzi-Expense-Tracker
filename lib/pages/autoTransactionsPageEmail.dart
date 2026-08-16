import 'dart:async';
import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart' hide AppSettings;
import 'package:budget/pages/addEmailTemplate.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/notificationEngine.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/accountAndBackup.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/openContainerNavigation.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/statusBox.dart';
import 'package:budget/widgets/tappable.dart';
import 'dart:convert';
import 'package:budget/pages/editCategoriesPage.dart';
import 'package:budget/struct/autoTransactionTracker.dart';
import 'package:budget/widgets/categoryIcon.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:budget/functions.dart';
import 'package:googleapis/gmail/v1.dart' as gMail;
import 'package:html/parser.dart';
import 'package:provider/provider.dart';
import 'addButton.dart';

export 'package:budget/struct/notificationEngine.dart';

class AutoTransactionsPageEmail extends StatefulWidget {
  const AutoTransactionsPageEmail({super.key});

  @override
  State<AutoTransactionsPageEmail> createState() =>
      _AutoTransactionsPageEmailState();
}

class _AutoTransactionsPageEmailState extends State<AutoTransactionsPageEmail> {
  bool canReadEmails =
      appStateSettings["AutoTransactions-canReadEmails"] ?? false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      if (canReadEmails == true && googleUser == null) {
        await signInGoogle(
            context: context, waitForCompletion: true, gMailPermissions: true);
        updateSettings("AutoTransactions-canReadEmails", true,
            pagesNeedingRefresh: [3], updateGlobalState: false);
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      dragDownToDismiss: true,
      title: "Advanced Automation",
      actions: [
        RefreshButton(onTap: () async {
          loadingIndeterminateKey.currentState?.setVisibility(true);
          await parseEmailsInBackground(context,
              sayUpdates: true, forceParse: true);
          loadingIndeterminateKey.currentState?.setVisibility(false);
        }),
      ],
      listWidgets: [
        SettingsGroupCard(
          title: "Mailbox Connection & Overview",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.mark_email_read_outlined
              : Icons.mark_email_read_rounded,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFont(
                    text:
                        "Connect your Google account to automatically scan and parse transaction receipts from your bank or payment services on launch. Emails are read securely and parsed locally.",
                    fontSize: 13.5,
                    textColor: getColor(context, "textLight"),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: canReadEmails && googleUser != null
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              canReadEmails && googleUser != null
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              size: 14,
                              color: canReadEmails && googleUser != null
                                  ? Theme.of(context).colorScheme.primary
                                  : getColor(context, "textLight"),
                            ),
                            const SizedBox(width: 5),
                            TextFont(
                              text: canReadEmails && googleUser != null
                                  ? (googleUser?.email ?? "Connected")
                                  : "Requires Google Sign-In",
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              textColor: canReadEmails && googleUser != null
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : getColor(context, "textLight"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SettingsContainerSwitch(
              onSwitched: (value) async {
                if (value == true) {
                  bool result = await signInGoogle(
                      context: context,
                      waitForCompletion: true,
                      gMailPermissions: true);
                  if (result == false) {
                    return false;
                  }
                  setState(() {
                    canReadEmails = true;
                  });
                  updateSettings("AutoTransactions-canReadEmails", true,
                      pagesNeedingRefresh: [3], updateGlobalState: false);
                } else {
                  setState(() {
                    canReadEmails = false;
                  });
                  updateSettings("AutoTransactions-canReadEmails", false,
                      updateGlobalState: false, pagesNeedingRefresh: [3]);
                }
              },
              title: "Scan Emails on App Launch",
              description:
                  "Checks recent inbox emails on launch. Each transaction is parsed only once.",
              initialValue: canReadEmails,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.mark_email_unread_outlined
                  : Icons.mark_email_unread_rounded,
            ),
          ],
        ),
        if (canReadEmails && googleUser != null)
          const GmailApiScreen()
        else if (canReadEmails && googleUser == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: StatusBox(
              title: "Google Sign-In Required",
              description: "Tap the switch above to sign in and authorize read-only Gmail access for bank receipts.",
              icon: Icons.account_circle_outlined,
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
      ],
    );
  }
}

Future<void> parseEmailsInBackground(context,
    {bool sayUpdates = false, bool forceParse = false}) async {
  if (appStateSettings["hasSignedIn"] == false) return;
  if (errorSigningInDuringCloud == true) return;
  if (appStateSettings["emailScanning"] == false) return;
  // Prevent sign-in on web - background sign-in cannot access Google Drive etc.
  if (kIsWeb && !entireAppLoaded) return;
  // print(entireAppLoaded);
  //Only run this once, don't run again if the global state changes (e.g. when changing a setting)
  if (entireAppLoaded == false || forceParse) {
    if (appStateSettings["AutoTransactions-canReadEmails"] == true) {
      List<Transaction> transactionsToAdd = [];
      Stopwatch stopwatch = Stopwatch()..start();
      print("Scanning emails");

      bool hasSignedIn = false;
      if (googleUser == null) {
        hasSignedIn = await signInGoogle(
            context: context,
            gMailPermissions: true,
            waitForCompletion: false,
            silentSignIn: true);
      } else {
        hasSignedIn = true;
      }
      if (hasSignedIn == false) {
        return;
      }

      List<dynamic> emailsParsed =
          appStateSettings["EmailAutoTransactions-emailsParsed"] ?? [];
      int amountOfEmails =
          appStateSettings["EmailAutoTransactions-amountOfEmails"] ?? 10;
      int newEmailCount = 0;

      final authHeaders = await googleUser!.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      gMail.GmailApi gmailApi = gMail.GmailApi(authenticateClient);
      gMail.ListMessagesResponse results = await gmailApi.users.messages
          .list(googleUser!.id.toString(), maxResults: amountOfEmails);

      int currentEmailIndex = 0;

      List<ScannerTemplate> scannerTemplates =
          await database.getAllScannerTemplates();
      if (scannerTemplates.isEmpty) {
        openSnackbar(
          SnackbarMessage(
            title:
                "You have not setup the email scanning configuration in settings.",
            onTap: () {
              pushRoute(
                context,
                const AutoTransactionsPageEmail(),
              );
            },
          ),
        );
      }
      for (gMail.Message message in results.messages!) {
        currentEmailIndex++;
        loadingProgressKey.currentState
            ?.setProgressPercentage(currentEmailIndex / amountOfEmails);
        // await Future.delayed(Duration(milliseconds: 1000));

        // Remove this to always parse emails
        if (emailsParsed.contains(message.id!)) {
          print("Already checked this email!");
          continue;
        }
        newEmailCount++;

        gMail.Message messageData = await gmailApi.users.messages
            .get(googleUser!.id.toString(), message.id!);
        DateTime messageDate = DateTime.fromMillisecondsSinceEpoch(
            int.parse(messageData.internalDate ?? ""));
        String messageString = getEmailMessage(messageData);
        print("Adding transaction based on email");

        String? title;
        double? amountDouble;

        bool doesEmailContain = false;
        ScannerTemplate? templateFound;
        for (ScannerTemplate scannerTemplate in scannerTemplates) {
          if (messageString.contains(scannerTemplate.contains)) {
            doesEmailContain = true;
            templateFound = scannerTemplate;
            title = getTransactionTitleFromEmail(
              messageString,
              scannerTemplate.titleTransactionBefore,
              scannerTemplate.titleTransactionAfter,
            );
            amountDouble = getTransactionAmountFromEmail(
              messageString,
              scannerTemplate.amountTransactionBefore,
              scannerTemplate.amountTransactionAfter,
            );
            break;
          }
        }

        if (doesEmailContain == false) {
          emailsParsed.insert(0, message.id!);
          continue;
        }

        if (title == null) {
          openSnackbar(
            SnackbarMessage(
              title:
                  "Couldn't find title in email. Check the email settings page for more information.",
              onTap: () {
                pushRoute(
                  context,
                  const AutoTransactionsPageEmail(),
                );
              },
            ),
          );
          emailsParsed.insert(0, message.id!);
          continue;
        } else if (amountDouble == null) {
          openSnackbar(
            SnackbarMessage(
              title:
                  "Couldn't find amount in email. Check the email settings page for more information.",
              onTap: () {
                pushRoute(
                  context,
                  const AutoTransactionsPageEmail(),
                );
              },
            ),
          );

          emailsParsed.insert(0, message.id!);
          continue;
        }

        TransactionAssociatedTitleWithCategory? foundTitle =
            (await database.getSimilarAssociatedTitles(title: title, limit: 1))
                .firstOrNull;

        TransactionCategory? selectedCategory = foundTitle?.category;
        if (selectedCategory == null) continue;

        title = filterEmailTitle(title);

        await addAssociatedTitles(title, selectedCategory);

        Transaction transactionToAdd = Transaction(
          transactionPk: "-1",
          name: title,
          amount: (amountDouble).abs() * (selectedCategory.income ? 1 : -1),
          note: "",
          categoryFk: selectedCategory.categoryPk,
          walletFk: appStateSettings["selectedWalletPk"],
          dateCreated: messageDate,
          dateTimeModified: null,
          income: selectedCategory.income,
          paid: true,
          skipPaid: false,
          methodAdded: MethodAdded.email,
        );
        transactionsToAdd.add(transactionToAdd);
        openSnackbar(
          SnackbarMessage(
            title: "${templateFound!.templateName}: From Email",
            description: title,
            icon: appStateSettings["outlinedIcons"]
                ? Icons.payments_outlined
                : Icons.payments_rounded,
          ),
        );
        gmailApi.users.messages.modify(
          gMail.ModifyMessageRequest(removeLabelIds: ["UNREAD"]),
          googleUser!.id,
          message.id!,
        );

        emailsParsed.insert(0, message.id!);
      }
      // wait for intro animation to finish
      if (const Duration(milliseconds: 2500) > stopwatch.elapsed) {
        print("waited extra${const Duration(milliseconds: 2500) - stopwatch.elapsed}");
        await Future.delayed(
            const Duration(milliseconds: 2500) - stopwatch.elapsed, () {});
      }
      for (Transaction transaction in transactionsToAdd) {
        registerAutoAddedTransaction(
            transaction.name, transaction.amount.abs());
        await database.createOrUpdateTransaction(insert: true, transaction);
      }
      List<dynamic> emails = [
        ...emailsParsed
            .take(appStateSettings["EmailAutoTransactions-amountOfEmails"] + 10)
      ];
      updateSettings(
        "EmailAutoTransactions-emailsParsed",
        emails, // Keep 10 extra in case maybe the user deleted some emails recently
        updateGlobalState: false,
      );
      if (newEmailCount > 0 || sayUpdates == true) {
        openSnackbar(
          SnackbarMessage(
            title: "Scanned ${results.messages!.length} emails",
            description: newEmailCount.toString() +
                pluralString(newEmailCount == 1, " new email"),
            icon: appStateSettings["outlinedIcons"]
                ? Icons.mark_email_unread_outlined
                : Icons.mark_email_unread_rounded,
            onTap: () {
              pushRoute(context, const AutoTransactionsPageEmail());
            },
          ),
        );
      }
    }
  }
}

String? getTransactionTitleFromEmail(String messageString,
    String titleTransactionBefore, String titleTransactionAfter) {
  String? title;
  try {
    int startIndex = messageString.indexOf(titleTransactionBefore) +
        titleTransactionBefore.length;
    int endIndex = messageString.indexOf(titleTransactionAfter, startIndex);
    title = messageString.substring(startIndex, endIndex);
    title = title.replaceAll("\n", "");
    title = title.toLowerCase();
    title = title.capitalizeFirst;
  } catch (e) {}
  return title;
}

double? getTransactionAmountFromEmail(String messageString,
    String amountTransactionBefore, String amountTransactionAfter) {
  double? amountDouble;
  try {
    int startIndex = messageString.indexOf(amountTransactionBefore) +
        amountTransactionBefore.length;
    int endIndex = messageString.indexOf(amountTransactionAfter, startIndex);
    String amountString = messageString.substring(startIndex, endIndex);
    amountDouble = double.parse(amountString.replaceAll(RegExp('[^0-9.]'), ''));
  } catch (e) {}
  return amountDouble;
}

class GmailApiScreen extends StatefulWidget {
  const GmailApiScreen({super.key});

  @override
  _GmailApiScreenState createState() => _GmailApiScreenState();
}

class _GmailApiScreenState extends State<GmailApiScreen> {
  bool loaded = false;
  bool loading = false;
  String error = "";
  int amountOfEmails =
      appStateSettings["EmailAutoTransactions-amountOfEmails"] ?? 10;

  late gMail.GmailApi gmailApi;
  List<String> messagesList = [];

  @override
  void initState() {
    super.initState();
  }

  init() async {
    loading = true;
    if (googleUser != null) {
      try {
        final authHeaders = await googleUser!.authHeaders;
        final authenticateClient = GoogleAuthClient(authHeaders);
        gMail.GmailApi gmailApi = gMail.GmailApi(authenticateClient);
        gMail.ListMessagesResponse results = await gmailApi.users.messages
            .list(googleUser!.id.toString(), maxResults: amountOfEmails);
        setState(() {
          loaded = true;
          error = "";
        });
        int currentEmailIndex = 0;
        for (gMail.Message message in results.messages!) {
          gMail.Message messageData = await gmailApi.users.messages
              .get(googleUser!.id.toString(), message.id!);
          // print(DateTime.fromMillisecondsSinceEpoch(
          //     int.parse(messageData.internalDate ?? "")));
          String emailMessageString = getEmailMessage(messageData);
          messagesList.add(emailMessageString);
          currentEmailIndex++;
          loadingProgressKey.currentState
              ?.setProgressPercentage(currentEmailIndex / amountOfEmails);
          if (mounted) {
            setState(() {});
          } else {
            loadingProgressKey.currentState?.setProgressPercentage(0);
            break;
          }
        }
      } catch (e) {
        setState(() {
          loaded = true;
          error = e.toString();
        });
      }
    }
    loading = false;
  }

  @override
  Widget build(BuildContext context) {
    if (googleUser == null) {
      return const SizedBox();
    } else if (error != "" || (loaded == false && loading == false)) {
      init();
    }
    if (error != "") {
      return Padding(
        padding: const EdgeInsetsDirectional.only(
          top: 28.0,
          start: 20,
          end: 20,
        ),
        child: Center(
          child: TextFont(
            text: error,
            fontSize: 15,
            textAlign: TextAlign.center,
            maxLines: 10,
          ),
        ),
      );
    }
    if (loaded) {
      // If the Future is complete, display the preview.

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsGroupCard(
            title: "Scanning Parameters",
            icon: appStateSettings["outlinedIcons"]
                ? Icons.tune_outlined
                : Icons.tune_rounded,
            children: [
              SettingsContainerDropdown(
                title: "Amount to Parse",
                description:
                    "The number of recent emails to check for transaction receipts.",
                initial: (amountOfEmails).toString(),
                items: const ["5", "10", "15", "20", "25"],
                onChanged: (value) {
                  updateSettings(
                    "EmailAutoTransactions-amountOfEmails",
                    int.parse(value),
                    updateGlobalState: false,
                  );
                },
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.format_list_numbered_outlined
                    : Icons.format_list_numbered_rounded,
              ),
            ],
          ),
          SettingsGroupCard(
            title: "Parser Templates",
            icon: appStateSettings["outlinedIcons"]
                ? Icons.rule_folder_outlined
                : Icons.rule_folder_rounded,
            children: [
              StreamBuilder<List<ScannerTemplate>>(
                stream: database.watchAllScannerTemplates(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: StatusBox(
                          title: "Email Configuration Missing",
                          description: "Please add a template configuration.",
                          icon: appStateSettings["outlinedIcons"]
                              ? Icons.warning_outlined
                              : Icons.warning_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (ScannerTemplate scannerTemplate in snapshot.data!)
                          ScannerTemplateEntry(
                            messagesList: messagesList,
                            scannerTemplate: scannerTemplate,
                          )
                      ],
                    );
                  } else {
                    return Container();
                  }
                },
              ),
              OpenContainerNavigation(
                openPage: AddEmailTemplate(
                  messagesList: messagesList,
                ),
                borderRadius: 15,
                button: (openContainer) {
                  return Row(
                    children: [
                      Expanded(
                        child: AddButton(
                          margin: const EdgeInsetsDirectional.only(
                            start: 15,
                            end: 15,
                            bottom: 9,
                            top: 4,
                          ),
                          onTap: openContainer,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          EmailsList(messagesList: messagesList)
        ],
      );
    } else {
      return const Padding(
        padding: EdgeInsetsDirectional.only(top: 28.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
  }
}

class ScannerTemplateEntry extends StatelessWidget {
  const ScannerTemplateEntry({
    required this.scannerTemplate,
    required this.messagesList,
    super.key,
  });
  final ScannerTemplate scannerTemplate;
  final List<String> messagesList;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15, end: 15, bottom: 10),
      child: OpenContainerNavigation(
        openPage: AddEmailTemplate(
          messagesList: messagesList,
          scannerTemplate: scannerTemplate,
        ),
        borderRadius: 15,
        button: (openContainer) {
          return Tappable(
            borderRadius: 15,
            color: getColor(context, "lightDarkAccent"),
            onTap: openContainer,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 7,
                end: 15,
                top: 5,
                bottom: 5,
              ),
              child: Row(
                children: [
                  CategoryIcon(
                    categoryPk: scannerTemplate.defaultCategoryFk,
                    size: 25,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFont(
                      text: scannerTemplate.templateName,
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ButtonIcon(
                    onTap: () async {
                      DeletePopupAction? action = await openDeletePopup(
                        context,
                        title: "Delete template?",
                        subtitle: scannerTemplate.templateName,
                      );
                      if (action == DeletePopupAction.Delete) {
                        await database.deleteScannerTemplate(
                            scannerTemplate.scannerTemplatePk);
                        popRoute(context);
                        openSnackbar(
                          SnackbarMessage(
                            title: "Deleted ${scannerTemplate.templateName}",
                            icon: Icons.delete,
                          ),
                        );
                      }
                    },
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.delete_outlined
                        : Icons.delete_rounded,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String parseHtmlString(String htmlString) {
  final document = parse(htmlString);
  final String parsedString = parse(document.body!.text).documentElement!.text;

  return parsedString;
}

class EmailsList extends StatelessWidget {
  const EmailsList({
    required this.messagesList,
    this.onTap,
    this.backgroundColor,
    super.key,
  });
  final List<String> messagesList;
  final Function(String)? onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScannerTemplate>>(
      stream: database.watchAllScannerTemplates(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<ScannerTemplate> scannerTemplates = snapshot.data!;
          List<Widget> messageTxt = [];
          for (String messageString in messagesList) {
            bool doesEmailContain = false;
            String? title;
            double? amountDouble;
            String? templateFound;

            for (ScannerTemplate scannerTemplate in scannerTemplates) {
              if (messageString.contains(scannerTemplate.contains)) {
                doesEmailContain = true;
                templateFound = scannerTemplate.templateName;
                title = getTransactionTitleFromEmail(
                    messageString,
                    scannerTemplate.titleTransactionBefore,
                    scannerTemplate.titleTransactionAfter);
                amountDouble = getTransactionAmountFromEmail(
                    messageString,
                    scannerTemplate.amountTransactionBefore,
                    scannerTemplate.amountTransactionAfter);
                break;
              }
            }

            messageTxt.add(
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 15, vertical: 5),
                child: Tappable(
                  borderRadius: 15,
                  color: doesEmailContain &&
                          (title == null || amountDouble == null)
                      ? Theme.of(context)
                          .colorScheme
                          .selectableColorRed
                          .withValues(alpha: 0.5)
                      : doesEmailContain
                          ? Theme.of(context)
                              .colorScheme
                              .selectableColorGreen
                              .withValues(alpha: 0.5)
                          : backgroundColor ??
                              getColor(context, "lightDarkAccent"),
                  onTap: () {
                    if (onTap != null) onTap!(messageString);
                    if (onTap == null) {
                      queueTransactionFromMessage(messageString);
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              doesEmailContain &&
                                      (title == null || amountDouble == null)
                                  ? const Padding(
                                      padding: EdgeInsetsDirectional.only(
                                          bottom: 5),
                                      child: TextFont(
                                        text: "Parsing failed.",
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    )
                                  : const SizedBox(),
                              doesEmailContain
                                  ? templateFound == null
                                      ? const TextFont(
                                          fontSize: 19,
                                          text: "Template Not found.",
                                          maxLines: 10,
                                          fontWeight: FontWeight.bold,
                                        )
                                      : TextFont(
                                          fontSize: 19,
                                          text: templateFound,
                                          maxLines: 10,
                                          fontWeight: FontWeight.bold,
                                        )
                                  : const SizedBox(),
                              doesEmailContain
                                  ? title == null
                                      ? const TextFont(
                                          fontSize: 15,
                                          text: "Title: Not found.",
                                          maxLines: 10,
                                          fontWeight: FontWeight.bold,
                                        )
                                      : TextFont(
                                          fontSize: 15,
                                          text: "Title: $title",
                                          maxLines: 10,
                                          fontWeight: FontWeight.bold,
                                        )
                                  : const SizedBox(),
                              doesEmailContain
                                  ? amountDouble == null
                                      ? const Padding(
                                          padding:
                                              EdgeInsetsDirectional.only(
                                                  bottom: 8.0),
                                          child: TextFont(
                                            fontSize: 15,
                                            text:
                                                "Amount: Not found / invalid number.",
                                            maxLines: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  bottom: 8.0),
                                          child: TextFont(
                                            fontSize: 15,
                                            text: "Amount: ${convertToMoney(
                                                    Provider.of<AllWallets>(
                                                        context),
                                                    amountDouble)}",
                                            maxLines: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                  : const SizedBox(),
                              TextFont(
                                fontSize: 13,
                                text: messageString,
                                maxLines: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return Column(
            children: messageTxt,
          );
        } else {
          return Container(width: 100, height: 100, color: Colors.white);
        }
      },
    );
  }
}

String getEmailMessage(gMail.Message messageData) {
  String messageEncoded = messageData.payload?.parts?[0].body?.data ?? "";
  String messageString;
  if (messageEncoded == "") {
    gMail.MessagePart payload = messageData.payload!;
    try {
      String htmlString = utf8
          .decode(payload.body!.dataAsBytes)
          .replaceAll("[^\\x00-\\x7F]", "");
      String parsedString = parseHtmlString(htmlString);
      messageString = parsedString;
    } catch (e) {
      messageString = "${messageData.snippet ?? ""}\n\nThere was an error getting the rest of the email";
    }
  } else {
    messageString = parseHtmlString(utf8.decode(base64.decode(messageEncoded)));
  }
  return messageString
      .split(RegExp(r"[ \t\r\f\v]+"))
      .join(" ")
      .replaceAll(RegExp(r'(?:[\t ]*(?:\r?\n|\r))+'), '\n\n')
      .replaceAll(RegExp(r"(?<=\n) +"), "");
}
