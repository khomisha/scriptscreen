
// ignore_for_file: slash_for_doc_comments, constant_identifier_names

import 'dart:io';
import 'package:base/base.dart';
import 'app_const.dart';
import 'package:path/path.dart' as path;

void process( dynamic data ) {
    var command = data[ 'command' ] as String;
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
                    data[ 'warning' ] = "No such method $command";
            }
        }
        on Exception catch( e, stack ) {
            data[ 'result' ] = FAILURE;
            data[ ERR_MSG ] = '$command ${ e.toString( ) }';
            data[ ERROR ] = e;
            data[ STACK ] = stack;
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
    if( data[ 'for_save' ] != null ) {
        _save( data[ 'for_save' ].data[ 'data' ] );
    }
    var file = File( path.join( 'assets', 'cfg', 'empty.json' ) );
    data[ 'data' ] = file.readAsStringSync( );
    data[ 'result' ] = SUCCESS;
}

/**
 * Loads project data from specified file
 * data the [Data] object to load
 */
void _load( Data data ) {
    if( data[ 'for_save' ] != null ) {
        _save( data[ 'for_save' ].data[ 'data' ] );
    }
    var file = File( data[ 'filename' ] );
    data[ 'data' ] = file.readAsStringSync( );
    data[ 'result' ] = SUCCESS;
}

/**
 * Saves project data to the specified file
 * data the [Data] object to save
 */
void _save( Data data ) {
    var file = File( data[ 'filename' ] );
    file.writeAsStringSync( data[ 'data' ] );
    data[ 'result' ] = SUCCESS;
    if( Config.config[ 'last_project' ] != data[ 'filename' ] ) {
        Config.config[ 'last_project' ] = data[ 'filename' ];
        writeConfig( );
    }
}

/**
 * Application exit
 * data the project data to save
 */
void _exit( Data data ) {
    _save( data );
    data[ 'result' ] = SUCCESS;
}
