// ignore_for_file: avoid_print
import 'package:configclient/components/ConfigSelect/ConfigSelect.dart';
import 'package:configclient/login.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

String host = "192.168.2.83";

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ConfigClient());
}

class ConfigClient extends StatelessWidget {
  const ConfigClient({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic;
          darkColorScheme = darkDynamic;
        } else {
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Config Client',
          theme: ThemeData(colorScheme: lightColorScheme, useMaterial3: true),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
          ),
          home: LoginView(
            onLogin: (context) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfigSelect(host: host) 
                )
              );
            },
            host: host,
          ),
        );
      },
    );
  }
}