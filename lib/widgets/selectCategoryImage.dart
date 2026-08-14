import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/premiumPage.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/ratingPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/struct/iconObjects.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextInput;

// Future<List<String>> getCategoryImages() async {
//   final manifestContent = await rootBundle.loadString('AssetManifest.json');

//   final Map<String, dynamic> manifestMap = json.decode(manifestContent);

//   final List<String> imagePaths = manifestMap.keys
//       .where((String key) => key.contains('categories/'))
//       .where((String key) => key.contains('.png'))
//       .toList();

//   return imagePaths;
// }

class SelectCategoryImage extends StatefulWidget {
  const SelectCategoryImage({
    super.key,
    required this.setSelectedImage,
    this.selectedImage,
    required this.setSelectedTitle,
    required this.setSelectedEmoji,
    this.next,
  });

  final Function(String?) setSelectedImage;
  final String? selectedImage;
  final Function(String?) setSelectedTitle;
  final Function(String?) setSelectedEmoji;
  final VoidCallback? next;

  @override
  _SelectCategoryImageState createState() => _SelectCategoryImageState();
}

class _SelectCategoryImageState extends State<SelectCategoryImage> {
  String? selectedImage;
  String searchTerm = "";
  bool isEmoji = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedImage != null) {
      setState(() {
        selectedImage =
            widget.selectedImage!.replaceAll("assets/categories/", "");
      });
    }
  }

  void openEmojiSelectorPopup() {
    openBottomSheet(
      context,
      popupWithKeyboard: true,
      PopupFramework(
        title: "enter-emoji".tr(),
        child: SelectText(
          buttonLabel: null,
          icon: appStateSettings["outlinedIcons"]
              ? Icons.emoji_emotions_outlined
              : Icons.emoji_emotions_rounded,
          setSelectedText: (value) {
            widget.setSelectedEmoji(value);
          },
          popContextWhenSet: true,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(
                r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])'))
          ],
          placeholder: "${"enter-emoji-placeholder".tr()} 😀...",
          autoFocus: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8.0),
      child: Column(
        children: [
          context.locale.toString() != "en"
              ? UseEmoji(onTap: () {
                  popRoute(context);
                  openEmojiSelectorPopup();
                })
              : const SizedBox.shrink(),
          context.locale.toString() == "en"
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child:
                          // Focus(
                          //   onFocusChange: (value) {
                          //     if (value) {
                          //       // Fix over-scroll stretch when keyboard pops up quickly
                          //       Future.delayed(Duration(milliseconds: 100), () {
                          //         bottomSheetControllerGlobal.scrollTo(0,
                          //             duration: Duration(milliseconds: 100));
                          //       });
                          //       // Update the size of the bottom sheet
                          //       Future.delayed(Duration(milliseconds: 500), () {
                          //         bottomSheetControllerGlobal.snapToExtent(0);
                          //       });
                          //     }
                          //   },
                          // child:
                          TextInput(
                        labelText: "search-placeholder".tr(),
                        icon: appStateSettings["outlinedIcons"]
                            ? Icons.search_outlined
                            : Icons.search_rounded,
                        onSubmitted: (value) {},
                        onChanged: (value) {
                          setState(() {
                            searchTerm = value.trim();
                          });
                          bottomSheetControllerGlobal.snapToExtent(0);
                        },
                        padding: const EdgeInsetsDirectional.all(0),
                        autoFocus: kIsWeb,
                      ),
                      // ),
                    ),
                    const SizedBox(width: 10),
                    ButtonIcon(
                      onTap: () {
                        popRoute(context);
                        openEmojiSelectorPopup();
                      },
                      icon: appStateSettings["outlinedIcons"]
                          ? Icons.emoji_emotions_outlined
                          : Icons.emoji_emotions_rounded,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
          const SizedBox(height: 5),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: iconObjects.map((IconForCategory image) {
                bool show = false;
                if (searchTerm != "") {
                  for (int i = 0; i < image.tags.length; i++) {
                    if (image.tags[i]
                        .toLowerCase()
                        .contains(searchTerm.toLowerCase())) {
                      show = true;
                      break;
                    }
                  }
                } else {
                  show = true;
                }
                if (show) {
                  return ImageIcon(
                    sizePadding: 8,
                    margin: const EdgeInsetsDirectional.all(5),
                    color: Colors.transparent,
                    size: 55,
                    iconPath: "assets/categories/${image.icon}",
                    onTap: () {
                      widget.setSelectedImage(image.icon);
                      if (context.locale.toString() == "en") {
                        widget.setSelectedTitle(image.mostLikelyCategoryName);
                      }
                      setState(() {
                        selectedImage = image.icon;
                      });
                      Future.delayed(const Duration(milliseconds: 70), () {
                        popRoute(context);
                        if (widget.next != null) {
                          widget.next!();
                        }
                      });
                    },
                    outline: selectedImage == image.icon,
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
          ),
          context.locale.toString() == "en"
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(top: 8.0),
                  child: UseEmoji(onTap: () {
                    popRoute(context);
                    openEmojiSelectorPopup();
                  }),
                )
              : const SizedBox.shrink(),
          const Padding(
            padding: EdgeInsetsDirectional.only(top: 8.0),
            child: SuggestIcon(),
          ),
          const Padding(
            padding: EdgeInsetsDirectional.only(top: 8.0),
            child: ProIconPackBanner(),
          ),
        ],
      ),
    );
  }
}

class ProIconPackBanner extends StatelessWidget {
  const ProIconPackBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: () {
        pushRoute(
          context,
          const PremiumPage(canDismiss: true, popRouteWithPurchase: true),
        );
      },
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.8),
      borderRadius: 15,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
            start: 15, end: 12, top: 12, bottom: 12),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Icon(
                appStateSettings["outlinedIcons"]
                    ? Icons.workspace_premium_outlined
                    : Icons.workspace_premium_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 31,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TextFont(
                        text: "Pro Icon Packs",
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const TextFont(
                          text: "PRO",
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  TextFont(
                    text: "Unlock exclusive HD category icon collections & custom packs",
                    fontSize: 12,
                    textColor: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
            Icon(
              appStateSettings["outlinedIcons"]
                  ? Icons.chevron_right_outlined
                  : Icons.chevron_right_rounded,
              size: 25,
            ),
          ],
        ),
      ),
    );
  }
}

class UseEmoji extends StatelessWidget {
  const UseEmoji({required this.onTap, super.key});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.7),
      borderRadius: 15,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
            start: 15, end: 10, top: 12, bottom: 12),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Icon(
                appStateSettings["outlinedIcons"]
                    ? Icons.emoji_emotions_outlined
                    : Icons.emoji_emotions_rounded,
                color: Theme.of(context).colorScheme.secondary,
                size: 31,
              ),
            ),
            Expanded(
              child: TextFont(
                textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                text: "use-emoji-details".tr(),
                maxLines: 5,
                fontSize: 14,
              ),
            ),
            Icon(
              appStateSettings["outlinedIcons"]
                  ? Icons.chevron_right_outlined
                  : Icons.chevron_right_rounded,
              size: 25,
            ),
          ],
        ),
      ),
    );
  }
}

class SuggestIcon extends StatelessWidget {
  const SuggestIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: () {
        openBottomSheet(
          context,
          const SuggestIconPopup(),
          popupWithKeyboard: true,
          reAssignBottomSheetControllerGlobal: false,
          useCustomController: true,
        );
      },
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.7),
      borderRadius: 15,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
            start: 15, end: 10, top: 12, bottom: 12),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Icon(
                appStateSettings["outlinedIcons"]
                    ? Icons.reviews_outlined
                    : Icons.reviews_rounded,
                color: Theme.of(context).colorScheme.secondary,
                size: 31,
              ),
            ),
            Expanded(
              child: TextFont(
                textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                text: "icon-suggestion-details".tr(),
                maxLines: 5,
                fontSize: 14,
              ),
            ),
            Icon(
              appStateSettings["outlinedIcons"]
                  ? Icons.chevron_right_outlined
                  : Icons.chevron_right_rounded,
              size: 25,
            ),
          ],
        ),
      ),
    );
  }
}

class SuggestIconPopup extends StatefulWidget {
  const SuggestIconPopup({super.key});

  @override
  State<SuggestIconPopup> createState() => _SuggestIconPopupState();
}

class _SuggestIconPopupState extends State<SuggestIconPopup> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "suggest-icon".tr(),
      child: Column(
        children: [
          TextInput(
            labelText: "suggestion".tr(),
            keyboardType: TextInputType.multiline,
            maxLines: null,
            minLines: 3,
            padding: EdgeInsetsDirectional.zero,
            controller: _feedbackController,
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 10),
          Opacity(
            opacity: 0.4,
            child: TextFont(
              text: "icon-suggestion-privacy".tr(),
              textAlign: TextAlign.center,
              fontSize: 12,
              maxLines: 5,
            ),
          ),
          const SizedBox(height: 15),
          Button(
            label: "submit".tr(),
            onTap: () async {
              shareFeedback(_feedbackController.text, "icon");
              popRoute(context);
            },
            disabled: _feedbackController.text == "",
          )
        ],
      ),
    );
  }
}

class ImageIcon extends StatelessWidget {
  const ImageIcon({
    super.key,
    required this.color,
    required this.size,
    this.onTap,
    this.margin,
    this.sizePadding = 20,
    this.outline = false,
    this.iconPath,
  });

  final Color color;
  final double size;
  final VoidCallback? onTap;
  final EdgeInsetsDirectional? margin;
  final double sizePadding;
  final bool outline;
  final String? iconPath;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: margin ??
          const EdgeInsetsDirectional.only(start: 8, end: 8, top: 8, bottom: 8),
      height: size,
      width: size,
      decoration: outline
          ? BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                width: 2,
              ),
              borderRadius: const BorderRadiusDirectional.all(Radius.circular(500)),
            )
          : BoxDecoration(
              border: Border.all(
                color: color,
                width: 0,
              ),
              borderRadius: const BorderRadiusDirectional.all(Radius.circular(500)),
            ),
      child: Tappable(
        color: color,
        onTap: onTap,
        borderRadius: 500,
        child: Padding(
          padding: EdgeInsetsDirectional.all(sizePadding),
          child: Image(
            image: AssetImage(iconPath ?? ""),
            width: size,
          ),
        ),
      ),
    );
  }
}

class CategoryIconPackGalleryPage extends StatefulWidget {
  const CategoryIconPackGalleryPage({super.key});

  @override
  State<CategoryIconPackGalleryPage> createState() =>
      _CategoryIconPackGalleryPageState();
}

class _CategoryIconPackGalleryPageState
    extends State<CategoryIconPackGalleryPage> {
  String search = "";
  String? selectedCategoryFilter;
  final TextEditingController _searchController = TextEditingController();

  final List<String> popularCategories = const [
    "All",
    "Food",
    "Shopping",
    "Transportation",
    "Entertainment",
    "Bills",
    "Health",
    "Finance",
    "Travel",
    "Education",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredIcons = iconObjects.where((item) {
      if (selectedCategoryFilter != null && selectedCategoryFilter != "All") {
        final cat = selectedCategoryFilter!.toLowerCase();
        final matchesCat = (item.mostLikelyCategoryName?.toLowerCase().contains(cat) ?? false) ||
            item.tags.any((t) => t.toLowerCase().contains(cat));
        if (!matchesCat) return false;
      }
      if (search.trim().isEmpty) return true;
      final q = search.toLowerCase().trim();
      return item.icon.toLowerCase().contains(q) ||
          item.tags.any((t) => t.toLowerCase().contains(q)) ||
          (item.mostLikelyCategoryName?.toLowerCase().contains(q) ?? false);
    }).toList();

    return PageFramework(
      title: "Icon Packs & Gallery",
      dragDownToDismiss: true,
      listWidgets: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: TextInput(
            labelText: "Search ${iconObjects.length}+ Icons...",
            icon: Icons.search_rounded,
            controller: _searchController,
            onChanged: (val) => setState(() => search = val),
          ),
        ),
        // Category Filter Chips
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: popularCategories.length,
            itemBuilder: (context, index) {
              final cat = popularCategories[index];
              final isSelected = (selectedCategoryFilter == null && cat == "All") ||
                  selectedCategoryFilter == cat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: TextFont(
                    text: cat,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    textColor: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: getColor(context, "lightDarkAccent"),
                  onSelected: (selected) {
                    setState(() {
                      selectedCategoryFilter = cat == "All" ? null : cat;
                    });
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TextFont(
                        text: "All 450+ HD Icons Available",
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 2),
                      TextFont(
                        text: "Tap any icon to view preview. Pro icons are unlocked for premium subscribers.",
                        fontSize: 11.5,
                        textColor: getColor(context, "textLight"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: filteredIcons.length,
            itemBuilder: (context, index) {
              final iconObj = filteredIcons[index];
              return Tappable(
                color: getColor(context, "lightDarkAccent"),
                borderRadius: 14,
                onTap: () {
                  openPopup(
                    context,
                    title: iconObj.mostLikelyCategoryName ?? "Category Icon",
                    description: "Tags: ${iconObj.tags.take(5).join(', ')}",
                    beforeDescriptionWidget: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image(
                        image: AssetImage("assets/categories/${iconObj.icon}"),
                        width: 64,
                        height: 64,
                      ),
                    ),
                    onSubmit: () => popRoute(context),
                    onSubmitLabel: "Done",
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image(
                    image: AssetImage("assets/categories/${iconObj.icon}"),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
