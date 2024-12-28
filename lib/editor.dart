
// ignore_for_file: constant_identifier_names

import 'package:path/path.dart' as p;
import 'package:base/base.dart';

class Editor {
    static final Editor _instance = Editor._( );
    bool created = false;
    late String path;

    Editor._( ) {
        path = p.join( p.current, 'assets', Config.config[ 'editor_config' ] );
    }

    factory Editor( ) {
        return _instance;
    }

    void create( ) async {
    }

    Future< String > getContent( ) async {
        return "";
    }

    void setContent( String content ) async {
    }

    void setVisible( bool visible ) {
    }
}
