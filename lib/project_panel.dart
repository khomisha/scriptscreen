
import 'package:flutter/material.dart';
import 'app_components.dart';
import 'app_const.dart';
import 'app_menu.dart';
import 'package:base/base.dart';
import 'form_presenter.dart';
import 'main_panel.dart';

class ProjectPanel {
    late Panel panel;

    ProjectPanel( Widget widget ) {
        var form = widget as ProjectForm;
        List< PopupMenuEntry > menuItems = [
            createProject,
            openProject,
            PopupMenuItem( onTap: form.edit, child: const Text( "Edit Project" ) ),
            exportProject,
            exitApp
        ];
        panel = Panel( 
            title: "Project", 
            childWidget: createProvider< FormPresenter >(
                PresenterRegistry( ).getPresenter( PROJECT, ( ) => FormPresenter( PROJECT ) ),
                form
            ), 
            icon: const Icon( Icons.work_outline ),
            actions: [ createMenu( menuItems ) ]
        );
    }
}
