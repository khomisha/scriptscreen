
import 'dart:js_interop';
import 'package:base/base.dart';
import 'app_electron_api.dart';
import 'editor.dart';

class EditorImpl implements Editor {

    @override
    void save( String fileName ) async {
        try {
            logger.info( fileName );
            await appElectronAPI.save( fileName.toJS ).toDart;
        }
        on JSError catch ( e ) {
            logger.severe( '$fileName ${e.message}' );
        }
    }

    @override
    void load( String fileName ) async {
        try {
            await appElectronAPI.load( fileName.toJS ).toDart;
        }
        on JSError catch ( e ) {
            logger.severe( '$fileName ${e.message}' );
        }
    }

    @override
    void setVisible( bool visible ) {
        appElectronAPI.changeVisibility( ).toDart;
    }
    
    @override
    void clear( ) {
        appElectronAPI.clear( ).toDart;
    }
}