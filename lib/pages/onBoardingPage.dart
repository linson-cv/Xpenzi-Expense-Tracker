import 'package:budget/colors.dart';
import 'package:budget/database/generatePreviewData.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/addBudgetPage.dart';
import 'package:budget/pages/addObjectivePage.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/languageMap.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/accountAndBackup.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/currencyPicker.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/linearGradientFadedEdges.dart';
import 'package:budget/widgets/moreIcons.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/selectAmount.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/autoTransactionsPageEmail.dart';
import 'package:budget/pages/offlineIntelligencePage.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/viewAllTransactionsButton.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextInput;
import 'package:budget/functions.dart';
import 'package:budget/widgets/radioItems.dart';
import 'package:budget/database/initializeDefaultDatabase.dart';

import 'package:budget/widgets/pageIndicator.dart';

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({
    super.key,
    this.popNavigationWhenDone = false,
    this.showPreviewDemoButton = true,
  });

  final bool popNavigationWhenDone;
  final bool showPreviewDemoButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: OnBoardingPageBody(
            popNavigationWhenDone: popNavigationWhenDone,
            showPreviewDemoButton: showPreviewDemoButton));
  }
}

class OnBoardingPageBody extends StatefulWidget {
  const OnBoardingPageBody({
    super.key,
    this.popNavigationWhenDone = false,
    this.showPreviewDemoButton = true,
  });
  final bool popNavigationWhenDone;
  final bool showPreviewDemoButton;

  @override
  State<OnBoardingPageBody> createState() => OnBoardingPageBodyState();
}

class OnBoardingPageBodyState extends State<OnBoardingPageBody> {
  final PageController controller = PageController();

  bool isGoalSelected = false;
  double? selectedAmount;
  int selectedPeriodLength = 1;
  DateTime selectedStartDate = DateTime.now().firstDayOfMonth();
  DateTime? selectedEndDate;
  String selectedRecurrence = "Monthly";
  bool selectedIncludeIncome = false;
  String selectedGoalTitle = "Savings Goal";

  bool showImage = false;
  final Image imageLanding1 = Image(
    image: AssetImage("assets/landing/Graph.png"),
  );
  final Image imageLanding2 = Image(
    image: AssetImage("assets/landing/BankOrPig.png"),
  );
  final Image imageLanding3 = Image(
    image: AssetImage("assets/landing/PigBank.png"),
  );

  @override
  void didChangeDependencies() {
    precacheImage(imageLanding1.image, context);
    precacheImage(imageLanding2.image, context);
    precacheImage(imageLanding3.image, context);
    super.didChangeDependencies();
  }

  nextNavigation({bool generatePreview = false}) async {
    if (selectedAmount != null && selectedAmount != 0) {
      if (isGoalSelected) {
        int order = (await database.getAllObjectives(objectiveType: ObjectiveType.goal)).length;
        await database.createOrUpdateObjective(
          Objective(
            objectivePk: "-1",
            name: selectedGoalTitle.trim().isEmpty ? "Savings Goal" : selectedGoalTitle.trim(),
            amount: selectedAmount ?? 0,
            order: order,
            colour: "0xff66bb6a",
            dateCreated: selectedStartDate,
            endDate: selectedEndDate,
            dateTimeModified: DateTime.now(),
            iconName: "piggy-bank.png",
            emojiIconName: null,
            income: true,
            pinned: true,
            walletFk: "0",
            archived: false,
            type: ObjectiveType.goal,
          ),
        );
      } else {
        int order = await database.getAmountOfBudgets();
        await database.createOrUpdateBudget(
          insert: true,
          Budget(
            budgetPk: "-1",
            name: "default-budget-name".tr(),
            amount: selectedAmount ?? 0,
            startDate: selectedStartDate,
            endDate: selectedEndDate ?? DateTime.now(),
            addedTransactionsOnly: false,
            periodLength: selectedPeriodLength,
            dateCreated: DateTime.now(),
            pinned: true,
            order: order,
            walletFk: "0",
            reoccurrence: mapRecurrence(selectedRecurrence),
            isAbsoluteSpendingLimit: false,
            budgetTransactionFilters: [
              ...(selectedIncludeIncome == false
                  ? [BudgetTransactionFilters.defaultBudgetTransactionFilters]
                  : [
                      BudgetTransactionFilters.includeIncome,
                      BudgetTransactionFilters.addedToOtherBudget,
                      BudgetTransactionFilters.addedToObjective,
                    ])
            ],
            income: false,
            archived: false,
          ),
        );
      }
    }
    if (generatePreview) {
      openLoadingPopup(context);
      await generatePreviewData();
      popRoute(context);
    }

    bool shouldOpenOfflineIntelligence = false;

    if (getPlatform(ignoreEmulation: true) == PlatformOS.isAndroid &&
        appStateSettings["notificationScanning"] != true &&
        !widget.popNavigationWhenDone) {
      bool isGranted = await NotificationListenerService.isPermissionGranted();
      if (!isGranted && context.mounted) {
        await openPopup(
          context,
          icon: Icons.notifications_active_rounded,
          title: "Auto-Detect Bank SMS & Alerts?",
          description:
              "Xpenzi can automatically capture and parse bank SMS, UPI payments, and card alerts into transactions on this device.\n\n🔒 100% Private: All parsing happens on your phone. No data is sent to external servers.",
          onSubmitLabel: "Enable Auto-Detect",
          onCancelLabel: "Skip for Now",
          onSubmit: () async {
            popRoute(context);
            bool status = await requestReadNotificationPermission(context: context);
            if (status) {
              await updateSettings("notificationScanning", true,
                  updateGlobalState: false);
              initNotificationScanning();
              shouldOpenOfflineIntelligence = true;
            }
          },
          onCancel: () {
            popRoute(context);
          },
        );
      }
    }

    if (widget.popNavigationWhenDone) {
      popRoute(context);
    } else {
      await updateSettings("hasOnboarded", true,
          pagesNeedingRefresh: [0], updateGlobalState: true, forceGlobalStateUpdate: true);
      if (shouldOpenOfflineIntelligence && context.mounted) {
        pushRoute(context, const OfflineIntelligencePage());
      }
    }
  }

  Future<void> continueWithoutSignInWithForcedName(BuildContext context) async {
    String currentName = (appStateSettings["username"] ?? "").toString().trim();
    if (currentName.isEmpty) {
      await openBottomSheet(
        context,
        popupWithKeyboard: true,
        PopupFramework(
          title: "enter-name".tr(),
          child: SelectText(
            buttonLabel: "set-name".tr(),
            icon: appStateSettings["outlinedIcons"]
                ? Icons.person_outlined
                : Icons.person_rounded,
            setSelectedText: (_) {},
            nextWithInput: (text) {
              if (text.trim().isNotEmpty) {
                updateSettings("username", text.trim(),
                    pagesNeedingRefresh: [0], updateGlobalState: true);
              }
            },
            selectedText: appStateSettings["username"],
            placeholder: "nickname".tr(),
            autoFocus: true,
          ),
        ),
      );
    }

    String finalName = (appStateSettings["username"] ?? "").toString().trim();
    if (finalName.isEmpty) {
      openSnackbar(
        SnackbarMessage(
          title: "Please enter your name to continue",
          icon: Icons.person_rounded,
        ),
      );
      return;
    }

    await nextNavigation();
  }

  final FocusNode _focusNode = FocusNode();
  late FocusAttachment _focusAttachment;

  @override
  void initState() {
    super.initState();
    _focusAttachment = _focusNode.attach(context, onKeyEvent: (node, event) {
      if (event.logicalKey.keyLabel == "Go Back" ||
          event.logicalKey == LogicalKeyboardKey.escape) {
        if (widget.popNavigationWhenDone) nextNavigation();
      } else if (event.runtimeType == KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        nextOnBoardPage();
      } else if (event.runtimeType == KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        previousOnBoardPage();
      }
      return KeyEventResult.handled;
    });
    _focusNode.requestFocus();

    Future.delayed(Duration.zero, () async {
      // Functions to run after entire UI loaded - landing page
      // Run here too, so user has a wallet when creating first budget
      // We need to run this after the UI is loaded - after translations are loaded
      await initializeDefaultDatabase();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void nextOnBoardPage() {
    if ((controller.page?.round().toInt() ?? 0) + 1 == numPages) {
      nextNavigation();
    } else {
      controller.nextPage(
        duration: const Duration(milliseconds: 1100),
        curve: const ElasticOutCurve(1.3),
      );
    }
  }

  void previousOnBoardPage() {
    controller.previousPage(
      duration: const Duration(milliseconds: 1100),
      curve: const ElasticOutCurve(1.3),
    );
  }

  int numPages = 3;
  @override
  Widget build(BuildContext context) {
    _focusAttachment.reparent();
    final List<Widget> children = [
      // OnBoardPage(
      //   widgets: [
      //     Container(
      //       constraints: BoxConstraints(
      //           maxWidth: MediaQuery.sizeOf(context).height <=
      //                   MediaQuery.sizeOf(context).width
      //               ? MediaQuery.sizeOf(context).height * 0.5
      //               : 300),
      //       child: Image(
      //         image: AssetImage("assets/landing/DepressedMan.png"),
      //       ),
      //     ),
      //     SizedBox(height: 15),
      //     Padding(
      //       padding: const EdgeInsetsDirectional.symmetric(horizontal: 25),
      //       child: TextFont(
      //         text: "Losing track of your spending?",
      //         fontWeight: FontWeight.bold,
      //         textAlign: TextAlign.center,
      //         fontSize: 25,
      //         maxLines: 5,
      //       ),
      //     ),
      //     SizedBox(height: 15),
      //     Padding(
      //       padding: const EdgeInsetsDirectional.symmetric(horizontal: 25),
      //       child: TextFont(
      //         text: "It's important to be mindful of your purchases.",
      //         textAlign: TextAlign.center,
      //         fontSize: 16,
      //         maxLines: 5,
      //       ),
      //     ),
      //   ],
      // ),
      OnBoardPage(
        widgets: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).height <=
                        MediaQuery.sizeOf(context).width
                    ? MediaQuery.sizeOf(context).height * 0.5
                    : 300),
            child: imageLanding1,
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 25),
            child: TextFont(
              text: "onboarding-title-1".tr(namedArgs: {"app": globalAppName}),
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              fontSize: 25,
              maxLines: 5,
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 25),
            child: TextFont(
              text: "onboarding-info-1".tr(),
              textAlign: TextAlign.center,
              fontSize: 16,
              maxLines: 5,
            ),
          ),
          StreamBuilder<AllWallets>(
            stream: database.watchAllWalletsIndexed(),
            builder: (context, snapshot) {
              TransactionWallet? primaryWallet = snapshot
                  .data?.indexedByPk[appStateSettings["selectedWalletPk"]];
              if (primaryWallet != null) {
                String currencyCode = (primaryWallet.currency ?? "").toUpperCase();
                String currencySymbol = "";
                if (currenciesJSON[primaryWallet.currency] != null &&
                    currenciesJSON[primaryWallet.currency]["Symbol"] != null) {
                  currencySymbol = currenciesJSON[primaryWallet.currency]["Symbol"];
                }
                String currencyDisplay = currencySymbol.isNotEmpty && currencySymbol != currencyCode
                    ? "$currencyCode ($currencySymbol)"
                    : currencyCode;
                String currentLocale = appStateSettings["locale"]?.toString() ?? "System";
                String languageDisplay = languageDisplayFilter(currentLocale);
                int currentDecimals = appStateSettings["amountDecimals"] ?? 2;

                return Padding(
                  padding: const EdgeInsetsDirectional.only(top: 25),
                  child: Column(
                    children: [
                      LowKeyButton(
                        onTap: () {
                          openBottomSheet(
                            context,
                            const SizedBox.shrink(),
                            customBuilder:
                                (context2, scrollController, sheetState) {
                              return CustomScrollView(
                                controller: scrollController,
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: PopupFramework(
                                      title: "select-primary-currency".tr(),
                                      subtitle:
                                          "select-primary-currency-description"
                                              .tr(),
                                      bottomSafeAreaExtraPadding: false,
                                      child: const SizedBox.shrink(),
                                    ),
                                  ),
                                  CurrencyPicker(
                                    showExchangeRateInfoNotice: false,
                                    onSelected: (selectedCurrency) {
                                      popRoute(context);
                                      database.createOrUpdateWallet(
                                          primaryWallet.copyWith(
                                              currency: Value(selectedCurrency)));
                                      setState(() {});
                                    },
                                    initialCurrency: primaryWallet.currency,
                                    onHasFocus: () {},
                                    unSelectedColor: appStateSettings["materialYou"]
                                        ? null
                                        : getColor(context, "canvasContainer"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        text: currencyDisplay.isNotEmpty
                            ? "${"change-currency".tr()}: $currencyDisplay"
                            : "change-currency".tr(),
                      ),
                      const SizedBox(height: 10),
                      LowKeyButton(
                        onTap: () async {
                          openLanguagePicker(context);
                        },
                        text: "${"language".tr()}: $languageDisplay",
                      ),
                      const SizedBox(height: 10),
                      LowKeyButton(
                        onTap: () async {
                          openBottomSheet(
                            context,
                            PopupFramework(
                              title: "decimal-precision".tr(),
                              child: RadioItems(
                                items: const [0, 1, 2],
                                initial: appStateSettings["amountDecimals"],
                                displayFilter: (item) => item.toString(),
                                onChanged: (value) async {
                                  updateSettings("amountDecimals", value,
                                      updateGlobalState: false);
                                  setState(() {});
                                  await Future.delayed(
                                      const Duration(milliseconds: 50));
                                  popRoute(context);
                                },
                              ),
                            ),
                          );
                        },
                        text: "${"decimal-precision".tr()}: $currentDecimals",
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 55),
        ],
        bottomWidget: widget.showPreviewDemoButton
            ? PreviewDemoButton(
                nextNavigation: nextNavigation,
              )
            : null,
      ),
      OnBoardPage(
        widgets: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).height <=
                        MediaQuery.sizeOf(context).width
                    ? MediaQuery.sizeOf(context).height * 0.5
                    : 300),
            child: imageLanding2,
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 25),
            child: TextFont(
              text: isGoalSelected ? "Set Your Savings Goal" : "Set Your Spending Budget",
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              fontSize: 25,
              maxLines: 5,
            ),
          ),
          const SizedBox(height: 10),
          // Toggle Selector for Budget vs Goal
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    avatar: Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 16,
                      color: !isGoalSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    label: TextFont(
                      text: "Budget",
                      fontSize: 13.5,
                      fontWeight: !isGoalSelected ? FontWeight.bold : FontWeight.normal,
                      textColor: !isGoalSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    selected: !isGoalSelected,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          isGoalSelected = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: Icon(
                      Icons.savings_outlined,
                      size: 16,
                      color: isGoalSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    label: TextFont(
                      text: "Savings Goal",
                      fontSize: 13.5,
                      fontWeight: isGoalSelected ? FontWeight.bold : FontWeight.normal,
                      textColor: isGoalSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    selected: isGoalSelected,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          isGoalSelected = true;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (!isGoalSelected)
            BudgetDetails(
              determineBottomButton: () {},
              setSelectedAmount: (amount, _) {
                setState(() {
                  selectedAmount = amount;
                });
              },
              initialSelectedAmount: selectedAmount,
              setSelectedPeriodLength: (length) {
                setState(() {
                  selectedPeriodLength = length;
                });
              },
              initialSelectedPeriodLength: selectedPeriodLength,
              setSelectedRecurrence: (recurrence) {
                setState(() {
                  selectedRecurrence = recurrence;
                });
              },
              initialSelectedRecurrence: selectedRecurrence,
              setSelectedStartDate: (date) {
                setState(() {
                  selectedStartDate = date;
                });
              },
              initialSelectedStartDate: selectedStartDate,
              setSelectedEndDate: (date) {
                setState(() {
                  selectedEndDate = date;
                });
              },
              initialSelectedEndDate: selectedEndDate,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SelectAmount(
                    amountPassed: (selectedAmount ?? 0).toString(),
                    setSelectedAmount: (amount, _) {
                      setState(() {
                        selectedAmount = amount;
                      });
                    },
                    selectedWalletPk: appStateSettings["selectedWalletPk"] ?? "0",
                    setSelectedWalletPk: (_) {},
                    enableWalletPicker: false,
                    onlyShowCurrencyIcon: true,
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
                  ),
                  const SizedBox(height: 10),
                  TextInput(
                    labelText: "Goal Name (e.g. Vacation, Emergency Fund)",
                    initialValue: selectedGoalTitle,
                    icon: Icons.flag_outlined,
                    onChanged: (val) {
                      selectedGoalTitle = val;
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          // Custom / Detailed Creator Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LowKeyButton(
                extraWidget: const Padding(
                  padding: EdgeInsetsDirectional.only(end: 6),
                  child: Icon(Icons.add_circle_outline_rounded, size: 18),
                ),
                extraWidgetAtBeginning: true,
                text: isGoalSelected ? "Custom Goal Options..." : "Custom Budget Options...",
                onTap: () {
                  if (isGoalSelected) {
                    pushRoute(
                      context,
                      const AddObjectivePage(
                        routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                        objectiveType: ObjectiveType.goal,
                      ),
                    );
                  } else {
                    pushRoute(
                      context,
                      const AddBudgetPage(
                        routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 25, vertical: 8),
            child: TextFont(
              text: isGoalSelected
                  ? "Track your target savings, milestones, and dreams with automated progress."
                  : "onboarding-info-2-1".tr(),
              textAlign: TextAlign.center,
              fontSize: 14,
              maxLines: 5,
              textColor: getColor(context, "black").withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
      OnBoardPage(
        widgets: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).height <=
                        MediaQuery.sizeOf(context).width
                    ? MediaQuery.sizeOf(context).height * 0.5
                    : 300),
            child: imageLanding3,
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 25),
            child: TextFont(
              text: "onboarding-title-3".tr(namedArgs: {"app": globalAppName}),
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              fontSize: 25,
              maxLines: 5,
            ),
          ),
          const SizedBox(height: 25),
          getPlatform() == PlatformOS.isIOS
              ? IntrinsicWidth(
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.symmetric(horizontal: 8.0),
                    child: Button(
                      label: "lets-go".tr(),
                      onTap: () {
                        continueWithoutSignInWithForcedName(context);
                      },
                      expandedLayout: false,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          getPlatform() == PlatformOS.isIOS
              ? const SizedBox.shrink()
              : SettingsContainerOutlined(
                  onTap: () async {
                    loadingIndeterminateKey.currentState?.setVisibility(true);
                    openLoadingPopupTryCatch(
                      () async {
                        // Can maybe use this function, but on web first login does not sync...
                        // Let's just use the functionality below this
                        // await signInAndSync(context, next: () {});

                        bool signedIn = await signInGoogle(
                          context: context,
                          waitForCompletion: false,
                          next: () {},
                        );
                        if (signedIn == false || googleUser == null) {
                          loadingIndeterminateKey.currentState
                              ?.setVisibility(false);
                          openSnackbar(
                            SnackbarMessage(
                              title: "Error signing in with Google",
                              icon: MoreIcons.google,
                            ),
                          );
                          return;
                        }
                        if (appStateSettings["username"] == "" &&
                            googleUser != null) {
                          updateSettings(
                              "username", googleUser?.displayName ?? "",
                              pagesNeedingRefresh: [0],
                              updateGlobalState: false);
                        }

                        // set this to true so cloud functions run
                        entireAppLoaded = true;
                        try {
                          await runAllCloudFunctions(
                            context,
                            forceSignIn: true,
                          );
                        } catch (e) {
                          print("Error running cloud functions: $e");
                        }

                        nextNavigation();
                        loadingIndeterminateKey.currentState
                            ?.setVisibility(false);
                      },
                      onError: (e) {
                        print("Error signing in: $e");
                        loadingIndeterminateKey.currentState
                            ?.setVisibility(false);
                        openSnackbar(
                          SnackbarMessage(
                            title: "Error signing in with Google",
                            icon: MoreIcons.google,
                          ),
                        );
                      },
                    );
                  },
                  title: "sign-in-with-google".tr(),
                  icon: MoreIcons.google,
                  isExpanded: false,
                ),
          getPlatform() == PlatformOS.isIOS
              ? const SizedBox.shrink()
              : const SizedBox(height: 8),
          getPlatform() == PlatformOS.isIOS
              ? const SizedBox.shrink()
              : Padding(
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 25),
                  child: TextFont(
                    text: "onboarding-info-3".tr(),
                    textAlign: TextAlign.center,
                    fontSize: 16,
                    maxLines: 5,
                  ),
                ),
          getPlatform() == PlatformOS.isIOS
              ? const SizedBox.shrink()
              : const SizedBox(height: 35),
          getPlatform() == PlatformOS.isIOS
              ? const SizedBox.shrink()
              : LowKeyButton(
                  onTap: () {
                    continueWithoutSignInWithForcedName(context);
                  },
                  text: "continue-without-sign-in".tr(),
                ),
          // IntrinsicWidth(
          //   child: Button(
          //     label: "Let's go!",
          //     onTap: () {
          //       nextNavigation();
          //     },
          //   ),
          // ),
        ],
      ),
    ];

    if (numPages != children.length) {
      print("Error: onboarding pages mismatch in length!");
    }

    return Stack(
      children: [
        PageView(
          controller: controller,
          children: children,
        ),
        PositionedDirectional(
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 100,
              width: 1000,
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: AlignmentDirectional.topCenter,
                  end: AlignmentDirectional.bottomCenter,
                  stops: const [0.1, 1],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
                bottom: MediaQuery.viewPaddingOf(context).bottom),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedBuilder(
                      animation: controller,
                      builder: (BuildContext context, Widget? child) {
                        int currentIndex =
                            controller.page?.round().toInt() ?? 0;
                        return AnimatedOpacity(
                          opacity: currentIndex <= 0 ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: ButtonIcon(
                            onTap: () {
                              previousOnBoardPage();
                            },
                            icon: getPlatform() == PlatformOS.isIOS
                                ? appStateSettings["outlinedIcons"]
                                    ? Icons.chevron_left_outlined
                                    : Icons.chevron_left_rounded
                                : appStateSettings["outlinedIcons"]
                                    ? Icons.arrow_back_outlined
                                    : Icons.arrow_back_rounded,
                            size: 50,
                            padding: getIsFullScreen(context) == false
                                ? const EdgeInsetsDirectional.all(3)
                                : const EdgeInsetsDirectional.all(6),
                          ),
                        );
                      },
                    ),
                    PageIndicator(
                        controller: controller, itemCount: children.length),
                    AnimatedBuilder(
                      animation: controller,
                      builder: (BuildContext context, Widget? child) {
                        int currentIndex =
                            controller.page?.round().toInt() ?? 0;
                        return AnimatedOpacity(
                          opacity: getPlatform() == PlatformOS.isIOS
                              ? 1
                              : currentIndex >= children.length - 1
                                  ? 0
                                  : 1,
                          duration: const Duration(milliseconds: 200),
                          child: ButtonIcon(
                            onTap: () => nextOnBoardPage(),
                            icon: getPlatform() == PlatformOS.isIOS
                                ? appStateSettings["outlinedIcons"]
                                    ? Icons.chevron_right_outlined
                                    : Icons.chevron_right_rounded
                                : appStateSettings["outlinedIcons"]
                                    ? Icons.arrow_forward_outlined
                                    : Icons.arrow_forward_rounded,
                            size: 50,
                            padding: getIsFullScreen(context) == false
                                ? const EdgeInsetsDirectional.all(3)
                                : const EdgeInsetsDirectional.all(6),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OnBoardPage extends StatelessWidget {
  const OnBoardPage({super.key, required this.widgets, this.bottomWidget});
  final List<Widget> widgets;
  final Widget? bottomWidget;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: LinearGradientFadedEdges(
            gradientSize: 20,
            enableTop: getPlatform() == PlatformOS.isIOS,
            enableBottom: getPlatform() == PlatformOS.isIOS,
            enableStart: false,
            enableEnd: false,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                Column(
                  children: [
                    const SizedBox(height: 20),
                    ...widgets,
                    const SizedBox(height: 80),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(
              bottom: 60 + MediaQuery.paddingOf(context).bottom),
          child: Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: bottomWidget ?? const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
