
// ignore_for_file: slash_for_doc_comments

import 'package:scriptscreen/base/widget_presenter.dart';
import 'app_presenter.dart';

class FormPresenter extends WidgetPresenter {

    FormPresenter( String dataType) {
        super.dataType = dataType;
        AppPresenter( ).subscribe( this );
    }

    @override
    int add( ) {
        return 0;
    }

    @override
    void startEdit( int index ) {
        super.startEdit( index );
        notifyListeners( );
    }

    @override
    void delete( int index ) {
    }
}


