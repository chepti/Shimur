import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/teachers_list_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('שגיאה באתחול Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'שימור',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF11a0db),
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF11a0db),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigationScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TeachersListScreen(),
    const TasksScreen(),
    const DashboardScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onItemSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  static const Color _navBackground = Color(0xFF11a0db);

  static const List<Color> _accentColors = [
    Color(0xFFed1c24),
    Color(0xFFfaa41a),
    Color(0xFFb2d234),
    Color(0xFF40ae49),
  ];

  static const List<_NavItemData> _items = [
    _NavItemData(
      icon: Icons.people,
      label: 'הצוות שלי',
    ),
    _NavItemData(
      icon: Icons.task_alt,
      label: 'משימות',
    ),
    _NavItemData(
      icon: Icons.dashboard,
      label: 'דשבורד',
    ),
    _NavItemData(
      icon: Icons.settings,
      label: 'הגדרות',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: _navBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double horizontalPadding = 16;
                const double barHeight = 64;
                const double circleRadius = 16;

                final double barWidth =
                    constraints.maxWidth - (horizontalPadding * 2);
                final int itemCount = _items.length;
                final double itemWidth = barWidth / itemCount;

                final bool isRtl =
                    Directionality.of(context) == TextDirection.rtl;
                final int visualIndex =
                    isRtl ? (itemCount - 1 - currentIndex) : currentIndex;

                final double leftForCircle =
                    horizontalPadding + (itemWidth * visualIndex) +
                        (itemWidth / 2) -
                        circleRadius;

                return SizedBox(
                  height: barHeight + circleRadius + 8,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        bottom: 0,
                        child: Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(itemCount, (index) {
                              final item = _items[index];
                              final bool isActive = index == currentIndex;
                              final Color accentColor =
                                  _accentColors[index % _accentColors.length];

                              return Expanded(
                                child: _NavItem(
                                  data: item,
                                  isActive: isActive,
                                  accentColor: accentColor,
                                  onTap: () => onItemSelected(index),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutQuad,
                        top: -circleRadius + 6,
                        left: leftForCircle,
                        child: Container(
                          width: circleRadius * 2,
                          height: circleRadius * 2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _navBackground,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  final _NavItemData data;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isActive ? accentColor : Colors.grey.shade700;
    final Color textColor = isActive ? accentColor : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.icon,
              color: iconColor,
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
