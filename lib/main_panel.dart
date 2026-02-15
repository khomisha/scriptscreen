// ignore_for_file: slash_for_doc_comments

import 'package:base/base.dart' as base;
import 'package:base/www.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_presenter.dart';
import 'detail_panel.dart';
import 'location_panel.dart';
import 'model.dart';
import 'project_panel.dart';
import 'role_panel.dart';
import 'script_panel.dart';
import 'action_time_panel.dart';
import 'app_const.dart';
import 'app_components.dart';
//import 'form_presenter.dart';
//import 'list_presenter.dart';
import 'note_editor.dart';
import 'note_panel.dart';
//import 'note_presenter.dart';

class MainPanel extends StatefulWidget implements base.Subscriber {
    late final Function( base.Event ) _onEvent;
    late final base.Supervisor sv;

    MainPanel( { super.key } ) {
        base.Functions.put( "process", process );
        base.eventBroker
            ..subscribe( this, EXIT )
            ..subscribe( this, SEND )
            ..subscribe( this, END_UPDATE );
    }

    @override
    State< MainPanel > createState( ) => _MainPanelState( );

    @override
    void onEvent( base.Event event ) {
        logger.info( 'MainPanel: onEvent: ${event.type}' );
        _onEvent( event );
    }
}

class _MainPanelState extends State< MainPanel > implements base.Pane {
    List< base.Panel > _panels = [];
	var _currentPanelIndex = 0;
    var _loading = true;
    bool makeItOnce = true;
    var nb = const NotificationButton( );

    void _onEvent( base.Event event ) {
        switch( event.type ) {
            case EXIT:
                base.eventBroker.dispose( );
                widget.sv.destroy( );
                break;
            case SEND:
                setState( ( ) => _loading = true );
                break;
            case END_UPDATE:
                setState( 
                    ( ) {
                        if( makeItOnce ) {
                            makeItOnce = false;
                            _panels = [
                                ProjectPanel( ProjectForm( ) ).panel,
                                ScriptPanel( ScriptForm( ) ).panel,
                                NotePanel( const NoteDiagramEditor( ) ).panel,
                                RolePanel( DataList( ) ).panel,
                                LocationPanel( DataList( ) ).panel,
                                DetailPanel( DataList( ) ).panel,
                                ActionTimePanel( DataList( ) ).panel,
                            ];        
                        }
                        _loading = false;    
                    }
                );
                break;
            default:
                throw UnsupportedError( "No such event $event" );
        }
    }

	@override
	Widget build( BuildContext context ) {
        if( _loading ) {
            return const Center( child: CircularProgressIndicator( ) );
        }
        var navBar = BottomNavigationBar( 
            items: _createNavBarItems( ), 
            currentIndex: _currentPanelIndex, 
            unselectedIconTheme: IconThemeData( color: Style.theme.colorScheme.primary ),
            selectedIconTheme: IconThemeData( color: Style.theme.colorScheme.inversePrimary ), 
            onTap: _replacePanel,
            showUnselectedLabels: true,
            selectedItemColor: Style.theme.colorScheme.inversePrimary,
            unselectedItemColor: Style.theme.colorScheme.primary,
            selectedLabelStyle: TextStyle( color: Style.theme.colorScheme.inversePrimary ),
            unselectedLabelStyle: TextStyle( color: Style.theme.colorScheme.primary )
        );
        var stack = IndexedStack(
            index: _currentPanelIndex,
            children: _panels,
        );
        var panel = _panels[ _currentPanelIndex ];
        var appBar = AppBar( title: Text( panel.title ), actions: < Widget >[ nb ] + ( panel.actions?? [] ) );
        return Scaffold( appBar: appBar, body: stack, bottomNavigationBar: navBar );
	}
    
    @override
    void initState( ) {
        super.initState( );
        notification.stream.listen( 
            ( record ) { 
                WidgetsBinding.instance.addPostFrameCallback(
                    ( _ ) {
                        showToast( context, record );
                    }
                );
            }
        );
        logger.info( "*** application start ***" );
        widget.sv = base.Supervisor( this );
        widget._onEvent = _onEvent;
        AppPresenter( ).loadData( );
    }

    @override
    void dispose( ) {
        eventBroker.dispose( );
        notification.dispose( );
        AppPresenter( ).dispose( );
        PresenterRegistry( ).disposeAll( );
        super.dispose( );
    }

    @override
    void onClose( ) {
        logger.info( "=== application close ===" );
        dispose( );
    }

    /**
     * Changes current panel index
     */
    void _replacePanel( int panelIndex ) {
        setState( ( ) { _currentPanelIndex = panelIndex; } );
    }

    /**
     * Creates navigation bar items using panel icon and title
     */
    List< BottomNavigationBarItem > _createNavBarItems( ) {
        var items = < BottomNavigationBarItem > [];
        for( var panel in _panels ) {
            items.add( BottomNavigationBarItem( icon: panel.icon!, label: panel.title ) );
        }
        return items;
    }
}

/**
 * Creates change notifier provider for specified widget
 * type the widget presenter type
 * widget the widget to create provider
 */
Widget createProvider< T extends WidgetPresenter >( T presenter, Widget child ) {
    return ChangeNotifierProvider< T >.value( value: presenter, child: child );
}

