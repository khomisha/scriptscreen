
abstract class AttributeMap< K, V >  implements Comparable {
    late Map< K, V > _attributes;
    
    AttributeMap( ) {
       _attributes = < K, V > { }; 
    }

    V? operator []( K key ) {
        if( _attributes.containsKey( key ) ) {
            return _attributes[ key ];
        } else {
            throw UnsupportedError( "No attribute named $key" );
        }
    }
    operator []=( K key, V value ) {
        if( _attributes.containsKey( key ) ) {
            _attributes[ key ] = value; 
        } else {
            throw UnsupportedError( "No attribute named $key" );
        }
    }

    Map< K, V > get attributes => _attributes;

    copy( );
}

