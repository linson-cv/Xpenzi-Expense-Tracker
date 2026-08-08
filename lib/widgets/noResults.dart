import 'package:budget/colors.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';

class NoResults extends StatefulWidget {
  const NoResults({
    super.key,
    required this.message,
    this.tintColor,
    this.padding,
    this.noSearchResultsVariation = false,
  });
  final String message;
  final Color? tintColor;
  final EdgeInsetsDirectional? padding;
  final bool noSearchResultsVariation;

  @override
  State<NoResults> createState() => _NoResultsState();
}

class _NoResultsState extends State<NoResults> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 200),
      child: Opacity(
        opacity: Theme.of(context).brightness == Brightness.light ? 1 : 0.8,
        child: Center(
          child: Padding(
            padding: widget.padding ??
                EdgeInsetsDirectional.only(
                  top: MediaQuery.sizeOf(context).height * 0.4 > 400 ? 100 : 35,
                  end: 30,
                  start: 30,
                ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _animation.value),
                      child: child,
                    );
                  },
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).height <=
                                MediaQuery.sizeOf(context).width
                            ? MediaQuery.sizeOf(context).height * 0.4 > 400
                                ? 400
                                : MediaQuery.sizeOf(context).height * 0.4
                            : 270),
                    child: appStateSettings["materialYou"]
                        ? ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              !appStateSettings["materialYou"]
                                  ? getColor(context, "black").withValues(alpha: 0.1)
                                  : widget.tintColor == null
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.7)
                                      : widget.tintColor!.withValues(alpha: 0.7),
                              BlendMode.srcATop,
                            ),
                            child: ColorFiltered(
                              colorFilter: greyScale,
                              child: Opacity(
                                opacity: 1,
                                child: Image(
                                  image: widget.noSearchResultsVariation
                                      ? const AssetImage(
                                          "assets/images/no-search-filter.png")
                                      : const AssetImage(
                                          "assets/images/empty-filter.png"),
                                ),
                              ),
                            ),
                          )
                        : Image(
                            image: widget.noSearchResultsVariation
                                ? const AssetImage("assets/images/no-search.png")
                                : const AssetImage("assets/images/empty.png"),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
                TextFont(
                  maxLines: 4,
                  fontSize: 15,
                  text: widget.message,
                  textAlign: TextAlign.center,
                  textColor: getColor(context, "textLight"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
