
// ignore_for_file: constant_identifier_names, slash_for_doc_comments

import 'dart:async';
import 'dart:convert';
import 'package:scriptscreen/base/config.dart';
import 'package:scriptscreen/base/root_widget.dart';
import 'package:scriptscreen/data.dart';
import 'app_const.dart';
import 'base/util.dart';
import 'presenter.dart';

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
            if( data.attributes[ 'command' ] == CREATE || data.attributes[ 'command' ] == LOAD ) {
                projectData = ProjectData.fromJson( jsonDecode( data.attributes[ 'data' ] ) );
                Config.config[ 'last_project' ] = data.attributes[ 'filename' ];
                notify( );
            } else if( data.attributes[ 'command' ] == SAVE ) {
                notify( );
            } else if( data.attributes[ 'command' ] == EXIT ) {
                rootWidget.destroy( );
            }
        } else if( data.attributes[ 'result' ] == FAILURE ) {
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
        var lastProject = Config.config[ 'last_project' ] as String;
        if( lastProject.isEmpty ) {
            create( false );
        } else {
            load( lastProject, false );
        }
    }

    /**
     * Creates empty project and saves the old project
     * save the flag if true saves previous project 
     */
    void create( bool save ) {
        rootWidget.manageSplashscreen( true );
        if( save ) {
            send( Data.forCreate( forSave: Data.forSave( projectData, Config.config[ 'last_project' ] ) ) );
        } else {
            send( Data.forCreate( ) );
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
            send( 
                Data.forOpen( 
                    fileName: path, forSave: Data.forSave( projectData, Config.config[ 'last_project' ] ) 
                ) 
            );
        } else {
            send( Data.forOpen( fileName: path ) );
        }
    }

    /**
     * Saves project before exit from application
     */
    void exit( ) {
        send( Data.forExit( projectData, Config.config[ 'last_project' ] ) );
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
        send( Data.forSave( projectData, Config.config[ 'last_project' ] ) );
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
