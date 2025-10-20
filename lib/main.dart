import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  // ignore: deprecated_member_use
  final int r = (color.red * 255.0).round() & 0xff;
  // ignore: deprecated_member_use
  final int g = (color.green * 255.0).round() & 0xff;
  // ignore: deprecated_member_use
  final int b = (color.blue * 255.0).round() & 0xff;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  final int colorValue = (0xFF << 24) | (r << 16) | (g << 8) | b;
  return MaterialColor(colorValue, swatch);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  await Supabase.initialize(
    url: 'https://dkctepzpessgbalewkjl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY3RlcHpwZXNzZ2JhbGV3a2psIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4NzI5MjIsImV4cCI6MjA3MzQ0ODkyMn0.vrEN2cCWobFh8bsVMftIC8wvC3_GobBUMItAMF813V4',
  );

  final initialScreen = Supabase.instance.client.auth.currentSession != null
      ? const HomeScreen()
      : const LoginScreen();

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autos Villarosa App',
      theme: ThemeData(
        primaryColor: const Color(0xFF0053A0),
        scaffoldBackgroundColor: const Color(0xFF0053A0),
        canvasColor: const Color(0xFFE6F0FA),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: createMaterialColor(const Color(0xFF0053A0)),
          accentColor: const Color(0xFF1A6BB8),
          backgroundColor: const Color(0xFFE6F0FA),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0053A0),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFF0053A0), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFF0053A0), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFF0053A0), width: 2.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A6BB8),
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: const BorderSide(color: Color(0xFF0053A0), width: 1.0),
            ),
            minimumSize: const Size(120.0, 38.0),
            textStyle: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(color: Colors.grey.shade400, width: 1.0),
            ),
            minimumSize: const Size(120.0, 38.0),
            textStyle: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black),
          labelMedium: TextStyle(fontSize: 14.0, color: Colors.black),
          titleLarge: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0053A0),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black,
          contentTextStyle: TextStyle(
            fontSize: 14.0,
            color: Colors.white,
          ),
          actionTextColor: Colors.white,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0053A0),
          ),
          contentTextStyle:
              const TextStyle(fontSize: 14.0, color: Colors.black),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: const TextStyle(fontSize: 14.0, color: Colors.black),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide:
                  const BorderSide(color: Color(0xFF0053A0), width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide:
                  const BorderSide(color: Color(0xFF0053A0), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide:
                  const BorderSide(color: Color(0xFF0053A0), width: 2.0),
            ),
          ),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(Colors.white),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: const BorderSide(color: Colors.grey, width: 1.0),
              ),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey.shade200,
          selectedColor: const Color(0xFF0053A0),
          disabledColor: Colors.grey.shade400,
          labelStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.grey.shade400, width: 1.0),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1A6BB8),
          foregroundColor: Colors.white,
          shape: CircleBorder(
            side: BorderSide(color: Color(0xFF0053A0), width: 1.0),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey.shade200,
          selectedItemColor: Colors.grey.shade800,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle:
              const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12.0),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF0053A0),
          linearTrackColor: Colors.grey,
        ),
      ),
      home: initialScreen,
    );
  }
}
