import 'package:drift/drift.dart' show Value;
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultCategories.dart';

//Initialize default values in database
Future<bool> initializeDefaultDatabase() async {
  //Initialize default categories, but not after a backup load
  if (isDatabaseImportedOnThisSession != true &&
      (await database.getAllCategories()).isEmpty) {
    await createDefaultCategories();
  }

  if ((await database.getAllWallets()).isEmpty) {
    await database.createOrUpdateWallet(
      defaultWallet(),
      customDateTimeModified: DateTime(0),
    );
  }
  return true;
}

Future<bool> createDefaultCategories() async {
  print("Creating default categories");
  for (TransactionCategory category in defaultCategories()) {
    try {
      TransactionCategory? existing =
          await database.getCategoryInstanceOrNull(category.categoryPk);
      if (existing == null) {
        print("Default category ${category.categoryPk} (${category.name}) does not exist, creating");
        await database.createOrUpdateCategory(category,
            customDateTimeModified: DateTime(0));
      } else if (existing.iconName == "pill.png" ||
          existing.iconName == "home.png" ||
          existing.iconName == "gas-pump.png") {
        print("Healing default category ${existing.categoryPk} icon to ${category.iconName}");
        await database.createOrUpdateCategory(
          existing.copyWith(iconName: Value(category.iconName)),
        );
      }
    } catch (e) {
      print("Error checking/creating default category ${category.categoryPk}: $e");
    }
  }
  return true;
}

TransactionWallet defaultWallet() {
  return TransactionWallet(
    walletPk: "0",
    name: "default-account-name".tr(),
    dateCreated: DateTime.now(),
    order: 0,
    currency: getDevicesDefaultCurrencyCode(),
    dateTimeModified: null,
    decimals: 2,
    homePageWidgetDisplay: defaultWalletHomePageWidgetDisplay,
  );
}
