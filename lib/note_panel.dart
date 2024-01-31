
import 'package:flutter/material.dart';
import 'app_const.dart';
import 'app_menu.dart';
import 'base/panel.dart';
import 'main_panel.dart';

class NotePanel {
    late Panel panel;

    NotePanel( Widget widget ) {
        List< PopupMenuEntry > menuItems = [
            exitApp
        ];
        panel = Panel( 
            title: "Notes", 
            childWidget: createProvider( NOTE, widget ), 
            icon: const Icon( Icons.dashboard ),
            menu: createMenu( menuItems )
        );
    }
}