import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/uid_login_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _schoolSymbolController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _uidController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _schoolSymbolController.dispose();
    _schoolNameController.dispose();
    _managerNameController.dispose();
    _uidController.dispose();
    super.dispose();
  }

  void _showUidLoginDialog() {
    _uidController.clear();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UidLoginDialog(
        uidController: _uidController,
        authService: _authService,
        onSuccess: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        },
        onError: (msg) {
          Navigator.of(ctx).pop();
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 5)));
        },
      ),
    );
  }

  void _handleUidLogin() {
    _showUidLoginDialog();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        // הרשמה
        await _authService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _schoolSymbolController.text.trim(),
        );
        
        // יצירת בית ספר
        await _firestoreService.createSchool(
          _schoolSymbolController.text.trim(),
          _schoolNameController.text.trim(),
          managerName: _managerNameController.text.trim().isNotEmpty
              ? _managerNameController.text.trim()
              : null,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('נרשמת בהצלחה!')),
          );
          // ניווט למסך הבית וניקוי ההיסטוריה
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else {
        // התחברות
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('התחברת בהצלחה!')),
          );
          // ניווט למסך הבית וניקוי ההיסטוריה
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    // לוגו חמ"ד
                    Column(
                      children: [
                        // ריבועים צבעוניים מעל (מופחתים)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFac2b31).withOpacity(0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFfaa41a).withOpacity(0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFb2d234).withOpacity(0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF11a0db).withOpacity(0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // טקסט "חמד"
                        const Text(
                          'חמד',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF11a0db),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // טקסט "בית חינוך כמשפחה"
                        Text(
                          'בית חינוך כמשפחה',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'שימור',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'מעקב אחרי מצב המורים',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'אימייל',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'נא להזין אימייל';
                        }
                        if (!value.contains('@')) {
                          return 'אימייל לא תקין';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'סיסמה',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'נא להזין סיסמה';
                        }
                        if (value.length < 6) {
                          return 'סיסמה חייבת להכיל לפחות 6 תווים';
                        }
                        return null;
                      },
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _schoolSymbolController,
                        decoration: InputDecoration(
                          labelText: 'סמל מוסד',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'נא להזין סמל מוסד';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _schoolNameController,
                        decoration: InputDecoration(
                          labelText: 'שם בית הספר',
                          prefixIcon: const Icon(Icons.school),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'נא להזין שם בית ספר';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _managerNameController,
                        decoration: InputDecoration(
                          labelText: 'שם המנהל/ת',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF11a0db),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _isSignUp ? 'הרשמה' : 'התחברות',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                        });
                      },
                      child: Text(
                        _isSignUp
                            ? 'יש לך חשבון? התחבר'
                            : 'אין לך חשבון? הירשם',
                        style: const TextStyle(
                          color: Color(0xFF11a0db),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: TextButton(
                        onPressed: _handleUidLogin,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Colors.grey[500],
                        ),
                        child: const Text(
                          'Login as...',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}

class _UidLoginDialog extends StatefulWidget {
  const _UidLoginDialog({
    required this.uidController,
    required this.authService,
    required this.onSuccess,
    required this.onError,
  });

  final TextEditingController uidController;
  final AuthService authService;
  final VoidCallback onSuccess;
  final void Function(String) onError;

  @override
  State<_UidLoginDialog> createState() => _UidLoginDialogState();
}

class _UidLoginDialogState extends State<_UidLoginDialog> {
  bool _isLoading = false;

  Future<void> _submit() async {
    final uid = widget.uidController.text.trim();
    if (uid.isEmpty) {
      widget.onError('נא להזין UID');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = await UidLoginService.getCustomTokenForUid(uid);
      await widget.authService.signInWithCustomToken(token);
      if (mounted) {
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        widget.onError(msg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('התחבר כמשתמש אחר'),
        content: TextField(
          controller: widget.uidController,
          decoration: const InputDecoration(
            labelText: 'UID מפיירבייס',
            hintText: 'הדביקי את ה-UID',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF11a0db)),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('התחבר'),
          ),
        ],
      ),
    );
  }
}

