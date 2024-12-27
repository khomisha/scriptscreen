// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors_in_immutables, avoid_print

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_linux_webview/flutter_linux_webview.dart';


class Browser extends StatefulWidget {
    final String initialUrl;
    late final WebViewController controller;

    Browser( { super.key, required this.initialUrl } );

    @override
    _BrowserState createState( ) => _BrowserState( );
}

class _BrowserState extends State< Browser > with WidgetsBindingObserver {
    final Completer< WebViewController > _completer = Completer< WebViewController >( );

    @override
    void initState( ) {
        super.initState( );
        WidgetsBinding.instance.addObserver( this );
    }

    @override
    void dispose( ) {
        WidgetsBinding.instance.removeObserver( this );
        super.dispose( );
    }

    @override
    Future< AppExitResponse > didRequestAppExit( ) async {
        await LinuxWebViewPlugin.terminate( );
        return AppExitResponse.exit;
    }

    @override
    Widget build( BuildContext context ) {
        var webview = WebView(
            initialUrl: widget.initialUrl,
            onWebViewCreated: ( WebViewController controller ) {                   
                _completer.complete( controller );
                widget.controller = controller;
                print( "controller completed" );
            },
            javascriptMode: JavascriptMode.unrestricted,
        );
        return webview;
    }
}
