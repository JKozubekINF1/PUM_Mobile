import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:pum_project/services/local_storage.dart';
import 'package:pum_project/services/app_settings.dart';
import 'package:pum_project/services/upload_queue.dart';
import 'package:pum_project/services/route_observer.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  late PageController _pageViewController;
  bool loading = true;
  List<String>? localActivitiesList = [];
  List<Map<String, dynamic>>? onlineActivities;
  List<Map<String, dynamic>>? leaderboard;
  bool showLocalActivities = false;
  bool offlineMode = true;
  int queueSize = 0;
  bool onlineActivitiesInitiated = false;
  bool leaderboardInitiated = false;

  int _currentIndex = 0;

  String? _sortOption = "startedAt";
  bool _sortOrder = false;

  String? _rankOption = "totalDistanceKm";

  bool _processing = false;

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
    _pageViewController.dispose();
  }

  @override
  void initState() {
    _loadPageData();
    _checkOfflineMode();
    super.initState();
    _pageViewController = PageController(initialPage: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(
      this,
      ModalRoute.of(context)! as PageRoute<dynamic>,
    );
    _checkUploadQueue();
    _loadLocalActivityList();
  }

  @override
  void didPopNext() {
    _checkUploadQueue();
  }

  void _changeToPage(int number) {
    setState(() {
      _currentIndex = number;
    });
    _pageViewController.animateToPage(number,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic);
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      _displaySnackbar(AppLocalizations.of(context)!.logoutSuccessfulMessage);
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    }
  }

  Future<void> _turnOffOfflineMode() async {
    try {
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      await appSettings.setOfflineMode(offline: false);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
      }
    } catch (e) {
      debugPrint("$e");
    }
  }

  Future<void> _checkOfflineMode() async {
    try {
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      final mode = await appSettings.checkOfflineMode();
      if (mounted) {
        setState(() {
          offlineMode = mode ?? true;
        });
      }
    } catch (e) {
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      }
      debugPrint('$e');
    }
  }

  Future<void> _checkUploadQueue() async {
    try {
      final uploadQueue = Provider.of<UploadQueue>(context, listen: false);
      final size = await uploadQueue.getQueueSize();
      if (mounted) {
        setState(() {
          queueSize = size ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      }
      debugPrint('$e');
    }
  }

  Future<void> _cancelQueue() async {
    try {
      final uploadQueue = Provider.of<UploadQueue>(context, listen: false);
      await uploadQueue.cancelQueue();
      if (mounted) {
        _displaySnackbar(
            AppLocalizations.of(context)!.activityQueueCancelledMessage);
        await _checkUploadQueue();
        await _loadLocalActivityList();
      }
    } catch (e) {
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      }
      debugPrint('$e');
    }
  }

  Future<void> _retryUpload() async {
    try {
      final uploadQueue = Provider.of<UploadQueue>(context, listen: false);
      final check = await uploadQueue.processQueue();
      if (check) {
        if (mounted) {
          _displaySnackbar(AppLocalizations.of(context)!.activitySentMessage);
        }
      } else {
        if (mounted) {
          _displaySnackbar(AppLocalizations.of(context)!.noConnectionMessage);
        }
      }
      await _checkUploadQueue();
    } catch (e) {
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      }
      debugPrint('$e');
    }
  }

  Future<void> _logoutPopupWindow() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.warningLabel),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(AppLocalizations.of(context)!.logoutWarningMessage),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(AppLocalizations.of(context)!.acceptOptionLabel),
                onPressed: () async {
                  await _turnOffOfflineMode();
                  if (mounted) _logout();
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.declineOptionLabel),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  Future<void> _clearQueueWindow() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.warningLabel),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(AppLocalizations.of(context)!
                      .activityQueueCancelDialogMessage),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(AppLocalizations.of(context)!.acceptOptionLabel),
                onPressed: () async {
                  Navigator.pop(context);
                  await _cancelQueue();
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.declineOptionLabel),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  Future<void> _loadOnlineActivity(String id) async {
    _processing = true;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      Map<String, dynamic>? map = await api.getActivity(id);

      if (!mounted) return;

      await Navigator.pushNamed(context, '/activity/get', arguments: {
        'Data': map,
      });
      _processing = false;
    } catch (e) {
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      }
      debugPrint('$e');
      _processing = false;
    }
  }

  void _displaySnackbar(String message) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _loadLocalActivityList() async {
    try {
      final localStorage = Provider.of<LocalStorage>(context, listen: false);
      List<String>? fileList = await localStorage.getStorageList();
      if (fileList!.isNotEmpty) {
        if (mounted) {
          setState(() {
            localActivitiesList = fileList;
            showLocalActivities = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            showLocalActivities = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      }
      debugPrint('$e');
    }
  }

  Future<void> _loadOnlineActivityList() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      List<Map<String, dynamic>>? activityList = await api.getUserActivities();

      if (activityList != null) {
        if (mounted) {
          setState(() {
            onlineActivities = activityList;
          });
        }
        if (activityList.isNotEmpty) {
          _sortActivityList();
        }
      }
    } catch (e) {
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
        if (onlineActivities == null) {
          setState(() {
            onlineActivities = [];
          });
        }
      }
      debugPrint('Failed to load online activities: $e');
    }
  }

  void _sortActivityList() {
    if (onlineActivities == null) return;

    List<Map<String, dynamic>> newList = List.from(onlineActivities!);

    newList.sort((a, b) {
      final valueA = a[_sortOption];
      final valueB = b[_sortOption];
      final alphaA = a['title'];
      final alphaB = b['title'];

      if (valueA == null && valueB == null) return 0;
      if (valueA == null) return -1;
      if (valueB == null) return 1;

      if (valueA == valueB) {
        return alphaA
            .toString()
            .trim()
            .toLowerCase()
            .compareTo(alphaB.toString().trim().toLowerCase());
      }

      if (valueA is String && valueB is String) {
        return valueA
            .trim()
            .toLowerCase()
            .compareTo(valueB.trim().toLowerCase());
      } else if (valueA is num && valueB is num) {
        return valueA.compareTo(valueB);
      } else if (valueA is DateTime && valueB is DateTime) {
        return valueA.compareTo(valueB);
      } else {
        return valueA.toString().compareTo(valueB.toString());
      }
    });

    if (!_sortOrder) {
      newList = newList.reversed.toList();
    }
    setState(() {
      onlineActivities = newList;
    });
  }

  void _sortLeaderboard() {
    if (leaderboard == null) return;

    List<Map<String, dynamic>> newList = List.from(leaderboard!);

    newList.sort((a, b) {
      final valueA = a[_rankOption];
      final valueB = b[_rankOption];

      if (valueA == null && valueB == null) return 0;
      if (valueA == null) return 1;
      if (valueB == null) return -1;

      return valueB.compareTo(valueA);
    });

    setState(() {
      leaderboard = newList;
    });
  }

  Future<void> _loadLeaderboard() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      List<Map<String, dynamic>>? newLeaderboard = await api.getLeaderboard();
      if (newLeaderboard.isNotEmpty) {
        if (mounted) {
          setState(() {
            leaderboard = newLeaderboard;
          });
        }
        _sortLeaderboard();
      }
    } catch (e) {
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      }
      debugPrint('Failed to load leaderboard: $e');
    }
  }

  Future<void> _readLocalActivity(String filename) async {
    try {
      final localStorage = Provider.of<LocalStorage>(context, listen: false);
      Map? fileContent = await localStorage.readFromStorage(filename);
      if (fileContent != null) {
        if (mounted) {
          Navigator.pushNamed(context, '/results', arguments: {
            'Local': true,
            'Data': fileContent,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.localFileErrorMessage);
      }
      debugPrint('$e');
    }
  }

  Future<void> _loadPageData() async {
    await _loadLocalActivityList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return Scaffold(
        appBar:
        AppBar(title: Text(AppLocalizations.of(context)!.homePageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.homePageTitle),
        elevation: 0,
        actions: [
          _buildProfilePopupMenu(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageViewController,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              if (index == 1 && !offlineMode && !onlineActivitiesInitiated) {
                _loadOnlineActivityList();
                onlineActivitiesInitiated = true;
              }
              if (index == 2 && !offlineMode && !leaderboardInitiated) {
                _loadLeaderboard();
                leaderboardInitiated = true;
              }
            },
            children: <Widget>[
              _buildNewActivityPage(),
              _buildActivityHistoryPage(),
              _buildLeaderboardPage(),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _buildFloatingNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavigationBar() {
    final cardColor = Theme.of(context).cardTheme.color;
    final selectedColor = Theme.of(context).iconTheme.color;
    final unselectedColor =
    Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(CupertinoIcons.play_circle_fill, 0, selectedColor,
              unselectedColor),
          _buildNavItem(
              CupertinoIcons.list_bullet, 1, selectedColor, unselectedColor),
          _buildNavItem(CupertinoIcons.chart_bar_alt_fill, 2, selectedColor,
              unselectedColor),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, int index, Color? selected, Color? unselected) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _changeToPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 32,
          color: isSelected ? selected : unselected,
        ),
      ),
    );
  }

  Widget _buildProfilePopupMenu() {
    final hintColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: Theme.of(context).cardTheme.color,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      child: PopupMenuButton<int>(
        offset: const Offset(0, 50),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).cardTheme.color,
            child: Icon(CupertinoIcons.person_solid,
                color: Theme.of(context).iconTheme.color),
          ),
        ),
        itemBuilder: (BuildContext context) {
          if (offlineMode) {
            return [
              _buildPopupItem(
                  1,
                  AppLocalizations.of(context)!.settingsButtonLabel,
                  Icons.settings,
                  hintColor, onTap: () {
                Navigator.pushNamed(context, '/settings');
              }),
              _buildPopupItem(
                  2,
                  AppLocalizations.of(context)!.loginButtonLabel,
                  Icons.login,
                  hintColor,
                  onTap: _turnOffOfflineMode),
            ];
          } else {
            return [
              _buildPopupItem(
                  1,
                  AppLocalizations.of(context)!.profileButtonLabel,
                  Icons.person,
                  hintColor,
                  onTap: () => Navigator.pushNamed(context, '/profile')),
              _buildPopupItem(
                  2,
                  AppLocalizations.of(context)!.settingsButtonLabel,
                  Icons.settings,
                  hintColor,
                  onTap: () => Navigator.pushNamed(context, '/settings')),
              _buildPopupItem(
                  3,
                  AppLocalizations.of(context)!.logoutButtonLabel,
                  Icons.logout,
                  hintColor,
                  onTap: _logoutPopupWindow),
            ];
          }
        },
      ),
    );
  }

  PopupMenuItem<int> _buildPopupItem(
      int value, String text, IconData icon, Color? color,
      {VoidCallback? onTap}) {
    return PopupMenuItem<int>(
      value: value,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildNewActivityPage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Expanded(
            flex: 2,
            child: _buildStartActivityCard(),
          ),
          const SizedBox(height: 20),
          if (showLocalActivities) ...[
            Text(
              AppLocalizations.of(context)!
                  .localActivityListLabel
                  .toUpperCase(),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 1,
              child: _buildLocalActivityListView(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStartActivityCard() {
    return Card(
      elevation: 8,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(context, '/track').then((_) {
            _loadLocalActivityList();
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardTheme.color!,
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .appBarTheme
                          .backgroundColor!
                          .withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_run_rounded,
                  size: 80,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                AppLocalizations.of(context)!.createNewActivityButtonLabel,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.newActivityPageMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalActivityListView() {
    final List<String> list = localActivitiesList!;
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(CupertinoIcons.doc_text_fill,
                color: Theme.of(context).iconTheme.color),
            title: Text(
              list[index],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _readLocalActivity(list[index]),
          ),
        );
      },
    );
  }

  Widget _buildActivityHistoryPage() {
    if (offlineMode) return _buildDummyOfflinePage();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      child: Column(
        children: [
          _buildOnlineActivityControlRow(),
          const SizedBox(height: 10),
          Expanded(child: _buildOnlineActivitiesListView()),
          _buildQueueDisplay(),
        ],
      ),
    );
  }

  Widget _buildOnlineActivityControlRow() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: _buildActivityChooseSortField()),
            const SizedBox(width: 10),
            _buildIconButton(
              _sortOrder ? CupertinoIcons.sort_down : CupertinoIcons.sort_up,
                  () {
                if (mounted) {
                  _sortOrder = !_sortOrder;
                  _sortActivityList();
                }
              },
            ),
            const SizedBox(width: 5),
            _buildIconButton(Icons.refresh_rounded, () {
              if (mounted) _loadOnlineActivityList();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 28, color: Theme.of(context).iconTheme.color),
      ),
    );
  }

  Widget _buildActivityChooseSortField() {
    final Map<String, String> sortOptions = {
      "title": AppLocalizations.of(context)!.titleLabel,
      "activityType": AppLocalizations.of(context)!.activityTypeLabel,
      "startedAt": AppLocalizations.of(context)!.dateLabel,
      "durationSeconds": AppLocalizations.of(context)!.timeLabel,
      "distanceMeters": AppLocalizations.of(context)!.distanceLabel,
      "averageSpeedMs": AppLocalizations.of(context)!.avgSpeedLabel,
    };

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _sortOption,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down,
            color: Theme.of(context).iconTheme.color),
        dropdownColor: Theme.of(context).cardTheme.color,
        style: TextStyle(
          fontSize: 18,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        onChanged: (String? newValue) {
          setState(() {
            _sortOption = newValue;
            _sortActivityList();
          });
        },
        items: sortOptions.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOnlineActivitiesListView() {
    if (onlineActivities == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final list = onlineActivities!;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.noActivitiesFoundMessage ?? "No activities found",
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).disabledColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final activity = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (!_processing) _loadOnlineActivity(activity["id"]);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .scaffoldBackgroundColor
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getActivityIcon(activity["activityType"]),
                      color: Theme.of(context).iconTheme.color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${activity["title"] ?? 'Activity'}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(activity["startedAt"]),
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _getActivitySortingOptionText(list, index),
                      const SizedBox(height: 4),
                      Icon(Icons.chevron_right,
                          color: Theme.of(context).disabledColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardPage() {
    if (offlineMode) return _buildDummyOfflinePage();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      child: Column(
        children: [
          _buildLeaderboardControlRow(),
          const SizedBox(height: 10),
          Expanded(child: _buildLeaderboardListView()),
        ],
      ),
    );
  }

  Widget _buildLeaderboardControlRow() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: _buildLeaderboardChooseSortField()),
            _buildIconButton(Icons.refresh_rounded, () {
              if (mounted) _loadLeaderboard();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardChooseSortField() {
    final Map<String, String> sortOptions = {
      "totalDistanceKm":
      AppLocalizations.of(context)!.sortByTotalDistanceLabel,
      "activityCount": AppLocalizations.of(context)!.sortByActivityCountLabel,
    };
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _rankOption,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down,
            color: Theme.of(context).iconTheme.color),
        dropdownColor: Theme.of(context).cardTheme.color,
        style: TextStyle(
          fontSize: 18,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        onChanged: (String? newValue) {
          setState(() {
            _rankOption = newValue;
            _sortLeaderboard();
          });
        },
        items: sortOptions.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeaderboardListView() {
    if (leaderboard == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final list = leaderboard!;

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final isTop3 = index < 3;
        Color? rankColor;
        if (index == 0) rankColor = const Color(0xFFFFD700);
        if (index == 1) rankColor = const Color(0xFFC0C0C0);
        if (index == 2) rankColor = const Color(0xFFCD7F32);

        final rankNumColor =
        isTop3 ? Colors.black : Theme.of(context).textTheme.bodyMedium?.color;

        return Card(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rankColor ??
                        Theme.of(context)
                            .scaffoldBackgroundColor
                            .withValues(alpha: 0.5),
                    boxShadow: isTop3
                        ? [
                      BoxShadow(
                          color: rankColor!.withValues(alpha: 0.5),
                          blurRadius: 10)
                    ]
                        : [],
                  ),
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: rankNumColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    list[index]["userName"] ?? "Unknown",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _rankOption == "totalDistanceKm"
                      ? "${list[index]["totalDistanceKm"]} km"
                      : "${list[index]["activityCount"]}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDummyOfflinePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_off_rounded,
            size: 80, color: Theme.of(context).disabledColor),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            AppLocalizations.of(context)!.offlineModePageBlockedMessage,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueDisplay() {
    if (queueSize > 0) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.uploadQueueLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                Text(
                    "${AppLocalizations.of(context)?.pendingQueueLabel ?? "Pending:"} $queueSize",
                    style: const TextStyle(color: Colors.orange)),
              ],
            ),
            Row(
              children: [
                IconButton(
                    onPressed: _retryUpload,
                    icon: const Icon(Icons.sync, color: Colors.orange)),
                IconButton(
                    onPressed: _clearQueueWindow,
                    icon: const Icon(Icons.clear, color: Colors.orange)),
              ],
            )
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  IconData _getActivityIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'run':
      case 'running':
        return Icons.directions_run;
      case 'bike':
      case 'cycling':
        return Icons.directions_bike;
      case 'walk':
      case 'walking':
        return Icons.directions_walk;
      case 'swim':
      case 'swimming':
        return Icons.pool;
      case 'gym':
        return Icons.fitness_center;
      default:
        return Icons.local_activity;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "-";
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat("dd.MM.yyyy HH:mm").format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _getActivitySortingOptionText(List list, int index) {
    if (_sortOption == "startedAt" || _sortOption == "title") {
      return const SizedBox.shrink();
    }
    String text = "${list[index][_sortOption]}";
    if (_sortOption == "distanceMeters") text += " m";
    if (_sortOption == "durationSeconds") text += " s";
    if (_sortOption == "averageSpeedMs") {
      text = "${list[index]['averageSpeedMs'].toString().substring(0,4)} m/s";
    }

    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }
}