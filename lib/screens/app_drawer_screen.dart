import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_manager_service.dart';
import '../themes/terminal_theme.dart';
import '../widgets/app_icon_widget.dart';

class AppDrawerScreen extends StatefulWidget {
  const AppDrawerScreen({super.key});

  @override
  State<AppDrawerScreen> createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends State<AppDrawerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              _buildSearchBar(),
              Expanded(
                child: _buildAppList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: TerminalTheme.matrixGreen, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: TerminalTheme.matrixGreen),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'APP DRAWER',
            style: TerminalTheme.promptText,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: TerminalTheme.terminalText,
        decoration: InputDecoration(
          hintText: 'Search apps...',
          hintStyle: TextStyle(color: TerminalTheme.darkGreen),
          prefixIcon: Icon(Icons.search, color: TerminalTheme.matrixGreen),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: TerminalTheme.matrixGreen),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: TerminalTheme.matrixGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: TerminalTheme.cyberCyan, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildAppList() {
    return Consumer<AppManagerService>(
      builder: (context, appService, child) {
        if (appService.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: TerminalTheme.matrixGreen,
            ),
          );
        }

        final apps = _searchQuery.isEmpty
            ? appService.installedApps
            : appService.searchApps(_searchQuery);

        if (apps.isEmpty) {
          return Center(
            child: Text(
              'No apps found',
              style: TerminalTheme.terminalText,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            return AppIconWidget(
              app: app,
              onTap: () async {
                await appService.launchApp(app.packageName);
              },
            );
          },
        );
      },
    );
  }
}