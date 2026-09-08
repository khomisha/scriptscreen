
// ignore_for_file: avoid_print, slash_for_doc_comments

import 'app_const.dart';
import 'app_presenter.dart';
import 'note_presenter.dart';
import 'script_data.dart';
import 'package:base/base.dart';

class ListPresenter extends WidgetPresenter {
    // the name of the object being edited, taken before the edit, see [endEdit]
    String _oldName = "";

    ListPresenter( super.dataType ) {
        eventBroker.subscribe( this, UPDATE );
        final initialList = AppPresenter( ).getData( dataType );
        if( initialList.isNotEmpty ) {
            selectedIndex = 0;      // select first item by default
        }
        list = initialList;
    }

    @override
    int add( ) {
        adding = true;
        list.add( ListItem( emptyItem( dataType ) ) );
        selectedIndex = list.length - 1;
        startEdit( list.length - 1 );
        return list.length - 1;
    }

    @override
    void delete( int index ) {
        final referred = deleteReference( index );
        super.delete( index );
        if( referred ) {
            // the object is gone from the cards, the references to it in their
            // text go with it
            PresenterRegistry( ).getPresenter( NOTE, ( ) => NotePresenter( ) ).syncNotes( );
        }
    }

    @override
    void startEdit( int index ) {
        _oldName = ( list[ index ].customData as GenericData ).name;
        super.startEdit( index );
        notifyListeners( );
    }

    @override
    void endEdit( bool ok ) {
        readOnly = true;
        if( !ok && adding ) {
            delete( editIndex );
        }
        // the form writes the fields on ok only, see BaseForm.onOK, so the
        // name is compared here and the cards are updated before the project
        // is saved by super
        if( ok && !adding ) {
            final name = ( list[ editIndex ].customData as GenericData ).name;
            if( name != _oldName ) {
                rename( _oldName, name );
            }
        }
        super.endEdit( ok );
   }

    /**
     * Renames the object in the cards it is attached to: the chip of the card
     * and the references in its text follow the new name, the text the author
     * wrote is left as it is
     * oldName the name of the object before the rename
     * newName the name after it
     */
    void rename( String oldName, String newName ) {
        for( final noteItem in AppPresenter( ).getData( NOTE ) ) {
            final note = noteItem.customData as NoteData;
            for( final item in note.attributes[ dataType ] as List< ListItem > ) {
                final data = item.customData as GenericData;
                if( data.name == oldName ) {
                    data.name = newName;
                }
            }
        }
        // the card may hold the renamed object itself and not a copy of it, so
        // its chip carries the new name already while the text does not
        PresenterRegistry( ).getPresenter( NOTE, ( ) => NotePresenter( ) )
            .renameRefs( dataType, oldName, newName );
    }

    @override
    void select( int index ) {
        if( selectedIndex != index ) {
            // Deselect previous item if any
            if( selectedIndex != -1 ) {
                list[ selectedIndex ].setState( ListItemState.unselected.index );
            }
            // Select the new item
            list[ index ].setState( ListItemState.selected.index );
            selectedIndex = index;
        }
        notifyListeners( );
    }

    /**
     * Deletes specified reference from notes
     * index the deleting item index 
     * returns true when at least one card referred to the deleted object
     */
    bool deleteReference( int index ) {
        var deletingItem = list[ index ].customData;
        var noteItems = AppPresenter( ).getData( NOTE );
        var referred = false;
        for( var noteItem in noteItems ) {
            var note = noteItem.customData as NoteData;
            final references = note.attributes[ dataType ] as List< ListItem >;
            final count = references.length;
            references.removeWhere( 
                ( ListItem item ) {
                    return item.customData.attributes[ 'name' ] == deletingItem.attributes[ 'name' ];
                }
            );
            referred = referred || references.length != count;
        }
        return referred;
    }

    @override
    void onSuccess( ) {
        AppPresenter( ).save( );
    }

    @override
    void onEvent( Event event ) {
        if( event.type == UPDATE ) {
            final newList = AppPresenter( ).getData( dataType );
            // Adjust selectedIndex to be within bounds of the new list
            if( selectedIndex >= newList.length ) {
                selectedIndex = newList.isEmpty ? -1 : 0;
            }
            // Assign the new list; the setter will set the state for the (possibly adjusted) selectedIndex
            list = newList;
        }
    }
}