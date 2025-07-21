// ignore_for_file: slash_for_doc_comments

import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_facing.dart';
import 'package:base/base.dart';
import 'main_panel.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main( ) async {
    AppFacing( );
    await loadConfig( );
    initLogger( );
    runApp( const App( ) );
}

class App extends StatelessWidget {
    const App( { super.key } );

    // This widget is the root of your application.
    @override
    Widget build( BuildContext context ) {
        return MaterialApp(
            title: 'Script Screen',
            theme: Style.theme,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
                Locale( 'ru', 'RU' ), 
                Locale( 'en', 'US' )
            ],
            scrollBehavior: _CustomScrollBehavior( ),
            home: MainPanel( )
        );
    }
}

class _CustomScrollBehavior extends MaterialScrollBehavior {
    // Override behavior methods and getters like dragDevices
    @override
    Set< PointerDeviceKind > get dragDevices => { 
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch
    };
}


