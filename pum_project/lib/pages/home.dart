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
  bool showLocalActivities = false;
  bool offlineMode = true;
  int queueSize = 0;

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
    _pageViewController.dispose();
  }

  @override
  void initState() {
    _loadPageData();
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
    _checkOfflineMode();
    _checkUploadQueue();
    _loadLocalActivityList();
    if (!offlineMode) {
      _loadOnlineActivityList();
    }
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
        }
    );
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
      List<Map<String,dynamic>>? activityMap = await api.getUserActivities();
      if (activityMap.isNotEmpty) {
        if (mounted) {
          setState(() {
            onlineActivities = activityMap;
          });
        }
      }
    } catch (e) {
      if (mounted) _displaySnackbar(AppLocalizations.of(context)!.genericErrorMessage);
      debugPrint('Failed to load online activities: $e');
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
            child: Text(AppLocalizations.of(context)!.settingsButtonLabel),
          ),
          PopupMenuItem<int>(
              value: 2,
              onTap: _turnOffOfflineMode,
              child: Text(AppLocalizations.of(context)!.loginButtonLabel)
          ),
        ],
      );
    } else {
      return PopupMenuButton<int>(
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
            child: Text(AppLocalizations.of(context)!.profileButtonLabel),
          ),
          PopupMenuItem<int>(
            value: 2,
            onTap: () => (
            Navigator.pushNamed(context,'/settings'),
            ),
            child: Text(AppLocalizations.of(context)!.settingsButtonLabel),
          ),
          PopupMenuItem<int>(
              value: 3,
              onTap: _logoutPopupWindow,
              child: Text(AppLocalizations.of(context)!.logoutButtonLabel)
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
            Text('Uploaded Activity History Page'),
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
            Text('Leaderboard Page'),
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
}