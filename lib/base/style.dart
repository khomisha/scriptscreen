
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'config.dart';
import 'util.dart';

const double BORDER_CIRCULAR = 7;

class Style {   
    static final color = colors[ Config.config[ 'gui_primary_color' ] ] ?? Colors.blue; 
    static final ColorScheme _cs = ColorScheme.fromSeed( seedColor: color );
    static final ThemeData _theme = ThemeData( 
        colorScheme: _cs,
        appBarTheme: AppBarTheme( backgroundColor: _cs.onInverseSurface )
    );
    static final ThemeData theme = ThemeData.localize(
        _theme, 
        _theme.typography.geometryThemeFor( ScriptCategory.englishLike ) 
    );
    static final BorderRadius borderRadius = BorderRadius.circular( BORDER_CIRCULAR );
    static final BoxDecoration boxDecor = BoxDecoration( 
        border: Border.all( width: 1, color: theme.primaryColor ),
        borderRadius: borderRadius
    );
    static final InputDecoration inputDecor = InputDecoration(
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
    static final TextStyle listTileStyle = theme.textTheme.titleMedium!;
    static final DividerPainter divPainter = DividerPainters.grooved1( backgroundColor: theme.primaryColor );
    static final TextStyle formFieldStyle = theme.textTheme.bodyLarge!;
    static final TextStyle fieldStyle = theme.textTheme.bodyLarge!;
    static final TextStyle fieldLabelStyle = theme.textTheme.titleLarge!;
    static final ButtonStyle styleButton = ElevatedButton.styleFrom( 
        minimumSize: const Size( 89.0, 50.0 ), 
        textStyle: listTileStyle 
    );
}
