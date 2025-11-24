// ignore_for_file: slash_for_doc_comments

import 'dart:js_interop';
import 'package:base/base.dart';
import 'app_electron_api.dart';

/**
 * Exports project content to the pdf file
 * headers the chapter headers
 * htmlFiles the content
 * pdfPath the pdf file path
 */
void export2pdf( List< String > headers,  List< String > htmlFiles, String pdfPath ) async {
    try {
        logger.info( "Export to pdf started" );
        appElectronAPI.convert2PDF( headers.toJSArray( ), htmlFiles.toJSArray( ), pdfPath.toJS ).toDart;
        logger.info( "Export to pdf completed" );
    }
    on JSError catch ( e ) {
        logger.severe( e.message );
    }
}

/**
 * Transcripts mp3 audio file to text
 * path the audio file path
 * model the whisper model name
 * lang the language symbol 
 */
void transcribe( String path, String model, String lang ) async {
    try {
        logger.info( "Transciption started" );
        await appElectronAPI.transcribe( path.toJS, model.toJS, lang.toJS ).toDart;
        logger.info( "Transciption completed" );
    }
    on JSError catch ( e ) {
        logger.severe( e.message );
    }
}
