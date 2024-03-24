
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

const double BORDER_CIRCULAR = 6;

class Style {    
    static final Style _instance = Style._( );
    late ThemeData theme;
    late BoxDecoration boxDecor;
    late InputDecoration inputDecor;
    late TextStyle listTileStyle;
    late BorderRadius borderRadius;
    late DividerPainter divPainter;
    late TextStyle formFieldStyle;
    late TextStyle fieldStyle;
    late TextStyle fieldLabelStyle;
    late ButtonStyle styleButton;

    Style._( ) {
        theme = ThemeData( colorScheme: ColorScheme.fromSeed( seedColor: Colors.blue ) );
        theme = ThemeData.localize(
            theme, 
            theme.typography.geometryThemeFor( ScriptCategory.englishLike ) 
        );
        borderRadius = BorderRadius.circular( BORDER_CIRCULAR );
        boxDecor = BoxDecoration( 
            border: Border.all( width: 1, color: theme.primaryColor ),
            borderRadius: borderRadius
        );
        inputDecor = InputDecoration(
            border: const OutlineInputBorder( ),
            contentPadding: const EdgeInsets.symmetric( vertical: 20, horizontal: 12 ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide( color: theme.primaryColor, width: 1.25 ),
                borderRadius: borderRadius
            ),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide( color: theme.primaryColor.withOpacity( 0.45 ) ),
                borderRadius: borderRadius
            ),
            labelStyle: theme.textTheme.headlineSmall,
            errorBorder: OutlineInputBorder(
                borderSide: const BorderSide( color: Colors.pink ),
                borderRadius: borderRadius
            )
        );
        listTileStyle = theme.textTheme.titleMedium!;
        formFieldStyle = theme.textTheme.bodyLarge!;
        fieldStyle = theme.textTheme.bodyLarge!;
        fieldLabelStyle = theme.textTheme.titleLarge!;
        divPainter = DividerPainters.grooved1( backgroundColor: theme.primaryColor );
        styleButton = ElevatedButton.styleFrom( 
            minimumSize: const Size( 89.0, 50.0 ), 
            textStyle: listTileStyle 
        );
    }

    factory Style( ) {
        return _instance;
    }    
}
