import 'ads.dart';
import 'main.dart';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      maintainBottomViewPadding: true,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 12, 12, 12),
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: BannerAdWidget(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget> [
              Padding(
                padding: const EdgeInsets.only(left: 0, right: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 12, right: 12),
                      child: Text("\nSet app usage goals...", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
                      child: Text("Once you reach your usage goal limit, You will be reminded every time you open the app, you can still choose to use the app.", style: TextStyle(color: Colors.grey, height: 1.5)),
                    ),
                    SizedBox(height: 3),
                  ] +
                  [
                    //BannerAdWidget(),
                    NativeAdWidget()
                  ] +
                  List.generate(
                    apps!.length,
                    (index) {
                      ApplicationWithIcon app = apps![index];
                      if(selectedApps.contains(app.packageName)){
                        return Padding(
                          padding: const EdgeInsets.only(left: 12, right: 12),
                          child: ListTile(
                            contentPadding: index != apps!.length - 1 ? const EdgeInsets.only(left:0, right: 0, top: 5, bottom: 5) : const EdgeInsets.only(left: 0, right: 0, top: 5, bottom: 80),
                            leading: SizedBox(height: 39, width: 39, child: Image(image: MemoryImage(app.icon))),
                            title: SizedBox(height: 30, child: Text(app.appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18.5, fontWeight: FontWeight.w700))),
                            subtitle: Text("${(usage[index] ~/ 3600000)}:${((usage[index] ~/ 60000) % 60).toString().padLeft(2, '0')}:${((usage[index] ~/ 1000) % 60).toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 14),),
                            trailing: OutlinedButton(
                              onPressed: (){
                                showModalBottomSheet(
                                  context: context, 
                                  enableDrag: false,
                                  isDismissible: false, 
                                  builder: (context){
                                    return WillPopScope(
                                      onWillPop: () async{
                                        setState((){});
                                        Navigator.pop(context);
                                        return false;
                                      },
                                      child: BottomSheet(
                                        onClosing: (){setState((){});}, 
                                        backgroundColor: const Color.fromARGB(255, 20, 20, 20),
                                        builder: (context){
                                          return Padding(
                                            padding: const EdgeInsets.all(0),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children : [
                                                  DurationField(indexValue: selectedApps.indexOf(app.packageName)),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 12, right: 12),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: OutlinedButton(
                                                            onPressed: () async{
                                                              goals[selectedApps.indexOf(app.packageName)] = 0;
                                                              setState((){});
                                                              Navigator.pop(context);
                                                              await preferences.setStringList('goals', List.generate(selectedApps.length, (index) => goals[index].toString()));    
                                                              startService();
                                                            }, 
                                                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                                                            child: const Text("No goal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: OutlinedButton(
                                                            onPressed: () async{
                                                              goals[selectedApps.indexOf(app.packageName)] = 1;
                                                              setState((){});
                                                              Navigator.pop(context);
                                                              await preferences.setStringList('goals', List.generate(selectedApps.length, (index) => goals[index].toString()));    
                                                              startService();
                                                            }, 
                                                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                                                            child: const Text("Always remind", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                                          ),
                                                        )
                                                      ]
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 12, right: 12),
                                                    child: ElevatedButton(
                                                      onPressed: () async{
                                                        setState((){});
                                                        Navigator.pop(context);                                                        
                                                        startService();
                                                      },
                                                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.max, children: [Text("Select goal")])
                                                    ),
                                                  )
                                                ]
                                              ),
                                            ),
                                          );
                                        }
                                      ),
                                    );
                                  }
                                );
                              },
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                              child: Text(goals[selectedApps.indexOf(app.packageName)] == 0 ? "Set goal" : (goals[selectedApps.indexOf(app.packageName)] != 1 ? "${(goals[selectedApps.indexOf(app.packageName)] ~/ 3600000)}:${((goals[selectedApps.indexOf(app.packageName)] ~/ 60000) % 60).toString().padLeft(2, '0')}" : "Always remind"), style: const TextStyle(fontWeight: FontWeight.bold))
                            )
                          ),
                        );
                      }
                      else{
                        return const SizedBox();
                      }
                    }                
                  )                  
                ),
              ),
            ]
          ),
        )
      ),
    );
  }
}

class DurationField extends StatefulWidget {
  final int indexValue;

  const DurationField({super.key, required this.indexValue});

  @override
  State<DurationField> createState() => _DurationFieldState();
}

class _DurationFieldState extends State<DurationField> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          BannerAdWidget(),
          
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Text("Set goal usage...", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(width: 0.8, color: Colors.grey), borderRadius: BorderRadius.circular(5)), 
                        padding: const EdgeInsets.all(8.0),
                        child: Text(goals[widget.indexValue] == 0 ? "Set goal" : (goals[widget.indexValue] != 1 ? "${(goals[widget.indexValue] ~/ 3600000)}:${((goals[widget.indexValue] ~/ 60000) % 60).toString().padLeft(2, '0')}" : "Always remind"))
                      )                
                    )
                  ],
                ),
          
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
          
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(width: 0.8, color: Colors.grey), borderRadius: BorderRadius.circular(5)), 
                        padding: const EdgeInsets.all(8.0),
                        child: const Text("  Hours "),
                      )                
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            11,
                            (index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0, left: 8.0),
                                child: GestureDetector(
                                  onTap: () async{  
                                    setState(() {
                                      goals[widget.indexValue] = (goals[widget.indexValue] % 3600000) + (index) * 3600000;
                                    });
                                    await preferences.setStringList('goals', List.generate(selectedApps.length, (index) => goals[index].toString()));
                                  },                            
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(border: Border.all(width: 0.8, color: (goals[widget.indexValue] ~/ 3600000) == (index) ? Colors.green : Colors.grey), borderRadius: BorderRadius.circular(5), color: (goals[widget.indexValue] ~/ 3600000) == (index) ? Colors.green : Colors.transparent), 
                                    child:  Text((index).toString()),
                                  ),
                                ),
                              );
                            }
                          )
                        ),
                      ),
                    )
                  ]
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(width: 0.8, color: Colors.grey), borderRadius: BorderRadius.circular(5)), 
                        padding: const EdgeInsets.all(8.0),
                        child: const Text("Minutes"),
                      )                
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            12,
                            (index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0, left: 8.0),
                                child: GestureDetector(
                                  onTap: () async{
                                    setState(() {
                                      goals[widget.indexValue] = (index*5)*60000 + (goals[widget.indexValue] ~/ 3600000) * 3600000;
                                    });
                                    await preferences.setStringList('goals', List.generate(selectedApps.length, (index) => goals[index].toString()));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(border: Border.all(width: 0.8, color: (goals[widget.indexValue] % 3600000) / 60000 == ((index) * 5) && goals[widget.indexValue] != 0 ? Colors.green : Colors.grey), borderRadius: BorderRadius.circular(5), color: (goals[widget.indexValue] % 3600000) / 60000 == ((index) * 5) && goals[widget.indexValue] != 0 ? Colors.green : Colors.transparent), 
                                    child:  Text(((index) * 5).toString()),
                                  ),
                                ),
                              );
                            }
                          )
                        ),
                      ),
                    )
                  ]
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
              ],
            ),
          )
        ],
      )
    );
  }
}