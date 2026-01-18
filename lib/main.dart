import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/teachers_list_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';

// הערה: firebase_options.dart נוצר אוטומטית על ידי flutterfire configure
// אם הקובץ לא קיים, הרץ: flutterfire configure
// לאחר מכן, הוסף כאן: import 'firebase_options.dart';
// ושנה את השורה הבאה ל: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // אם יש firebase_options.dart, השתמש בו:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // אחרת, השתמש בהגדרות ידניות (לא מומלץ לפרודקשן):
    await Firebase.initializeApp();
  } catch (e) {
    // אם יש שגיאה, ודא שרצת: flutterfire configure
    debugPrint('שגיאה באתחול Firebase: $e');
    debugPrint('הרץ: flutterfire configure');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'שימור',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF11a0db),
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardTheme(
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
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TeachersListScreen(),
    const TasksScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: const Color(0xFF11a0db),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'הצוות שלי',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt),
              label: 'משימות',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'הגדרות',
            ),
          ],
        ),
      ),
    );
  }
}

