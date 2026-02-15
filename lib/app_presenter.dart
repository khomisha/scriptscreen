
// ignore_for_file: constant_identifier_names, slash_for_doc_comments, avoid_print

import 'dart:async';
import 'dart:convert';
import 'script_data.dart';
import 'app_const.dart';
import 'package:base/base.dart';
import 'broker_init_web.dart' if (dart.library.io) 'broker_init_io.dart';
import 'package:path/path.dart';

class AppPresenter {
    static final AppPresenter _instance = AppPresenter._( );
    late Timer _timer;
    late AppBroker _broker;

    AppPresenter._( ) {
        _broker = AppBroker._( );
        _timer = Timer.periodic( 
            Duration( seconds: config[ 'default_autosave' ] ), 
            ( _ ) { 
                save( );
                eventBroker.dispatch( Event( SAVE_CONTENT ) );
            } 
        );
    }

    factory AppPresenter( ) => _instance;

    /**
     * Loads data on application open
     */
    void loadData( ) {
        final fileName = config[ 'last_project' ] as String;
        if( fileName.isEmpty || !GenericFile.isExist( fileName ) ) {
            logger.warning( 'Project $fileName does not exist. Create new.' );
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
        eventBroker.dispatch( Event( SEND ) );
        final fileName = createEntityName( "scripts", NONAME, ext: "json", version: START_VERSION );
        final dirName = createEntityName( "scripts", NONAME, version: START_VERSION, addon: "r" );
        Data? data4Save;
        if( save ) {
            var encoder = const JsonEncoder.withIndent( INDENT );
            data4Save = Data.create( 
                < String > [ 'command', 'data', 'filename', 'result' ], 
                < dynamic > [ 
                    CMD_SAVE, 
                    encoder.convert( _broker.projectData ), 
                    config[ 'last_project' ], 
                    NO_ACTION 
                ] 
            );
        }
        _broker.send(
            Data.create( 
                < String > [ 'command', 'data', 'filename', 'dirname', 'for_save', 'save', 'result' ], 
                < dynamic > [ CMD_CREATE, "", fileName, dirName, data4Save?.attributes, save, NO_ACTION ] 
            )
        );
    }

    /**
     * Loads project data and saves the old project
     * path the loading project path 
     * save the flag if true saves previous project 
     */
    void load( String path, bool save ) {
        eventBroker.dispatch( Event( SEND ) );
        Data? data4Save;
        if( save ) {
            var encoder = const JsonEncoder.withIndent( INDENT );
            data4Save = Data.create( 
                < String > [ 'command', 'data', 'filename', 'result' ], 
                < dynamic > [ 
                    CMD_SAVE, 
                    encoder.convert( _broker.projectData ), 
                    config[ 'last_project' ], 
                    NO_ACTION 
                ] 
            );
        }            
        _broker.send(
            Data.create( 
                < String > [ 'command', 'data', 'filename', 'for_save', 'save', 'result' ], 
                < dynamic > [ CMD_LOAD, "", path, data4Save?.attributes, save, NO_ACTION ] 
            )
        );
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
                    CMD_EXIT, 
                    encoder.convert( _broker.projectData ), 
                    config[ 'last_project' ], 
                    NO_ACTION 
                ] 
            )
        );
    }

    /**
     * Saves current project
     */
    void save( ) {
        final fileName = config[ 'last_project' ] as String;
        final name = _broker.projectData.name;
        final version = _broker.projectData.version;
        final updateConfig = !fileName.contains( name ) || !fileName.contains( version );
        if( updateConfig ) {
            config[ 'last_project' ] = createEntityName( 
                "scripts", 
                name, 
                ext: "json", 
                version: version 
            );
            final dirName = createEntityName( "scripts", name, version: version, addon: "r" );
            GenericFile.copyDirectory( _broker.projectData.dir, dirName );
            _broker.projectData.dir = dirName;   
        }
        var encoder = const JsonEncoder.withIndent( INDENT );
        _broker.send(
            Data.create( 
                < String > [ 'command', 'data', 'filename', 'update_config', 'result' ], 
                < dynamic > [ 
                    CMD_SAVE, 
                    encoder.convert( _broker.projectData ), 
                    config[ 'last_project' ], 
                    updateConfig,
                    NO_ACTION 
                ] 
            )
        );
    }

    void dispose( ) {
        _timer.cancel( );
        _broker.dispose( );
    }

    /**
     * Returns data of the specified type
     * type the list type [ROLE], [DETAIL], [LOCATION], [NOTE], [SCRIPT], [PROJECT]
     */
    List< ListItem > getData( String type ) {
        switch( type ) {
            case ROLE:
                return _broker.projectData.roles;
            case DETAIL:
                return _broker.projectData.details;
            case LOCATION:
                return _broker.projectData.locations;
            case ACTION_TIME:
                return _broker.projectData.actionTimes;
            case NOTE:
                return _broker.projectData.script.notes;
            case SCRIPT:
                return < ListItem > [ ListItem( _broker.projectData.script ) ];
            case PROJECT:
                return < ListItem > [ ListItem( _broker.projectData ) ];
            default:
                throw UnsupportedError( "Wrong data type $type" );
        }
    }
}

class AppBroker extends Broker with Initing {
    late ProjectData projectData;

    AppBroker._( ) {
        init( );
    }

    @override
    void update( data ) {
        if( data[ 'result' ] == SUCCESS ) {
            if( data[ 'command' ] == CMD_CREATE ) {
                projectData = ProjectData.fromJson( jsonDecode( data[ 'data' ] ) );
                projectData.dir = data[ 'dirname' ];
                eventBroker.dispatch( Event( UPDATE, data[ 'save' ] ) );
                updateConfig( );
            } else if ( data[ 'command' ] == CMD_LOAD ) {
                projectData = ProjectData.fromJson( jsonDecode( data[ 'data' ] ) );
                eventBroker.dispatch( Event( UPDATE, data[ 'save' ] ) );
            } else if( data[ 'command' ] == CMD_SAVE ) {
                logger.info( 'save completed' );
                eventBroker.dispatch( Event( UPDATE, false ) );
                if( data[ 'update_config' ] ) {
                    updateConfig( );
                }
            } else if( data[ 'command' ] == CMD_EXIT ) {
                eventBroker.dispatch( Event( EXIT ) );
            }
        } else if( data[ 'result' ] == FAILURE ) {
            logger.severe( data[ ERR_MSG ], data[ ERROR ] ?? "", data[ STACK ] ?? "" );
        } else if( data[ 'result' ] == NO_ACTION ) {
            logger.warning( Message( 'NO_ACTION returns??? ${data[ "command" ]}', '${data[ "data" ]}') );
        }
        eventBroker.dispatch( Event( END_UPDATE ) );
    }
}

/**
 * Returns file name for specified note
 */
String getBodyFileName( NoteData note ) {
    final dir = ( AppPresenter( ).getData( PROJECT )[ 0 ].customData as ProjectData ).dir;
    return join( dir, note.body );
}


