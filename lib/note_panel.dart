
import 'package:flutter/material.dart';
import 'app_const.dart';
import 'app_menu.dart';
import 'package:base/base.dart';
import 'main_panel.dart';
import 'note_presenter.dart';

class NotePanel {
    late Panel panel;

    NotePanel( Widget widget ) {
        panel = Panel( 
            title: "Notes", 
            childWidget: createProvider< NotePresenter >(
                PresenterRegistry( ).getPresenter( NOTE, ( ) => NotePresenter( ) ),
                widget
            ), 
            icon: const Icon( Icons.dashboard ),
            actions: [ _createMenu( ) ]
        );
    }

    Widget _createMenu( ) {
        var pmb = PopupMenuButton( 
            icon: const Icon( Icons.menu ), 
            itemBuilder: ( context ) {
                final presenter = PresenterRegistry( ).getPresenter( NOTE, ( ) => NotePresenter( ) );
                final bool selected = presenter.selectedIndex != -1;
                return[ 
                    PopupMenuItem(
                        enabled: selected,
                        onTap: transcript,
                        child: const Text( 'Transcript Audio File...' )
                    ),
                    showEditor,
                    const PopupMenuDivider( ),
                    exitApp
                ];
            } 
        );
        return pmb;
    }
}
