
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
    final Widget mainWidget;
    final Future< void > Function( ) processingData;
    
    const SplashScreen( { super.key, required this.mainWidget, required this.processingData } );

    @override
    Widget build( BuildContext context ) {

        return FutureBuilder(
            future: processingData( ),
            builder: ( BuildContext context, AsyncSnapshot snapshot ) {
                if( snapshot.connectionState == ConnectionState.waiting ) {
                    return const Center( child: CircularProgressIndicator( ) );
                } else {
                    return mainWidget;
                }   
            }
        );
    }
}
