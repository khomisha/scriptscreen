// ignore_for_file: slash_for_doc_comments

import 'package:flutter/material.dart';
import 'package:scriptscreen/app_const.dart';
import 'app_components.dart';
import 'app_menu.dart';
import 'base/panel.dart';
import 'main_panel.dart';

class DetailPanel {
    late Panel panel;
	
    DetailPanel( Widget widget ) {
        var list = widget as DataList;
        List< PopupMenuEntry > menuItems = [
            PopupMenuItem( onTap: list.add, child: const Text( "Add Detail" ) ),
            const PopupMenuDivider( ),
            exitApp
        ];
        panel = Panel( 
            title: "Details", 
            childWidget: createProvider( DETAIL, list ), 
            icon: const Icon( Icons.collections_bookmark ),
            menu: createMenu( menuItems )
        );
    }
}
