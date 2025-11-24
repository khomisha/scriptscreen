// ignore_for_file: slash_for_doc_comments

import 'package:flutter/material.dart';
import 'app_const.dart';
import 'app_components.dart';
import 'app_menu.dart';
import 'package:base/base.dart';
import 'main_panel.dart';

class RolePanel {
    late Panel panel;

    RolePanel( Widget widget ) {
        var list = widget as DataList;
        List< PopupMenuEntry > menuItems = [
            PopupMenuItem( onTap: list.add, child: const Text( "Add Role" ) ),
            const PopupMenuDivider( ),
            exitApp
        ];
        panel = Panel( 
            title: "Roles", 
            childWidget: createProvider( ROLE, list ), 
            icon: const Icon( Icons.theater_comedy ),
            actions: [ createMenu( menuItems ) ] 
        );
    }
}
