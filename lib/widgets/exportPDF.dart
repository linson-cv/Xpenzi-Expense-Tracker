import 'package:budget/database/tables.dart';
import 'package:budget/functions/pdf_export.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/outlinedButtonStacked.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/pages/addBudgetPage.dart';
import 'package:budget/functions.dart';
import 'package:budget/widgets/util/showDatePicker.dart';
import 'package:drift/drift.dart' hide Column, Table;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:provider/provider.dart';

class ExportPDF extends StatelessWidget {
  const ExportPDF({super.key});

  Future exportPDF({
    required BuildContext boxContext,
    required DateTimeRange? dateTimeRange,
    required List<String>? selectedWalletPks,
  }) async {
    await openLoadingPopupTryCatch(() async {
      List<TransactionWithCategory> transactions = await database
          .getAllTransactionsWithCategoryWalletBudgetObjectiveSubCategory(
        (tbl) =>
            database.onlyShowBasedOnWalletFks(tbl, selectedWalletPks) &
            tbl.paid.equals(true) &
            database.onlyShowBasedOnTimeRange(
              tbl,
              dateTimeRange?.start,
              dateTimeRange?.end,
              null,
            ),
      );
      if (transactions.isEmpty) {
        openSnackbar(SnackbarMessage(
          title: "no-transactions-within-time-range".tr().capitalizeFirstofEach,
          icon: appStateSettings["outlinedIcons"]
              ? Icons.warning_outlined
              : Icons.warning_rounded,
        ));
        return;
      }
      
      await generateTransactionsPDF(transactions, "Transactions Report", Provider.of<AllWallets>(boxContext, listen: false));
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      onTap: () {
        openBottomSheet(
          context,
          PopupFramework(
            title: "Export PDF Report",
            child: ExportPDFPopup(onExport: exportPDF),
          ),
        );
      },
      title: "Export PDF Report",
      description: "Export transactions to a clean, printable PDF statement",
      icon: appStateSettings["outlinedIcons"]
          ? Icons.picture_as_pdf_outlined
          : Icons.picture_as_pdf_rounded,
    );
  }
}

class ExportPDFPopup extends StatefulWidget {
  const ExportPDFPopup({super.key, required this.onExport});
  final Function({
    required BuildContext boxContext,
    required DateTimeRange? dateTimeRange,
    required List<String>? selectedWalletPks,
  }) onExport;

  @override
  State<ExportPDFPopup> createState() => _ExportPDFPopupState();
}

class _ExportPDFPopupState extends State<ExportPDFPopup> {
  List<String>? selectedWallets;
  @override
  void initState() {
    selectedWallets = sharedPreferences.getStringList("exportPDFWalletList");
    if (selectedWallets?.isEmpty == true) selectedWallets = null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WalletChipSelector(
          expand:
              Provider.of<AllWallets>(context, listen: false).list.length > 1,
          onSelected: (selected) {
            selectedWallets = selected;
            sharedPreferences.setStringList(
                "exportPDFWalletList", selected ?? []);
          },
          initiallySelectedWalletFks: selectedWallets,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButtonStacked(
                  text: "all-time".tr().capitalizeFirstofEach,
                  iconData: appStateSettings["outlinedIcons"]
                      ? Icons.all_inclusive_outlined
                      : Icons.all_inclusive_rounded,
                  onTap: () async {
                    popRoute(context);
                    await widget.onExport(
                      boxContext: context,
                      dateTimeRange: null,
                      selectedWalletPks: selectedWallets,
                    );
                  },
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: OutlinedButtonStacked(
                  text: "custom-range".tr().capitalizeFirstofEach,
                  iconData: appStateSettings["outlinedIcons"]
                      ? Icons.date_range_outlined
                      : Icons.date_range_rounded,
                  onTap: () async {
                    popRoute(context);
                    DateTimeRangeOrAllTime dateRange = await showCustomDateRangePicker(
                      context,
                      null,
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                      allTimeButton: false,
                    );
                    if (dateRange.dateTimeRange == null) return;
                    await widget.onExport(
                      boxContext: context,
                      dateTimeRange: dateRange.dateTimeRange,
                      selectedWalletPks: selectedWallets,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
