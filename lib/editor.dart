

// ignore_for_file: constant_identifier_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:path/path.dart' as p;
import 'package:base/base.dart';

class Editor {
    static final Editor _instance = Editor._( );
    late Webview _webview;
    bool created = false;
    late String _path;

    Editor._( ) {
        _path = p.join( p.current, 'assets', Config.config[ 'editor_config' ] );
    }

    factory Editor( ) {
        return _instance;
    }

    void create( ) async {
        _webview = await WebviewWindow.create(
            configuration: CreateConfiguration(
                userDataFolderWindows: p.join( Platform.environment[ 'HOME' ] ?? Platform.environment[ 'USERPROFILE' ]!, 'editor' ),
                titleBarHeight: 0,
                windowWidth: 1200,
                windowHeight: 400
            )
        );
        _webview
            ..setBrightness( Brightness.dark )
            ..launch( "file://$_path" )
            ..onClose.whenComplete( ( ) { created = false; }
        );
        created = true;
    }

    Future< String > getContent( ) async {
        return await _webview.evaluateJavaScript( 'tinymce.activeEditor.getContent()' ) ?? "";
    }

    void setContent( String content ) async {
        //content = '<div style="text-align: center;"><em><span style="font-size: 18pt;">index;title</span></em></div><div><em>description</em></div><div><em>action_time</em></div><div><em>location</em></div><div><em>detail</em></div><div><em>role</em></div><div>&nbsp;</div>';
        //print( content );
        var script = 'tinymce.activeEditor.setContent("$content")';
        await _webview.evaluateJavaScript( script );
    }

    void setVisible( bool visible ) {
        _webview.setWebviewWindowVisibility( visible );
    }
}
