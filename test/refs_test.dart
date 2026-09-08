// Tests of the object references of the card text, see lib/refs.dart. The
// functions under test are pure, they neither read the project nor touch the
// file system, so they run without the application being started.

import 'package:flutter_test/flutter_test.dart';
import 'package:scriptscreen/app_const.dart';
import 'package:scriptscreen/import.dart';
import 'package:scriptscreen/refs.dart';

// the descriptions of the project objects, see projectDescriptions
const Map< String, Map< String, String > > _DESCRIPTIONS = < String, Map< String, String > > {
    ROLE: < String, String > { 'Кирилл': '33 года, предприниматель-неудачник' },
    LOCATION: < String, String > { 'КУХНЯ': '' },
    DETAIL: < String, String > { 'письмо': 'мятый конверт' },
    ACTION_TIME: < String, String > {}
};

String _body( String content ) {
    return '<div><span style="font-size: 12pt;">$content</span></div>';
}

void main( ) {
    group( 'resolveRefs', ( ) {
        test( 'writes the description at the first appearance only', ( ) {
            final described = < String > {};
            final first = resolveRefs(
                _body( 'Входит ${ refSpan( ROLE, 'Кирилл', 'Кирилл' ) }.' ),
                _DESCRIPTIONS,
                described
            );
            expect( first, _body( 'Входит Кирилл (33 года, предприниматель-неудачник).' ) );
            // the next card of the same export
            final second = resolveRefs(
                _body( 'Уходит ${ refSpan( ROLE, 'Кирилл', 'Кириллом' ) }.' ),
                _DESCRIPTIONS,
                described
            );
            expect( second, _body( 'Уходит Кириллом.' ) );
        } );

        test( 'keeps the text the author wrote', ( ) {
            expect(
                resolveRefs(
                    _body( 'о ${ refSpan( DETAIL, 'письмо', 'письме' ) }' ),
                    _DESCRIPTIONS,
                    < String > {}
                ),
                _body( 'о письме (мятый конверт)' )
            );
        } );

        test( 'unwraps a reference without a description', ( ) {
            expect(
                resolveRefs(
                    _body( 'на ${ refSpan( LOCATION, 'КУХНЯ', 'КУХНЕ' ) }' ),
                    _DESCRIPTIONS,
                    < String > {}
                ),
                _body( 'на КУХНЕ' )
            );
        } );

        test( 'unwraps a reference to an object gone from the project', ( ) {
            expect(
                resolveRefs(
                    _body( refSpan( ROLE, 'АННА', 'АННА' ) ),
                    _DESCRIPTIONS,
                    < String > {}
                ),
                _body( 'АННА' )
            );
        } );

        test( 'leaves the text without references as it is', ( ) {
            final html = _body( 'Кирилл входит' );
            expect( resolveRefs( html, _DESCRIPTIONS, < String > {} ), html );
        } );
    } );

    group( 'syncRefs', ( ) {
        final names = < String, List< String > > {
            ROLE: < String > [ 'Кирилл', 'Анна Мария' ],
            LOCATION: < String > [ 'КУХНЯ' ],
            DETAIL: < String > [],
            ACTION_TIME: < String > []
        };

        test( 'marks the names of the attached objects', ( ) {
            expect(
                syncRefs( _body( 'Кирилл входит на КУХНЯ' ), names ),
                _body(
                    '${ refSpan( ROLE, 'Кирилл', 'Кирилл' ) } входит на '
                    '${ refSpan( LOCATION, 'КУХНЯ', 'КУХНЯ' ) }'
                )
            );
        } );

        test( 'ignores the case and takes the longest name', ( ) {
            expect(
                syncRefs( _body( 'анна мария и Кирилл' ), names ),
                _body(
                    '${ refSpan( ROLE, 'Анна Мария', 'анна мария' ) } и '
                    '${ refSpan( ROLE, 'Кирилл', 'Кирилл' ) }'
                )
            );
        } );

        test( 'marks the whole words only', ( ) {
            expect( syncRefs( _body( 'Кириллица и Кирилла' ), names ), null );
        } );

        test( 'leaves the text already synced as it is', ( ) {
            expect(
                syncRefs( _body( '${ refSpan( ROLE, 'Кирилл', 'Кирилл' ) } входит' ), names ),
                null
            );
        } );

        test( 'keeps the reference written by the import', ( ) {
            // the text is written in another form, the import marked it
            expect(
                syncRefs( _body( 'вслед за ${ refSpan( ROLE, 'Кирилл', 'Кириллом' ) }' ), names ),
                null
            );
        } );

        test( 'unwraps the reference to a detached object', ( ) {
            expect(
                syncRefs( _body( 'уходит ${ refSpan( ROLE, 'АННА', 'АННА' ) }' ), names ),
                _body( 'уходит АННА' )
            );
        } );

        test( 'unwraps everything when the card refers to nothing', ( ) {
            expect(
                syncRefs(
                    _body( '${ refSpan( ROLE, 'Кирилл', 'Кирилл' ) } входит' ),
                    < String, List< String > > {}
                ),
                _body( 'Кирилл входит' )
            );
        } );

        test( 'leaves the text mentioning nothing alone', ( ) {
            expect( syncRefs( _body( 'Дверь скрипнула' ), names ), null );
        } );
    } );

    group( 'the marked up text', ( ) {
        test( 'the description written in it comes back at the export', ( ) {
            final fragment = parse(
                '<text><title>t</title>'
                'В комнату входит <role>Кирилл'
                '<role_desc>33 года, предприниматель-неудачник</role_desc></role>, '
                'садится за стол.'
                '</text>'
            )[ 0 ];
            final html = toHtml( bodyText( fragment.body.toString( ) ) );
            // the description belongs to the object, the card text is without it
            expect( html.contains( 'предприниматель' ), false );
            expect(
                html,
                _body(
                    'В комнату входит ${ refSpan( ROLE, 'Кирилл', 'Кирилл' ) }, садится за стол.'
                )
            );
            // the import puts it to the object, the export writes it back
            expect(
                resolveRefs(
                    html,
                    < String, Map< String, String > > { ROLE: fragment.descriptions[ ROLE ]! },
                    < String > {}
                ),
                _body(
                    'В комнату входит Кирилл (33 года, предприниматель-неудачник), '
                    'садится за стол.'
                )
            );
        } );
    } );

    group( 'renameRefs', ( ) {
        test( 'points the references at the new name, keeping the text', ( ) {
            expect(
                renameRefs(
                    _body( 'вслед за ${ refSpan( ROLE, 'Кирилл', 'Кириллом' ) }' ),
                    ROLE, 'Кирилл', 'Кирилл Петров'
                ),
                _body( 'вслед за ${ refSpan( ROLE, 'Кирилл Петров', 'Кириллом' ) }' )
            );
        } );

        test( 'leaves the references to the other objects alone', ( ) {
            expect(
                renameRefs(
                    _body( refSpan( LOCATION, 'Кирилл', 'Кирилл' ) ),
                    ROLE, 'Кирилл', 'Кирилл Петров'
                ),
                null
            );
        } );

        test( 'returns null when the text refers to the object no more', ( ) {
            expect(
                renameRefs( _body( 'Кирилл входит' ), ROLE, 'Кирилл', 'Кирилл Петров' ),
                null
            );
        } );

        test( 'the renamed reference survives the sync', ( ) {
            final renamed = renameRefs(
                _body( 'вслед за ${ refSpan( ROLE, 'Кирилл', 'Кириллом' ) }' ),
                ROLE, 'Кирилл', 'Кирилл Петров'
            )!;
            // the card chip carries the new name as well, see ListPresenter.rename
            expect(
                syncRefs( renamed, < String, List< String > > { ROLE: < String > [ 'Кирилл Петров' ] } ),
                null
            );
        } );
    } );
}
