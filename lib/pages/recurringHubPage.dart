import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/subscriptionsPage.dart';
import 'package:budget/pages/upcomingOverdueTransactionsPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:easy_localization/easy_localization.dart';

class RecurringHubPage extends StatefulWidget {
  final int initialIndex;
  const RecurringHubPage({super.key, this.initialIndex = 0});

  @override
  State<RecurringHubPage> createState() => _RecurringHubPageState();
}

class _RecurringHubPageState extends State<RecurringHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "Recurring & Subscriptions",
      dragDownToDismiss: true,
      floatingActionButton: AnimateFABDelayed(
        fab: AddFAB(
          tooltip: _tabController.index == 0 ? "add-subscription".tr() : "add-upcoming".tr(),
          openPage: AddTransactionPage(
            selectedType: _tabController.index == 0
                ? TransactionSpecialType.subscription
                : TransactionSpecialType.upcoming,
            routesToPopAfterDelete: RoutesToPopAfterDelete.None,
          ),
        ),
      ),
      listWidgets: [
        // Top Projections Summary Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: StreamBuilder<List<Transaction>>(
            stream: database.watchAllUpcomingTransactions(null),
            builder: (context, snapshot) {
              List<Transaction> transactions = snapshot.data ?? [];
              double monthlyEstimate = 0;
              for (var t in transactions) {
                monthlyEstimate += t.amount.abs();
              }
              double annualEstimate = monthlyEstimate * 12;

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: boxShadowGeneral(context),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        TextFont(
                          text: "Recurring Projections",
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFont(
                              text: "Monthly Estimate",
                              fontSize: 13,
                              textColor: getColor(context, "textLight"),
                            ),
                            TextFont(
                              text: convertToMoney(
                                Provider.of<AllWallets>(context),
                                monthlyEstimate,
                              ),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              textColor: getColor(context, "expenseAmount"),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFont(
                              text: "Annual Estimate",
                              fontSize: 13,
                              textColor: getColor(context, "textLight"),
                            ),
                            TextFont(
                              text: convertToMoney(
                                Provider.of<AllWallets>(context),
                                annualEstimate,
                              ),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              textColor: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Subscriptions & Scheduled Tab View Links
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: getColor(context, "lightDarkAccentHeavyLight"),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: getColor(context, "textLight"),
              tabs: const [
                Tab(text: "Subscriptions"),
                Tab(text: "Scheduled Bills"),
              ],
            ),
          ),
        ),

        // Tab Content Height Box
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: const [
              SubscriptionsPage(),
              UpcomingOverdueTransactions(overdueTransactions: null),
            ],
          ),
        ),
      ],
    );
  }
}
