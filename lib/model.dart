
// ignore_for_file: slash_for_doc_comments, constant_identifier_names

import 'package:base/base.dart';
import 'app_const.dart';
import 'package:path/path.dart' as path;

void process( dynamic data ) {
    if( data is Data ) {
        var command = data[ 'command' ] as String;
        try {
            switch( command ) {
                case CMD_CREATE:
                    _create( data );
                    break;
                case CMD_LOAD:
                    _load( data );
                    break;
                case CMD_SAVE:
                    _save( data );
                    break;
                case CMD_EXIT:
                    _exit( data );
                    break;
                default:
                    data[ 'result' ] = FAILURE;
                    data[ ERR_MSG ] = "No such method $command";
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
        _save( data[ 'for_save' ] );
    }
    var file = GenericFile( path.join( GenericFile.assetsDir, 'cfg', 'empty.json' ) );
    GenericFile.mkDir( data[ 'dirname' ] );
    data[ 'data' ] = file.readString( );
    data[ 'result' ] = SUCCESS;
}

/**
 * Loads project data from specified file
 * data the [Data] object to load
 */
void _load( Data data ) {
    if( data[ 'for_save' ] != null ) {
        _save( data[ 'for_save' ] );
    }
    var file = GenericFile( data[ 'filename' ] );
    data[ 'data' ] = file.readString( );
    data[ 'result' ] = SUCCESS;
}

/**
 * Saves project data to the specified file
 * data the [Data] object to save
 */
void _save( Data data ) {
    var file = GenericFile( data[ 'filename' ] );
    file.writeString( data[ 'data' ] );
    data[ 'result' ] = SUCCESS;
}

/**
 * Application exit
 * data the project data to save
 */
void _exit( Data data ) {
    _save( data );
    data[ 'result' ] = SUCCESS;
}
