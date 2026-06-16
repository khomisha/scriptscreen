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
void export2pdf( String preamble, List< String > headers,  List< String > htmlFiles, String pdfPath ) async {
    try {
        logger.info( "Export to pdf started" );
        appElectronAPI.convert2PDF( headers.toJSArray( ), htmlFiles.toJSArray( ), pdfPath.toJS, preamble.toJS ).toDart;
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
