import 'ads.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timer_awarness/main.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 12, 12, 12),
        bottomNavigationBar: BannerAdWidget(),
        body: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Visibility(
                visible: !usagePermission || !ignoreBatteryOptimizationsPermission || !displayOverOtherAppPermission,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Permissions required", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Divider(color: Colors.grey),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              

              //USAGE PERMISSION
              Visibility(
                visible: !usagePermission,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Usage stats", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 10),
                    const Text("This permission is used to detect the current running app in foreground, so that popup timers and reminders can be displayed accordingly", style: TextStyle(color: Colors.grey, height: 1.5)),
                    TextButton(
                      style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
                      onPressed: () async{
                        Timer.periodic(const Duration(seconds: 1), (timer) async{
                          bool permissionGive = false;
                          permissionGive = await UsageStats.checkUsagePermission() ?? false;
                          if(permissionGive){
                            setState(() {
                              usagePermission = true;
                            });
                            if(usagePermission){
                              timer.cancel();
                            }
                            if(usagePermission && displayOverOtherAppPermission && ignoreBatteryOptimizationsPermission){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => UsageStatsPage()));
                            }
                            timer.cancel();
                          }
                        });
                        await UsageStats.grantUsagePermission();              
                      },
                      child: const Text('Grant permission', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              //Display over other apps
              Visibility(
                visible: !displayOverOtherAppPermission,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("System alarm window", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 10),
                    const Text("This permission is used to display popup timers and reminders", style: TextStyle(color: Colors.grey, height: 1.5)),
                    TextButton(
                      style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
                      onPressed: () async{
                        PermissionStatus status = await Permission.systemAlertWindow.request();
                        if(status.isGranted){
                          setState(() {
                            displayOverOtherAppPermission = true;
                          });
                        }
                        if(usagePermission && displayOverOtherAppPermission && ignoreBatteryOptimizationsPermission){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => UsageStatsPage()));
                        }
                      },
                      child: const Text('Grant permission', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              Visibility(
                visible: !ignoreBatteryOptimizationsPermission,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ignore battery optimizations", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 10),
                    const Text("This permission is used to prevent system from killing app's background activity", style: TextStyle(color: Colors.grey, height: 1.5)),
                    TextButton(
                      style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
                      onPressed: () async{
                        PermissionStatus status = await Permission.ignoreBatteryOptimizations.request();
                        if(status.isGranted){
                          setState(() {
                            ignoreBatteryOptimizationsPermission = true;
                          });
                        }
                        if(usagePermission && displayOverOtherAppPermission && ignoreBatteryOptimizationsPermission){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => UsageStatsPage()));
                        }
                      },
                      child: const Text('Grant permission', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ]
          )
        )
      ),
    );
  }
}

/*






ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () async{
            Timer.periodic(Duration(seconds: 1), (timer) async{
              bool permissionGive = false;
              permissionGive = await UsageStats.checkUsagePermission() ?? false;
              if(permissionGive){
                setState(() {
                  usagePermission = true;
                });
                if(usagePermission){
                  timer.cancel();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => UsageStatsPage())); 
                }
                timer.cancel();
              }
            });
            await UsageStats.grantUsagePermission();              
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Grant permission', style: TextStyle(fontSize: 17)),
            ],
          )
        )








*/