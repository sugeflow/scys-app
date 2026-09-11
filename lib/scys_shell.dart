import 'package:flutter/material.dart';

import 'scys_navigation.dart';

class ScysShell extends StatefulWidget {
  const ScysShell({
    super.key,
    required this.webContent,
    required this.onNavigate,
    this.showNavigationBar = true,
  });

  final Widget webContent;
  final ValueChanged<String> onNavigate;
  final bool showNavigationBar;

  @override
  State<ScysShell> createState() => _ScysShellState();
}

class _ScysShellState extends State<ScysShell> {
  int _selectedIndex = 0;

  void _selectSection(int index) {
    widget.onNavigate(scysTabs[index].path);
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.webContent,
      bottomNavigationBar: widget.showNavigationBar
          ? DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFECECEC))),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _selectSection,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: const Color(0xFF50AE9F),
                unselectedItemColor: const Color(0xFF9A9A9A),
                selectedFontSize: 10,
                unselectedFontSize: 10,
                iconSize: 25,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.article_outlined),
                    activeIcon: Icon(Icons.article_rounded),
                    label: '看帖',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.layers_outlined),
                    activeIcon: Icon(Icons.layers_rounded),
                    label: '项目',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.sailing_outlined),
                    activeIcon: Icon(Icons.sailing_rounded),
                    label: '航海',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.groups_2_outlined),
                    activeIcon: Icon(Icons.groups_2_rounded),
                    label: '聚会',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    activeIcon: Icon(Icons.person_rounded),
                    label: '我的',
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
