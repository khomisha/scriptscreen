
// ignore_for_file: prefer_const_constructors_in_immutables, slash_for_doc_comments

import 'form_presenter.dart';
import 'package:base/base.dart';
import 'list_presenter.dart';

/**
 * Data list with data form to edit selected list item
 */
class DataList extends BaseList< ListPresenter > {

    DataList( { super.key } );

    @override
    T getForm< T extends BaseForm >( ) {
        return DataForm( ) as T;
    }
}

class DataForm extends BaseForm< ListPresenter > {

    DataForm( { super.key } );
}

class ProjectForm extends BaseForm< FormPresenter > {

    ProjectForm( { super.key } );
}

class ScriptForm extends BaseForm< FormPresenter > {

    ScriptForm( { super.key } );
}
