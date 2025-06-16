// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Para localización (idioma, formato)
import 'screens/home_screen.dart'; // Importa la pantalla principal

void main() {
  // Es MUY IMPORTANTE llamar a ensureInitialized() antes de usar plugins
  // como sqflite o path_provider, especialmente antes de runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Inicia la aplicación Flutter
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Gastos SV', // Título de la aplicación
      debugShowCheckedModeBanner:
          false, // Oculta la cinta "Debug" en la esquina
      // --- TEMA GLOBAL DE LA APLICACIÓN ---
      // ----- ¡ESTA ES LA ZONA PRINCIPAL PARA PERSONALIZAR EL LOOK & FEEL GENERAL! -----
      theme: ThemeData(
        // Define la paleta de colores principal
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, // Color base para generar la paleta
          // Puedes sobreescribir colores específicos:
          primary: Colors.deepPurpleAccent,
          secondary: Colors.amber,
          surface: Colors.white, // Color de fondo de superficies como Card
          background: Colors.grey[50], // Color de fondo general del Scaffold
          error: Colors.redAccent, // Color para errores
          onPrimary: Colors.white, // Color del texto sobre el color primario
          onSecondary:
              Colors.black, // Color del texto sobre el color secundario
          onSurface: Colors.black87, // Color del texto sobre superficies
          onBackground:
              Colors.black87, // Color del texto sobre el fondo general
          onError: Colors.white, // Color del texto sobre el color de error
        ),
        useMaterial3: true, // Habilita el diseño Material 3 (recomendado)
        // Define la fuente principal de la aplicación (¡Asegúrate de añadirla en pubspec.yaml si usas una custom!)
        // fontFamily: 'Montserrat', // Ejemplo

        // Personaliza la apariencia del AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurpleAccent, // Color de fondo del AppBar
          foregroundColor:
              Colors.white, // Color del título y los iconos del AppBar
          elevation: 4.0, // Sombra
          centerTitle: true, // Centra el título
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            // fontFamily: 'Montserrat', // Aplica fuente si la definiste
          ),
        ),

        // Personaliza la apariencia de las tarjetas (Card)
        cardTheme: CardTheme(
          elevation: 2.0, // Sombra ligera
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Bordes redondeados
          ),
          color: Colors.white, // Color de fondo de la tarjeta
        ),

        // Personaliza los botones flotantes (FloatingActionButton)
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.amber, // Color de fondo
          foregroundColor: Colors.black, // Color del icono/texto
          elevation: 6.0,
        ),

        // Personaliza la apariencia de los campos de texto (InputDecoration)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.deepPurple.withOpacity(0.05), // Relleno muy sutil
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none, // Sin borde por defecto
          ),
          enabledBorder: OutlineInputBorder(
            // Borde cuando está habilitado pero no enfocado
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            // Borde cuando está enfocado
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              color: Colors.deepPurpleAccent,
              width: 2.0,
            ),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]), // Estilo del label
          prefixIconColor:
              Colors.deepPurpleAccent, // Color de los iconos de prefijo
        ),

        // Personaliza los botones elevados (ElevatedButton)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent, // Color de fondo
            foregroundColor: Colors.white, // Color del texto/icono
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Personaliza los botones de texto (TextButton)
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.deepPurpleAccent, // Color del texto
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        // ... puedes añadir más personalizaciones aquí (ListTileTheme, DialogTheme, etc.)
      ),
      // ----- FIN DE LA PERSONALIZACIÓN DEL TEMA -----

      // Configuración de localización para soportar Español (El Salvador)
      localizationsDelegates: const [
        GlobalMaterialLocalizations
            .delegate, // Localización para widgets de Material
        GlobalWidgetsLocalizations.delegate, // Localización general de widgets
        GlobalCupertinoLocalizations
            .delegate, // Localización para widgets de Cupertino (iOS style)
      ],
      supportedLocales: const [
        Locale(
          'es',
          'SV',
        ), // Español, específico para El Salvador (para formatos de fecha/moneda)
        Locale('es', ''), // Español genérico (fallback)
        Locale('en', ''), // Inglés (fallback)
      ],
      locale: const Locale(
        'es',
        'SV',
      ), // Establece el idioma por defecto de la app
      // La pantalla inicial de la aplicación
      home: const HomeScreen(),
    );
  }
}
