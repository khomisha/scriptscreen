
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class Config {    
    static final Config _instance = Config._( );
    Map< String, dynamic > config = < String, dynamic >{ };
    late final String _fileName;

    Config._( ) {
        _fileName = path.join( 'assets', 'cfg', 'app_settings.json' );
        var file = File( _fileName );
        config = json.decode( file.readAsStringSync( ) );
    }

    factory Config( ) {
        return _instance;
    }

    void write( ) {
        var encoder = const JsonEncoder.withIndent( ' ' );
        var file = File( _fileName );
        file.writeAsStringSync( encoder.convert( config ) );
    }
}