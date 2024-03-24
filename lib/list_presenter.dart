
// ignore_for_file: avoid_print, slash_for_doc_comments

import 'package:scriptscreen/app_const.dart';
import 'package:scriptscreen/app_presenter.dart';
import 'package:scriptscreen/data.dart';
import 'base/util.dart';
import 'base/widget_presenter.dart';

class ListPresenter extends WidgetPresenter {

    ListPresenter( type ) {
        super.dataType = type;
        AppPresenter( ).subscribe( this );
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
            list[ index ].selected = !list[ index ].selected;
        } else {
            list[ selectedIndex ].selected = false;
            list[ index ].selected = true;
        }
        selectedIndex = index;
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
}