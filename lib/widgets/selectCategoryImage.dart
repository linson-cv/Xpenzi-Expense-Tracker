import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/premiumPage.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/ratingPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/struct/iconObjects.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        child: EmojiSelectorInput(
          onEmojiSelected: (value) {
            widget.setSelectedEmoji(value);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<IconForCategory> filteredIcons = iconObjects
        .where((image) =>
            searchTerm == "" ||
            image.tags.any(
                (item) => item.toLowerCase().contains(searchTerm.toLowerCase())))
        .toList();

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
                      child: TextInput(
                        controller: _searchController,
                        labelText: "search-placeholder".tr(),
                        icon: searchTerm.trim().isNotEmpty
                            ? (appStateSettings["outlinedIcons"]
                                ? Icons.close_outlined
                                : Icons.close_rounded)
                            : (appStateSettings["outlinedIcons"]
                                ? Icons.search_outlined
                                : Icons.search_rounded),
                        iconOnTap: searchTerm.trim().isNotEmpty
                            ? () {
                                _searchController.clear();
                                setState(() {
                                  searchTerm = "";
                                });
                                bottomSheetControllerGlobal.snapToExtent(0);
                              }
                            : null,
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
          const SizedBox(height: 10),
          // // Change icon theme and style button
          // Tappable(
          //   onTap: () {
          //     pushRoute(context, const CategoryIconPackGalleryPage());
          //   },
          //   color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.6),
          //   borderRadius: 14,
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          //     child: Row(
          //       children: [
          //         Icon(
          //           appStateSettings["outlinedIcons"]
          //               ? Icons.category_outlined
          //               : Icons.category_rounded,
          //           size: 22,
          //           color: Theme.of(context).colorScheme.primary,
          //         ),
          //         const SizedBox(width: 12),
          //         Expanded(
          //           child: TextFont(
          //             text: "Change icon theme and style",
          //             fontSize: 14,
          //             fontWeight: FontWeight.w600,
          //             textColor: Theme.of(context).colorScheme.onSecondaryContainer,
          //           ),
          //         ),
          //         Icon(
          //           Icons.chevron_right_rounded,
          //           size: 20,
          //           color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.6),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 12),
          // 5 Columns Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemCount: filteredIcons.length,
            itemBuilder: (context, index) {
              final image = filteredIcons[index];
              return Center(
                child: ImageIcon(
                  sizePadding: 8,
                  margin: EdgeInsetsDirectional.zero,
                  color: Colors.transparent,
                  size: 55,
                  iconPath: "assets/categories/" + image.icon,
                  onTap: () {
                    widget.setSelectedImage(image.icon);
                    if (context.locale.toString() == "en" &&
                        image.mostLikelyCategoryName != null) {
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
                ),
              );
            },
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
        ],
      ),
    );
  }
}

class EmojiSelectorInput extends StatefulWidget {
  const EmojiSelectorInput({required this.onEmojiSelected, super.key});
  final Function(String) onEmojiSelected;

  @override
  State<EmojiSelectorInput> createState() => _EmojiSelectorInputState();
}

class _EmojiSelectorInputState extends State<EmojiSelectorInput> {
  final TextEditingController _controller = TextEditingController();
  bool _showWarning = false;

  static final RegExp _emojiRegex = RegExp(
    r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (value.isEmpty) {
      if (_showWarning) {
        setState(() {
          _showWarning = false;
        });
      }
      return;
    }

    if (_emojiRegex.hasMatch(value)) {
      if (_showWarning) {
        setState(() {
          _showWarning = false;
        });
      }
      // Valid emoji entered, apply and close
      widget.onEmojiSelected(value.trim());
      popRoute(context);
    } else {
      // Non-emoji characters entered
      setState(() {
        _showWarning = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextInput(
          controller: _controller,
          labelText: "${"enter-emoji".tr()} 😀...",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.emoji_emotions_outlined
              : Icons.emoji_emotions_rounded,
          autoFocus: true,
          onChanged: _onChanged,
          onSubmitted: (value) {
            if (_emojiRegex.hasMatch(value)) {
              widget.onEmojiSelected(value.trim());
              popRoute(context);
            } else {
              setState(() {
                _showWarning = true;
              });
            }
          },
        ),
        AnimatedExpanded(
          expand: _showWarning,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
                start: 12, end: 12, top: 8, bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFont(
                    text:
                        "Please enter a valid emoji (e.g. 🍕, 🚗, 💡) instead of letters or text.",
                    fontSize: 12.5,
                    textColor: Theme.of(context).colorScheme.error,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
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
  int selectedPackIndex = appStateSettings["categoryIconPack"] ?? 0;
  int selectedShapeIndex = appStateSettings["categoryIconShape"] ?? 0;

  final List<Map<String, dynamic>> iconPacks = [
    {
      "name": "Standard Colorful",
      "isPro": false,
      "previewIcons": [
        "assets/categories/fast-food.png",
        "assets/categories/groceries.png",
        "assets/categories/shopping.png",
        "assets/categories/tram.png",
      ],
      "iconBgColors": [
        Color(0xFF2C3E50),
        Color(0xFF27AE60),
        Color(0xFFC0392B),
        Color(0xFFF39C12),
      ],
      "monochrome": false,
    },
    {
      "name": "Solid Minimalist",
      "isPro": true,
      "previewIcons": [
        "assets/categories/fast-food.png",
        "assets/categories/groceries.png",
        "assets/categories/shopping.png",
        "assets/categories/tram.png",
      ],
      "iconBgColors": [
        Color(0xFF2B3A42),
        Color(0xFF244837),
        Color(0xFF4A2338),
        Color(0xFF4A4423),
      ],
      "monochrome": true,
      "tint": Color(0xFFBDC3C7),
    },
    {
      "name": "Line Art Outline",
      "isPro": true,
      "previewIcons": [
        "assets/categories/fast-food.png",
        "assets/categories/groceries.png",
        "assets/categories/shopping.png",
        "assets/categories/tram.png",
      ],
      "iconBgColors": [
        Color(0xFF1E2B37),
        Color(0xFF1A382B),
        Color(0xFF3B1A2B),
        Color(0xFF3B351A),
      ],
      "monochrome": true,
      "tint": Color(0xFFF39C12),
    },
  ];

  final List<Map<String, dynamic>> iconShapes = [
    {
      "name": "Circle",
      "isPro": false,
      "radius": 500.0,
      "borderRadius": BorderRadius.circular(500),
    },
    {
      "name": "Rounded Square",
      "isPro": true,
      "radius": 16.0,
      "borderRadius": BorderRadius.circular(16),
    },
    {
      "name": "Smooth Squircle",
      "isPro": true,
      "radius": 24.0,
      "borderRadius": BorderRadius.circular(24),
    },
    {
      "name": "Diamond / Asymmetric",
      "isPro": true,
      "radius": 8.0,
      "borderRadius": BorderRadius.circular(8),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "Theme & Style",
      dragDownToDismiss: true,
      listWidgets: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TextFont(
                  text: "Category Icon Pack",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 14),
                for (int i = 0; i < iconPacks.length; i++) ...[
                  _buildPackCard(context, i, iconPacks[i]),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: getColor(context, "dividerColor"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextFont(
                        text: "Icon Shape",
                        fontSize: 12,
                        textColor: getColor(context, "textLight"),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: getColor(context, "dividerColor"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < iconShapes.length; i++) ...[
                        _buildShapeCard(context, i, iconShapes[i]),
                        const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackCard(BuildContext context, int index, Map<String, dynamic> pack) {
    final bool isSelected = selectedPackIndex == index;
    final bool isPro = pack["isPro"] == true;
    final List<String> previewIcons = pack["previewIcons"] as List<String>;
    final List<Color> bgColors = pack["iconBgColors"] as List<Color>;
    final bool monochrome = pack["monochrome"] == true;
    final Color? tintColor = pack["tint"] as Color?;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Tappable(
          borderRadius: 18,
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          onTap: () {
            if (isPro && appStateSettings["purchaseID"] == null) {
              pushRoute(
                context,
                const PremiumPage(canDismiss: true, popRouteWithPurchase: true),
              );
              return;
            }
            setState(() {
              selectedPackIndex = index;
            });
            updateSettings("categoryIconPack", index, updateGlobalState: true);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                width: isSelected ? 2.2 : 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int j = 0; j < previewIcons.length; j++)
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: bgColors[j],
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(11),
                    child: monochrome
                        ? ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              tintColor ?? Colors.white70,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(previewIcons[j]),
                          )
                        : Image.asset(previewIcons[j]),
                  ),
              ],
            ),
          ),
        ),
        if (isPro)
          Positioned(
            top: -6,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFB4C5E7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextFont(
                text: "Pro",
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                textColor: Color(0xFF1E2D4A),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShapeCard(BuildContext context, int index, Map<String, dynamic> shape) {
    final bool isSelected = selectedShapeIndex == index;
    final bool isPro = shape["isPro"] == true;
    final BorderRadius borderRadius = shape["borderRadius"] as BorderRadius;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Tappable(
          borderRadius: 18,
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          onTap: () {
            if (isPro && appStateSettings["purchaseID"] == null) {
              pushRoute(
                context,
                const PremiumPage(canDismiss: true, popRouteWithPurchase: true),
              );
              return;
            }
            setState(() {
              selectedShapeIndex = index;
            });
            updateSettings("categoryIconShape", index, updateGlobalState: true);
          },
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                width: isSelected ? 2.2 : 1.2,
              ),
            ),
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF93A5CF),
                  borderRadius: borderRadius,
                ),
              ),
            ),
          ),
        ),
        if (isPro)
          Positioned(
            top: -6,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFB4C5E7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const TextFont(
                text: "Pro",
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                textColor: Color(0xFF1E2D4A),
              ),
            ),
          ),
      ],
    );
  }
}
