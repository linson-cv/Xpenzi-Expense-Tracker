import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addWalletPage.dart';
import 'package:budget/pages/autoTransactionsPageEmail.dart';
import 'package:budget/pages/settingsPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/navigationSidebar.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/saveBottomButton.dart';
import 'package:budget/widgets/selectCategory.dart';
import 'package:budget/widgets/selectChips.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:budget/colors.dart';
import 'package:provider/provider.dart';

class AddEmailTemplate extends StatefulWidget {
  const AddEmailTemplate({
    super.key,
    required this.messagesList,
    this.scannerTemplate,
  });
  final List<String> messagesList;
  //When a transaction is passed in, we are editing that transaction
  final ScannerTemplate? scannerTemplate;

  @override
  _AddEmailTemplateState createState() => _AddEmailTemplateState();
}

class _AddEmailTemplateState extends State<AddEmailTemplate> {
  int characterPadding = 8;

  bool? canAddTemplate;

  TransactionCategory? selectedCategory;
  String? selectedWalletPk;
  String? selectedMessageString;
  String? selectedName;
  String? selectedSubject;
  String? amountTransactionBefore;
  String? amountTransactionAfter;
  String? selectedAmount;
  String? titleTransactionBefore;
  String? titleTransactionAfter;
  String? selectedTitle;

  ScannerTemplate? templateInitial;

  @override
  void initState() {
    super.initState();
    if (widget.scannerTemplate != null) {
      selectedWalletPk = widget.scannerTemplate!.walletFk == "-1"
          ? null
          : widget.scannerTemplate!.walletFk;
      selectedName = widget.scannerTemplate!.templateName;
      selectedSubject = widget.scannerTemplate!.contains;
      amountTransactionBefore = widget.scannerTemplate!.amountTransactionBefore;
      amountTransactionAfter = widget.scannerTemplate!.amountTransactionAfter;
      titleTransactionBefore = widget.scannerTemplate!.titleTransactionBefore;
      titleTransactionAfter = widget.scannerTemplate!.titleTransactionAfter;
      canAddTemplate = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateInitial();
    });
  }

  updateInitial() async {
    if (widget.scannerTemplate != null) {
      TransactionCategory? getSelectedCategory = await database
          .getCategoryInstanceOrNull(widget.scannerTemplate!.defaultCategoryFk);
      if (getSelectedCategory == null) {
        try {
          getSelectedCategory = await database.getCategoryInstance("0");
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          selectedCategory = getSelectedCategory;
        });
      }
      templateInitial = createTemplate();
      determineBottomButton();
    }
  }

  bool _hasChanges() {
    if (widget.scannerTemplate == null) {
      return (selectedName != null && selectedName!.trim().isNotEmpty) ||
          selectedMessageString != null ||
          selectedSubject != null;
    }
    final initial = templateInitial ?? widget.scannerTemplate;
    if (initial == null) return false;
    return (selectedName ?? "") != initial.templateName ||
        (selectedSubject ?? "") != initial.contains ||
        (selectedCategory?.categoryPk ?? initial.defaultCategoryFk) != initial.defaultCategoryFk ||
        (selectedWalletPk ?? initial.walletFk) != initial.walletFk ||
        (amountTransactionBefore ?? "") != initial.amountTransactionBefore ||
        (amountTransactionAfter ?? "") != initial.amountTransactionAfter ||
        (titleTransactionBefore ?? "") != initial.titleTransactionBefore ||
        (titleTransactionAfter ?? "") != initial.titleTransactionAfter;
  }

  void _handleBack() {
    if (_hasChanges()) {
      discardChangesPopup(
        context,
        forceShow: true,
      );
    } else {
      popRoute(context);
    }
  }

  void showDiscardChangesPopupIfNotEditing() {
    _handleBack();
  }

  @override
  void dispose() {
    super.dispose();
  }

  determineBottomButton() {
    if (selectedName == null || (selectedName?.trim().isEmpty ?? true)) {
      if (mounted) {
        setState(() {
          canAddTemplate = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        canAddTemplate = true;
      });
    }
    return true;
  }

  void setMessageString(String messageString) {
    setState(() {
      selectedMessageString = messageString;
    });
    determineBottomButton();
    return;
  }

  void setSelectedName(String title) {
    setState(() {
      selectedName = title;
    });
    determineBottomButton();
    return;
  }

  void setSelectedCategory(TransactionCategory category) {
    setState(() {
      selectedCategory = category;
    });
    determineBottomButton();
    return;
  }

  void setSelectedWalletPk(String? walletPk) {
    setState(() {
      selectedWalletPk = walletPk;
    });
    determineBottomButton();
    return;
  }

  (String selected, String before, String after)? _extractBounds(
      String text, TextSelection selection) {
    if (text.isEmpty) return null;
    int start = selection.start;
    int end = selection.end;
    if (start < 0 || end < 0 || start >= end) return null;
    start = start.clamp(0, text.length);
    end = end.clamp(0, text.length);
    if (start >= end) return null;

    String selected = text.substring(start, end);
    int beforeStart = (start - characterPadding).clamp(0, text.length);
    String before = text.substring(beforeStart, start);

    int afterEnd = (end + characterPadding).clamp(0, text.length);
    String after = text.substring(end, afterEnd);

    return (selected, before, after);
  }

  String? _extractSubstring(String text, TextSelection selection) {
    if (text.isEmpty) return null;
    int start = selection.start;
    int end = selection.end;
    if (start < 0 || end < 0 || start >= end) return null;
    start = start.clamp(0, text.length);
    end = end.clamp(0, text.length);
    if (start >= end) return null;
    return text.substring(start, end);
  }

  Widget selectSubjectText(String messageString, VoidCallback next) {
    return PopupFramework(
      title: "Select Subject Text",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextFont(
            text: "Only these messages that contain this text will be scanned.",
            fontSize: 14,
            maxLines: 10,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 5),
          const TextFont(
            text:
                "Long press/double tap to select text. Press the 'Done' button at the bottom after selected",
            fontSize: 14,
            maxLines: 10,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadiusDirectional.all(Radius.circular(15)),
              color: getColor(context, "lightDarkAccentHeavy"),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(15),
              child: SelectableText(
                messageString,
                onSelectionChanged: (selection, changeCause) {
                  String? extracted = _extractSubstring(messageString, selection);
                  if (extracted != null && extracted.isNotEmpty) {
                    selectedSubject = extracted;
                    determineBottomButton();
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Button(
            label: "done".tr(),
            onTap: () {
              determineBottomButton();
              setState(() {});
              popRoute(context);
              next();
            },
          )
        ],
      ),
    );
  }

  Widget selectAmountText(String messageString, VoidCallback next) {
    return PopupFramework(
      title: "Select Amount",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextFont(
            text: "Select the amount of the transaction.",
            fontSize: 14,
            fontWeight: FontWeight.bold,
            maxLines: 10,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 5),
          const TextFont(
            text:
                "Long press/double tap to select text. Press the 'Done' button at the bottom after selected",
            fontSize: 14,
            maxLines: 10,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadiusDirectional.all(Radius.circular(15)),
              color: getColor(context, "lightDarkAccentHeavy"),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(15),
              child: SelectableText(
                messageString,
                onSelectionChanged: (selection, changeCause) {
                  var bounds = _extractBounds(messageString, selection);
                  if (bounds != null) {
                    selectedAmount = bounds.$1;
                    amountTransactionBefore = bounds.$2;
                    amountTransactionAfter = bounds.$3;
                    determineBottomButton();
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Button(
            label: "done".tr(),
            onTap: () {
              determineBottomButton();
              popRoute(context);
              setState(() {});
              next();
            },
          )
        ],
      ),
    );
  }

  Widget selectTitleText(String messageString, VoidCallback next) {
    return PopupFramework(
      title: "Select Title",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextFont(
            text: "Select the title of the transaction.",
            fontSize: 14,
            fontWeight: FontWeight.bold,
            maxLines: 10,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 5),
          const TextFont(
            text:
                "Long press/double tap to select text. Press the 'Done' button at the bottom after selected",
            fontSize: 14,
            maxLines: 10,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadiusDirectional.all(Radius.circular(15)),
              color: getColor(context, "lightDarkAccentHeavy"),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(15),
              child: SelectableText(
                messageString,
                onSelectionChanged: (selection, changeCause) {
                  var bounds = _extractBounds(messageString, selection);
                  if (bounds != null) {
                    selectedTitle = bounds.$1;
                    titleTransactionBefore = bounds.$2;
                    titleTransactionAfter = bounds.$3;
                    determineBottomButton();
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Button(
            label: "done".tr(),
            onTap: () {
              determineBottomButton();
              next();
              setState(() {});
              popRoute(context);
            },
          )
        ],
      ),
    );
  }

  Future addTemplate() async {
    print("Added template");
    try {
      ScannerTemplate templateToSave = createTemplate();
      if (templateToSave.templateName.trim().isEmpty) {
        openSnackbar(
          SnackbarMessage(
            title: "Please enter a template name",
            icon: Icons.warning_rounded,
          ),
        );
        return;
      }
      await database.createOrUpdateScannerTemplate(
        insert: widget.scannerTemplate == null,
        templateToSave,
      );
      savingHapticFeedback();
      popRoute(context);
    } catch (e) {
      print("Error saving template: $e");
      openSnackbar(
        SnackbarMessage(
          title: "Error saving template",
          description: e.toString(),
          icon: Icons.error_outline_rounded,
        ),
      );
    }
  }

  ScannerTemplate createTemplate() {
    String templatePk = widget.scannerTemplate?.scannerTemplatePk ?? "";
    if (templatePk.isEmpty || templatePk == "-1") {
      templatePk = uuid.v4();
    }
    return ScannerTemplate(
      scannerTemplatePk: templatePk,
      dateCreated: widget.scannerTemplate?.dateCreated ?? DateTime.now(),
      dateTimeModified: DateTime.now(),
      amountTransactionAfter: amountTransactionAfter ?? "",
      amountTransactionBefore: amountTransactionBefore ?? "",
      contains: selectedSubject ?? "",
      defaultCategoryFk: selectedCategory?.categoryPk ??
          widget.scannerTemplate?.defaultCategoryFk ??
          "0",
      templateName: selectedName ?? widget.scannerTemplate?.templateName ?? "",
      titleTransactionAfter: titleTransactionAfter ?? "",
      titleTransactionBefore: titleTransactionBefore ?? "",
      walletFk: selectedWalletPk ?? widget.scannerTemplate?.walletFk ?? "-1",
      ignore: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleBack();
        return false;
      },
      child: PageFramework(
        staticOverlay: Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: SaveBottomButton(
            label: widget.scannerTemplate == null
                ? "Add Template"
                : "save-changes".tr(),
            onTap: () {
              addTemplate();
            },
            disabled: !(canAddTemplate ?? false),
          ),
        ),
        resizeToAvoidBottomInset: true,
        dragDownToDismissEnabled: true,
        dragDownToDismiss: true,
        title:
            widget.scannerTemplate == null ? "Add Template" : "Edit Template",
        onBackButton: () async {
          _handleBack();
        },
        onDragDownToDismiss: () async {
          _handleBack();
        },
        listWidgets: [
          Container(height: 10),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
            child: TextInput(
              autoFocus: kIsWeb && getIsFullScreen(context),
              labelText: "name-placeholder".tr(),
              bubbly: false,
              initialValue: selectedName,
              onChanged: (text) {
                setSelectedName(text);
              },
              padding: const EdgeInsetsDirectional.only(start: 7, end: 7),
              fontSize: 30,
              fontWeight: FontWeight.bold,
              topContentPadding: 20,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
            child: TextFont(
              text: "Default Category",
              textColor: getColor(context, "textLight"),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
            child: TextFont(
              text:
                  "Categories are also automatically set based on the Associated Title.",
              textColor: getColor(context, "textLight"),
              fontSize: 11,
              maxLines: 5,
            ),
          ),
          const SizedBox(height: 3),
          SelectCategory(
            horizontalList: true,
            selectedCategory: selectedCategory,
            setSelectedCategory: setSelectedCategory,
            popRoute: false,
          ),
          const SizedBox(height: 15),
          SelectChips(
            wrapped: enableDoubleColumn(context),
            extraWidgetBeforeSticky: true,
            allowMultipleSelected: false,
            onLongPress: (TransactionWallet? wallet) {
              pushRoute(
                context,
                AddWalletPage(
                  wallet: wallet,
                  routesToPopAfterDelete: RoutesToPopAfterDelete.PreventDelete,
                ),
              );
            },
            items: <TransactionWallet?>[
              null,
              ...Provider.of<AllWallets>(context).list
            ],
            getSelected: (TransactionWallet? wallet) {
              return selectedWalletPk == wallet?.walletPk;
            },
            onSelected: (TransactionWallet? wallet) {
              setSelectedWalletPk(wallet?.walletPk);
            },
            getCustomBorderColor: (TransactionWallet? item) {
              return dynamicPastel(
                context,
                lightenPastel(
                  HexColor(
                    item?.colour,
                    defaultColor: Theme.of(context).colorScheme.primary,
                  ),
                  amount: 0.3,
                ),
                amount: 0.4,
              );
            },
            getLabel: (TransactionWallet? wallet) {
              if (wallet == null) return "primary-default".tr();
              return getWalletStringName(
                  Provider.of<AllWallets>(context), wallet);
            },
            extraWidgetAfter: const SelectChipsAddButtonExtraWidget(
              openPage: AddWalletPage(
                routesToPopAfterDelete: RoutesToPopAfterDelete.None,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 25),
            child: Button(
                label: "Select Message",
                onTap: () {
                  openBottomSheet(
                    context,
                    PopupFramework(
                      title: "Select Message",
                      hasPadding: false,
                      child: EmailsList(
                        backgroundColor: getColor(context, "white"),
                        messagesList: widget.messagesList,
                        onTap: (messageString) {
                          setMessageString(messageString);
                          popRoute(context);
                          openBottomSheet(
                            context,
                            selectSubjectText(
                              selectedMessageString ?? "",
                              () {
                                openBottomSheet(
                                  context,
                                  selectAmountText(
                                    selectedMessageString ?? "",
                                    () {
                                      openBottomSheet(
                                        context,
                                        selectTitleText(
                                          selectedMessageString ?? "",
                                          () {},
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 15),
            child: selectedMessageString == null
                ? Container()
                : Column(
                    children: [
                      TemplateInfoBox(
                        onTap: () {
                          openBottomSheet(
                            context,
                            selectSubjectText(
                              selectedMessageString ?? "",
                              () {},
                            ),
                          );
                        },
                        selectedText: selectedSubject ?? "",
                        label: "Subject: ",
                        secondaryLabel:
                            "All messages containing this text will be checked.",
                      ),
                      const SizedBox(height: 10),
                      TemplateInfoBox(
                        onTap: () {
                          openBottomSheet(
                            context,
                            selectAmountText(
                              selectedMessageString ?? "",
                              () {},
                            ),
                          );
                        },
                        selectedText: selectedAmount ?? "",
                        label: "Amount: ",
                        secondaryLabel:
                            "The selected amount from this message. Surrounding text will be used to find this amount in new messages.",
                        extraCheck: (input) {
                          return getTransactionAmountFromEmail(
                                selectedMessageString ?? "",
                                amountTransactionBefore ?? "",
                                amountTransactionAfter ?? "",
                              ) !=
                              null;
                        },
                        extraCheckMessage: "Please select a valid number!",
                      ),
                      const SizedBox(height: 10),
                      TemplateInfoBox(
                        onTap: () {
                          openBottomSheet(
                            context,
                            selectTitleText(
                              selectedMessageString ?? "",
                              () {},
                            ),
                          );
                        },
                        selectedText: selectedTitle ?? "",
                        label: "Title: ",
                        secondaryLabel:
                            "The selected title from this message. Surrounding text will be used to find this title in new messages.",
                      ),
                    ],
                  ),
          ),
          widget.scannerTemplate == null && selectedMessageString == null
              ? const SizedBox.shrink()
              : Padding(
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 15),
                  child: Container(
                    margin: const EdgeInsetsDirectional.symmetric(vertical: 10),
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 18, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadiusDirectional.circular(15),
                      color: getColor(context, "lightDarkAccentHeavy"),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TextFont(
                          text: "Sample",
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        TextFont(
                          text: (selectedSubject ?? "").replaceAll("\n", ""),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          maxLines: 10,
                          textColor: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 2),
                        TextFont(
                          text: "${(amountTransactionBefore ?? "")
                                  .replaceAll("\n", "")}... [Amount] ...${(amountTransactionAfter ?? "")
                                  .replaceAll("\n", "")}",
                          fontSize: 16,
                          maxLines: 10,
                          textColor: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 2),
                        TextFont(
                          text: "${(titleTransactionBefore ?? "")
                                  .replaceAll("\n", "")}... [Title] ...${(titleTransactionAfter ?? "")
                                  .replaceAll("\n", "")}",
                          fontSize: 16,
                          maxLines: 10,
                          textColor: Theme.of(context).colorScheme.tertiary,
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }
}

class TemplateInfoBox extends StatelessWidget {
  const TemplateInfoBox(
      {required this.onTap,
      required this.selectedText,
      required this.label,
      required this.secondaryLabel,
      this.extraCheck,
      this.extraCheckMessage,
      super.key});

  final Function() onTap;
  final String selectedText;
  final String label;
  final String secondaryLabel;
  final Function(String)? extraCheck;
  final String? extraCheckMessage;

  @override
  Widget build(BuildContext context) {
    final bool hasError = selectedText == "" ||
        (extraCheck != null && extraCheck!(selectedText) == false);

    return Tappable(
      onTap: onTap,
      color: hasError
          ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.7)
          : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFont(
                  text: label,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  textColor: hasError
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: TextFont(
                    text: selectedText.isEmpty ? "Tap to select..." : selectedText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    textColor: hasError
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onSurface,
                    maxLines: 10,
                  ),
                ),
                Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: hasError
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : getColor(context, "textLight"),
                ),
              ],
            ),
            if (hasError && extraCheckMessage != null && selectedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextFont(
                  fontSize: 12,
                  text: extraCheckMessage ?? "",
                  textColor: Theme.of(context).colorScheme.error,
                  maxLines: 2,
                ),
              ),
            const SizedBox(height: 4),
            TextFont(
              fontSize: 12,
              text: secondaryLabel,
              textColor: hasError
                  ? Theme.of(context).colorScheme.onErrorContainer.withValues(alpha: 0.8)
                  : getColor(context, "textLight"),
              maxLines: 3,
            )
          ],
        ),
      ),
    );
  }
}
