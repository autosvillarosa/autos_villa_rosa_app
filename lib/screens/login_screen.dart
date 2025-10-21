import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = '$username@autosvillarosa.com';

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null && mounted) {
        _usernameController.clear();
        _passwordController.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message.contains('invalid login credentials')
              ? 'La clave es errónea'
              : e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error inesperado: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseFontSize =
        Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Container(
          color: Theme.of(context).canvasColor,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo con fondo circular blanco
                  Container(
                    width: 150.0,
                    height: 150.0,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo_avs.png',
                        height: 100.0,
                        width: 100.0,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  // Título
                  Text(
                    'Iniciar Sesión',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24.0),
                  // Campo de usuario
                  SizedBox(
                    width: 300.0, // Ancho fijo para el campo de usuario
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre de Usuario',
                          labelStyle:
                              Theme.of(context).inputDecorationTheme.labelStyle,
                          prefixIcon: const Icon(Icons.person, size: 20.0),
                          contentPadding: Theme.of(context)
                              .inputDecorationTheme
                              .contentPadding,
                          filled: Theme.of(context).inputDecorationTheme.filled,
                          fillColor:
                              Theme.of(context).inputDecorationTheme.fillColor,
                          border: Theme.of(context).inputDecorationTheme.border,
                          enabledBorder: Theme.of(context)
                              .inputDecorationTheme
                              .enabledBorder,
                          focusedBorder: Theme.of(context)
                              .inputDecorationTheme
                              .focusedBorder,
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: baseFontSize + 1),
                      ),
                    ),
                  ),
                  // Campo de contraseña
                  SizedBox(
                    width: 300.0, // Ancho fijo para el campo de contraseña
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Clave',
                          labelStyle:
                              Theme.of(context).inputDecorationTheme.labelStyle,
                          prefixIcon: const Icon(Icons.lock, size: 20.0),
                          contentPadding: Theme.of(context)
                              .inputDecorationTheme
                              .contentPadding,
                          filled: Theme.of(context).inputDecorationTheme.filled,
                          fillColor:
                              Theme.of(context).inputDecorationTheme.fillColor,
                          border: Theme.of(context).inputDecorationTheme.border,
                          enabledBorder: Theme.of(context)
                              .inputDecorationTheme
                              .enabledBorder,
                          focusedBorder: Theme.of(context)
                              .inputDecorationTheme
                              .focusedBorder,
                        ),
                        obscureText: true,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: baseFontSize + 1),
                      ),
                    ),
                  ),
                  // Mensaje de error
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16.0),
                  // Botón de iniciar sesión
                  ElevatedButton(
                    onPressed: _login,
                    style: Theme.of(context).elevatedButtonTheme.style,
                    child: const Text(
                      'Ingresar',
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
