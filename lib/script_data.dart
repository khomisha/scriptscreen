
// ignore_for_file: constant_identifier_names, slash_for_doc_comments

import 'dart:io';
import 'app_const.dart';
import 'package:base/base.dart';
import 'package:html/parser.dart';
import 'package:path/path.dart' as p;

/**
 * Returns empty item of the specified application data type
 */
dynamic emptyItem( String type ) {
    switch( type ) {
        case ROLE:
            return RoleData( "", "" );
        case DETAIL:
            return DetailData( "", "" );
        case LOCATION:
            return LocationData( "", "" );
        case ACTION_TIME:
            return ActionTimeData( "", "" );
        case SCRIPT:
            return ScriptData( 
                "", 
                "", DateTime.now( ).year.toString( ), "", 
                "", "",
                < ListItem > []
            );
        case NOTE:
            return NoteData( 
                "", "",
                < ListItem > [], 
                < ListItem > [],
                < ListItem > [],
                < ListItem > [],
                '<div><span style="font-size: 12pt;"></span></div>'
            );
        case PROJECT:
            return ProjectData( 
                NONAME, 
                "1.0",
                < ListItem > [], 
                < ListItem > [], 
                < ListItem > [],
                < ListItem > [],
                emptyItem( SCRIPT )
            );
        default:
            throw UnsupportedError( "Wrong type $type" );
    }
}

class GenericData extends AttributeMap< String, dynamic > {

    GenericData( String name, String description ) {
        attributes[ 'name' ] = name;
        attributes[ 'description' ] = description;
    }

    GenericData.fromJson( Map< String, dynamic > map ) {
        name = map[ 'name' ];
        description = map[ 'description' ];
    }

    String get name => attributes[ 'name' ] ?? "";
    String get description => attributes[ 'description' ] ?? "";

    set name( String value ) => attributes[ 'name' ] = value;
    set description( String value ) => attributes[ 'description' ] = value;

    Map< String, dynamic > toJson( ) {
        var map = < String, dynamic > {
            'name': name,
            'description': description
        };
        return map;
    }
    
    @override
    int compareTo( other ) {
        return name.compareTo( other.name );
    }

    @override
    GenericData copy( ) {
        return GenericData( name, description );
    }

    @override
    bool operator ==( Object other ) {
        return other is GenericData && name == other.name && description == other.description;
    }

    @override
    int get hashCode => name.hashCode * description.hashCode;
}

class RoleData extends GenericData {

    RoleData( super.name, super.description );

    RoleData.fromJson( super.map ) : super.fromJson( );

    @override
    RoleData copy( ) {
        return RoleData( name, description );
    }
}

class LocationData extends GenericData {

    LocationData( super.name, super.description );

    LocationData.fromJson( super.map ) : super.fromJson( );

    @override
    LocationData copy( ) {
        return LocationData( name, description );
    }
}

class DetailData extends GenericData {

    DetailData( super.name, super.description );

    DetailData.fromJson( super.map ) : super.fromJson( );

    @override
    DetailData copy( ) {
        return DetailData( name, description );
    }
}

class ActionTimeData extends GenericData {

    ActionTimeData( super.name, super.description );

    ActionTimeData.fromJson( super.map ) : super.fromJson();

    @override
    ActionTimeData copy( ) {
        return ActionTimeData( name, description );
    }
}

const String KEY_TAG = "em";

class NoteData extends AttributeMap< String, dynamic > {
    static final _file = File( p.join( p.current, 'assets', "templates", Config.config[ 'note_header_template' ] ) );
    static final _template = _file.readAsStringSync( );

    NoteData( 
        String title,
        String description,
        List< ListItem > roles, 
        List< ListItem > locations, 
        List< ListItem > details,
        List< ListItem > actionTimes,
        String body
    ) {
        attributes[ 'title' ] = title;
        attributes[ 'description' ] = description;
        attributes[ ROLE ] = roles;
        attributes[ LOCATION ] = locations;
        attributes[ DETAIL ] = details;
        attributes[ ACTION_TIME ] = actionTimes;
        attributes[ 'body' ] = body;
    }

    NoteData.fromJson( Map< String, dynamic > map ) {
        title = map[ 'title' ];
        description = map[ 'description' ];
        var list = map[ ROLE ] as List< dynamic >;
        roles = list.map( ( e ) => ListItem( RoleData.fromJson( e ) ) ).toList( );
        list = map[ LOCATION ] as List< dynamic >;
        locations = list.map( ( e ) => ListItem( LocationData.fromJson( e ) ) ).toList( );
        list = map[ DETAIL ] as List< dynamic >;
        details = list.map( ( e ) => ListItem( DetailData.fromJson( e ) ) ).toList( );
        list = map[ ACTION_TIME ] as List< dynamic >;
        actionTimes = list.map( ( e ) => ListItem( ActionTimeData.fromJson( e ) ) ).toList( );
        body = fromHex( map[ 'body' ] );
    }

    int get index => attributes[ 'index' ] ?? 1;
    String get title => attributes[ 'title' ] ?? "";
    String get description => attributes[ 'description' ] ?? "";
    List< ListItem > get roles => attributes[ ROLE ] ?? < ListItem > [];
    List< ListItem > get locations => attributes[ LOCATION ] ?? < ListItem > [];
    List< ListItem > get details => attributes[ DETAIL ] ?? < ListItem > [];
    List< ListItem > get actionTimes => attributes[ ACTION_TIME ] ?? < ListItem > [];
    String get body => attributes[ 'body' ] ?? "";

    set index( int value ) => attributes[ 'index' ] = value;
    set title( String value ) => attributes[ 'title' ] = value; 
    set description( String value ) => attributes[ 'description' ] = value;
    set roles( List< ListItem > value ) => attributes[ ROLE ] = value;
    set locations( List< ListItem > value ) => attributes[ LOCATION ] = value;
    set details( List< ListItem > value ) => attributes[ DETAIL ] = value;
    set actionTimes( List< ListItem > value ) => attributes[ ACTION_TIME ] = value;
    set body( String value ) => attributes[ 'body' ] = value;

    Map< String, dynamic > toJson( ) {
        var map = < String, dynamic > {
            'title': title,
            'description': description,
            ROLE: roles.map( ( e ) { var data = e.customData as RoleData; return data.toJson( ); } ).toList( ),
            LOCATION: locations.map( ( e ) { var data = e.customData as LocationData; return data.toJson( ); } ).toList( ),
            DETAIL: details.map( ( e ) { var data = e.customData as DetailData; return data.toJson( ); } ).toList( ),
            ACTION_TIME: actionTimes.map( ( e ) { var data = e.customData as ActionTimeData; return data.toJson( ); } ).toList( ),
            'body': toHex( body )
        };
        return map;
    }

    @override
    int compareTo( other ) {
        return index.compareTo( other.index );
    }

    @override
    NoteData copy( ) {
        return NoteData( title, description, roles, locations, details, actionTimes, body );
    }

    String getHeaderAsHtml( ) {
        var doc = parse( _template );
        var elements = doc.querySelectorAll( KEY_TAG );
        for( var e in elements ) { 
            var ls = e.text.split( ";" );   //???
            var result = "";
            for( String s in ls ) {
                if( attributes[ s ] is List ) {
                    for( ListItem item in attributes[ s ] ) {
                        result = "${item.customData.attributes[ 'name' ]} ${item.customData.attributes[ 'description' ]} ";
                    }
                } else {
                    result = "${attributes[ s ]} ";
                }
            }
            e.text = result;
        }
        return doc.toString( );
    }
}

class ScriptData extends AttributeMap< String, dynamic > {

    ScriptData(
        String title, 
        String authors,
        String date, 
        String place, 
        String logline, 
        String synopsis, 
        List< ListItem > notes 
    ) {
        attributes[ 'title' ] = title;
        attributes[ AUTHOR ] = authors;
        attributes[ 'date' ] = date;
        attributes[ 'place' ] = place;
        attributes[ 'logline' ] = logline;
        attributes[ 'synopsis' ] = synopsis;
        attributes[ NOTE ] = notes;
    }

    ScriptData.fromJson( Map< String, dynamic > map ) {
        title = map[ 'title' ];
        authors = map[ AUTHOR ];
        date = map[ 'date' ];
        place = map[ 'place' ];
        logline = map[ 'logline' ];
        synopsis = map[ 'synopsis' ];
        var list = map[ NOTE ] as List< dynamic >;
        notes = list.map( ( e ) => ListItem( NoteData.fromJson( e ) ) ).toList( );
    }

    String get title => attributes[ 'title' ] ?? "";
    String get authors => attributes[ AUTHOR ] ?? "";
    String get date => attributes[ 'date' ] ?? DateTime.now( ).year.toString( );
    String get place => attributes[ 'place' ] ?? "";
    String get logline => attributes[ 'logline' ] ?? "";
    String get synopsis => attributes[ 'synopsis' ] ?? "";
    List< ListItem > get notes => attributes[ NOTE ] ?? < ListItem > [];

    set title( String value ) => attributes[ 'title' ] = value;
    set authors( String value ) => attributes[ AUTHOR ] = value;
    set date( String value ) => attributes[ 'date' ] = value;
    set place( String value ) => attributes[ 'place' ] = value;
    set logline( String value ) => attributes[ 'logline' ] = value;
    set synopsis( String value ) => attributes[ 'synopsis' ] = value;
    set notes( List< ListItem > value ) => attributes[ NOTE ] = value;

    Map< String, dynamic > toJson( ) {
        var map = < String, dynamic > {
            'title': title,
            AUTHOR: authors,
            'date': date,
            'place': place,
            'logline': logline,
            'synopsis': synopsis,
            NOTE: notes.map( ( e ) { var data = e.customData as NoteData; return data.toJson( ); } ).toList( )
        };
        return map;
    }

    @override
    int compareTo( other ) {
        return title.compareTo( other.title );
    }

    @override
    ScriptData copy( ) {
        return ScriptData( title, authors, date, place, logline, synopsis, notes );
    }
}

class ProjectData extends AttributeMap< String, dynamic > {
    
    ProjectData(
        String name, 
        String version,
        List< ListItem > roles, 
        List< ListItem > locations, 
        List< ListItem > details,
        List< ListItem > actionTimes,
        ScriptData script 
    ) {
        attributes[ 'name' ] = name;
        attributes[ 'version' ] = version;
        attributes[ ROLE ] = roles;
        attributes[ LOCATION ] = locations;
        attributes[ DETAIL ] = details;
        attributes[ ACTION_TIME ] = actionTimes;
        attributes[ SCRIPT ] = script;
    }

    ProjectData.fromJson( Map< String, dynamic > map ) {
        name = map[ 'name' ];
        version = map[ 'version' ];
        var list = map[ ROLE ] as List< dynamic >;
        roles = list.map( ( e ) => ListItem( RoleData.fromJson( e ) ) ).toList( );
        list = map[ LOCATION ] as List< dynamic >;
        locations = list.map( ( e ) => ListItem( LocationData.fromJson( e ) ) ).toList( );
        list = map[ DETAIL ] as List< dynamic >;
        details = list.map( ( e ) => ListItem( DetailData.fromJson( e ) ) ).toList( );
        list = map[ ACTION_TIME ] as List< dynamic >;
        actionTimes = list.map( ( e ) => ListItem( ActionTimeData.fromJson( e ) ) ).toList( );
        script = ScriptData.fromJson( map[ SCRIPT ] );
    }

    String get name => attributes[ 'name' ] ?? NONAME;
    String get version => attributes[ 'version' ] ?? "1.0";
    List< ListItem > get roles => attributes[ ROLE ] ?? < ListItem > [];
    List< ListItem > get locations => attributes[ LOCATION ] ?? < ListItem > [];
    List< ListItem > get details => attributes[ DETAIL ] ?? < ListItem > [];
    List< ListItem > get actionTimes => attributes[ ACTION_TIME ] ?? < ListItem > [];
    ScriptData get script => attributes[ SCRIPT ] ?? emptyItem( SCRIPT );

    set name( String value ) => attributes[ 'name' ] = value;
    set version( String value ) => attributes[ 'version' ] = value;
    set roles( List< ListItem > value ) => attributes[ ROLE ] = value;
    set locations( List< ListItem > value ) => attributes[ LOCATION ] = value;
    set details( List< ListItem > value ) => attributes[ DETAIL ] = value;
    set actionTimes( List< ListItem > value ) => attributes[ ACTION_TIME ] = value;
    set script( ScriptData value ) => attributes[ SCRIPT ] = value;

    Map< String, dynamic > toJson( ) {
        var map = < String, dynamic > {
            'name': name,
            'version': version,
            ROLE: roles.map( ( e ) { var data = e.customData as RoleData; return data.toJson( ); } ).toList( ),
            LOCATION: locations.map( ( e ) { var data = e.customData as LocationData; return data.toJson( ); } ).toList( ),
            DETAIL: details.map( ( e ) { var data = e.customData as DetailData; return data.toJson( ); } ).toList( ),
            ACTION_TIME: actionTimes.map( ( e ) { var data = e.customData as ActionTimeData; return data.toJson( ); } ).toList( ),
            SCRIPT: script.toJson( )
        };
        return map;
    }

    @override
    int compareTo( other ) {
        return name.compareTo( other.name );
    }

    @override
    ProjectData copy( ) {
        return ProjectData( name, version, roles, locations, details, actionTimes, script );
    }
}
