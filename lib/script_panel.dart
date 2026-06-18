
import 'package:flutter/material.dart';
import 'app_components.dart';
import 'app_const.dart';
import 'app_menu.dart';
import 'package:base/base.dart';
import 'form_presenter.dart';
import 'main_panel.dart';

class ScriptPanel {
    late Panel panel;

    ScriptPanel( Widget widget ) {
        var form = widget as ScriptForm;
        List< PopupMenuEntry > menuItems = [
            PopupMenuItem( onTap: form.edit, child: Text( tr( 'menu_edit_script' ) ) ),
            const PopupMenuDivider( ),
            aboutApp,
            exitApp
        ];
        panel = Panel(
            title: tr( 'panel_script' ),
            childWidget: createProvider< FormPresenter >(
                PresenterRegistry( ).getPresenter( SCRIPT, ( ) => FormPresenter( SCRIPT ) ),
                form
            ), 
            icon: const Icon( Icons.summarize ),
            actions: [ createMenu( menuItems ) ]
        );
    }
}