// ignore_for_file: avoid_function_literals_in_foreach_calls, use_key_in_widget_constructors, library_private_types_in_public_api

import 'ads.dart';
import 'goals.dart';
import 'topbar.dart';
import 'permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_apps/device_apps.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

late MethodChannel platform;
late SharedPreferences preferences;

int serviceRunning = 2; // 0 = not running, 1 = running, 2 = unknown
List? apps;
List<int> usage = [];
List<String> selectedApps = [];
List<int> goals = [];

bool showAd = false;

bool usagePermission = true;
bool displayOverOtherAppPermission = true;
bool ignoreBatteryOptimizationsPermission = true;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  platform = const MethodChannel("com.usage.timer");

  preferences = await SharedPreferences.getInstance();

  MobileAds.instance.initialize();  

  usagePermission = await UsageStats.checkUsagePermission() ?? false;
  displayOverOtherAppPermission = await Permission.systemAlertWindow.isGranted;
  ignoreBatteryOptimizationsPermission = await Permission.ignoreBatteryOptimizations.isGranted;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const UsageStatsPage(),
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UsageStatsPage extends StatefulWidget {
  const UsageStatsPage({super.key});

  @override
  _UsageStatsPageState createState() => _UsageStatsPageState();
}

class _UsageStatsPageState extends State<UsageStatsPage> {

  final AdManager _adManager = AdManager();

  @override
  void initState() {
    super.initState();
    getServiceState();
    getApps();
        
    _adManager.loadInterstitialAd();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if(!usagePermission || !displayOverOtherAppPermission || !ignoreBatteryOptimizationsPermission){
        Navigator.push(context, MaterialPageRoute(builder: (context) => PermissionPage()));
      }
    });
  }

  update(){
    topBarKey.currentState?.update();
  }

  updatePage(){
    setState((){});
  }

  Future<void> getServiceState() async{
    bool isServiceRunning = false;

    isServiceRunning = await platform.invokeMethod('isRunning');

    if(isServiceRunning){
      serviceRunning = 1;
      selectedApps = preferences.getStringList('selected_apps')!;
      goals = List.generate(selectedApps.length, (index) => int.parse(preferences.getStringList('goals')![index]));
    } else{
      serviceRunning = 0;
    }
    update();
  }

  Future<void> getApps() async {

    if(apps == null){
      apps = await DeviceApps.getInstalledApplications(
      includeSystemApps: true,
      includeAppIcons: true,
      onlyAppsWithLaunchIntent: true,
    );

    apps!.removeWhere((element) => element.packageName == "com.usage.timer");

    apps!.forEach((element) async{
      usage.add(int.parse(await platform.invokeMethod('usage', {"package": element.packageName})));
      if(apps!.indexOf(element) == apps!.length - 1){
        setState(() {});
      }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color.fromARGB(255, 12, 12, 12),
        bottomNavigationBar: BannerAdWidget(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,            
            children: [
              //stop button
              TopBar(
                key: topBarKey, 
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, right: 18.0, top: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async{
                                    if(showAd){
                                      _adManager.showInterstitialAd();
                                    }
                                    showAd = !showAd;
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalsPage()));
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.track_changes, size: 20),
                                      Text("  Goals")
                                    ] 
                                  )
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async{
                                    showModalBottomSheet(
                                      context: context, 
                                      builder: (context){
                                        return BottomSheet(
                                          onClosing: (){},
                                          backgroundColor: const Color.fromARGB(255, 20, 20, 20),
                                          builder: (context){
                                            return SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 15),
                                                  const Padding(
                                                    padding: EdgeInsets.only(left:12, right: 12),
                                                    child: Text('Are you sure?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  const Padding(
                                                    padding: EdgeInsets.only(left:12, right: 12),
                                                    child: Text('This action will stop displaying popup usage timer and reminders for all selected apps.', style: TextStyle(height: 1.5)),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 12, right: 12, left: 12, bottom: 8),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: OutlinedButton(
                                                            onPressed: (){
                                                              Navigator.pop(context);
                                                            },
                                                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                                                            child: const Text('cancel', style: TextStyle(color: Colors.white)),
                                                          ),
                                                        ),

                                                        const SizedBox(width: 10),

                                                        Expanded(
                                                          child: ElevatedButton(
                                                            onPressed: () async{
                                                              Navigator.pop(context);
                                                              await platform.invokeMethod('stop');
                                                              setState((){serviceRunning = 0; selectedApps = [];});                                                      
                                                            },
                                                            child: const Text('stop'),
                                                          ),
                                                        ),
                                                      ]
                                                    ),
                                                  ),
                                                ],
                                              )
                                            );
                                          },
                                        );
                                      }
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.stop),
                                      Text("  Stop")
                                    ] 
                                  )
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              //apps list
              apps == null ?
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NativeAdWidget(),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 1)
                  ],
                )
              ) :
              Expanded(
                child: SingleChildScrollView(
                  child:  Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget> [
                    
                    const Padding(
                      padding: EdgeInsets.only(left: 12, right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 15),
                          Text("Select apps to continue...", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          Text("A popup timer of usage will be displayed when the selected apps are in foreground ", style: TextStyle(color: Colors.grey, height: 1.5)),
                          SizedBox(height: 15),
                          //Divider()
                        ]
                      ),
                    ),
                  ] +
                  List.generate(
                    apps!.length,
                    (index) {
                      ApplicationWithIcon app = apps![index];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          index == 0 ? NativeAdWidget() : const SizedBox(),

                          const SizedBox(height: 10),

                          (index % 20 == 0 && index != 0) ? BannerAdWidget() : const SizedBox(),

                          ListTile(
                            contentPadding: index != apps!.length - 1 ? const EdgeInsets.only(left: 12, right: 12, top: 5, bottom: 5) : const EdgeInsets.only(left: 12, right: 12, top: 5, bottom: 15),
                            leading: SizedBox(height: 39, width: 39, child: Image(image: MemoryImage(app.icon))),
                            title: SizedBox(height: 30, child: Text(app.appName, style: const TextStyle(fontSize: 18.5, fontWeight: FontWeight.w700))),
                            subtitle: Text("${(usage[index] ~/ 3600000)}:${((usage[index] ~/ 60000) % 60).toString().padLeft(2, '0')}:${((usage[index] ~/ 1000) % 60).toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 14),),
                            trailing: StatefulBuilder(
                              builder: (context, setState) {
                                return Switch(                      
                                  value: selectedApps.contains(app.packageName), 
                                  activeColor: Colors.green, 
                                  onChanged: (value) async{
                                    if(value) {
                                      selectedApps.add(app.packageName);
                                      goals.add(0);
                                      if(selectedApps.length == 1){
                                        update();
                                      }
                                      startService();
                                    } 
                                    else {
                                      goals.removeAt(selectedApps.indexOf(app.packageName));
                                      selectedApps.remove(app.packageName);
                                      if(selectedApps.isEmpty){
                                        update();
                                        await platform.invokeMethod('stop');
                                      } else{
                                        startService();
                                      }
                                    }
                                    await preferences.setStringList('selected_apps', selectedApps);
                                    await preferences.setStringList('goals', List.generate(selectedApps.length, (index) => goals[index].toString()));
                                    setState((){});
                                  }
                                );
                              }
                            )
                          ),
                          ],
                        );                          
                      }                
                    )
                  )
                )
              )
            ],
          ),
        )
      ),
    );
  }
}

void startService() async{
  List<int> Goals = goals.map((goal) => goal == 0 ? 86400000 : goal).toList();
  await platform.invokeMethod('start', {"packages": selectedApps, "goals": Goals});
}