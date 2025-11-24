
// ignore_for_file: slash_for_doc_comments

import 'package:base/base.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:path/path.dart';

/**
 * Exports project content to the pdf file
 * headers the chapter headers
 * htmlFiles the content
 * pdfPath the pdf file path
 */
void export2pdf( List< String > headers,  List< String > htmlFiles, String pdfPath ) async {
    final buffer = StringBuffer( );

    var index = 0;
    for( var fileName in htmlFiles ) {
        var file = GenericFile( fileName );
        buffer.writeln( headers[ index ] );
        buffer.writeln( file.readString( ) );
        buffer.writeln( '<hr>' );
        index++;
    }
    FlutterHtmlToPdf.convertFromHtmlContent( buffer.toString( ), dirname( pdfPath ), basename( pdfPath ) );
}

/**
 * Transcripts mp3 audio file to text
 * path the audio file path
 * model the whisper model name
 * lang the language symbol 
 */
void transcribe( String path, String model, String lang ) {
    logger.warning( "Not yet implemented" );
}
