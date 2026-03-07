import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'widgets/auth_gate.dart';
import 'providers/navigation_provider.dart';

class DareDayApp extends StatelessWidget {
  const DareDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFA855F7);
    const neonCyan = Color(0xFF22D3EE);
    const backgroundDark = Color(0xFF191022);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        title: 'DareDay',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: backgroundDark,
          primaryColor: primaryColor,
          colorScheme: const ColorScheme.dark(
            primary: primaryColor,
            secondary: neonCyan,
            surface: Color(0xFF2A1B3D),
          ),
          textTheme: GoogleFonts.splineSansTextTheme(
            ThemeData.dark().textTheme,
          ).apply(bodyColor: Colors.white, displayColor: Colors.white),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
