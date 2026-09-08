// ignore_for_file: constant_identifier_names, slash_for_doc_comments

import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'app_const.dart';
import 'app_presenter.dart';
import 'package:base/base.dart';
import 'script_data.dart';

/**
 * References to the project objects ( roles, locations, details, action
 * times ) in the card text.
 *
 * A reference is a span carrying the object type and name:
 *
 *     <span class="ref" data-type="role" data-name="Кирилл">Кирилл</span>
 *
 * The description itself is never stored in the text, it is taken from the
 * project by the type and the name, so it never goes stale.
 *
 * The references of a card follow the objects attached to it: [syncRefs] marks
 * the name of every attached object met in the text and unwraps the references
 * to the objects the card no longer refers to. The text is synced when an
 * object is attached to the card or taken from it, when an object is deleted
 * from the project, when the card is opened in the editor and when the project
 * is exported. The import writes the references of the names it is given right
 * away, see [toHtml].
 *
 * The editor underlines the references and shows the description on hover, see
 * editor_refs.js; the export unwraps them, adding the description at the first
 * appearance of the object, see [resolveRefs].
 */

// the reference markup, see the class comment
const String REF_CLASS = "ref";
const String REF_TYPE = "data-type";
const String REF_NAME = "data-name";

// the data types the card text may refer to
const List< String > REF_TYPES = < String > [ ROLE, LOCATION, DETAIL, ACTION_TIME ];

/**
 * Returns the reference markup of the specified object
 * type the data type, one of [REF_TYPES]
 * name the object name, the identifier of the object within its type
 * text the text the reference is written over, the name as the author wrote it
 */
String refSpan( String type, String name, String text ) {
    return '<span class="$REF_CLASS" $REF_TYPE="${ escapeHtml( type ) }" '
        '$REF_NAME="${ escapeHtml( name ) }">${ escapeHtml( text ) }</span>';
}

/**
 * Escapes the html markup characters, the quote included, so the result fits
 * both the text content and an attribute value
 */
String escapeHtml( String text ) {
    return text
        .replaceAll( '&', '&amp;' )
        .replaceAll( '<', '&lt;' )
        .replaceAll( '>', '&gt;' )
        .replaceAll( '"', '&quot;' );
}

/**
 * Removes the reference markup from the card text, adding the object
 * description at the first appearance of the object. The markup itself is the
 * working format of the project, the exported text carries the descriptions
 * instead of it.
 * html the card text
 * descriptions the object descriptions by data type and name, see
 * [projectDescriptions]
 * described the objects already described, as '<type>|<name>', the caller
 * keeps it over the whole export, so an object is described once only
 */
String resolveRefs( 
    String html, 
    Map< String, Map< String, String > > descriptions, 
    Set< String > described 
) {
    if( !html.contains( REF_CLASS ) ) {
        return html;
    }
    final fragment = parseFragment( html );
    for( final element in fragment.querySelectorAll( 'span.$REF_CLASS' ) ) {
        final parent = element.parentNode;
        if( parent == null ) {
            continue;
        }
        final type = element.attributes[ REF_TYPE ] ?? "";
        final name = element.attributes[ REF_NAME ] ?? element.text;
        final description = descriptions[ type ]?[ name ] ?? "";
        if( description.isNotEmpty && described.add( '$type|$name' ) ) {
            element.append( Text( ' ($description)' ) );
        }
        // the reference is unwrapped, the text the author wrote stays as it is
        for( final node in element.nodes.toList( ) ) {
            node.remove( );
            parent.insertBefore( node, element );
        }
        element.remove( );
    }
    return fragment.outerHtml;
}

/**
 * Brings the references of the card text in step with the objects attached to
 * the card: the name of an attached object met in the text becomes a
 * reference, a reference to an object the card no longer refers to is
 * unwrapped. A name is matched as it is written, an inflected form is marked
 * by the import only, see [toHtml].
 * html the card text
 * names the names of the attached objects by data type, see [noteNames]
 * returns the text with the references or null when there is nothing to change
 */
String? syncRefs( String html, Map< String, List< String > > names ) {
    final ordered = < _Name > [];
    for( final type in REF_TYPES ) {
        for( final name in names[ type ] ?? < String > [] ) {
            if( name.isNotEmpty ) {
                ordered.add( _Name( type, name ) );
            }
        }
    }
    if( !_hasWork( html, ordered ) ) {
        return null;
    }
    // the longest name wins, so 'ANNA MARIE' is not marked as 'ANNA'
    ordered.sort( ( a, b ) => b.name.length.compareTo( a.name.length ) );
    final fragment = parseFragment( html );
    final counter = _Counter( );
    _unwrapDetached( fragment, ordered, counter );
    _markNodes( fragment, ordered, counter );
    return counter.value == 0 ? null : fragment.outerHtml;
}

/**
 * Returns true when the text holds a reference or a name to look at, so the
 * text of a card mentioning none of its objects is never parsed
 */
bool _hasWork( String html, List< _Name > names ) {
    if( html.contains( 'class="$REF_CLASS"' ) ) {
        return true;
    }
    final lower = html.toLowerCase( );
    for( final name in names ) {
        if( lower.contains( name.lower ) ) {
            return true;
        }
    }
    return false;
}

/**
 * Unwraps the references to the objects missing from the specified names, the
 * text the author wrote stays as it is
 */
void _unwrapDetached( DocumentFragment fragment, List< _Name > names, _Counter counter ) {
    for( final element in fragment.querySelectorAll( 'span.$REF_CLASS' ) ) {
        final type = element.attributes[ REF_TYPE ] ?? "";
        final name = element.attributes[ REF_NAME ] ?? element.text;
        if( names.any( ( e ) => e.type == type && e.name == name ) ) {
            continue;
        }
        final parent = element.parentNode;
        if( parent == null ) {
            continue;
        }
        for( final child in element.nodes.toList( ) ) {
            child.remove( );
            parent.insertBefore( child, element );
        }
        element.remove( );
        counter.value++;
    }
}

/**
 * Marks the names in the text nodes of the specified node, see [syncRefs]
 */
void _markNodes( Node node, List< _Name > names, _Counter counter ) {
    for( final child in node.nodes.toList( ) ) {
        if( child is Text ) {
            _markText( child, names, counter );
        } else if( child is Element && !child.classes.contains( REF_CLASS ) ) {
            _markNodes( child, names, counter );
        }
    }
}

/**
 * Replaces the names found in the text node with the reference markup
 */
void _markText( Text node, List< _Name > names, _Counter counter ) {
    final parent = node.parentNode;
    if( parent == null ) {
        return;
    }
    final text = node.data;
    final lower = text.toLowerCase( );
    final nodes = < Node > [];
    var start = 0;         // the end of the last written part of the text
    var position = 0;
    while( position < text.length ) {
        final found = _nameAt( names, text, lower, position );
        if( found == null ) {
            position++;
            continue;
        }
        final end = position + found.name.length;
        if( position > start ) {
            nodes.add( Text( text.substring( start, position ) ) );
        }
        nodes.add( _refElement( found.type, found.name, text.substring( position, end ) ) );
        counter.value++;
        position = end;
        start = end;
    }
    if( nodes.isEmpty ) {
        return;
    }
    if( start < text.length ) {
        nodes.add( Text( text.substring( start ) ) );
    }
    for( final replacement in nodes ) {
        parent.insertBefore( replacement, node );
    }
    node.remove( );
}

/**
 * Returns the name written at the specified position of the text, null when
 * there is none. The name is matched ignoring the case and as a whole word.
 */
_Name? _nameAt( List< _Name > names, String text, String lower, int position ) {
    for( final name in names ) {
        final end = position + name.name.length;
        if( end > text.length || !lower.startsWith( name.lower, position ) ) {
            continue;
        }
        if( _isWordChar( text, position - 1 ) || _isWordChar( text, end ) ) {
            continue;
        }
        return name;
    }
    return null;
}

final RegExp _WORD_CHAR = RegExp( r'[\p{L}\p{N}_]', unicode: true );

/**
 * Returns true when the specified position of the text holds a letter, a digit
 * or an underscore, so a name met there is a part of a longer word
 */
bool _isWordChar( String text, int position ) {
    if( position < 0 || position >= text.length ) {
        return false;
    }
    return _WORD_CHAR.hasMatch( text[ position ] );
}

/**
 * Returns the reference element, see [refSpan]
 */
Element _refElement( String type, String name, String text ) {
    final element = Element.tag( 'span' );
    element.classes.add( REF_CLASS );
    element.attributes[ REF_TYPE ] = type;
    element.attributes[ REF_NAME ] = name;
    element.append( Text( text ) );
    return element;
}

/**
 * One of the names to look for, see [syncRefs]
 */
class _Name {
    final String type;
    final String name;
    final String lower;

    _Name( this.type, this.name ) : lower = name.toLowerCase( );
}

/**
 * The number of the references changed, see [syncRefs]
 */
class _Counter {
    int value = 0;
}

/**
 * Returns the descriptions of the project objects by data type and name, the
 * objects without a description are left out
 */
Map< String, Map< String, String > > projectDescriptions( ) {
    final result = < String, Map< String, String > > {};
    for( final type in REF_TYPES ) {
        final items = < String, String > {};
        for( final item in AppPresenter( ).getData( type ) ) {
            final data = item.customData as GenericData;
            if( data.description.isNotEmpty ) {
                items[ data.name ] = data.description;
            }
        }
        result[ type ] = items;
    }
    return result;
}

/**
 * Returns the object descriptions the editor shows on hover, as json:
 * { "labels": { "role": "Роль", ... }, "items": { "role": { "name": "description" }, ... } }
 * see editor_refs.js
 */
String refsAsJson( ) {
    final labels = < String, String > {};
    for( final type in REF_TYPES ) {
        labels[ type ] = tr( type );
    }
    return jsonEncode( < String, dynamic > { 'labels': labels, 'items': projectDescriptions( ) } );
}

/**
 * Points the references to the object at its new name, the text the author
 * wrote is left as it is: a reference keeps the word it is written over.
 * html the card text
 * type the data type of the renamed object
 * oldName the name of the object before the rename
 * newName the name after it
 * returns the text with the references renamed or null when there are none
 */
String? renameRefs( String html, String type, String oldName, String newName ) {
    if( !html.contains( 'class="$REF_CLASS"' ) ) {
        return null;
    }
    final fragment = parseFragment( html );
    var count = 0;
    for( final element in fragment.querySelectorAll( 'span.$REF_CLASS' ) ) {
        if( element.attributes[ REF_TYPE ] == type && element.attributes[ REF_NAME ] == oldName ) {
            element.attributes[ REF_NAME ] = newName;
            count++;
        }
    }
    return count == 0 ? null : fragment.outerHtml;
}

/**
 * Points the references of the specified card text file at the new name of the
 * object, see [renameRefs]
 * note the card
 * type the data type of the renamed object
 * oldName the name of the object before the rename
 * newName the name after it
 * returns true when the file is rewritten
 */
Future< bool > renameNoteRefs( NoteData note, String type, String oldName, String newName ) async {
    final file = GenericFile( getBodyFileName( note ) );
    final html = renameRefs( await file.readString( ), type, oldName, newName );
    if( html == null ) {
        return false;
    }
    file.writeString( html );
    return true;
}

/**
 * Returns the names of the objects attached to the specified card by data
 * type, see [syncRefs]
 */
Map< String, List< String > > noteNames( NoteData note ) {
    final names = < String, List< String > > {};
    for( final type in REF_TYPES ) {
        names[ type ] = ( note.attributes[ type ] as List< ListItem > )
            .map( ( e ) => ( e.customData as GenericData ).name )
            .toList( );
    }
    return names;
}

/**
 * Brings the text file of the specified card in step with the objects attached
 * to it, see [syncRefs]. The card text is left alone when there is nothing to
 * change.
 * note the card
 * returns true when the file is rewritten
 */
Future< bool > syncNoteRefs( NoteData note ) async {
    final file = GenericFile( getBodyFileName( note ) );
    final html = syncRefs( await file.readString( ), noteNames( note ) );
    if( html == null ) {
        return false;
    }
    file.writeString( html );
    return true;
}
