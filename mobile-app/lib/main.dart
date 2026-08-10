import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/settings_service.dart';
import 'services/behavioral_data_collector.dart';
import 'utils/constants.dart';
import 'pages/home_page.dart';
import 'pages/card_page.dart';
import 'pages/statistics_page.dart';
import 'pages/add_card_page.dart';
import 'pages/login_page.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UCOBankingApp());
}

class UCOBankingApp extends StatefulWidget {
  const UCOBankingApp({super.key});

  @override
  State<UCOBankingApp> createState() => _UCOBankingAppState();
}

class _UCOBankingAppState extends State<UCOBankingApp> {
  bool _loggedIn = false;
  bool _loading = true;
  final _behavioralCollector = BehavioralDataCollector();
  
  // Variables for tracking gestures
  DateTime? _tapStartTime;
  Offset? _tapPosition;
  DateTime? _swipeStartTime;
  Offset? _swipeStartPosition;
  Offset? _swipeEndPosition;

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _behavioralCollector.startSession();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final loginId = prefs.getString('login_id');
    setState(() {
      _loggedIn = loginId != null && loginId.isNotEmpty;
      _loading = false;
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _loggedIn = true;
    });
  }

  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('login_id');
    _behavioralCollector.recordScreenTransition('login');
    setState(() {
      _loggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    // Wrap your app in a GestureDetector to track taps and swipes
    return GestureDetector(
      onTapDown: (details) {
        // Record tap start time and position
        _tapStartTime = DateTime.now();
        _tapPosition = details.globalPosition;
      },
      onTapUp: (details) {
        // Calculate tap duration
        if (_tapStartTime != null) {
          final duration = DateTime.now().difference(_tapStartTime!);
          _behavioralCollector.recordTap(_tapPosition ?? Offset.zero, duration);
        }
      },
      onPanStart: (details) {
        // Record swipe start time and position
        _swipeStartTime = DateTime.now();
        _swipeStartPosition = details.globalPosition;
      },
      onPanEnd: (details) {
        // Calculate swipe details if we have start position
        if (_swipeStartPosition != null && _swipeStartTime != null) {
          final duration = DateTime.now().difference(_swipeStartTime!);
          _behavioralCollector.recordSwipe(
            _swipeStartPosition!, 
            _swipeEndPosition ?? _swipeStartPosition!, 
            duration
          );
        }
      },
      onPanUpdate: (details) {
        // Update swipe end position
        _swipeEndPosition = details.globalPosition;
      },
      child: MaterialApp(
        title: 'UCO Banking App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryBlue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.darkBackground,
        ),
        home: _loggedIn
            ? BankingHomePage(onLogout: _onLogout)
            : LoginPage(onLoginSuccess: _onLoginSuccess),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}


class BankingHomePage extends StatefulWidget {
  final VoidCallback onLogout;
  const BankingHomePage({super.key, required this.onLogout});

  @override
  State<BankingHomePage> createState() => _BankingHomePageState();
}

class _BankingHomePageState extends State<BankingHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToHome() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const HomePage();
      case 1:
        return CardPage(onBackPressed: _navigateToHome);
      case 2:
        return StatisticsPage(onBackPressed: _navigateToHome, onLogout: widget.onLogout);
      case 3:
        return AddCardPage(onBackPressed: _navigateToHome, onCardAdded: () => setState(() {}));
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentPage(),
      bottomNavigationBar: Container(
        height: AppSizes.bottomNavHeight,
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.credit_card, 1),
            _buildNavItem(Icons.bar_chart, 2),
            _buildNavItem(Icons.add, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _selectedIndex == index 
              ? AppColors.primaryBlue 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.smallBorderRadius),
        ),
        child: Icon(
          icon,
          color: AppColors.white,
          size: AppSizes.iconSize,
        ),
      ),
    );
  }
}
