
import 'package:base/base.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:path/path.dart';

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