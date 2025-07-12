import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';

// Services
import 'services/supabase_service.dart';

// Providers
import 'providers/dashboard_provider.dart';
import 'providers/reservas_provider.dart';
import 'providers/clientes_provider.dart';
import 'providers/inventario_provider.dart';

// Screens
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar ventana para desktop
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1400, 800),
    minimumSize: Size(1200, 700),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'MistiWasi - Sistema de Gestión',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://jopucpjkfzhaxnwkfwuh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvcHVjcGprZnpoYXhud2tmd3VoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNjY5MDksImV4cCI6MjA2Nzc0MjkwOX0.T4kNbDHusGSJriRkd1Nbr9eI17FWUeSwenvwZZT1iRI',
  );

  runApp(const MistiWasiApp());
}

class MistiWasiApp extends StatelessWidget {
  const MistiWasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ReservasProvider()),
        ChangeNotifierProvider(create: (_) => ClientesProvider()),
        ChangeNotifierProvider(create: (_) => InventarioProvider()),
      ],
      child: MaterialApp(
        title: 'MistiWasi Desktop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(),
          cardTheme: const CardThemeData(
            elevation: 2,
            margin: EdgeInsets.all(8),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black87,
          ),
        ),
        home: const MainLayout(),
      ),
    );
  }
}