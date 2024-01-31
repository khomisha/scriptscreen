
// ignore_for_file: avoid_print, slash_for_doc_comments

import 'app_const.dart';
import 'app_presenter.dart';
import 'base/util.dart';
import 'base/widget_presenter.dart';
import 'data.dart';
import 'editor.dart';

class NotePresenter extends WidgetPresenter {
    final _filter = < String >[ ];

    int _stackIndex = 0;
    int get stackIndex => _stackIndex;
    set stackIndex( int value ) { 
        _stackIndex = value;
        notifyListeners( );
    }

    NotePresenter( ) {
        super.dataType = NOTE;
        AppPresenter( ).subscribe( this );
    }

    @override
    int add( ) {
        list.add( ListItem( emptyItem( NOTE ) ) );
        return list.length - 1;
    }

    @override
    void startEdit( int index ) {
        super.startEdit( index );
        stackIndex = 1;
    }

    @override
    void endEdit( bool ok ) {
        stackIndex = 0;
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
     * On select saves selected note (if any) content and loads selecting 
     * note content to the text editor.
     * selectedIndex the selected note index
     * selectingIndex the selecting note index 
     */
    Future< void > onSelect( int? selectedIndex, int selectingIndex ) async {
        if( !Editor( ).created ) {
            Editor( ).create( );
            await Future.delayed( const Duration( seconds: 2 ) );   // ???   
        }
        if( selectedIndex != null ) {
            var note = list[ selectedIndex ].customData as NoteData;
            Editor( ).getContent( ).then( ( value ) { note.body = value.substring( 1, value.length - 1 ); } );
            //AppPresenter( ).save( );
        }
        var note = list[ selectingIndex ].customData as NoteData;
        Editor( ).setContent( note.body );
    }
}
