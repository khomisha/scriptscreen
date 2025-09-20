import 'dart:js_interop';

/**
 * see [flutter2electron_bridge.md]
 */
extension type AppElectronAPI._( JSObject _ ) implements JSObject {
    external JSPromise< JSAny > changeVisibility( );
    external JSPromise< JSAny > load( JSString fileName );
    external JSPromise< JSAny > save( JSString fileName );
    external JSPromise< JSAny > clear( );
    external JSPromise< JSAny > convert2PDF( JSArray< JSString > headers, JSArray< JSString > htmlFiles, JSString pdfPath );
}

@JS( )
external AppElectronAPI get appElectronAPI;
