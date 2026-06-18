// ignore_for_file: slash_for_doc_comments

import 'package:flutter/material.dart';
import 'app_const.dart';
import 'app_components.dart';
import 'app_menu.dart';
import 'package:base/base.dart';
import 'list_presenter.dart';
import 'main_panel.dart';

class DetailPanel {
    late Panel panel;
	
    DetailPanel( Widget widget ) {
        var list = widget as DataList;
        List< PopupMenuEntry > menuItems = [
            PopupMenuItem( onTap: list.add, child: Text( tr( 'menu_add_detail' ) ) ),
            const PopupMenuDivider( ),
            aboutApp,
            exitApp
        ];
        panel = Panel(
            title: tr( 'panel_details' ),
            childWidget: createProvider< ListPresenter >(
                PresenterRegistry( ).getPresenter( DETAIL, ( ) => ListPresenter( DETAIL ) ),
                list
            ), 
            icon: const Icon( Icons.collections_bookmark ),
            actions: [ createMenu( menuItems ) ]
        );
    }
}
