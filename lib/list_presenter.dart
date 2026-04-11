
// ignore_for_file: avoid_print, slash_for_doc_comments

import 'app_const.dart';
import 'app_presenter.dart';
import 'script_data.dart';
import 'package:base/base.dart';

class ListPresenter extends WidgetPresenter {

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
        deleteReference( index );
        super.delete( index );
    }

    @override
    void startEdit( int index ) {
        super.startEdit( index );
        notifyListeners( );
    }

    @override
    void endEdit( bool ok ) {
        readOnly = true;
        if( !ok && adding ) {
            delete( editIndex );
        }
        super.endEdit( ok );
   }

    @override
    void select( int index ) {
        if( selectedIndex == index ) {
            // Toggle off: deselect the current item
            //list[ index ].setState( ListItemState.unselected.index );
            //selectedIndex = -1;
        } else {
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
     */
    void deleteReference( int index ) {
        var deletingItem = list[ index ].customData;
        var noteItems = AppPresenter( ).getData( NOTE );
        for( var noteItem in noteItems ) {
            var note = noteItem.customData as NoteData;
            note.attributes[ dataType ].removeWhere( 
                ( ListItem item ) {
                    return item.customData.attributes[ 'name' ] == deletingItem.attributes[ 'name' ];
                }
            );
        }
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