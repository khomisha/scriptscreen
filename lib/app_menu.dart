
// ignore_for_file: slash_for_doc_comments
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'app_presenter.dart';
import 'package:base/base.dart';
import 'package:path/path.dart';
import 'editor.dart';

PopupMenuEntry createProject = const PopupMenuItem( onTap: create, child: Text( "New Project" ) );
PopupMenuEntry openProject = const PopupMenuItem( onTap: open, child: Text( "Open Project" ) );
PopupMenuEntry exportProject = const PopupMenuItem( onTap: export, child: Text( "Export Project" ) );
PopupMenuEntry exitApp = const PopupMenuItem( onTap: exit, child: Text( "Exit" ) );
PopupMenuEntry showEditor = ToggleMenuItem( editor.setVisible, const < String >[ "Show Editor", "Hide Editor" ] );

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

void export( ) {
}

void exit( ) async {
    AppPresenter( ).exit( );
}
