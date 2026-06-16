import 'dart:js_interop';

/**
 * see [flutter2electron_bridge.md]
 */
extension type AppElectronAPI._( JSObject _ ) implements JSObject {
    external JSPromise< JSAny > load( JSString fileName );
    external JSPromise< JSAny > save( JSString fileName );
    external JSPromise< JSAny > clear( );
    external JSPromise< JSAny > convert2PDF( JSArray< JSString > headers, JSArray< JSString > htmlFiles, JSString pdfPath, JSString preamble );
    external JSPromise< JSAny > transcribe( JSString path, JSString model, JSString lang, JSString format );
    external JSPromise< JSAny > startLiveTranscribe( JSString model, JSString lang );
    external JSPromise< JSAny > stopLiveTranscribe( );
}

@JS( )
external AppElectronAPI get appElectronAPI;
