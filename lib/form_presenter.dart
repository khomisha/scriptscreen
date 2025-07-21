
// ignore_for_file: slash_for_doc_comments

import 'package:base/base.dart';
import 'app_presenter.dart';

class FormPresenter extends WidgetPresenter {

    FormPresenter( super.dataType ) {
        eventBroker.subscribe( this, UPDATE );
        list = AppPresenter( ).getData( dataType );
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
}


