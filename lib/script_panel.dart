
import 'package:flutter/material.dart';
import 'app_components.dart';
import 'app_const.dart';
import 'app_menu.dart';
import 'package:base/base.dart';
import 'main_panel.dart';

class ScriptPanel {
    late Panel panel;

    ScriptPanel( Widget widget ) {
        var form = widget as ScriptForm;
        List< PopupMenuEntry > menuItems = [
            PopupMenuItem( onTap: form.edit, child: const Text( "Edit Script Summary" ) ),
            const PopupMenuDivider( ),
            exitApp
        ];
        panel = Panel( 
            title: "Script Summary", 
            childWidget: createProvider( SCRIPT, form ), 
            icon: const Icon( Icons.summarize ),
            actions: [ createMenu( menuItems ) ]
        );
    }
}