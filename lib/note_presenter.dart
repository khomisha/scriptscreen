
// ignore_for_file: avoid_print, slash_for_doc_comments

import 'package:flutter/material.dart';
import 'editor.dart';
import 'app_const.dart';
import 'app_presenter.dart';
import 'package:base/base.dart';
import 'script_data.dart';

class NotePresenter extends WidgetPresenter {
    final _filter = < String >[ ];

    int _stackIndex = 0;
    int get stackIndex => _stackIndex;
    set stackIndex( int value ) { 
        _stackIndex = value;
        notifyListeners( );
    }
    
    // Add a specific event notifier
    final refreshNotifier = ChangeNotifier( );

    NotePresenter( ) : super( NOTE ) {
        eventBroker.subscribe( this, UPDATE );
        eventBroker.subscribe( this, SAVE_CONTENT );
        list = AppPresenter( ).getData( dataType );
    }

    @override
    int add( ) {
        var note = emptyItem( dataType ) as NoteData;
        list.add( ListItem( note ) );
        var file = GenericFile( getBodyFileName( note ) );
        file.writeString( EMPTY_CONTENT );
        return list.length - 1;
    }

    @override
    void delete( int index ) {
        editor.clear( );
        var file = GenericFile( getBodyFileName( list[ index ].customData as NoteData ) );
        file.delete( );
        super.delete( index );
    }

    @override
    void startEdit( int index ) {
        super.startEdit( index );
        stackIndex = 1;
    }

    @override
    void endEdit( bool ok ) {
        stackIndex = 0;
        readOnly = true;
        super.endEdit( ok );
    }

    /**
     * Changes notes filter
     * keyWord the key word to filter
     */
    void changeFilter( String keyWord ) {
        if( _filter.contains( keyWord ) ) {
            _filter.removeWhere( ( String itemName ) { return itemName == keyWord; } );
        } else {
            _filter.add( keyWord );
        }
    }

    /**
     * Returns notes filter
     */
    List< String > getFilter( ) {
        return _filter;
    }

    /**
     * Applies filter to specified note
     * index the note index
     * returns true if note is filtered and false otherwise
     */
    bool applyFilter( int index ) {
        if( _filter.isEmpty ) {
            return true;
        }
        var attributeNames = [ ROLE, DETAIL, LOCATION ];
        for( var attributeName in attributeNames ) {
            var l = list[ index ].customData[ attributeName ] as List;
            for( var listItem in l ) {
                if( _filter.contains( listItem.customData.attributes[ 'name' ] ) ) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * On select loads selecting note content to the text editor.
     * selecting the selecting list item
     */
    Future< void > onSelect( ListItem item ) async {
        var note = item.customData as NoteData;
        editor.load( getBodyFileName( note ) );
    }

    /**
     * On deselect saves selected note and clean editor content
     * item the selected list item
     */
    Future< void > onDeselect( ListItem item ) async {
        var note = item.customData as NoteData;
        await editor.save( getBodyFileName( note ) );
        await editor.clear( );
    }
    
    @override
    void onSuccess( ) {
        AppPresenter( ).save( );
    }

    @override
    void onEvent( Event event ) {
        if( event.type == UPDATE ) {
            list = AppPresenter( ).getData( dataType );
            if( event.data ) {
                refreshNotifier.notifyListeners( );
            }
        }
        if( event.type == SAVE_CONTENT && selectedIndex > -1 ) {
            var note = list[ selectedIndex ].customData as NoteData;
            editor.save( getBodyFileName( note ) );
        }
    }
}
