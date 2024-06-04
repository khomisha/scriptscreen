// ignore_for_file: slash_for_doc_comments

import 'package:flutter/material.dart';
import 'app_const.dart';
import 'app_components.dart';
import 'app_menu.dart';
import 'package:base/base.dart';
import 'main_panel.dart';

class ActionTimePanel {
    late Panel panel;
	
    ActionTimePanel( Widget widget ) {
        var list = widget as DataList;
        List< PopupMenuEntry > menuItems = [
            PopupMenuItem( onTap: list.add, child: const Text( "Add Action Time" ) ),
            const PopupMenuDivider( ),
            exitApp
        ];
        panel = Panel( 
            title: "Action Times", 
            childWidget: createProvider( ACTION_TIME, list ), 
            icon: const Icon( Icons.schedule ),
            menu: createMenu( menuItems )
        );
    }
}
