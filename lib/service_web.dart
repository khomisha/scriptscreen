import 'dart:js_interop';
import 'package:base/base.dart';
import 'app_electron_api.dart';

void export2pdf( List< String > headers,  List< String > htmlFiles, String pdfPath ) async {
    try {
        appElectronAPI.convert2PDF( headers.toJSArray( ), htmlFiles.toJSArray( ), pdfPath.toJS ).toDart;
    }
    on JSError catch ( e ) {
        logger.severe( e.message );
    }
}
