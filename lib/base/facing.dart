
// ignore_for_file: slash_for_doc_comments

import 'util.dart';

final _facing = < String, Map< String, FieldPattern > > { };

/**
 * Returns fields pattern set specified by key
 * key the fields pattern set key 
 */
Map< String, FieldPattern > getPattern( String key ) {
    return _facing[ key ] ?? < String, FieldPattern > { };
}

/**
 * Adds new pattern for specified key
 * key the fields pattern set key 
 * pattern the fields pattern
 */
void addPattern( String key, Map< String, FieldPattern > pattern ) {
    _facing[ key ] = pattern;
}
