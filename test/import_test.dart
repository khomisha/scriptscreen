
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
            // the title and the description are taken out, the names stay in
            // place with their markup, see toHtml
            expect(
                bodyText( fragment.body.toString( ) ),
                '<role>ANNA</role> enters the <loc>KITCHEN</loc> at <time>DAY</time>\n'
                'and finds a <det>letter</det> on the table.'
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
            expect(
                bodyText( fragments[ 0 ].body.toString( ) ),
                '<role>ANNA</role> and <role>ANNA</role> again'
            );
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

        test( 'reads the description of an object', ( ) {
            final fragments = parse(
                '<text><title>t</title>'
                'Входит <role>Кирилл<role_desc>  33 года, предприниматель  </role_desc></role>.'
                '</text>'
            );
            final fragment = fragments[ 0 ];
            expect( fragment.names[ ROLE ], [ 'Кирилл' ] );
            expect( fragment.descriptions[ ROLE ], { 'Кирилл': '33 года, предприниматель' } );
            // the description belongs to the object, the name stays in the text
            expect(
                bodyText( fragment.body.toString( ) ),
                'Входит <role>Кирилл</role>.'
            );
        } );

        test( 'reads the description of every kind of object', ( ) {
            final fragments = parse(
                '<text><title>t</title>'
                '<loc>Кухня<loc_desc>тесная</loc_desc></loc> '
                '<det>письмо<det_desc>мятый конверт</det_desc></det> '
                '<time>Утро<time_desc>раннее</time_desc></time>'
                '</text>'
            );
            final fragment = fragments[ 0 ];
            expect( fragment.descriptions[ LOCATION ], { 'Кухня': 'тесная' } );
            expect( fragment.descriptions[ DETAIL ], { 'письмо': 'мятый конверт' } );
            expect( fragment.descriptions[ ACTION_TIME ], { 'Утро': 'раннее' } );
        } );

        test( 'keeps the first description of an object', ( ) {
            final fragments = parse(
                '<text><title>t</title>'
                '<role>Кирилл<role_desc>первое</role_desc></role> и '
                '<role>Кирилл<role_desc>второе</role_desc></role>'
                '</text>'
            );
            expect( fragments[ 0 ].descriptions[ ROLE ], { 'Кирилл': 'первое' } );
        } );

        test( 'reads the name written around the description', ( ) {
            final fragments = parse(
                '<text><title>t</title>'
                '<role>Кирилл<role_desc>предприниматель</role_desc> Петров</role>'
                '</text>'
            );
            expect( fragments[ 0 ].names[ ROLE ], [ 'Кирилл Петров' ] );
            expect( fragments[ 0 ].descriptions[ ROLE ], { 'Кирилл Петров': 'предприниматель' } );
        } );

        test( 'ignores an empty description', ( ) {
            final fragments = parse(
                '<text><title>t</title><role>Кирилл<role_desc> </role_desc></role></text>'
            );
            expect( fragments[ 0 ].descriptions[ ROLE ], < String, String > {} );
        } );

        test( 'reports a description outside the tag of its object', ( ) {
            expect(
                ( ) => parse( '<text><title>t</title><role_desc>кто это</role_desc></text>' ),
                throwsA( isA< ImportException >( ) )
            );
            expect(
                ( ) => parse(
                    '<text><title>t</title><loc>Кухня<role_desc>кто это</role_desc></loc></text>'
                ),
                throwsA( isA< ImportException >( ) )
            );
        } );

        test( 'reports an unclosed description tag', ( ) {
            expect(
                ( ) => parse( '<text><title>t</title><role>Кирилл<role_desc>кто это</role></text>' ),
                throwsA( isA< ImportException >( ) )
            );
        } );

        test( 'reports every error of the file, not the first one only', ( ) {
            try {
                parse(
                    '<text><title>t</title><role> </role></text>\n'   // empty name
                    '</text>\n'                                       // close without an open
                    '<text><title>two</title><loc>Кухня</text>\n'     // unclosed loc
                );
                fail( 'the malformed markup is not reported' );
            }
            on ImportException catch( e ) {
                expect( e.errors.length, 3 );
                expect( e.errors[ 0 ], contains( 'err_import_empty_value' ) );
                expect( e.errors[ 1 ], contains( 'err_import_unexpected_close' ) );
                expect( e.errors[ 2 ], contains( 'err_import_unclosed_tag' ) );
                expect( e.message, e.errors.join( '\n' ) );
            }
        } );

        test( 'reads the fragments following the malformed one', ( ) {
            try {
                parse( '<text><title>one</title><role>ANNA<text><title>two</title></text>' );
                fail( 'the nested text tag is not reported' );
            }
            on ImportException catch( e ) {
                // the unclosed <role> and the <text> opened within the fragment
                expect( e.errors.length, 2 );
                expect( e.errors[ 0 ], contains( 'err_import_unclosed_tag' ) );
                expect( e.errors[ 1 ], contains( 'err_import_nested_text' ) );
            }
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

        test( 'turns the name markup into a reference', ( ) {
            expect(
                toHtml( '<role>ANNA</role> enters the <loc>KITCHEN</loc>' ),
                '<div><span style="font-size: 12pt;">'
                '<span class="ref" data-type="role" data-name="ANNA">ANNA</span>'
                ' enters the '
                '<span class="ref" data-type="location" data-name="KITCHEN">KITCHEN</span>'
                '</span></div>'
            );
        } );

        test( 'escapes the name and the text around it', ( ) {
            expect(
                toHtml( 'a < b <det>"key"</det>' ),
                '<div><span style="font-size: 12pt;">a &lt; b '
                '<span class="ref" data-type="detail" data-name="&quot;key&quot;">'
                '&quot;key&quot;</span></span></div>'
            );
        } );

        test( 'writes an unclosed markup as the text it is', ( ) {
            expect(
                toHtml( '<role>ANNA' ),
                '<div><span style="font-size: 12pt;">&lt;role&gt;ANNA</span></div>'
            );
        } );
    } );
}
