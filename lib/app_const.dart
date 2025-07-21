
// ignore_for_file: constant_identifier_names, slash_for_doc_comments, dangling_library_doc_comments

/**
 * Application constants and typedefs
 */

// data types
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
const String CMD_CREATE = "cmd_create";
const String CMD_LOAD = "cmd_load";
const String CMD_SAVE = "cmd_save";
const String CMD_EXIT = "cmd_exit";

// events
const String EXIT = "exit";
const String SEND = "send";
const String END_UPDATE = "end_update";
const String SAVE_CONTENT = "save_content";

const String EMPTY_CONTENT = '<div><span style="font-size: 12pt;"></span></div>';
