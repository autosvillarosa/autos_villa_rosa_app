import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'actividad_screen.dart';
import 'coches_screen.dart';
import 'citas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const ActividadScreen(),
    const CochesScreen(),
    const CitasScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si es web o Android
    if (kIsWeb) {
      return _buildWebLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  // Diseño para web (barra lateral)
  Widget _buildWebLayout() {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar de navegación
            Container(
              width: 80.0,
              color: Colors.grey.shade200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 16.0),
                  _buildNavItem(Icons.list, 'Actividad', 0),
                  const SizedBox(height: 16.0),
                  _buildNavItem(Icons.car_rental, 'Coches', 1),
                  const SizedBox(height: 16.0),
                  _buildNavItem(Icons.calendar_today, 'Citas', 2),
                ],
              ),
            ),
            // Contenido principal
            Expanded(
              child: _screens[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }

  // Diseño para Android (barra inferior)
  Widget _buildMobileLayout() {
    return Scaffold(
      body: SafeArea(
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Actividad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.car_rental),
            label: 'Coches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Citas',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.grey.shade800,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.grey.shade200,
        onTap: _onItemTapped,
      ),
    );
  }

  // Método para los ítems de la barra lateral (usado en web)
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade300 : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.grey.shade800 : Colors.grey.shade600,
              size: 24.0,
            ),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.grey.shade800 : Colors.grey.shade600,
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
