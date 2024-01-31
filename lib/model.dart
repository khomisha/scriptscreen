
// ignore_for_file: slash_for_doc_comments, constant_identifier_names

import 'dart:io';
import 'package:scriptscreen/base/config.dart';
import 'app_const.dart';
import 'base/util.dart';
import 'data.dart';
import 'package:path/path.dart' as path;

void process( dynamic data ) {
    var command = data.attributes[ 'command' ] as String;
    if( data is Data ) {
        try {
            switch( command ) {
                case CREATE:
                    _create( data );
                    break;
                case LOAD:
                    _load( data );
                    break;
                case SAVE:
                    _save( data );
                    break;
                case EXIT:
                    _exit( data );
                    break;
                default:
                    data.attributes[ 'warning' ] = "No such method $command";
            }
        }
        on Exception catch( e, stack ) {
            data.attributes[ 'result' ] = FAILURE;
            data.attributes[ ERR_MSG ] = '$command ${ e.toString( ) }';
            data.attributes[ ERROR ] = e;
            data.attributes[ STACK ] = stack;
        }
    } else {
        throw UnsupportedError( "Data object wrong type $data.runtimeType" );
    }
}

/**
 * Creates empty project data
 * data the [Data] object
 */
void _create( Data data ) {
    if( data.attributes[ 'for_save' ] != null ) {
        _save( data.attributes[ 'for_save' ].data.attributes[ 'data' ] );
    }
    var file = File( path.join( 'assets', 'cfg', 'empty.json' ) );
    data.attributes[ 'data' ] = file.readAsStringSync( );
    data.attributes[ 'result' ] = SUCCESS;
}

/**
 * Loads project data from specified file
 * data the [Data] object to load
 */
void _load( Data data ) {
    if( data.attributes[ 'for_save' ] != null ) {
        _save( data.attributes[ 'for_save' ].data.attributes[ 'data' ] );
    }
    var file = File( data.attributes[ 'filename' ] );
    data.attributes[ 'data' ] = file.readAsStringSync( );
    data.attributes[ 'result' ] = SUCCESS;
}

/**
 * Saves project data to the specified file
 * data the [Data] object to save
 */
void _save( Data data ) {
    var file = File( data.attributes[ 'filename' ] );
    file.writeAsStringSync( data.attributes[ 'data' ] );
    data.attributes[ 'result' ] = SUCCESS;
    Config( ).write( );
}

/**
 * Application exit
 * data the project data to save
 */
void _exit( Data data ) {
    _save( data );
    data.attributes[ 'result' ] = SUCCESS;
}
