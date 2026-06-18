// ignore_for_file: slash_for_doc_comments

import 'dart:js_interop';
import 'package:base/base.dart';
import 'app_electron_api.dart';

/**
 * Exports project content to the pdf file
 * headers the chapter headers
 * htmlFiles the content
 * pdfPath the pdf file path
 * titles the chapter titles, in order
 * tocTitle the localized table of contents heading
 */
void export2pdf( String preamble, List< String > headers,  List< String > htmlFiles, String pdfPath, List< String > titles, String tocTitle ) async {
    try {
        logger.info( "Export to pdf started" );
        final toc = _buildTableOfContents( titles, tocTitle );
        appElectronAPI.convert2PDF( headers.toJSArray( ), htmlFiles.toJSArray( ), pdfPath.toJS, preamble.toJS, toc.toJS ).toDart;
        logger.info( "Export to pdf completed" );
    }
    on JSError catch ( e ) {
        logger.severe( e.message );
    }
}

/**
 * Builds the table of contents page as a standalone HTML document. The page
 * number cell of each row is left empty; the Electron renderer fills it once
 * the real per-section page counts are known. Returns an empty string when
 * there are no chapters.
 */
String _buildTableOfContents( List< String > titles, String tocTitle ) {
    if( titles.isEmpty ) {
        return '';
    }
    final rows = StringBuffer( );
    for( final title in titles ) {
        rows.writeln(
            '<div class="toc-row"><span class="toc-title">${_escape( title )}</span>'
            '<span class="toc-dots"></span><span class="toc-page"></span></div>'
        );
    }
    return '<!DOCTYPE html><html><head><meta charset="utf-8"><style>'
        'body { font-family: serif; padding: 40px; }'
        'h1 { text-align: center; font-size: 24pt; margin-bottom: 40px; }'
        '.toc-row { display: flex; align-items: baseline; font-size: 12pt; margin: 10px 0; }'
        '.toc-title { white-space: nowrap; }'
        '.toc-dots { flex: 1; border-bottom: 1px dotted #000; margin: 0 6px; transform: translateY( -3px ); }'
        '.toc-page { white-space: nowrap; }'
        '</style></head><body><h1>${_escape( tocTitle )}</h1>$rows</body></html>';
}

/**
 * Escapes the HTML special characters of a plain text value.
 */
String _escape( String text ) {
    return text
        .replaceAll( '&', '&amp;' )
        .replaceAll( '<', '&lt;' )
        .replaceAll( '>', '&gt;' );
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
        String fmt = config[ 'transcribe_fmt' ];
        await appElectronAPI.transcribe( path.toJS, model.toJS, lang.toJS, fmt.toJS ).toDart;
        logger.info( "Transciption completed" );
    }
    on JSError catch ( e ) {
        logger.severe( e.message );
    }
}

bool _liveTranscribing = false;

bool isLiveTranscribing( ) => _liveTranscribing;

void startLiveTranscription( String model, String lang ) async {
    try {
        logger.info( "Live transcription started" );
        _liveTranscribing = true;
        await appElectronAPI.startLiveTranscribe( model.toJS, lang.toJS ).toDart;
    }
    on JSError catch ( e ) {
        _liveTranscribing = false;
        logger.severe( e.message );
    }
}

void stopLiveTranscription( ) async {
    try {
        _liveTranscribing = false;
        await appElectronAPI.stopLiveTranscribe( ).toDart;
        logger.info( "Live transcription stopped" );
    }
    on JSError catch ( e ) {
        logger.severe( e.message );
    }
}
