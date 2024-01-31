
// ignore_for_file: slash_for_doc_comments

import 'package:flutter/material.dart';
import 'package:scriptscreen/app_presenter.dart';
import 'util.dart';

abstract class WidgetPresenter extends ChangeNotifier {
    late String dataType;
    late int editIndex;
    late List< ListItem > _list;
    List< ListItem > get list => _list;
    late int selectedIndex;
    set list( List< ListItem > value ) { 
        _list = value;
        _list.sort( );
        selectedIndex = _list.isEmpty ? -1 : 0;
        debugPrint( "refresh data" );
        notifyListeners( );
    }
    bool readOnly = true;

    /**
     * Adds empty data
     */
    int add( );

    /**
     * Deletes specified data
     * index the note data index
     */
    void delete( int index ) {
        _list.removeAt( index );
        AppPresenter( ).save( );
    }

    /**
     * Starts editing specified data
     * index the data index
     */
    void startEdit( int index ) {
        editIndex = index;
        readOnly = false;
    }

    /**
     * Ends editing data
     * ok the end editing success flag
     */
    void endEdit( bool ok ) {
        if( ok ) {
            AppPresenter( ).save( );
        }
        readOnly = true;
    }

    /**
     * Updates specified attribute of the editing data
     * attributeName the attribute name
     * newValue the new value
     * notify the notify flag
     */
    void update( String attributeName, dynamic newValue, bool notify ) {
        var value = list[ editIndex ].customData[ attributeName ];
        if( value is List ) {
            var length = value.length;
            value.removeWhere( 
                ( e ) => e.customData.attributes[ 'name' ] == newValue.customData.attributes[ 'name' ] 
            );
            if( value.length == length ) {
                value.add( newValue );
            }
            value.sort( );
        } else {
            list[ editIndex ].customData[ attributeName ] = newValue;
        }
        if( notify ) {
            notifyListeners( );
        }
    } 

    /**
     * Selects specified item
     * index the item index to select
     */
    void select( int index ) {
    }

    /** 
     * Returns specified data
     * index the data index
     */
    ListItem get( int index ) {
        return _list[ index ];
    }
}