
// ignore_for_file: slash_for_doc_comments
import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_presenter.dart';
import 'package:base/base.dart';
import 'package:path/path.dart';
import 'editor.dart';
import 'app_const.dart';
import 'script_data.dart';
import 'service_web.dart' if( dart.library.io ) 'service_io.dart';

// used to reach a BuildContext from menu onTap callbacks ( assigned in MaterialApp )
final navigatorKey = GlobalKey< NavigatorState >( );

// application notice / attribution, loaded from assets/cfg/notice.json ( see loadNotice )
// the consts from app_const act as a fallback if the file is missing or unreadable
Map< String, dynamic > notice = {
    'product': APP_NAME,
    'version': APP_VERSION,
    'copyright': APP_COPYRIGHT,
    'licenseName': 'Apache License, Version 2.0',
    'licenseUrl': 'https://www.apache.org/licenses/LICENSE-2.0',
    'thirdParty': < dynamic >[],
};

/**
 * Loads the application notice ( product, copyright, license, third-party list )
 */
Future< void > loadNotice( ) async {
    final file = GenericFile( join( GenericFile.assetsDir, 'cfg', 'notice.json' ) );
    final raw = await file.readString( );
    if( raw.isNotEmpty ) {
        notice = json.decode( raw ) as Map< String, dynamic >;
    }
}

PopupMenuEntry get createProject => PopupMenuItem( onTap: create, child: Text( tr( 'menu_new_project' ) ) );
PopupMenuEntry get openProject => PopupMenuItem( onTap: open, child: Text( tr( 'menu_open_project' ) ) );
PopupMenuEntry get exportProject => PopupMenuItem( onTap: export, child: Text( tr( 'menu_export_project' ) ) );
PopupMenuEntry get aboutApp => PopupMenuItem( onTap: about, child: Text( tr( 'menu_about' ) ) );
PopupMenuEntry get exitApp => PopupMenuItem( onTap: exit, child: Text( tr( 'menu_exit' ) ) );
PopupMenuEntry get showEditor => ToggleMenuItem( editor.setVisible, < String >[ tr( 'menu_show_editor' ), tr( 'menu_hide_editor' ) ] );

void create( ) async {
    AppPresenter( ).create( true );
}

void open( ) async {
    final path = await GenericFile.pickFile(
        title: tr( 'picker_project_title' ),
        filterName: tr( 'picker_project_filter' ),
        extensions: [ 'json' ],
    );
    if( path != null ) { 
        AppPresenter( ).load( path, true );
    }
}

void export( ) async {
    final pdfPath = ( config[ 'last_project' ] as String ).replaceFirst( ".json", ".pdf" );
    final headerTemplateFile = GenericFile( join( GenericFile.assetsDir, 'cfg', config[ 'note_header_template' ] ) );
    final headerTemplate = await headerTemplateFile.readString( );
    List< String > headers = [];
    List< String > htmlFiles = [];
    List< String > titles = [];
    for( ListItem item in AppPresenter( ).getData( NOTE ) ) {
        var note = item.customData as NoteData;
        var t = headerTemplate.replaceAll( "@title", note.title );
        t = t.replaceAll( "@description", note.description );
        headers.add( t );
        htmlFiles.add( getBodyFileName( note ) );
        titles.add( note.title );
    }
    final script = AppPresenter( ).getData( SCRIPT )[ 0 ].customData as ScriptData;
    export2pdf( _buildPreamble( script ), headers, htmlFiles, pdfPath, titles, tr( 'toc_title' ) );
}

String _buildPreamble( ScriptData script ) {
    final buffer = StringBuffer( );
    buffer.writeln( '<div style="page-break-after: always; text-align: center; padding-top: 200px;">' );
    buffer.writeln( '<p style="font-size: 14pt;"><strong>${script.authors}</strong></p>' );
    buffer.writeln( '<h1 style="font-size: 24pt;">${script.title}</h1>' );
    buffer.writeln( '<p style="font-size: 12pt; margin-top: 60px;">${script.place}, ${script.date}</p>' );
    buffer.writeln( '</div>' );
    if( script.logline.isNotEmpty ) {
        buffer.writeln( '<div style="page-break-after: always; padding: 40px;">' );
        buffer.writeln( '<h2>${tr( 'logline' )}</h2>' );
        buffer.writeln( '<p>${script.logline}</p>' );
        buffer.writeln( '</div>' );
    }
    if( script.synopsis.isNotEmpty ) {
        buffer.writeln( '<div style="page-break-after: always; padding: 40px;">' );
        buffer.writeln( '<h2>${tr( 'synopsis' )}</h2>' );
        buffer.writeln( '<p>${script.synopsis}</p>' );
        buffer.writeln( '</div>' );
    }
    return buffer.toString( );
}

void transcript( ) async {
    final path = await GenericFile.pickFile(
        title: tr( 'picker_audio_title' ),
        filterName: tr( 'picker_audio_filter' ),
        extensions: ['mp3', 'wav', 'm4a'],
    );
    if( path != null ) {
        final lang = ( AppPresenter( ).getData( PROJECT )[ 0 ].customData as ProjectData ).lang;
        transcribe( path, config[ 'whisper_model' ], lang );
    }
}

PopupMenuEntry transcriptLiveItem( ) {
    if( isLiveTranscribing( ) ) {
        return PopupMenuItem( onTap: _stopLive, child: Text( tr( 'menu_stop_live' ) ) );
    }
    return PopupMenuItem( onTap: _startLive, child: Text( tr( 'menu_start_live' ) ) );
}

void _startLive( ) {
    final lang = ( AppPresenter( ).getData( PROJECT )[ 0 ].customData as ProjectData ).lang;
    startLiveTranscription( config[ 'whisper_live_model' ], lang );
}

void _stopLive( ) {
    stopLiveTranscription( );
}

void about( ) {
    final context = navigatorKey.currentContext;
    if( context == null ) { return; }
    showAboutDialog(
        context: context,
        applicationName: notice[ 'product' ] as String,
        applicationVersion: '${tr( 'version' )} ${notice[ 'version' ]}',
        applicationLegalese: '${notice[ 'copyright' ]}\n${notice[ 'licenseName' ]}',
    );
}

void exit( ) async {
    AppPresenter( ).exit( );
}

