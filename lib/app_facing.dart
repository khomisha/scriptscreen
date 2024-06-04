
import 'app_const.dart';
import 'package:base/base.dart';

class AppFacing {

    static final _notePattern = < String, FieldPattern > {
        'index': FieldPattern(
            label: "Index",
            validator: ( value ) {
                var i = int.tryParse( value! );
                if( i == null ) {
                    return 'Value cannot parse to int: $value';
                }
                if( i < 1 ) {
                    return 'Value less than 1';
                }
                return null;
            },
            style: TEXT_FIELD 
        ),
        'title': FieldPattern(
            label: "Title",
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return 'Value cannot be empty';
                }
                return null;
            },
            style: TEXT_FIELD 
        ),
        'description': FieldPattern( label: "Description", style: TEXT_FIELD ),
        ROLE: FieldPattern( label: "Role", style: CHIP_LIST_FIELD, containerId: "wc" ),
        DETAIL: FieldPattern( label: "Detail", style: CHIP_LIST_FIELD, containerId: "wc" ),
        LOCATION: FieldPattern( label: "Location", style: CHIP_LIST_FIELD, containerId: "wc" ),
        ACTION_TIME: FieldPattern( label: "Action Time", style: CHIP_LIST_FIELD, containerId: "wc" )
    };

    static final _rolePattern = < String, FieldPattern > {
        'name': FieldPattern(
            label: "Name",
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return 'Value cannot be empty';
                }
                return null;
            },
            style: TEXT_FIELD 
        ),
        'description': FieldPattern( label: "Description", style: TEXT_FIELD )
    };

    static final _locationPattern = < String, FieldPattern > {
        'name': FieldPattern(
            label: "Name",
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return 'Value cannot be empty';
                }
                return null;
            },
            style: TEXT_FIELD 
        ),
        'description': FieldPattern( label: "Description", style: TEXT_FIELD )
    };

    static final _detailPattern = < String, FieldPattern > {
        'name': FieldPattern(
            label: "Name",
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return 'Value cannot be empty';
                }
                return null;
            },
            style: TEXT_FIELD 
        ),
        'description': FieldPattern( label: "Description", style: TEXT_FIELD )
    };

    static final _actionTimePattern = < String, FieldPattern > {
        'name': FieldPattern(
            label: "Name",
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return 'Value cannot be empty';
                }
                return null;
            },
            style: TEXT_FIELD 
        ),
        'description': FieldPattern( label: "Description", style: TEXT_FIELD )
    };

    static final _scriptPattern = < String, FieldPattern > {
        'title': FieldPattern(
            label: "Title",
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return 'Value cannot be empty';
                }
                return null;
            },
            style: TEXT_FIELD 
        ),
        AUTHOR: FieldPattern( label: "Author", style: TEXT_FIELD ),
        'date': FieldPattern( 
            label: "Date",
            validator: ( value ) {
                var dt = parse2Datetime( "d.M.y", value! );
                if( dt == null ) {
                    return 'Value cannot parse to datetime: $value';
                }
                return null;
            },
            style: TEXT_FIELD
        ),
        'place': FieldPattern( label: "Place", style: TEXT_FIELD ),
        'logline': FieldPattern( label: "Logline", style: TEXT_FIELD ),
        'synopsis': FieldPattern( label: "Synopsis", style: TEXT_FIELD )
    };

    static final _projectPattern = < String, FieldPattern > {
        'name': FieldPattern(
            label: "Name",
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return 'Value cannot be empty';
                }
                var validChars = RegExp( r'^[a-zA-Z0-9_\-=\.]+$' );
                if( !validChars.hasMatch( value ) ) {
                    return 'Invalid name $value';
                }
                return null;
            },
            style: TEXT_FIELD 
        ),
        'version': FieldPattern(
            label: "Version",
            validator: ( value ) {
                if( value == null || value.isEmpty ) {
                    return 'Value cannot be empty';
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