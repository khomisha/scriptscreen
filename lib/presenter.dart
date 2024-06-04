
// ignore_for_file: slash_for_doc_comments, constant_identifier_names

import 'dart:isolate';
import 'package:easy_isolate/easy_isolate.dart';
import 'package:base/base.dart';
import 'model.dart';

abstract class Presenter {
    // A worker is responsible for a new isolate (thread)
    late Worker _worker;
    final _subscribers = < String, WidgetPresenter > { };
    bool init = false;

    Presenter( ) {
        _worker = Worker( );
    }

    /**
     * Sends data to the model
     * 
     * arbitrary data object
     */
    void send( dynamic data ) async {
        if( !init ) {
            init = true;
            await _worker.init( _mainHandler, _isolateHandler, errorHandler: print, queueMode: true );
        }
        _worker.sendMessage( data );
    }

    /**
     * Closes presenter
     */
    void dispose( ) {
        _worker.dispose( );
        for( WidgetPresenter wp in _subscribers.values ) {
            wp.dispose( );
        }
    }

    /**
     * After proccessed data in model, receives result and update (if any) widgets data
     * 
     * data returned from model
     * isolateSendPort the worker (isolate) send port
     */
    void _mainHandler( dynamic data, SendPort isolateSendPort ) {
        update( data );
    }

    /**
     * Process data in model
     * data the data to process in model and returns to the presenter
     * mainSendPort the presenter port to get data from model
     * onSendError the function to handle send error
     */
    static _isolateHandler( dynamic data, SendPort mainSendPort, SendErrorFunction onSendError ) async {
        process( data );
        mainSendPort.send( data );
    }

    /**
     * Updates widgets data
     */
    void update( dynamic data );

    /**
     * Subscribes specified presenter
     * widgetPresenter the presenter to subscribe
     */
    void subscribe( WidgetPresenter widgetPresenter ) {
        _subscribers[ widgetPresenter.dataType ] = widgetPresenter;
        widgetPresenter.list = getData( widgetPresenter.dataType );
    }

    /**
     * Unsubscribes specified presenter
     * type the application data type
     */
    void unsubscribe( String type ) {
        _subscribers.remove( type );
    }

    /**
     * Usubscribes all subscribers
     */
    void unsubscribeAll( ) {
        for( String type in _subscribers.keys ) {
            _subscribers.remove( type );
        }
    }
    
    /**
     * Returns specified application data
     * type the application data type
     */
    List< ListItem > getData( String type );

    /**
     * Notifies subscribers that the application data is changed
     */
    void notify( ) {
        for( String type in _subscribers.keys ) {
            var wp = _subscribers[ type ] as WidgetPresenter;
            wp.list = getData( type );
        }
    }

    /**
     * Returns specified presenter
     * type the presenter type
     */
    WidgetPresenter getPresenter( String type ) {
        return _subscribers[ type ]!;
    }
}
