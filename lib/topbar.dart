import 'main.dart';
import 'package:flutter/material.dart';

final GlobalKey<TopBarState> topBarKey = GlobalKey<TopBarState>();


class TopBar extends StatefulWidget {
  final Widget child;

  const TopBar({super.key, required this.child});

  @override
  State<TopBar> createState() => TopBarState();
}

class TopBarState extends State<TopBar> {

  void update(){
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return serviceRunning == 2 || apps == null ?
    Container() : 
    Visibility(
      visible: selectedApps.isNotEmpty,
      child: widget.child                 
    );
  }
}