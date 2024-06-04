
// ignore_for_file: constant_identifier_names, slash_for_doc_comments

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'script_data.dart';
import 'app_const.dart';
import 'presenter.dart';
import 'package:base/base.dart';

class AppPresenter extends Presenter {
    static final AppPresenter _instance = AppPresenter._( );
    late RootWidget rootWidget;
    late Timer _timer;
    late ProjectData projectData;

    AppPresenter._( ) : super( ) {
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

    @override
    void update( data ) {
        if( data[ 'result' ] == SUCCESS ) {
            if( data[ 'command' ] == CREATE || data[ 'command' ] == LOAD ) {
                projectData = ProjectData.fromJson( jsonDecode( data.attributes[ 'data' ] ) );
                Config.config[ 'last_project' ] = data[ 'filename' ];
                notify( );
            } else if( data[ 'command' ] == SAVE ) {
                notify( );
            } else if( data[ 'command' ] == EXIT ) {
                rootWidget.destroy( );
            }
        } else if( data[ 'result' ] == FAILURE ) {
            logger.e( 
                data.attributes[ ERR_MSG ], 
                error: data.attributes[ ERROR ], 
                stackTrace: data.attributes[ STACK ] 
            );
        }
        rootWidget.manageSplashscreen( false );
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
        rootWidget.manageSplashscreen( true );
        Directory( getPathFromUserDir( "scripts" ) ).createSync( );
        var path = createFileName( "scripts", NONAME, "json", version: START_VERSION );
        if( save ) {
            var encoder = const JsonEncoder.withIndent( INDENT );
            var data4Save = Data.create( 
                < String > [ 'command', 'data', 'filename', 'result' ], 
                < dynamic > [ SAVE, encoder.convert( projectData ), Config.config[ 'last_project' ], NO_ACTION ] 
            );
            send(
                Data.create( 
                    < String > [ 'command', 'data', 'filename', 'for_save', 'result' ], 
                    < dynamic > [ CREATE, "", path, data4Save, NO_ACTION ] 
                )
            );
        } else {
            send(
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
        rootWidget.manageSplashscreen( true );
        if( save ) {
            var encoder = const JsonEncoder.withIndent( INDENT );
            var data4Save = Data.create( 
                < String > [ 'command', 'data', 'filename', 'result' ], 
                < dynamic > [ SAVE, encoder.convert( projectData ), Config.config[ 'last_project' ], NO_ACTION ] 
            );
            send(
                Data.create( 
                    < String > [ 'command', 'data', 'filename', 'for_save', 'result' ], 
                    < dynamic > [ LOAD, "", path, data4Save, NO_ACTION ] 
                )
            );
        } else {
            send(
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
        send(
            Data.create( 
                < String > [ 'command', 'data', 'filename', 'result' ], 
                < dynamic > [ EXIT, encoder.convert( projectData ), Config.config[ 'last_project' ], NO_ACTION ] 
            )
        );
    }

    /**
     * Saves current project
     */
    void save( ) {
        var fileName = Config.config[ 'last_project' ] as String;
        if( !fileName.contains( projectData.name ) || !fileName.contains( projectData.version ) ) {
            Config.config[ 'last_project' ] = createFileName( 
                "scripts", 
                projectData.name, 
                "json", 
                version: projectData.version 
            );
        }
        var encoder = const JsonEncoder.withIndent( INDENT );
        send(
            Data.create( 
                < String > [ 'command', 'data', 'filename', 'result' ], 
                < dynamic > [ SAVE, encoder.convert( projectData ), Config.config[ 'last_project' ], NO_ACTION ] 
            )
        );
    }

    /**
     * Returns data of the specified type
     * type the list type [ROLE], [DETAIL], [LOCATION], [NOTE], [SCRIPT], [PROJECT]
     */
    @override
    List< ListItem > getData( String type ) {
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

    @override
    void dispose( ) {
        _timer.cancel( );
        super.dispose( );
    }
}
