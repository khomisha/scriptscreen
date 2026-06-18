
import 'app_const.dart';
import 'package:base/base.dart';

class AppFacing {

    static final _notePattern = < String, FieldPattern > {
        'index': FieldPattern(
            label: tr( 'index' ),
            validator: ( value ) {
                var i = int.tryParse( value! );
                if( i == null ) {
                    return '${tr( 'err_not_int' )}: $value';
                }
                if( i < 1 ) {
                    return tr( 'err_less_than_1' );
                }
                return null;
            },
            style: TEXT_FIELD
        ),
        'title': FieldPattern(
            label: tr( 'title' ),
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return tr( 'err_empty' );
                }
                return null;
            },
            style: TEXT_FIELD
        ),
        'description': FieldPattern( label: tr( 'description' ), style: TEXT_FIELD ),
        ROLE: FieldPattern( label: tr( 'role' ), style: CHIP_LIST_FIELD, containerId: "wc" ),
        DETAIL: FieldPattern( label: tr( 'detail' ), style: CHIP_LIST_FIELD, containerId: "wc" ),
        LOCATION: FieldPattern( label: tr( 'location' ), style: CHIP_LIST_FIELD, containerId: "wc" ),
        ACTION_TIME: FieldPattern( label: tr( 'action_time' ), style: CHIP_LIST_FIELD, containerId: "wc" )
    };

    static final _rolePattern = < String, FieldPattern > {
        'name': FieldPattern(
            label: tr( 'name' ),
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return tr( 'err_empty' );
                }
                return null;
            },
            style: TEXT_FIELD
        ),
        'description': FieldPattern( label: tr( 'description' ), style: TEXT_FIELD )
    };

    static final _locationPattern = < String, FieldPattern > {
        'name': FieldPattern(
            label: tr( 'name' ),
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return tr( 'err_empty' );
                }
                return null;
            },
            style: TEXT_FIELD
        ),
        'description': FieldPattern( label: tr( 'description' ), style: TEXT_FIELD )
    };

    static final _detailPattern = < String, FieldPattern > {
        'name': FieldPattern(
            label: tr( 'name' ),
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return tr( 'err_empty' );
                }
                return null;
            },
            style: TEXT_FIELD
        ),
        'description': FieldPattern( label: tr( 'description' ), style: TEXT_FIELD )
    };

    static final _actionTimePattern = < String, FieldPattern > {
        'name': FieldPattern(
            label: tr( 'name' ),
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return tr( 'err_empty' );
                }
                return null;
            },
            style: TEXT_FIELD
        ),
        'description': FieldPattern( label: tr( 'description' ), style: TEXT_FIELD )
    };

    static final _scriptPattern = < String, FieldPattern > {
        'title': FieldPattern(
            label: tr( 'title' ),
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return tr( 'err_empty' );
                }
                return null;
            },
            style: TEXT_FIELD
        ),
        AUTHOR: FieldPattern( label: tr( 'author' ), style: TEXT_FIELD ),
        'date': FieldPattern(
            label: tr( 'date' ),
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return tr( 'err_empty' );
                }
                var validChars = RegExp( r'^[a-zA-Z0-9_\-=\.]+$' );
                if( !validChars.hasMatch( value ) ) {
                    return '${tr( 'err_invalid_name' )} $value';
                }
                return null;
            },
            style: TEXT_FIELD
        ),
        'place': FieldPattern( label: tr( 'place' ), style: TEXT_FIELD ),
        'logline': FieldPattern( label: tr( 'logline' ), style: TEXT_FIELD ),
        'synopsis': FieldPattern( label: tr( 'synopsis' ), style: TEXT_FIELD )
    };

    static final _projectPattern = < String, FieldPattern > {
        'name': FieldPattern(
            label: tr( 'name' ),
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return tr( 'err_empty' );
                }
                var validChars = RegExp( r'^[a-zA-Z0-9_\-=\.]+$' );
                if( !validChars.hasMatch( value ) ) {
                    return '${tr( 'err_invalid_name' )} $value';
                }
                return null;
            },
            style: TEXT_FIELD
        ),
        'version': FieldPattern(
            label: tr( 'version' ),
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return tr( 'err_empty' );
                }
                return null;
            },
            style: TEXT_FIELD
        )
    };

    AppFacing( ) {
        addPattern( NOTE, _notePattern );
        addPattern( ROLE, _rolePattern );
        addPattern( DETAIL, _detailPattern );
        addPattern( LOCATION, _locationPattern );
        addPattern( ACTION_TIME, _actionTimePattern );
        addPattern( SCRIPT, _scriptPattern );
        addPattern( PROJECT, _projectPattern );
    }
}