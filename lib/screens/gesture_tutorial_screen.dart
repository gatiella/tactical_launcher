import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/terminal_theme.dart';

class GestureTutorialScreen extends StatefulWidget {
  const GestureTutorialScreen({super.key});

  @override
  State<GestureTutorialScreen> createState() => _GestureTutorialScreenState();
}

class _GestureTutorialScreenState extends State<GestureTutorialScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<TutorialPage> _pages = [
    TutorialPage(
      icon: Icons.swipe_up,
      title: 'SWIPE UP',
      description: 'Toggle system widgets\nand quick actions',
      color: TerminalTheme.matrixGreen,
    ),
    TutorialPage(
      icon: Icons.swipe_down,
      title: 'SWIPE DOWN',
      description: 'Open app drawer\nto browse all apps',
      color: TerminalTheme.cyberCyan,
    ),
    TutorialPage(
      icon: Icons.swipe_left,
      title: 'SWIPE LEFT/RIGHT',
      description: 'Change color themes\nMatrix, Cyber, Alert, Tactical',
      color: TerminalTheme.warningYellow,
    ),
    TutorialPage(
      icon: Icons.touch_app,
      title: 'DOUBLE TAP',
      description: 'Quickly clear\nterminal screen',
      color: TerminalTheme.alertRed,
    ),
    TutorialPage(
      icon: Icons.settings,
      title: 'LONG PRESS',
      description: 'Open settings\nand preferences',
      color: TerminalTheme.matrixGreen,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TerminalTheme.black,
      body: SafeArea(
        child: Container(
          decoration: TerminalTheme.terminalDecoration,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),
              _buildIndicator(),
              _buildButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Text(
        '⚡ GESTURE CONTROLS',
        style: TerminalTheme.promptText.copyWith(fontSize: 24),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPage(TutorialPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: page.color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: page.color.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: TerminalTheme.promptText.copyWith(
              fontSize: 28,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: TerminalTheme.terminalText.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? TerminalTheme.matrixGreen
                : TerminalTheme.darkGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildButton() {
    final isLastPage = _currentPage == _pages.length - 1;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton(
        onPressed: () {
          if (isLastPage) {
            _completeTutorial();
          } else {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: TerminalTheme.matrixGreen.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: TerminalTheme.matrixGreen, width: 2),
          ),
        ),
        child: Text(
          isLastPage ? 'GET STARTED' : 'NEXT',
          style: TerminalTheme.promptText.copyWith(fontSize: 18),
        ),
      ),
    );
  }
}

class TutorialPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}