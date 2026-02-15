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
                const double barHeight = 72;
                const double circleRadius = 13;

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

                final double notchCenterX =
                    (leftForCircle - horizontalPadding) + circleRadius;

                return SizedBox(
                  height: barHeight + circleRadius + 8,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        bottom: 0,
                        child: PhysicalShape(
                          color: Colors.white,
                          elevation: 6,
                          clipper: _NavBarNotchedClipper(
                            notchCenterX: notchCenterX,
                            notchWidth: circleRadius * 2.2,
                            notchDepth: circleRadius * 0.85,
                            cornerRadius: 32,
                          ),
                          child: SizedBox(
                            height: barHeight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(itemCount, (index) {
                                final item = _items[index];
                                final bool isActive = index == currentIndex;
                                final Color accentColor = _accentColors[
                                    index % _accentColors.length];

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
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutQuad,
                        top: -circleRadius * 0.2,
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

class _NavBarNotchedClipper extends CustomClipper<Path> {
  _NavBarNotchedClipper({
    required this.notchCenterX,
    required this.notchWidth,
    required this.notchDepth,
    required this.cornerRadius,
  });

  final double notchCenterX;
  final double notchWidth;
  final double notchDepth;
  final double cornerRadius;

  @override
  Path getClip(Size size) {
    final double r =
        cornerRadius.clamp(0, size.height / 2);

    final double halfWidth = (notchWidth / 2).clamp(8, size.width / 2 - r - 4);
    final double startX = (notchCenterX - halfWidth).clamp(r + 4, size.width - r - 4);
    final double endX = (notchCenterX + halfWidth).clamp(r + 4, size.width - r - 4);
    final double midX = notchCenterX;
    final double depth = notchDepth.clamp(4, size.height * 0.45);

    final Path path = Path();

    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(startX, 0);

    // גומה מעוגלת: צדדים רכים (בקרה קרוב ל־y=0) ואמצע מעוגל (פגישה בתחתית) – בלי שפיץ
    const double sideBlend = 0.18; // חיבור רך לצדדים
    const double midBlend = 0.8;   // עיגול האמצע
    path.quadraticBezierTo(
      startX + halfWidth * midBlend,
      depth * sideBlend,
      midX,
      depth,
    );
    path.quadraticBezierTo(
      endX - halfWidth * midBlend,
      depth * sideBlend,
      endX,
      0,
    );

    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);
    path.lineTo(size.width, size.height - r);
    path.quadraticBezierTo(
        size.width, size.height, size.width - r, size.height);
    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);
    path.lineTo(0, r);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _NavBarNotchedClipper oldClipper) {
    return oldClipper.notchCenterX != notchCenterX ||
        oldClipper.notchWidth != notchWidth ||
        oldClipper.notchDepth != notchDepth ||
        oldClipper.cornerRadius != cornerRadius;
  }
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
