
import 'package:flutter/material.dart';
import 'app_const.dart';
import 'app_menu.dart';
import 'package:base/base.dart';
import 'main_panel.dart';
import 'note_presenter.dart';

class NotePanel {
    late Panel panel;

    NotePanel( Widget widget ) {
        List< PopupMenuEntry > menuItems = [
            transcriptAudio,
            showEditor,
            const PopupMenuDivider( ),
            exitApp
        ];
        panel = Panel( 
            title: "Notes", 
            childWidget: createProvider< NotePresenter >(
                PresenterRegistry( ).getPresenter( NOTE, ( ) => NotePresenter( ) ),
                widget
            ), 
            icon: const Icon( Icons.dashboard ),
            actions: [ createMenu( menuItems ) ]
        );
    }
}