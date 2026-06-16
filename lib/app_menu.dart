
// ignore_for_file: slash_for_doc_comments
import 'package:flutter/material.dart';
import 'app_presenter.dart';
import 'package:base/base.dart';
import 'package:path/path.dart';
import 'editor.dart';
import 'app_const.dart';
import 'script_data.dart';
import 'service_web.dart' if( dart.library.io ) 'service_io.dart';

PopupMenuEntry createProject = const PopupMenuItem( onTap: create, child: Text( "New Project" ) );
PopupMenuEntry openProject = const PopupMenuItem( onTap: open, child: Text( "Open Project..." ) );
PopupMenuEntry exportProject = const PopupMenuItem( onTap: export, child: Text( "Export Project" ) );
PopupMenuEntry exitApp = const PopupMenuItem( onTap: exit, child: Text( "Exit" ) );
PopupMenuEntry showEditor = ToggleMenuItem( editor.setVisible, const < String >[ "Show Editor", "Hide Editor" ] );

void create( ) async {
    AppPresenter( ).create( true );
}

void open( ) async {
    final path = await GenericFile.pickFile(
        title: 'Project files',
        filterName: 'Project',
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
    for( ListItem item in AppPresenter( ).getData( NOTE ) ) {
        var note = item.customData as NoteData;
        var t = headerTemplate.replaceAll( "@title", note.title );
        t = t.replaceAll( "@description", note.description );
        headers.add( t );
        htmlFiles.add( getBodyFileName( note ) );
    }
    final script = AppPresenter( ).getData( SCRIPT )[ 0 ].customData as ScriptData;
    export2pdf( _buildPreamble( script ), headers, htmlFiles, pdfPath );
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
        buffer.writeln( '<h2>Logline</h2>' );
        buffer.writeln( '<p>${script.logline}</p>' );
        buffer.writeln( '</div>' );
    }
    if( script.synopsis.isNotEmpty ) {
        buffer.writeln( '<div style="page-break-after: always; padding: 40px;">' );
        buffer.writeln( '<h2>Synopsis</h2>' );
        buffer.writeln( '<p>${script.synopsis}</p>' );
        buffer.writeln( '</div>' );
    }
    return buffer.toString( );
}

void transcript( ) async {
    final path = await GenericFile.pickFile(
        title: 'Select audio file',
        filterName: 'Audio',
        extensions: ['mp3', 'wav', 'm4a'],
    );
    if( path != null ) {
        final lang = ( AppPresenter( ).getData( PROJECT )[ 0 ].customData as ProjectData ).lang;
        transcribe( path, config[ 'whisper_model' ], lang );
    }
}

PopupMenuEntry transcriptLiveItem( ) {
    if( isLiveTranscribing( ) ) {
        return const PopupMenuItem( onTap: _stopLive, child: Text( 'Stop Live Transcription' ) );
    }
    return const PopupMenuItem( onTap: _startLive, child: Text( 'Start Live Transcription' ) );
}

void _startLive( ) {
    final lang = ( AppPresenter( ).getData( PROJECT )[ 0 ].customData as ProjectData ).lang;
    startLiveTranscription( config[ 'whisper_live_model' ], lang );
}

void _stopLive( ) {
    stopLiveTranscription( );
}

void exit( ) async {
    AppPresenter( ).exit( );
}

