
// ignore_for_file: slash_for_doc_comments

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'app_presenter.dart';
import 'base/util.dart';

PopupMenuEntry createProject = const PopupMenuItem( onTap: create, child: Text( "New Project" ) );
PopupMenuEntry openProject = const PopupMenuItem( onTap: open, child: Text( "Open Project" ) );
PopupMenuEntry exportProject = const PopupMenuItem( onTap: export, child: Text( "Export Project" ) );
PopupMenuEntry exitApp = const PopupMenuItem( onTap: exit, child: Text( "Exit" ) );

void create( ) async {
    AppPresenter( ).create( true );
}

void open( ) async {
    var workspace = getPathFromUserDir( "scripts" );
    Directory( workspace ).createSync( );
    FilePickerResult? result = await FilePicker.platform.pickFiles( initialDirectory: workspace );
    if( result != null ) { 
        AppPresenter( ).load( result.files.single.path as String, true );
    }
}

void export( ) {
}

void exit( ) async {
    AppPresenter( ).exit( );
}

/**
 * Creates pop up menu
 * menuItems the menu items
 */
List< Widget > createMenu( List< PopupMenuEntry > menuItems ) {
    var pmb = PopupMenuButton( 
        icon: const Icon( Icons.menu ), 
        itemBuilder: ( BuildContext context ) => menuItems 
    );
    return [ pmb ];
}

