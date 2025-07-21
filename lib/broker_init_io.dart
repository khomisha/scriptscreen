// ignore_for_file: slash_for_doc_comments

import 'package:base/base.dart';
import 'dart:isolate';
import 'package:easy_isolate/easy_isolate.dart';
import 'model.dart';

mixin Initing on Broker {

    void init( ) {
        Functions.put( "isolateHandler", _isolateHandler );
    }
}

/**
 * Process data in isolate
 * data the data to process in isolate and returns to the main thread
 * mainSendPort the main thread port to get data from isolate
 * onSendError the function to handle send error
 */
void _isolateHandler( dynamic data, SendPort mainSendPort, SendErrorFunction onSendError ) async {
    process( data );
    mainSendPort.send( data );
}