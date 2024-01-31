
// ignore_for_file: slash_for_doc_comments, constant_identifier_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import "package:hex/hex.dart";
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'config.dart';

const String INDENT = '    ';

// result types
const int SUCCESS = 0;
const int FAILURE = 1;
const int NO_ACTION = 2;

typedef FromString = dynamic Function( String value );

/**
 * Different convertes from string to the specified type
 */
var _converters = < Type, dynamic > {
    ''.runtimeType: ( String value ) { dynamic v = value; return v; },
    1.runtimeType: ( String value ) { dynamic v = int.parse( value ); return v; },
    1.5.runtimeType: ( String value ) { dynamic v = double.parse( value ); return v; },
    true.runtimeType: ( String value ) { dynamic v = value.toLowerCase( ) == 'true'; return v; }
};

/**
 * Converts value to specified data type, 
 * accepted data types are String, int, double, bool
 */
dynamic fromString( Type type, String value ) {
    var func = _converters[ type ] as FromString;
    return func( value );
}

/**
 * Capitalizes string
 * s the string to capitalize
 */
String capitalize( String s ) {
    return s[ 0 ].toUpperCase( ) + s.substring( 1 );
}

/**
 * Returns widget stub
 */
Widget getStub( String text ) {
    return Center( child: Text( text ) );
}

/**
 * Try to parse specified value to the date time using specified format string.
 * Returns datetime if success or null otherwise
 * format the format string
 * value the value to parse
 */
DateTime? parse2Datetime( String format, String value ) {
    DateTime result;
    try {
        result = DateFormat( format ).parse( value );
    }
    // ignore: unused_catch_clause
    on FormatException catch( e ) {
        return null;
    }
    return result;
}

/**
 * Converts string to it's hex presentation
 */
String toHex( String s ) {
    return HEX.encode( utf8.encode( s ) );
}

/**
 * Converts hex strign to the string
 */
String fromHex( String hex ) {
    return utf8.decode( HEX.decode( hex ) );
}

/**
 * Returns current datetime as string
 */
String currentDatetime( ) {
    var dt = DateTime.now( );
    return '${ dt.year }${ dt.month }${ dt.day }${ dt.hour }${ dt.minute }${ dt.second }';
}

/**
 * Sleeps on specified duration
 * duration the duration to sleep millis
 */
void sleep( Duration duration ) {
    var ms = duration.inMilliseconds;
    var start = DateTime.now( ).millisecondsSinceEpoch;
    while( true ) {
        var current = DateTime.now( ).millisecondsSinceEpoch;
        if( current - start >= ms ) {
            break;
        }
    }
}

/**
 * Returns path for specified directory within current user directory
 * dirPath the directory path within current user directory
 */
String getPathFromUserDir( String dirPath ) {
    return path.join( Platform.environment[ 'HOME' ] ?? Platform.environment[ 'USERPROFILE' ]!, dirPath );
}

/**
 * Creates file name 
 * dirPath the directory path within current user directory
 * version the file version
 * name the meaningful file name
 * ext the file extension
 */
String createFileName( String dirPath, String name, String ext, { String? version } ) {
    var fileName = version == null ? 
        path.join( getPathFromUserDir( dirPath ), "${name}_${currentDatetime( )}.$ext" ) :
        path.join( getPathFromUserDir( dirPath ), "${name}_${version}_${currentDatetime( )}.$ext" );
    return fileName;
}

void Function( ) emptyFunc = ( ) { };

/**
 * Arbitrary functions store
 */
class Functions {
    static final Map< String, dynamic > _map = < String, dynamic > { }; 

    /**
     * Returns specified function
     */
    static T get< T >( String key ) {
        return _map[ key ] as T;
    }

    /**
     * Puts specified function to the store
     * key the key
     * function the function to store
     */
    static void put( String key, dynamic function ) { 
        _map[ key ] = function;
    }
}

/**
 * Generic list item with arbitrary object within
 */
class ListItem implements Comparable {
    bool selected = false;
    dynamic customData;

    ListItem( this.customData );
    
    @override
    int compareTo( other ) {
        return customData.compareTo( other.customData );
    }
}

const String TEXT_FIELD = "TextFormField";
const String DROPDOWN = "DropDownButton";
const String CHECK_BOX = "CheckBox";
const String RADIO = "Radio";
const String SWITCH = "Switch";
const String LIST_VIEW_FIELD = "ListView";
const String CHIP_LIST_FIELD = "ChipListField";

/**
 * Defines field pattern
 */
class FieldPattern {
    String? Function( String? value ) validator;
    String? style;
    double width;
    String containerId;
    Axis axis;
    String label;

    static String? _emptyValidator( String? value ) {
        return null;
    }

    FieldPattern( 
        { 
            this.label = "",
            this.validator = _emptyValidator, 
            this.style, 
            this.width = 130, 
            this.containerId = "", 
            this.axis = Axis.horizontal 
        } 
    );
}

const String ERR_MSG = "error_message";
const String ERROR = "error";
const String WARNING = "warning";
const String NOTICE = "notice";
const String STACK = "stack_trace";

Logger logger = Logger( 
    printer: PrettyPrinter( printEmojis: false, printTime: true, colors: false ),
    output: FileOutput( file: File( createFileName( "logs", Config( ).config[ 'app_name' ], "log" ) ) )
);

void logOnErrorFlutter( FlutterErrorDetails details ) {
    logger.e( details.exception.toString( ), details.exception, details.stack );
}

bool logOnErrorPlatform( Object error, StackTrace stack ) {
    var err = error as Exception; 
    logger.e( err.toString( ), err, stack );
    return true;
}

/**
 * Console output specified object
 * jsonObject the object to output, must implement Map< String, dynamic > toJson() method 
 */
void printObjectAsJson( String tag, dynamic jsonObject ) {
    var encoder = const JsonEncoder.withIndent( INDENT );
    debugPrint( tag );
    debugPrint( encoder.convert( jsonObject ) );
}



