
// ignore_for_file: slash_for_doc_comments

import 'editor_web.dart' if( dart.library.io ) 'editor_io.dart';

abstract class Editor {

    factory Editor( ) {
        return EditorImpl( );
    }

    /**
     * Save content from editor running in separate browser window
     * fileName the text full file name to save
     */
    void save( String fileName );

    /**
     * Put content to the editor running in separate browser window
     * fileName the text full file name to load 
     */    
    void load( String fileName );

    /**
     * Clears the editor content
     */
    void clear( );

    /**
     * Set visible editor browser window 
     * visible the browser window show flag
     */
    void setVisible( bool visible );
}

final Editor editor = Editor( );