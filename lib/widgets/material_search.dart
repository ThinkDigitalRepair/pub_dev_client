// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide SearchDelegate;
import 'package:tavern/src/enums.dart';

/// Shows a full screen search page and returns the search result selected by
/// the user when the page is closed.
///
/// The search page consists of an app bar with a search field and a body which
/// can either show suggested search queries or the search results.
///
/// The appearance of the search page is determined by the provided
/// `delegate`. The initial query string is given by `query`, which defaults
/// to the empty string. When `query` is set to null, `delegate.query` will
/// be used as the initial query.
///
/// This method returns the selected search result, which can be set in the
/// [SearchDelegate.close] call. If the search page is closed with the system
/// back button, it returns null.
///
/// A given [SearchDelegate] can only be associated with one active [showSearch]
/// call. Call [SearchDelegate.close] before re-using the same delegate instance
/// for another [showSearch] call.
///
/// The transition to the search page triggered by this method looks best if the
/// screen triggering the transition contains an [AppBar] at the top and the
/// transition is called from an [IconButton] that's part of [AppBar.actions].
/// The animation provided by [SearchDelegate.transitionAnimation] can be used
/// to trigger additional animations in the underlying page while the search
/// page fades in or out. This is commonly used to animate an [AnimatedIcon] in
/// the [AppBar.leading] position e.g. from the hamburger menu to the back arrow
/// used to exit the search page.
///
/// See also:
///
///  * [SearchDelegate] to define the content of the search page.
Future<T> showSearch<T>({
  @required BuildContext context,
  @required SearchDelegate<T> delegate,
  String query = '',
}) {
  assert(delegate != null);
  assert(context != null);
  delegate.query = query ?? delegate.query;
  delegate._currentBody = _SearchBody.suggestions;
  return Navigator.of(context).pushNamed(
    Routes.searchScreen,
    arguments: delegate,
  );
}

/// Delegate for [showSearch] to define the content of the search page.

/// The body below the [AppBar] can either show suggested queries (returned by
/// [SearchDelegate.buildSuggestions]) or - once the user submits a search  - the
/// results of the search as returned by [SearchDelegate.buildResults].
///
/// [SearchDelegate.query] always contains the current query entered by the user
/// and should be used to build the suggestions and results.
///
/// The results can be brought on screen by calling [SearchDelegate.showResults]
/// and you can go back to showing the suggestions by calling
/// [SearchDelegate.showSuggestions].
///
/// Once the user has selected a search result, [SearchDelegate.close] should be
/// called to remove the search page from the top of the navigation stack and
/// to notify the caller of [showSearch] about the selected search result.
///
/// A given [SearchDelegate] can only be associated with one active [showSearch]
/// call. Call [SearchDelegate.close] before re-using the same delegate instance
/// for another [showSearch] call.
abstract class SearchDelegate<T> {
  /// Suggestions shown in the body of the search page while the user types a
  /// query into the search field.
  ///
  /// The delegate method is called whenever the content of [query] changes.
  /// The suggestions should be based on the current [query] string. If the query
  /// string is empty, it is good practice to show suggested queries based on
  /// past queries or the current context.
  ///
  /// Usually, this method will return a [ListView] with one [ListTile] per
  /// suggestion. When [ListTile.onTap] is called, [query] should be updated
  /// with the corresponding suggestion and the results page should be shown
  /// by calling [showResults].
  Widget buildSuggestions(BuildContext context);

  /// The results shown after the user submits a search from the search page.
  ///
  /// The current value of [query] can be used to determine what the user
  /// searched for.
  ///
  /// This method might be applied more than once to the same query.
  /// If your [buildResults] method is computationally expensive, you may want
  /// to cache the search results for one or more queries.
  ///
  /// Typically, this method returns a [ListView] with the search results.
  /// When the user taps on a particular search result, [close] should be called
  /// with the selected result as argument. This will close the search page and
  /// communicate the result back to the initial caller of [showSearch].
  Widget buildResults(BuildContext context);

  /// The widget used as the search bar.
  Widget buildSearchBar(
      {BuildContext context,
      TextEditingController controller,
      FocusNode focusNode,
      TextInputAction textInputAction,
      Function(String _) onSubmitted});

  /// The theme used to style the [AppBar].
  ///
  /// By default, a white theme is used.
  ///
  /// See also:
  ///
  ///  * [AppBar.backgroundColor], which is set to [ThemeData.primaryColor].
  ///  * [AppBar.iconTheme], which is set to [ThemeData.primaryIconTheme].
  ///  * [AppBar.textTheme], which is set to [ThemeData.primaryTextTheme].
  ///  * [AppBar.brightness], which is set to [ThemeData.primaryColorBrightness].
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme.copyWith(
      primaryColor: Colors.white,
      primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.grey),
      primaryColorBrightness: Brightness.light,
      primaryTextTheme: theme.textTheme,
    );
  }

  /// The current query string shown in the [AppBar].
  ///
  /// The user manipulates this string via the keyboard.
  ///
  /// If the user taps on a suggestion provided by [buildSuggestions] this
  /// string should be updated to that suggestion via the setter.
  String get query => _queryTextController.text;

  set query(String value) {
    assert(query != null);
    _queryTextController.text = value;
  }

  /// Transition from the suggestions returned by [buildSuggestions] to the
  /// [query] results returned by [buildResults].
  ///
  /// If the user taps on a suggestion provided by [buildSuggestions] the
  /// screen should typically transition to the page showing the search
  /// results for the suggested query. This transition can be triggered
  /// by calling this method.
  ///
  /// See also:
  ///
  ///  * [showSuggestions] to show the search suggestions again.
  void showResults(BuildContext context) {
    _focusNode.unfocus();
    _currentBody = _SearchBody.results;
  }

  /// Transition from showing the results returned by [buildResults] to showing
  /// the suggestions returned by [buildSuggestions].
  ///
  /// Calling this method will also put the input focus back into the search
  /// field of the [AppBar].
  ///
  /// If the results are currently shown this method can be used to go back
  /// to showing the search suggestions.
  ///
  /// See also:
  ///
  ///  * [showResults] to show the search results.
  void showSuggestions(BuildContext context) {
    FocusScope.of(context).requestFocus(_focusNode);
    _currentBody = _SearchBody.suggestions;
  }

  /// Closes the search page and returns to the underlying route.
  ///
  /// The value provided for `result` is used as the return value of the call
  /// to [showSearch] that launched the search initially.
  void close(BuildContext context, T result) {
    _currentBody = null;
    _focusNode.unfocus();
    Navigator.of(context)
      ..popUntil((Route<dynamic> route) => route == _route)
      ..pop(result);
  }

  /// [Animation] triggered when the search pages fades in or out.
  Animation<double> get transitionAnimation => _proxyAnimation;

  final FocusNode _focusNode = FocusScopeNode();

  final TextEditingController _queryTextController = TextEditingController();

  final ProxyAnimation _proxyAnimation =
      ProxyAnimation(kAlwaysDismissedAnimation);

  final ValueNotifier<_SearchBody> _currentBodyNotifier =
      ValueNotifier<_SearchBody>(null);

  _SearchBody get _currentBody => _currentBodyNotifier.value;

  set _currentBody(_SearchBody value) {
    _currentBodyNotifier.value = value;
  }

  SearchPageRoute<T> _route;
}

/// Describes the body that is currently shown under the [AppBar] in the
/// search page.
enum _SearchBody {
  /// Suggested queries are shown in the body.
  ///
  /// The suggested queries are generated by [SearchDelegate.buildSuggestions].
  suggestions,

  /// Search results are currently shown in the body.
  ///
  /// The search results are generated by [SearchDelegate.buildResults].
  results,
}

class SearchPageRoute<T> extends PageRoute<T> {
  SearchPageRoute({
    @required this.delegate,
  }) : assert(delegate != null) {
    assert(
      delegate._route == null,
      'The ${delegate.runtimeType} instance is currently used by another active '
      'search. Please close that search by calling close() on the SearchDelegate '
      'before openening another search with the same delegate instance.',
    );
    delegate._route = this;
  }

  final SearchDelegate<T> delegate;

  @override
  Color get barrierColor => null;

  @override
  bool get opaque => false;

  @override
  String get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get maintainState => false;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: child),
    );
  }

  @override
  Animation<double> createAnimation() {
    final Animation<double> animation = super.createAnimation();
    delegate._proxyAnimation.parent = animation;
    return animation;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _SearchPage<T>(
      delegate: delegate,
      animation: animation,
    );
  }

  @override
  void didComplete(T result) {
    super.didComplete(result);
    assert(delegate._route == this);
    delegate._route = null;
    delegate._currentBody = null;
  }
}

class _SearchPage<T> extends StatefulWidget {
  const _SearchPage({
    this.delegate,
    this.animation,
  });

  final SearchDelegate<T> delegate;
  final Animation<double> animation;

  @override
  State<StatefulWidget> createState() => _SearchPageState<T>();
}

class _SearchPageState<T> extends State<_SearchPage<T>> {
  @override
  void initState() {
    super.initState();
    queryTextController.addListener(_onQueryChanged);
    widget.animation.addStatusListener(_onAnimationStatusChanged);
    widget.delegate._currentBodyNotifier.addListener(_onSearchBodyChanged);
    widget.delegate._focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    super.dispose();
    queryTextController.removeListener(_onQueryChanged);
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    widget.delegate._currentBodyNotifier.removeListener(_onSearchBodyChanged);
    widget.delegate._focusNode.removeListener(_onFocusChanged);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    if (widget.delegate._currentBody == _SearchBody.suggestions) {
      FocusScope.of(widget.delegate._focusNode.context)
          .requestFocus(widget.delegate._focusNode);
    }
  }

  void _onFocusChanged() {
    if (widget.delegate._focusNode.hasFocus &&
        widget.delegate._currentBody != _SearchBody.suggestions) {
      widget.delegate.showSuggestions(context);
    }
  }

  void _onQueryChanged() {
    setState(() {
      // rebuild ourselves because query changed.
    });
  }

  void _onSearchBodyChanged() {
    setState(() {
      // rebuild ourselves because search body changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final ThemeData theme = Theme.of(context);
    final String searchFieldLabel =
        MaterialLocalizations.of(context).searchFieldLabel;
    Widget body;
    switch (widget.delegate._currentBody) {
      case _SearchBody.suggestions:
        body = KeyedSubtree(
          key: const ValueKey<_SearchBody>(_SearchBody.suggestions),
          child: widget.delegate.buildSuggestions(context),
        );
        break;
      case _SearchBody.results:
        body = KeyedSubtree(
          key: const ValueKey<_SearchBody>(_SearchBody.results),
          child: widget.delegate.buildResults(context),
        );
        break;
    }
    String routeName;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        routeName = '';
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        routeName = searchFieldLabel;
    }

    return Semantics(
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: true,
      label: routeName,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            iconTheme: theme.primaryIconTheme,
            textTheme: theme.primaryTextTheme,
            brightness: theme.primaryColorBrightness,
            elevation: 0,
            title: widget.delegate.buildSearchBar(
              context: context,
              controller: queryTextController,
              focusNode: widget.delegate._focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (String _) {
                widget.delegate.showResults(context);
              },
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: body,
          ),
        ),
      ),
    );
  }

  TextEditingController get queryTextController =>
      widget.delegate._queryTextController;
}
