
import 'dart:js_interop';
import 'package:base/base.dart';
import 'app_electron_api.dart';
import 'editor.dart';

class EditorImpl implements Editor {

    @override
    Future< void > save( String fileName ) async {
        try {
            await appElectronAPI.save( fileName.toJS ).toDart;
        }
        on JSError catch ( e ) {
            logger.severe( '$fileName ${e.message}' );
        }
        // the editor window may fail to answer, see SAVE_TIMEOUT in main.js,
        // the caller goes on with the content the file holds
        catch( e, stack ) {
            logger.severe( '$fileName $e', e, stack );
        }
    }

    @override
    Future< void > load( String fileName ) async {
        try {
            await appElectronAPI.load( fileName.toJS ).toDart;
            logger.fine( 'loading $fileName is finished' );
        }
        on JSError catch ( e ) {
            logger.severe( '$fileName ${e.message}' );
        }
    }

    @override
    Future< void > setRefs( String json ) async {
        try {
            await appElectronAPI.setRefs( json.toJS ).toDart;
        }
        on JSError catch ( e ) {
            logger.severe( e.message );
        }
        catch( e, stack ) {
            logger.severe( '$e', e, stack );
        }
    }

    @override
    Future< bool > setVisible( bool visible ) async {
        final bool isVisible = await changeVisibility( );
        return isVisible;
    }

    @override
    void onVisibilityChanged( void Function( bool visible ) callback ) {
        appElectronAPI.onEditorVisibility(
            ( ( JSBoolean visible ) { callback( visible.toDart ); } ).toJS
        );
    }
    
    @override
    Future< void > clear( ) async {
        await appElectronAPI.clear( ).toDart;
        logger.fine( "clearing is finished" );
    }
}