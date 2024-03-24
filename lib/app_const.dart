
// ignore_for_file: constant_identifier_names, slash_for_doc_comments, dangling_library_doc_comments

/**
 * Application constants and typedefs
 */

const String ROLE = "role";
const String DETAIL = "detail";
const String LOCATION = "location";
const String ACTION_TIME = "action_time";
const String NOTE = "note";
const String SCRIPT = "script";
const String AUTHOR = "author";
const String PROJECT = "project";

// defaults settings
const String NONAME = "noname";
const String START_VERSION = "1.0";

typedef Delete = void Function( String id );
typedef StartEdit = void Function( String id );
typedef EndEdit = void Function( bool ok );
typedef ChangeFilter = void Function( String name );
typedef GetFilter = List< String > Function( );

// command types
const String CREATE = "create";
const String LOAD = "load";
const String SAVE = "save";
const String EXIT = "exit";
