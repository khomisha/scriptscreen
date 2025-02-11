
// ignore_for_file: constant_identifier_names, slash_for_doc_comments, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:easy_isolate/easy_isolate.dart';
import 'model.dart';
import 'script_data.dart';
import 'app_const.dart';
import 'package:base/base.dart';

class AppPresenter extends Publisher {
    static final AppPresenter _instance = AppPresenter._( );
    late Timer _timer;
    late AppBroker _broker;

    AppPresenter._( ) {
        _broker = AppBroker( _isolateHandler );
        _timer = Timer.periodic( 
            Duration( seconds: Config.config[ 'default_autosave' ] ), 
            ( _ ) { 
                save( ); 
            } 
        );
    }

    factory AppPresenter( ) {
        return _instance;
    }

    /**
     * Process data in isolate
     * data the data to process in isolate and returns to the main thread
     * mainSendPort the main thread port to get data from isolate
     * onSendError the function to handle send error
     */
    static _isolateHandler( dynamic data, SendPort mainSendPort, SendErrorFunction onSendError ) async {
        process( data );
        mainSendPort.send( data );
    }

    /**
     * Loads data on application open
     */
    void loadData( ) {
        var fileName = Config.config[ 'last_project' ] as String;
        if( fileName.isEmpty ) {
            create( false );
        } else {
            load( fileName, false );
        }
    }

    /**
     * Creates empty project and saves the old project
     * save the flag if true saves previous project 
     */
    void create( bool save ) {
        publish( ON_SEND );
        Directory( getPathFromUserDir( "scripts" ) ).createSync( );
        var path = createFileName( "scripts", NONAME, "json", version: START_VERSION );
        if( save ) {
            var encoder = const JsonEncoder.withIndent( INDENT );
            var data4Save = Data.create( 
                < String > [ 'command', 'data', 'filename', 'result' ], 
                < dynamic > [ 
                    SAVE, 
                    encoder.convert( Notification( ).messageBoard[ ON_UPDATE ] ), 
                    Config.config[ 'last_project' ], 
                    NO_ACTION 
                ] 
            );
            _broker.send(
                Data.create( 
                    < String > [ 'command', 'data', 'filename', 'for_save', 'result' ], 
                    < dynamic > [ CREATE, "", path, data4Save, NO_ACTION ] 
                )
            );
        } else {
            _broker.send(
                Data.create( 
                    < String > [ 'command', 'data', 'filename', 'for_save', 'result' ], 
                    < dynamic > [ CREATE, "", path, null, NO_ACTION ] 
                )
            );
        }
    }

    /**
     * Loads project data and saves the old project
     * path the loading project path 
     * save the flag if true saves previous project 
     */
    void load( String path, bool save ) {
        publish( ON_SEND );
        if( save ) {
            var encoder = const JsonEncoder.withIndent( INDENT );
            var data4Save = Data.create( 
                < String > [ 'command', 'data', 'filename', 'result' ], 
                < dynamic > [ 
                    SAVE, 
                    encoder.convert( Notification( ).messageBoard[ ON_UPDATE ] ), 
                    Config.config[ 'last_project' ], 
                    NO_ACTION 
                ] 
            );
            _broker.send(
                Data.create( 
                    < String > [ 'command', 'data', 'filename', 'for_save', 'result' ], 
                    < dynamic > [ LOAD, "", path, data4Save, NO_ACTION ] 
                )
            );
        } else {
            _broker.send(
                Data.create( 
                    < String > [ 'command', 'data', 'filename', 'for_save', 'result' ], 
                    < dynamic > [ LOAD, "", path, null, NO_ACTION ] 
                )
            );
        }
    }

    /**
     * Saves project before exit from application
     */
    void exit( ) {
        var encoder = const JsonEncoder.withIndent( INDENT );
        _broker.send(
            Data.create( 
                < String > [ 'command', 'data', 'filename', 'result' ], 
                < dynamic > [ 
                    EXIT, 
                    encoder.convert( Notification( ).messageBoard[ ON_UPDATE ] ), 
                    Config.config[ 'last_project' ], 
                    NO_ACTION 
                ] 
            )
        );
    }

    /**
     * Saves current project
     */
    void save( ) {
        var fileName = Config.config[ 'last_project' ] as String;
        var name = Notification( ).messageBoard[ ON_UPDATE ].name;
        var version = Notification( ).messageBoard[ ON_UPDATE ].version;
        if( !fileName.contains( name ) || !fileName.contains( version ) ) {
            Config.config[ 'last_project' ] = createFileName( 
                "scripts", 
                 name, 
                "json", 
                version: version 
            );
        }
        var encoder = const JsonEncoder.withIndent( INDENT );
        _broker.send(
            Data.create( 
                < String > [ 'command', 'data', 'filename', 'result' ], 
                < dynamic > [ 
                    SAVE, 
                    encoder.convert( Notification( ).messageBoard[ ON_UPDATE ] ), 
                    Config.config[ 'last_project' ], 
                    NO_ACTION 
                ] 
            )
        );
    }

    void dispose( ) {
        _timer.cancel( );
        _broker.dispose( );
    }
}

class AppBroker extends Broker {

    AppBroker( super.handler );

    @override
    void update( data ) {
        if( data[ 'result' ] == SUCCESS ) {
            if( data[ 'command' ] == CREATE || data[ 'command' ] == LOAD ) {
                Config.config[ 'last_project' ] = data[ 'filename' ];
                var projectData = ProjectData.fromJson( jsonDecode( data.attributes[ 'data' ] ) );
                publish( ON_UPDATE, data: projectData );
            } else if( data[ 'command' ] == SAVE ) {
                publish( ON_UPDATE, data: ProjectData.fromJson( jsonDecode( data.attributes[ 'data' ] ) ) );
            } else if( data[ 'command' ] == EXIT ) {
                publish( ON_EXIT );
            }
        } else if( data[ 'result' ] == FAILURE ) {
            logger.e( 
                data.attributes[ ERR_MSG ], 
                error: data.attributes[ ERROR ], 
                stackTrace: data.attributes[ STACK ] 
            );
        }
        publish( ON_END_UPDATE );
    }
}

/**
 * Returns data of the specified type
 * type the list type [ROLE], [DETAIL], [LOCATION], [NOTE], [SCRIPT], [PROJECT]
 */
List< ListItem > getData( String type ) {
    var projectData = Notification( ).messageBoard[ ON_UPDATE ] as ProjectData;
    switch( type ) {
        case ROLE:
            return projectData.roles;
        case DETAIL:
            return projectData.details;
        case LOCATION:
            return projectData.locations;
        case ACTION_TIME:
            return projectData.actionTimes;
        case NOTE:
            return projectData.script.notes;
        case SCRIPT:
            return < ListItem > [ ListItem( projectData.script ) ];
        case PROJECT:
            return < ListItem > [ ListItem( projectData ) ];
        default:
            throw UnsupportedError( "Wrong data btype $type" );
    }
}
