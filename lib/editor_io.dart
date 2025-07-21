// ignore_for_file: constant_identifier_names, slash_for_doc_comments

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:path/path.dart' as p;
import 'package:base/base.dart';
import 'app_const.dart';
import 'editor.dart';

class EditorImpl implements Editor {
    late Webview _webview;
    // path to start page for webview, must put tinymce in GenericFile.assetsDir
    final String _path = p.join( GenericFile.assetsDir, config[ 'editor_config' ] );

    EditorImpl( ) {
        _create( );
    }

    // Creates webview
    void _create( ) async {
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
            ..launch( "file://$_path" );
    }

    @override
    void save( String fileName ) async {
        try {
            var content = await _webview.evaluateJavaScript( 'tinymce.activeEditor.getContent()' ) ?? "";
            final file = GenericFile( fileName );
            file.writeString( content );
        }
        on Exception catch( e, stack ) {
             logger.severe( e.toString( ), stack );
        }
    }

    @override
    void load( String fileName ) async {
        try {
            final file = GenericFile( fileName );
            var content = await file.readString( );
            var script = 'tinymce.activeEditor.setContent("$content")';
            await _webview.evaluateJavaScript( script );
        }
        on Exception catch( e, stack ) {
            logger.severe( e.toString( ), stack );
        }
    }

    @override
    void setVisible( bool visible ) {
        _webview.setWebviewWindowVisibility( visible );
    }
    
    @override
    void clear( ) async {
        await _webview.evaluateJavaScript( 'tinymce.activeEditor.resetContent("$EMPTY_CONTENT")' );
    }
}
