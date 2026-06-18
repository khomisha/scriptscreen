
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
            title: tr( 'panel_notes' ),
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
                        child: Text( tr( 'menu_transcript_audio' ) )
                    ),
                    transcriptLiveItem( ),
                    showEditor,
                    const PopupMenuDivider( ),
                    aboutApp,
                    exitApp
                ];
            } 
        );
        return pmb;
    }
}
