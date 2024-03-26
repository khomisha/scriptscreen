// ignore_for_file: slash_for_doc_comments

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:scriptscreen/app_facing.dart';
import 'base/style.dart';
//import 'base/util.dart';
import 'main_panel.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main( ) {
    //FlutterError.onError = logOnErrorFlutter;
    //PlatformDispatcher.instance.onError = logOnErrorPlatform;
    AppFacing( );
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


