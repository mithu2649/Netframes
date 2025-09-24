import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/features/home/presentation/pages/home_page.dart';
import 'package:netframes/features/library/presentation/pages/library_page.dart';
import 'package:netframes/features/live_tv/presentation/pages/live_tv_page.dart';
import 'package:netframes/features/radio/presentation/cubit/radio_cubit.dart';
import 'package:netframes/features/radio/presentation/pages/radio_page.dart';
import 'package:netframes/features/radio/presentation/widgets/mini_player.dart';
import 'package:netframes/features/search/presentation/pages/search_page.dart';
import 'package:netframes/features/settings/presentation/pages/settings_page.dart';
// import 'package:netframes/features/tv_shows/presentation/pages/tv_shows_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late ScrollController _scrollController;
  late AnimationController _animationController;
  bool _showFabExtended = true;

  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    // TvShowsPage(),
    LiveTvPage(),
    RadioPage(),
    LibraryPage(),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_showFabExtended) {
          setState(() {
            _showFabExtended = false;
          });
          _animationController.reverse();
        }
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_showFabExtended) {
          setState(() {
            _showFabExtended = true;
          });
          _animationController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLiveTvPage = _selectedIndex == 1;
    final bool isRadioPage = _selectedIndex == 2;

    return BlocProvider(
      create: (context) => RadioCubit(),
      child: Scaffold(
        appBar: isLiveTvPage || isRadioPage
            ? null
            : AppBar(
                title: const Text('Netframes'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
        body: Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is UserScrollNotification) {
                    if (scrollNotification.direction == ScrollDirection.reverse) {
                      if (_showFabExtended) {
                        setState(() {
                          _showFabExtended = false;
                        });
                        _animationController.reverse();
                      }
                    } else if (scrollNotification.direction ==
                        ScrollDirection.forward) {
                      if (!_showFabExtended) {
                        setState(() {
                          _showFabExtended = true;
                        });
                        _animationController.forward();
                      }
                    }
                  }
                  return false;
                },
                child: Center(child: _widgetOptions.elementAt(_selectedIndex)),
              ),
            ),
            MiniPlayer(),
          ],
        ),
        floatingActionButton: isLiveTvPage || isRadioPage
            ? null
            : _showFabExtended
                ? FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchPage()),
                      );
                    },
                    label: const Text('Search'),
                    icon: const Icon(Icons.search),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                  )
                : FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchPage()),
                      );
                    },
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    child: const Icon(Icons.search),
                  ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.movie), label: 'Movies & TV'),
            // NavigationDestination(icon: Icon(Icons.tv), label: 'TV Shows'),
            NavigationDestination(icon: Icon(Icons.live_tv), label: 'Live TV'),
            NavigationDestination(icon: Icon(Icons.radio), label: 'Radio'),
            NavigationDestination(
              icon: Icon(Icons.video_library),
              label: 'Library',
            ),
          ],
        ),
      ),
    );
  }
}
