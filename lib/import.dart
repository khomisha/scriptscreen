
// ignore_for_file: constant_identifier_names, slash_for_doc_comments

import 'app_const.dart';
import 'app_presenter.dart';
import 'package:base/base.dart';
import 'script_data.dart';

/**
 * Import of a marked up plain text file.
 *
 * The text is prepared outside the application: the author exports the script
 * from any editor and marks it up with the tags below.
 *
 * <text>    delimits one fragment, one fragment becomes one plot card,
 *           anything outside the tag is not imported
 * <title>   the card title, the first one in the fragment wins
 * <desc>    the card description, the first one in the fragment wins
 * <role>    a role name, any number per fragment, the name is the identifier
 * <loc>     a location name, see <role>
 * <det>     a detail name, see <role>
 * <time>    an action time name, see <role>
 *
 * Roles, locations, details and action times missing from the project are
 * created, the remaining fragment text becomes the card content file. The
 * import is transactional: on any error the project stays as it was before,
 * see [importText].
 */

const String TAG_TEXT = "text";
const String TAG_TITLE = "title";
const String TAG_DESC = "desc";
const String TAG_ROLE = "role";
const String TAG_LOC = "loc";
const String TAG_DET = "det";
const String TAG_TIME = "time";

// markup tag to application data type, see app_const
const Map< String, String > _TYPES = < String, String > {
    TAG_ROLE: ROLE,
    TAG_LOC: LOCATION,
    TAG_DET: DETAIL,
    TAG_TIME: ACTION_TIME
};

final RegExp _TAG = RegExp(
    '<(/?)($TAG_TEXT|$TAG_TITLE|$TAG_DESC|$TAG_ROLE|$TAG_LOC|$TAG_DET|$TAG_TIME)>',
    caseSensitive: false
);

/**
 * Error found in the imported markup, the message is ready to show to the user
 */
class ImportException implements Exception {
    final String message;

    ImportException( this.message );

    @override
    String toString( ) => message;
}

/**
 * One <text> fragment, the source of a single plot card
 */
class Fragment {
    final int line;
    String title = "";
    String description = "";
    // data type to the names met in the fragment, in order of appearance
    final Map< String, List< String > > names = < String, List< String > > {
        ROLE: < String > [],
        LOCATION: < String > [],
        DETAIL: < String > [],
        ACTION_TIME: < String > []
    };
    final StringBuffer body = StringBuffer( );

    Fragment( this.line );
}

/**
 * The numbers of the created entities, see [importText]
 */
class ImportStat {
    int cards = 0;
    int roles = 0;
    int locations = 0;
    int details = 0;
    int actionTimes = 0;
}

/**
 * Imports the marked up text file into the current project. Parses the whole
 * file first, so a malformed markup leaves the project untouched, then applies
 * the result and saves the project. If applying fails, the project is rolled
 * back to the state before the import and the content files written by this
 * import are removed.
 * path the marked up text file path
 */
Future< void > importText( String path ) async {
    final content = await GenericFile( path ).readString( );
    List< Fragment > fragments;
    try {
        fragments = parse( content );
    }
    on ImportException catch( e ) {
        logger.severe( '${tr( 'import_failed' )} ${e.message}' );
        return;
    }
    if( fragments.isEmpty ) {
        logger.warning( tr( 'import_empty' ) );
        return;
    }
    // flush the content of the currently selected card before the board is rebuilt
    eventBroker.dispatch( Event( SAVE_CONTENT ) );
    final snapshot = AppPresenter( ).snapshot( );
    final written = < String > [];
    try {
        final stat = _apply( fragments, written );
        eventBroker.dispatch( Event( UPDATE, true ) );
        AppPresenter( ).save( );
        logger.info( _report( stat ) );
    }
    catch( e, stack ) {
        for( final fileName in written ) {
            GenericFile( fileName ).delete( );
        }
        AppPresenter( ).restore( snapshot );
        eventBroker.dispatch( Event( UPDATE, true ) );
        logger.severe( '${tr( 'import_failed' )} $e', e, stack );
    }
}

/**
 * Parses the marked up text into fragments, throws [ImportException] on a
 * malformed markup
 * content the marked up text
 */
List< Fragment > parse( String content ) {
    final counter = _LineCounter( content );
    final fragments = < Fragment > [];
    Fragment? fragment;         // the fragment being read, null outside <text>
    String? openTag;            // the inner tag being read, null when none is open
    var openLine = 0;           // the line the inner tag is opened at
    var buffer = StringBuffer( );   // the inner tag content
    var last = 0;               // the end of the previously met tag

    for( final match in _TAG.allMatches( content ) ) {
        final closing = match.group( 1 ) == '/';
        final tag = match.group( 2 )!.toLowerCase( );
        final text = content.substring( last, match.start );
        final line = counter.lineAt( match.start );
        last = match.end;
        if( openTag != null ) {
            if( !closing || tag != openTag ) {
                throw ImportException( _error( 'err_import_unclosed_tag', openLine, tag: openTag ) );
            }
            buffer.write( text );
            _closeTag( fragment!, openTag, buffer.toString( ), line );
            buffer = StringBuffer( );
            openTag = null;
            continue;
        }
        if( fragment != null ) {
            fragment.body.write( text );
        }
        if( tag == TAG_TEXT ) {
            if( closing ) {
                if( fragment == null ) {
                    throw ImportException( _error( 'err_import_unexpected_close', line, tag: tag ) );
                }
                if( fragment.title.isEmpty ) {
                    throw ImportException( _error( 'err_import_no_title', fragment.line ) );
                }
                fragments.add( fragment );
                fragment = null;
            } else {
                if( fragment != null ) {
                    throw ImportException( _error( 'err_import_nested_text', line ) );
                }
                fragment = Fragment( line );
            }
            continue;
        }
        // the inner tags are meaningful within a fragment only
        if( fragment == null ) {
            continue;
        }
        if( closing ) {
            throw ImportException( _error( 'err_import_unexpected_close', line, tag: tag ) );
        }
        openTag = tag;
        openLine = line;
    }
    if( openTag != null ) {
        throw ImportException( _error( 'err_import_unclosed_tag', openLine, tag: openTag ) );
    }
    if( fragment != null ) {
        throw ImportException( _error( 'err_import_unclosed_text', fragment.line ) );
    }
    return fragments;
}

/**
 * Adds the content of the closed inner tag to the fragment. The title and the
 * description are taken out of the card content, the names stay in place, so
 * the sentences they belong to are imported as they are written.
 * fragment the fragment being read
 * tag the closed tag
 * value the tag content
 * line the line the tag is closed at
 */
void _closeTag( Fragment fragment, String tag, String value, int line ) {
    final name = value.trim( );
    switch( tag ) {
        case TAG_TITLE:
            if( name.isEmpty && fragment.title.isEmpty ) {
                throw ImportException( _error( 'err_import_empty_value', line, tag: tag ) );
            }
            if( fragment.title.isEmpty ) {
                fragment.title = name;
            }
            break;
        case TAG_DESC:
            if( fragment.description.isEmpty ) {
                fragment.description = name;
            }
            break;
        default:
            if( name.isEmpty ) {
                throw ImportException( _error( 'err_import_empty_value', line, tag: tag ) );
            }
            final names = fragment.names[ _TYPES[ tag ] ]!;
            if( !names.contains( name ) ) {
                names.add( name );
            }
            fragment.body.write( value );
    }
}

/**
 * Creates the cards described by the fragments, adds the referenced roles,
 * locations, details and action times missing from the project and writes the
 * card content files
 * fragments the parsed fragments
 * written collects the written content file names, to remove them on rollback
 */
ImportStat _apply( List< Fragment > fragments, List< String > written ) {
    final stat = ImportStat( );
    final notes = AppPresenter( ).getData( NOTE );
    // the board assigns the indexes by the list order, keep the existing cards
    // in place and put the imported ones after them
    for( var i = 0; i < notes.length; i++ ) {
        ( notes[ i ].customData as NoteData ).index = i + 1;
    }
    final stamp = currentDatetime( pattern: "yyMMddHHmmssSSS" );
    for( final fragment in fragments ) {
        final note = NoteData(
            fragment.title,
            fragment.description,
            _references( fragment, ROLE, stat ),
            _references( fragment, LOCATION, stat ),
            _references( fragment, DETAIL, stat ),
            _references( fragment, ACTION_TIME, stat ),
            '${stamp}_${stat.cards}.html'
        );
        notes.add( ListItem( note ) );
        note.index = notes.length;
        final fileName = getBodyFileName( note );
        GenericFile( fileName ).writeString( toHtml( bodyText( fragment.body.toString( ) ) ) );
        written.add( fileName );
        stat.cards++;
    }
    return stat;
}

/**
 * Returns the card attribute list for the specified data type, adding the
 * names missing from the project to the project list
 * fragment the parsed fragment
 * type the data type [ROLE], [LOCATION], [DETAIL], [ACTION_TIME]
 * stat the counters to update
 */
List< ListItem > _references( Fragment fragment, String type, ImportStat stat ) {
    final projectItems = AppPresenter( ).getData( type );
    final references = < ListItem > [];
    for( final name in fragment.names[ type ]! ) {
        GenericData? data;
        for( final item in projectItems ) {
            if( ( item.customData as GenericData ).name == name ) {
                data = item.customData as GenericData;
                break;
            }
        }
        if( data == null ) {
            data = emptyItem( type ) as GenericData;
            data.name = name;
            projectItems.add( ListItem( data ) );
            _count( stat, type );
        }
        references.add( ListItem( data.copy( ) ) );
    }
    return references;
}

/**
 * Counts the created item of the specified data type
 */
void _count( ImportStat stat, String type ) {
    switch( type ) {
        case ROLE:
            stat.roles++;
            break;
        case LOCATION:
            stat.locations++;
            break;
        case DETAIL:
            stat.details++;
            break;
        case ACTION_TIME:
            stat.actionTimes++;
            break;
    }
}

/**
 * Returns the card content as plain text: the lines are trimmed, the leading
 * and trailing empty lines are dropped and the runs of empty lines are
 * collapsed into one
 * raw the fragment text with the markup removed
 */
String bodyText( String raw ) {
    final lines = raw.split( '\n' ).map( ( line ) => line.trim( ) ).toList( );
    final result = < String > [];
    for( final line in lines ) {
        if( line.isEmpty && ( result.isEmpty || result.last.isEmpty ) ) {
            continue;
        }
        result.add( line );
    }
    while( result.isNotEmpty && result.last.isEmpty ) {
        result.removeLast( );
    }
    return result.join( '\n' );
}

/**
 * Converts the card content to the html the text editor works with, see
 * [EMPTY_CONTENT]
 * text the card content as plain text
 */
String toHtml( String text ) {
    if( text.isEmpty ) {
        return EMPTY_CONTENT;
    }
    final buffer = StringBuffer( );
    for( final line in text.split( '\n' ) ) {
        final escaped = _escape( line );
        buffer.write( '<div><span style="font-size: 12pt;">${ escaped.isEmpty ? '&nbsp;' : escaped }</span></div>' );
    }
    return buffer.toString( );
}

/**
 * Escapes the html markup characters of the imported text
 */
String _escape( String text ) {
    return text
        .replaceAll( '&', '&amp;' )
        .replaceAll( '<', '&lt;' )
        .replaceAll( '>', '&gt;' );
}

/**
 * Returns the localized markup error message with the line number
 * key the message key, see assets/l10n
 * line the line the error is found at
 * tag the tag the error is about, if any
 */
String _error( String key, int line, { String? tag } ) {
    var message = tr( key );
    if( tag != null ) {
        message = message.replaceAll( '@tag', tag );
    }
    return '$message, ${ tr( 'err_import_line' ).replaceAll( '@line', line.toString( ) ) }';
}

/**
 * Returns the localized import report
 */
String _report( ImportStat stat ) {
    return tr( 'import_done' )
        .replaceAll( '@cards', stat.cards.toString( ) )
        .replaceAll( '@roles', stat.roles.toString( ) )
        .replaceAll( '@locations', stat.locations.toString( ) )
        .replaceAll( '@details', stat.details.toString( ) )
        .replaceAll( '@times', stat.actionTimes.toString( ) );
}

/**
 * Counts the lines of the parsed text. The tags are met in order, so the
 * already counted part of the text is never scanned twice.
 */
class _LineCounter {
    static const int _NEW_LINE = 0x0A;

    final String _content;
    int _scanned = 0;
    int _line = 1;

    _LineCounter( this._content );

    /**
     * Returns the number of the line the specified offset belongs to, the
     * offset must not be less than the offset of the previous call
     */
    int lineAt( int offset ) {
        while( _scanned < offset ) {
            if( _content.codeUnitAt( _scanned ) == _NEW_LINE ) {
                _line++;
            }
            _scanned++;
        }
        return _line;
    }
}
