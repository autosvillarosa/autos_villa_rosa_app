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
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Actividad'),
          BottomNavigationBarItem(
              icon: Icon(Icons.car_rental), label: 'Coches'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Citas'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor:
            Colors.grey.shade800, // Gris oscuro para ítem seleccionado
        unselectedItemColor:
            Colors.grey.shade600, // Gris medio para ítems no seleccionados
        backgroundColor:
            Colors.grey.shade200, // Gris claro como los botones de filtro
        onTap: _onItemTapped,
      ),
    );
  }
}
