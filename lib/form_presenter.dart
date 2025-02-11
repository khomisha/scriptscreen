
// ignore_for_file: slash_for_doc_comments

import 'package:base/base.dart';
import 'package:scriptscreen/app_const.dart';
import 'app_presenter.dart';

class FormPresenter extends WidgetPresenter {

    FormPresenter( String dataType) {
        super.dataType = dataType;
        Notification( ).subscribe( ON_UPDATE, this );
        list = getData( dataType );
    }

    @override
    void startEdit( int index ) {
        super.startEdit( index );
        notifyListeners( );
    }

    @override
    void endEdit( bool ok ) {
        readOnly = true;
        super.endEdit( ok );
    }

    @override
    void delete( int index ) {
    }

    @override
    void onSuccess( ) {
        AppPresenter( ).save( );
    }
    
    @override
    void receive( String event, { data } ) {
        if( event == ON_UPDATE && data != null ) {
            list = data as List< ListItem >;
        }
    }
}


