
// Tests of the marked up text parser, see lib/import.dart. The parser is pure,
// it neither reads the project nor touches the file system, so it runs without
// the application being started.

import 'package:flutter_test/flutter_test.dart';
import 'package:scriptscreen/app_const.dart';
import 'package:scriptscreen/import.dart';

void main( ) {
    group( 'parse', ( ) {
        test( 'ignores the text outside the fragments', ( ) {
            final fragments = parse(
                'a preamble with a stray <title>heading</title>\n'
                '<text><title>Scene 1</title>the body</text>\n'
                'a trailing note\n'
            );
            expect( fragments.length, 1 );
            expect( fragments[ 0 ].title, 'Scene 1' );
            expect( bodyText( fragments[ 0 ].body.toString( ) ), 'the body' );
        } );

        test( 'reads the title, the description and the names', ( ) {
            final fragments = parse(
                '<text>\n'
                '<title>  Scene 1  </title>\n'
                '<desc>Anna finds the letter</desc>\n'
                '<role>ANNA</role> enters the <loc>KITCHEN</loc> at <time>DAY</time>\n'
                'and finds a <det>letter</det> on the table.\n'
                '</text>\n'
            );
            expect( fragments.length, 1 );
            final fragment = fragments[ 0 ];
            expect( fragment.title, 'Scene 1' );
            expect( fragment.description, 'Anna finds the letter' );
            expect( fragment.names[ ROLE ], [ 'ANNA' ] );
            expect( fragment.names[ LOCATION ], [ 'KITCHEN' ] );
            expect( fragment.names[ ACTION_TIME ], [ 'DAY' ] );
            expect( fragment.names[ DETAIL ], [ 'letter' ] );
            // the title and the description are taken out, the names stay in place
            expect(
                bodyText( fragment.body.toString( ) ),
                'ANNA enters the KITCHEN at DAY\nand finds a letter on the table.'
            );
        } );

        test( 'keeps the first title and description only', ( ) {
            final fragments = parse(
                '<text><title>first</title><title>second</title>'
                '<desc>one</desc><desc>two</desc>body</text>'
            );
            expect( fragments[ 0 ].title, 'first' );
            expect( fragments[ 0 ].description, 'one' );
            expect( bodyText( fragments[ 0 ].body.toString( ) ), 'body' );
        } );

        test( 'keeps a repeated name once', ( ) {
            final fragments = parse(
                '<text><title>t</title><role>ANNA</role> and <role>ANNA</role> again</text>'
            );
            expect( fragments[ 0 ].names[ ROLE ], [ 'ANNA' ] );
            expect( bodyText( fragments[ 0 ].body.toString( ) ), 'ANNA and ANNA again' );
        } );

        test( 'reads several fragments', ( ) {
            final fragments = parse(
                '<text><title>one</title>first</text>\n'
                '<text><title>two</title>second</text>\n'
            );
            expect( fragments.length, 2 );
            expect( fragments[ 1 ].title, 'two' );
        } );

        test( 'reports an unclosed text tag', ( ) {
            expect(
                ( ) => parse( '<text><title>t</title>body' ),
                throwsA( isA< ImportException >( ) )
            );
        } );

        test( 'reports a nested text tag', ( ) {
            expect(
                ( ) => parse( '<text><title>t</title><text>' ),
                throwsA( isA< ImportException >( ) )
            );
        } );

        test( 'reports a closing tag without an opening one', ( ) {
            expect( ( ) => parse( '</text>' ), throwsA( isA< ImportException >( ) ) );
            expect(
                ( ) => parse( '<text><title>t</title>body</role></text>' ),
                throwsA( isA< ImportException >( ) )
            );
        } );

        test( 'reports an unclosed inner tag', ( ) {
            expect(
                ( ) => parse( '<text><title>t</title><role>ANNA</text>' ),
                throwsA( isA< ImportException >( ) )
            );
        } );

        test( 'reports a fragment without a title', ( ) {
            expect( ( ) => parse( '<text>body</text>' ), throwsA( isA< ImportException >( ) ) );
        } );

        test( 'reports an empty name', ( ) {
            expect(
                ( ) => parse( '<text><title>t</title><role> </role></text>' ),
                throwsA( isA< ImportException >( ) )
            );
        } );

        test( 'reports the line the error is found at', ( ) {
            try {
                parse( 'line one\nline two\n<text>\n<title>t</title>\n<role>A\n</text>\n' );
                fail( 'the unclosed role tag is not reported' );
            }
            on ImportException catch( e ) {
                expect( e.message, contains( '5' ) );
            }
        } );
    } );

    group( 'bodyText', ( ) {
        test( 'trims the lines and collapses the empty ones', ( ) {
            expect( bodyText( '\n\n  first  \n\n\n  second \n \n\n' ), 'first\n\nsecond' );
        } );

        test( 'returns an empty string for a blank body', ( ) {
            expect( bodyText( '  \n \n' ), '' );
        } );
    } );

    group( 'toHtml', ( ) {
        test( 'wraps every line and escapes the markup characters', ( ) {
            expect(
                toHtml( 'a < b & c' ),
                '<div><span style="font-size: 12pt;">a &lt; b &amp; c</span></div>'
            );
        } );

        test( 'keeps the empty lines as empty paragraphs', ( ) {
            expect(
                toHtml( 'one\n\ntwo' ),
                '<div><span style="font-size: 12pt;">one</span></div>'
                '<div><span style="font-size: 12pt;">&nbsp;</span></div>'
                '<div><span style="font-size: 12pt;">two</span></div>'
            );
        } );

        test( 'returns the empty editor content for an empty body', ( ) {
            expect( toHtml( '' ), EMPTY_CONTENT );
        } );
    } );
}
