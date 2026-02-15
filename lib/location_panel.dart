
import 'package:flutter/material.dart';
import 'app_const.dart';
import 'app_components.dart';
import 'app_menu.dart';
import 'package:base/base.dart';
import 'list_presenter.dart';
import 'main_panel.dart';

class LocationPanel {
    late Panel panel;
	
    LocationPanel( Widget widget ) {
        var list = widget as DataList;
        List< PopupMenuEntry > menuItems = [
            PopupMenuItem( onTap: list.add, child: const Text( "Add Location" ) ),
            const PopupMenuDivider( ),
            exitApp
        ];
        panel = Panel( 
            title: "Locations", 
            childWidget: createProvider< ListPresenter >(
                PresenterRegistry( ).getPresenter( LOCATION, ( ) => ListPresenter( LOCATION ) ),
                list
            ), 
            icon: const Icon( Icons.room ),
            actions: [ createMenu( menuItems ) ]
        );
    }
}