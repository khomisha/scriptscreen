// ignore_for_file: slash_for_doc_comments

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_facing.dart';
import 'app_menu.dart';
import 'package:base/base.dart';
import 'main_panel.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main( ) async {
    await loadConfig( );
    initLogger( );
    await initI18n( config[ 'language' ] as String? );
    await loadNotice( );
    _registerLicense( );
    AppFacing( );
    runApp( const App( ) );
}

// adds ScriptScreen's own license to Flutter's "View licenses" page
// ( third-party package licenses are collected automatically by the build )
void _registerLicense( ) {
    LicenseRegistry.addLicense( ( ) async* {
        yield LicenseEntryWithLineBreaks(
            [ notice[ 'product' ] as String ],
            '${notice[ 'product' ]}\n${notice[ 'copyright' ]}\n\n'
            'Licensed under the ${notice[ 'licenseName' ]}.\n'
            '${notice[ 'licenseUrl' ]}',
        );
    } );
}

class App extends StatelessWidget {
    const App( { super.key } );

    // This widget is the root of your application.
    @override
    Widget build( BuildContext context ) {
        return MaterialApp(
            title: 'Script Screen',
            navigatorKey: navigatorKey,
            theme: Style.theme,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
            ],
            locale: Locale( languageCode ),
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


