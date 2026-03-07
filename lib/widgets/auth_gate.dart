import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../main_shell.dart';
import '../screens/auth_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session != null) {
          return FutureBuilder<UserModel>(
            future: SupabaseService().fetchProfile(session.user.id),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF0F0814),
                  body: Center(child: CircularProgressIndicator(color: Color(0xFFA855F7))),
                );
              }
              
              if (userSnapshot.hasData && userSnapshot.data!.deletedAt != null) {
                // Account soft-deleted, sign out and go to login
                Supabase.instance.client.auth.signOut();
                return const AuthScreen();
              }

              // Record activity
              SupabaseService().updateLastActive(session.user.id);
              return const MainShell();
            },
          );
        }

        return const AuthScreen();
      },
    );
  }
}
