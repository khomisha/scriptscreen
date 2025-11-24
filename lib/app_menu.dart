
// ignore_for_file: slash_for_doc_comments
import 'package:file_picker/file_picker.dart';
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
PopupMenuEntry transcriptAudio = const PopupMenuItem( onTap: transcript, child: Text( "Transcript Audio File..." ) );

void create( ) async {
    AppPresenter( ).create( true );
}

void open( ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles( 
        initialDirectory: join( GenericFile.userDir, "scripts" ) 
    );
    if( result != null ) { 
        AppPresenter( ).load( result.files.single.path as String, true );
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
    export2pdf( headers, htmlFiles, pdfPath );
}

void transcript( ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles( );
    if( result != null ) { 
        final lang = ( AppPresenter( ).getData( PROJECT )[ 0 ].customData as ProjectData ).lang;
        transcribe( result.files.single.path as String, "medium", lang );
    }
}

void exit( ) async {
    eventBroker.dispatch( Event( SAVE_CONTENT ) );
    AppPresenter( ).exit( );
}

