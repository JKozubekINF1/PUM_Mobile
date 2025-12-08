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

class _HomePageState extends State<HomePage> with RouteAware{
  late PageController _pageViewController;
  bool loading = true;
  List<String>? localActivitiesList = [];
  List<Map<String,dynamic>>? onlineActivities;
  List<Map<String,dynamic>>? leaderboard;
  bool showLocalActivities = false;
  bool offlineMode = true;
  int queueSize = 0;
  bool onlineActivitiesInitiated = false;
  bool leaderboardInitiated = false;
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
    _pageViewController = PageController();
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
    _pageViewController.animateToPage(number, duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
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
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
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
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      debugPrint('$e');
    }
  }

  Future<void> _cancelQueue() async {
    try {
      final uploadQueue = Provider.of<UploadQueue>(context, listen: false);
      await uploadQueue.cancelQueue();
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.activityQueueCancelledMessage);
        await _checkUploadQueue();
        await _loadLocalActivityList();
      }
    } catch (e) {
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      debugPrint('$e');
    }
  }

  Future<void> _retryUpload() async {
    try {
      final uploadQueue = Provider.of<UploadQueue>(context, listen: false);
      final check = await uploadQueue.processQueue();
      if (check) {
        if (mounted) _displaySnackbar(AppLocalizations.of(context)!.activitySentMessage);
      } else {
        if (mounted) _displaySnackbar(AppLocalizations.of(context)!.noConnectionMessage);
      }
      await _checkUploadQueue();
    } catch (e) {
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      debugPrint('$e');
    }
  }

  Future<void> _logoutPopupWindow() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.warningLabel,style:TextStyle(color:Colors.black)),
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
        }
    );
  }

  Future<void> _clearQueueWindow() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.warningLabel,style:TextStyle(color:Colors.black)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(AppLocalizations.of(context)!.activityQueueCancelDialogMessage),
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
        }
    );
  }

  Future<void> _loadOnlineActivity(String id) async {
    _processing = true;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      Map<String,dynamic>? map = await api.getActivity(id);
      await Navigator.pushNamed(context, '/activity/get', arguments: {
        'Data': map,
      });
      _processing = false;
    } catch (e) {
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
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
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      debugPrint('$e');
    }
  }

  Future<void> _loadOnlineActivityList() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      List<Map<String,dynamic>>? activityList = await api.getUserActivities();
      if (activityList.isNotEmpty) {
        if (mounted) {
          setState(() {
            onlineActivities = activityList;
          });
        }
        _sortActivityList();
      }
    } catch (e) {
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
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
        return alphaA.toString().trim().toLowerCase().compareTo(alphaB.toString().trim().toLowerCase());
      }

      if (valueA is String && valueB is String) {
        return valueA.trim().toLowerCase().compareTo(valueB.trim().toLowerCase());
      } else if (valueA is num && valueB is num) {
        return valueA.compareTo(valueB);
      } else if (valueA is DateTime && valueB is DateTime) {
        return valueA.compareTo(valueB);
      }else {
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
      final valueA = a[_sortOption];
      final valueB = b[_sortOption];

      if (valueA == null && valueB == null) return 0;
      if (valueA == null) return -1;
      if (valueB == null) return 1;

      return valueA.compareTo(valueB);
    });
    setState(() {
      leaderboard = newList;
    });
  }

  Future<void> _loadLeaderboard() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      List<Map<String,dynamic>>? newLeaderboard = await api.getLeaderboard();
      if (newLeaderboard.isNotEmpty) {
        if (mounted) {
          setState(() {
            leaderboard = newLeaderboard;
          });
        }
      }
    } catch (e) {
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      debugPrint('Failed to load leaderboard: $e');
    }
  }

  Future<void> _readLocalActivity(String filename) async {
    try {
      final localStorage = Provider.of<LocalStorage>(context, listen: false);
      Map? fileContent = await localStorage.readFromStorage(filename);
      if (fileContent!=null) {
        if (mounted) {
          Navigator.pushNamed(context, '/results', arguments: {
            'Local': true,
            'Data': fileContent,
          });
        }
      }
    } catch (e) {
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.localFileErrorMessage);
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
        appBar: AppBar(title: const Text("Title")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.homePageTitle),
        actions: [
          _buildProfilePopupMenu(),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: SizedBox(
                child: _buildMenu(),
              ),
            ),
            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePopupMenu() {
    if (offlineMode) {
      return PopupMenuButton<int>(
        color: Theme.of(context).cardTheme.color,
        child: Row(
          children: [
            Icon(CupertinoIcons.profile_circled, size: 35),
            Icon(CupertinoIcons.ellipsis_vertical, size: 35),
          ],
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<int>> [
          PopupMenuItem<int>(
            value: 1,
            onTap: () => (
            Navigator.pushNamed(context,'/settings'),
            ),
            child: Text(AppLocalizations.of(context)!.settingsButtonLabel,style:TextStyle(color:Theme.of(context).inputDecorationTheme.hintStyle!.color)),
          ),
          PopupMenuItem<int>(
              value: 2,
              onTap: _turnOffOfflineMode,
              child: Text(AppLocalizations.of(context)!.loginButtonLabel,style:TextStyle(color:Theme.of(context).inputDecorationTheme.hintStyle!.color))
          ),
        ],
      );
    } else {
      return PopupMenuButton<int>(
        color: Theme.of(context).cardTheme.color,
        child: Row(
          children: [
            Icon(CupertinoIcons.profile_circled, size: 35),
            Icon(CupertinoIcons.ellipsis_vertical, size: 35),
          ],
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<int>> [
          PopupMenuItem<int>(
            value: 1,
            onTap: () => (
            Navigator.pushNamed(context,'/profile'),
            ),
            child: Text(AppLocalizations.of(context)!.profileButtonLabel,style:TextStyle(color:Theme.of(context).inputDecorationTheme.hintStyle!.color)),
          ),
          PopupMenuItem<int>(
            value: 2,
            onTap: () => (
            Navigator.pushNamed(context,'/settings'),
            ),
            child: Text(AppLocalizations.of(context)!.settingsButtonLabel,style:TextStyle(color:Theme.of(context).inputDecorationTheme.hintStyle!.color)),
          ),
          PopupMenuItem<int>(
              value: 3,
              onTap: _logoutPopupWindow,
              child: Text(AppLocalizations.of(context)!.logoutButtonLabel,style:TextStyle(color:Theme.of(context).inputDecorationTheme.hintStyle!.color))
          ),
        ],
      );
    }
  }

  Widget _buildMenu() {
    return Column(
      children: <Widget>[
        Expanded(
          child: PageView(
            controller: _pageViewController,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index) {
              if (index == 1) {
                if (!offlineMode) {
                  if (!onlineActivitiesInitiated) {
                    _loadOnlineActivityList();
                    onlineActivitiesInitiated = true;
                  }
                }
              }
              if (index == 2) {
                if (!offlineMode) {
                  if (!leaderboardInitiated) {
                    _loadLeaderboard();
                    leaderboardInitiated = true;
                  }
                }
              }
            },
            children: <Widget>[
              Column(
                children: [
                  _buildNewActivityPage(),
                ],
              ),
              Column(
                children: [
                  _buildActivityHistoryPage(),
                ],
              ),
              Column(
                children: [
                  _buildLeaderboardPage(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBar() {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: ColoredBox(
            color: Theme.of(context).appBarTheme.backgroundColor as Color,
            child: TextButton(
              onPressed: () {
                _changeToPage(0);
              },
              child: Icon(CupertinoIcons.timer,size: 45),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ColoredBox(
            color: Theme.of(context).appBarTheme.backgroundColor as Color,
            child: TextButton(
              onPressed: () {
                _changeToPage(1);
              },
              child: Icon(CupertinoIcons.book,size: 45),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ColoredBox(
            color: Theme.of(context).appBarTheme.backgroundColor as Color,
            child: TextButton(
              onPressed: () {
                _changeToPage(2);
              },
              child: Icon(CupertinoIcons.chart_bar,size: 45),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewActivityPage() {
    return Expanded(
      child: SizedBox(
        child: Column(
          children: [
            Expanded(child: _buildStartActivityColumn()),
            if (showLocalActivities)
              Expanded(
                flex: 1,
                child: ColoredBox(
                  color: Theme.of(context).appBarTheme.backgroundColor as Color,
                  child: _buildLocalActivityContainer(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityHistoryPage() {
    if (offlineMode) {
      return _buildDummyOfflinePage();
    }
    return Expanded(
      child: SizedBox(
        child: Column(
          children: [
            Text(AppLocalizations.of(context)!.activityHistoryPageTitle, overflow: TextOverflow.ellipsis),
            _buildOnlineActivityControlRow(),
            Expanded(child: _buildOnlineActivitiesListView()),
            _buildQueueDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardPage() {
    if (offlineMode) {
      return _buildDummyOfflinePage();
    }
    return Expanded(
      child: SizedBox(
        child: Column(
          children: [
            Text(AppLocalizations.of(context)!.leaderboardPageTitle, overflow: TextOverflow.ellipsis),
            _buildLeaderboardControlRow(),
            Expanded(child: _buildLeaderboardListView()),
          ],
        ),
      ),
    );
  }

  Widget _buildDummyOfflinePage() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(AppLocalizations.of(context)!.offlineModePageBlockedMessage,style: TextStyle(fontSize:34),textAlign: TextAlign.center),
          SizedBox(height:45),
          Icon(Icons.lock_sharp,size:56),
        ],
      ),
    );
  }

  Widget _buildStartActivityColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(AppLocalizations.of(context)!.newActivityPageMessage),
        Icon(Icons.directions_run,size: 130),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(100, 80),
          ),
          onPressed: () {
            Navigator.pushNamed(context,'/track').then((_) {
              _loadLocalActivityList();
            });
          },
          child: Text(AppLocalizations.of(context)!.createNewActivityButtonLabel),
        ),
      ],
    );
  }

  Widget _buildLocalActivityContainer() {
    if (showLocalActivities) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme
                .of(context)
                .appBarTheme
                .backgroundColor as Color,
            child: Center(child: Text(AppLocalizations.of(context)!.localActivityListLabel,style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor))),
          ),
          Expanded(
            flex: 1,
            child: _buildLocalActivityListView(),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildLocalActivityListView() {
    final List<String> list = localActivitiesList!;
    return ListView.builder(
        padding: EdgeInsets.all(15.0),
        itemCount: list.length,
        itemBuilder: (BuildContext context, int index) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 60),
              padding: EdgeInsets.all(30.0),
            ),
            onPressed: () {
              _readLocalActivity(list[index]);
              },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc,size: 25),
                Flexible(child: Text(list[index],style:TextStyle(fontSize: 16))),
              ],
            ),
          );
        }
    );
  }

  Widget _buildQueueDisplay() {
    if (queueSize>0) {
      return Card(
        child: Column(
          children: [
            Text("($queueSize) ${AppLocalizations.of(context)!.uploadQueueLabel}",overflow: TextOverflow.ellipsis),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _retryUpload,
                  icon: Icon(Icons.change_circle_rounded),
                  iconSize: 40,
                ),
                SizedBox(width:30),
                IconButton(
                  onPressed: _clearQueueWindow,
                  icon: Icon(Icons.cancel),
                  iconSize: 40,
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildOnlineActivitiesListView() {
    if (onlineActivities == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<Map<String,dynamic>> list = onlineActivities!;
    return ListView.builder(
        padding: EdgeInsets.all(15.0),
        itemCount: list.length,
        itemBuilder: (BuildContext context, int index) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 60),
              padding: EdgeInsets.all(30.0),
              backgroundColor: index.isEven ? Theme.of(context).cardTheme.color as Color : Theme.of(context).elevatedButtonTheme.style!.backgroundColor!.resolve({}),
            ),
            onPressed: () {
              if (!_processing) {
                _loadOnlineActivity(list[index]["id"]);
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: Text("${list[index]["title"]}",overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: _getActivitySortingOptionText(list, index),
                ),
              ],
            ),
          );
        }
    );
  }

  Widget _getActivitySortingOptionText(List list,int index) {
    if (_sortOption=="startedAt") {
      DateTime date = DateTime.parse(list[index]["startedAt"]);
      String formattedDate = DateFormat("dd.MM.yyyy hh:mm").format(date);
      return Text(formattedDate,overflow: TextOverflow.ellipsis);
    } else if (_sortOption!="title") {
      return Text("${list[index][_sortOption]}",overflow: TextOverflow.ellipsis);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildLeaderboardListView() {
    if (leaderboard == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<Map<String,dynamic>> list = leaderboard!;
    return ListView.builder(
        padding: EdgeInsets.all(15.0),
        itemCount: list.length,
        itemBuilder: (BuildContext context, int index) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 60),
              padding: EdgeInsets.all(30.0),
              backgroundColor: index.isEven ? Theme.of(context).cardTheme.color as Color : Theme.of(context).elevatedButtonTheme.style!.backgroundColor!.resolve({}),
            ),
            onPressed: () {

            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text((index+1).toString(),overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  flex: 4,
                  child: Text("${list[index]["userName"]}",overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  flex: 2,
                  child: Text("${list[index][_rankOption]}",overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          );
        }
    );
  }

  Widget _buildRefreshOnlineActivityListButton() {
    return IconButton(
      icon: Icon(Icons.refresh_rounded),
      iconSize: 45,
      onPressed: () {
        if (mounted) {
          _loadOnlineActivityList();
        }
      },
    );
  }

  Widget _buildInvertActivityListSortingButton() {
    return IconButton(
      icon: _sortOrder ? Icon(CupertinoIcons.sort_down) : Icon(CupertinoIcons.sort_up),
      onPressed: () {
        if (mounted) {
          _sortOrder = !_sortOrder;
          _sortActivityList();
        }
      },
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
    return DropdownButtonFormField<String>(
      initialValue: _sortOption,
      dropdownColor: Theme.of(context).cardTheme.color,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.sortByLabel,
        border: const OutlineInputBorder(),
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
          child: Text(entry.value,style:TextStyle(color:Theme.of(context).inputDecorationTheme.hintStyle!.color)),
        );
      }).toList(),
    );
  }

  Widget _buildLeaderboardChooseSortField() {
    final Map<String, String> sortOptions = {
      "totalDistanceKm": AppLocalizations.of(context)!.sortByTotalDistanceLabel,
      "activityCount": AppLocalizations.of(context)!.sortByActivityCountLabel,
      "totalDuration": AppLocalizations.of(context)!.sortByTotalDurationLabel,
    };
    return DropdownButtonFormField<String>(
      initialValue: _rankOption,
      dropdownColor: Theme.of(context).cardTheme.color,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.rankedByLabel,
        border: const OutlineInputBorder(),
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
          child: Text(entry.value,style:TextStyle(color:Theme.of(context).inputDecorationTheme.hintStyle!.color)),
        );
      }).toList(),
    );
  }

  Widget _buildOnlineActivityControlRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _buildActivityChooseSortField(),
          ),
          Flexible(
            child: _buildInvertActivityListSortingButton(),
          ),
          Expanded(
            flex: 1,
            child: SizedBox(),
          ),
          Flexible(
            child: _buildRefreshOnlineActivityListButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardControlRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _buildLeaderboardChooseSortField(),
          ),
          Expanded(
            flex: 1,
            child: SizedBox(),
          ),
          Flexible(
            child: _buildRefreshLeaderboardButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshLeaderboardButton() {
    return IconButton(
      icon: Icon(Icons.refresh_rounded),
      iconSize: 45,
      onPressed: () {
        if (mounted) {
          _loadLeaderboard();
        }
      },
    );
  }
}