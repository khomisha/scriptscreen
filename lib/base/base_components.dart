
// ignore_for_file: slash_for_doc_comments

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:provider/provider.dart';
import 'package:scriptscreen/base/injection_object.dart';
import 'package:scriptscreen/base/widget_presenter.dart';
import 'facing.dart';
import 'style.dart';
import 'util.dart';

/**
 * The base list with form to edit selected list item
 */
abstract class BaseList< V extends WidgetPresenter > extends StatelessWidget {
    final Agent agent = Agent( );
    final bool addBtnVisible;

    BaseList( { super.key, this.addBtnVisible = false } );

    @override
    Widget build( BuildContext context ) {
        var presenter = context.watch< V >( );
        agent.presenter = presenter;

        Widget buildList( BuildContext context, int index ) {
            var delete = SlidableAction(
                onPressed: ( _ ) { presenter.delete( index ); },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete'
            );
            var edit = SlidableAction(
                onPressed: ( _ ) { presenter.startEdit( index ); },
                backgroundColor: Style( ).theme.primaryColor,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit'
            );
            var decoration = BoxDecoration( 
                border: Border.all( 
                    width: 1, 
                    color: presenter.list[ index ].selected ? Colors.pink : Style( ).theme.primaryColor 
                ),
                borderRadius: Style( ).borderRadius
            );
            var key = presenter.list[ index ].customData.attributes.keys.toList( )[ 0 ];
            var tile = ListTile( 
                title: Text( 
                    presenter.list[ index ].customData.attributes[ key ], 
                    style: Style( ).listTileStyle 
                ),
                onTap: ( ) { presenter.select( index ); }
            );
            var item = Container(
                decoration: decoration,
                width: MediaQuery.of( context ).size.width,
                height: 50,
                child: Center( child: tile )
            );
            var slidable = Slidable( 
                enabled: presenter.list[ index ].selected,
                endActionPane: ActionPane( motion: const DrawerMotion( ), children: [ edit, delete ] ), 
                child: item
            );
            return Padding( padding: const EdgeInsets.all( 6.0 ), child: slidable );
        }
        var listWidget = presenter.list.isNotEmpty ? 
            ListView.builder( itemCount: presenter.list.length, itemBuilder: buildList ) : 
            getStub( "List is Empty" );
        var btnAdd = ElevatedButton(
            onPressed: add,
            style: Style( ).styleButton, 
            child: const Text( "Add" )
        );
        var row = Row( mainAxisAlignment: MainAxisAlignment.end, children: < Widget > [ btnAdd ] );
        var column = Column( 
            children: [ 
                Expanded( child: listWidget ), 
                Padding( 
                    padding: const EdgeInsets.all( 16.0 ), 
                    child: Visibility( visible: presenter.readOnly && addBtnVisible, child: row )
                ) 
            ] 
        );
        var msvc = MultiSplitViewController( areas: [ Area( minimalSize: 150 ), Area( minimalSize: 250 ) ] );
        var multiSplit = MultiSplitView( controller: msvc, children: [ column, getForm( ) ] );
        var msvt = MultiSplitViewTheme(
            data: MultiSplitViewThemeData( dividerPainter: Style( ).divPainter, dividerThickness: 5 ),
            child: multiSplit
        );
        return msvt;
    }

    /**
     * Returns form to edit specified list item
     * index the list item index
     */
    T getForm< T extends BaseForm >( );

    /**
     * Adds new list item
     */
    void add( ) {
        agent.presenter.add( );
    }
}

abstract class BaseForm< T extends WidgetPresenter > extends StatelessWidget {
    final _fields = < String, Field > { };
    final Agent agent = Agent( );

    BaseForm( { super.key } );

    @override
    Widget build( BuildContext context ) {  
        var presenter = context.watch< T >( );
        agent.presenter = presenter;
        var widgets = < Widget > [];
        if( presenter.selectedIndex < 0 ) {
            widgets.add( Container( ) );
        } else {
            var containers = < String, WidgetContainer > { };
            for( String attributeName in getPattern( presenter.dataType ).keys.toList( ) ) {
                var field = createField( attributeName, presenter.selectedIndex );
                _fields[ attributeName ] = field;
                var pattern = getPattern( presenter.dataType )[ attributeName ]!;
                if( pattern.containerId != "" ) {   
                    var container = containers.putIfAbsent( 
                        pattern.containerId, 
                        ( ) { 
                            var wc = WidgetContainer( axis: pattern.axis );
                            widgets.add( wc );
                            return wc; 
                        } 
                    );
                    container.add( field );
                } else {
                    widgets.add( field );
                }
            }
            var buttonBar = ButtonBar(
                buttonHeight: 50,
                children: < Widget > [ getButton( onOK, "OK" ), getButton( onCancel, "Cancel" ) ]
            );
            widgets.add( Visibility( visible: !presenter.readOnly, child: buttonBar ) );
            addExtra( widgets );
        }
        return ListView(
            padding: const EdgeInsets.symmetric( horizontal: 32, vertical: 6 ),
            children: widgets
        );
    }

    /**
     * Adds extra widgets
     * widgets the widget list
     */
    void addExtra( List< Widget > widgets ) {
    }

    /**
     * Creates form field for specified data attribute
     * attributeName the attribute name
     */
    Field createField( String attributeName, int index ) {
        late Field field;
        var pattern = getPattern( agent.presenter.dataType )[ attributeName ]!;
        var data = agent.presenter.get( index ).customData;

        switch( pattern.style ) {
            case TEXT_FIELD:
                field = Field.textField( 
                    value: data[ attributeName ], 
                    pattern: pattern
                );
               break;
            default:
                field = Field( followup: pattern.style ?? "" );
        }
        return field;
    }

    /**
     * Action on press form OK button
     */
    void onOK( ) {
		for( String attributeName in getPattern( agent.presenter.dataType ).keys.toList( ) ) {
            var field = _fields[ attributeName ];
            if( field!.nativeField is TextBox ) { 
                var value = field.accessObj.innerObj.controller!.text;
                if( value != null ) {
                    if( !field.nativeField.fieldKey.currentState!.validate( ) ) {
                        return;
                    }
                    agent.presenter.update(
                        attributeName, 
                        fromString( field.nativeField.value.runtimeType, value ), 
                        false
                    );
                }
            }
        }
        agent.presenter.endEdit( true );
    }

    /**
     * Action on press form Cancel button
     */
    void onCancel( ) {
        agent.presenter.endEdit( false );
    }

    /**
     * Start edit
     */
    void edit( ) {
        agent.presenter.startEdit( 0 );
    }
}

/**
 * Keeps reference on presenter
 */
class Agent {
    late WidgetPresenter presenter;

}

typedef IsSelected = bool Function( String name ) ;
typedef OnSelected = Function( ListItem listItem );

ElevatedButton getButton( void Function( ) function, String name ) {
    return ElevatedButton( 
        onPressed: ( ) { function( ); }, 
        style: Style( ).styleButton, 
        child: Text( name ) 
    );
}

/**
 * The form field
 */
class Field extends StatelessWidget {
    late final dynamic nativeField;
    final InjectionObject accessObj = InjectionObject( );

    Field( { Key? key, String followup = "" } ) : super( key: key ) {
        nativeField = FieldStub( followup: followup );
    }

    /**
     * key the unique identifier see [Widget]
     * label the field label
     * value the field value
     * pattern the field pattern [FieldPattern]
     * readOnly the read only flag, default false
     */
    Field.textField( 
        { 
            Key? key, 
            value, 
            required FieldPattern pattern, 
            bool readOnly = false 
        } 
    ) : super( key: key ) {
        nativeField = TextBox( 
            value: value, pattern: pattern, readOnly: readOnly, accessObj: accessObj 
        );
    }

    Field.chipListField( 
        { 
            Key? key, 
            value, 
            required FieldPattern pattern, 
            required IsSelected isSelected, 
            required OnSelected onSelected 
        } 
    ) : super( key: key ) {
        nativeField = ChipListField( 
            value: value, 
            pattern: pattern, 
            isSelected: isSelected, 
            onSelected: onSelected
        );
    }

    @override
    Widget build( BuildContext context ) {
        return Padding( 
            padding: const EdgeInsets.symmetric( vertical: 15.0 ), 
            child: nativeField.build( context ) 
        );
    }
}

class TextBox extends StatelessWidget {
    final dynamic value;
    final FieldPattern pattern;
    final GlobalKey< FormFieldState > fieldKey = GlobalKey( );
    final bool readOnly;
    final InjectionObject accessObj;

    TextBox( 
        { 
            Key? key, 
            this.value, 
            required this.pattern, 
            required this.readOnly,
            required this.accessObj
        } 
    ) : super( key: key );

    @override
    Widget build( BuildContext context ) {
        var widget = TextFormField( 
            key: fieldKey,
            controller: TextEditingController( text: value.toString( ) ),
            decoration: Style( ).inputDecor.copyWith( labelText: pattern.label ),
            style: Style( ).formFieldStyle,
            maxLines: null,
            readOnly: readOnly,
            validator: pattern.validator
        );
        accessObj.innerObj = widget;
        return widget;
    }
}

class ChipListField extends StatelessWidget {
    final dynamic value;
    final FieldPattern pattern;
    final IsSelected isSelected;
    final OnSelected onSelected;
    final bool showCheckmark;

    const ChipListField( 
        { 
            Key? key, 
            this.value, 
            required this.pattern,
            required this.isSelected,
            required this.onSelected,
            this.showCheckmark = true
        } 
    ) : super( key: key );

    @override
    Widget build( BuildContext context ) {
        return ChipList( 
            text: pattern.label, 
            list: value,
            width: pattern.width, 
            isSelected: isSelected,
            onSelected: onSelected,
            showCheckmark: showCheckmark
        );
    }
}

/**
 * The chip list with title
 */
class ChipList extends StatelessWidget {
    final List< ListItem > list;
    final double width;
    final IsSelected isSelected;
    final OnSelected onSelected;
    final bool showCheckmark;
    final String text;

    const ChipList( 
        { 
            Key? key, 
            required this.text, 
            required this.list, 
            this.width = 130, 
            required this.isSelected, 
            required this.onSelected, 
            this.showCheckmark = false 
        } 
    ) : super( key: key );

    Widget _buildList( BuildContext context, int index ) {
        var name = list[ index ].customData.attributes[ 'name' ];
        var filterChip = FilterChip(
            selected: isSelected( name ),
            label: SizedBox( width: width - 5.0, child: Text( name ) ),
            onSelected: ( selected ) {
                onSelected( list[ index ] );
            },
            side: BorderSide( color: Style( ).theme.primaryColor ),
            backgroundColor: Colors.white,
            selectedColor: Style( ).theme.primaryColor,
            showCheckmark: showCheckmark
        );
        return Padding( padding: const EdgeInsets.all( 3 ), child: filterChip );
    }

    @override
    Widget build( BuildContext context ) {
        var chipList = ListView.builder( 
            scrollDirection: Axis.vertical, 
            itemCount: list.length, 
            itemBuilder: _buildList 
        );
        var title = Text( text, style: Style( ).listTileStyle, textAlign: TextAlign.start );
        var column = Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [ 
                Padding( padding: const EdgeInsets.all( 4 ), child: title ), 
                Expanded( child: chipList ) 
            ]
        );
        return Container( width: width, color: Colors.grey[ 60 ], child: column );
    }
}

class WidgetContainer extends StatelessWidget {
    final _list = < Widget > [ ];
    final Axis axis;
    final Widget divider;

    WidgetContainer( 
        { Key? key, this.axis = Axis.horizontal, this.divider = const SizedBox( width: 1 ) } 
    ) : super( key: key );

    @override
    Widget build( BuildContext context ) {
        var listView = ListView.separated(
            scrollDirection: axis,
            itemBuilder: ( BuildContext context, int index ) {
                return _list[ index ];
            }, 
            separatorBuilder: ( BuildContext context, int index ) => divider, 
            itemCount: _list.length
        );
        return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB( 0, 18, 0, 0 ),
            child: SizedBox( height: 320, child: listView )
        );
    }

    void add( Widget widget ) {
        _list.add( widget );
    }

    bool remove( Widget widget ) {
        return _list.remove( widget );
    }
}

class FieldStub extends StatelessWidget {
    final String followup;

    const FieldStub( { Key? key, this.followup = "" } ) : super( key: key );
  
    @override
    Widget build( BuildContext context ) {
        return getStub( "Not implemented $followup" );
    }
}

class SwiperPanel extends StatelessWidget {
    final List< Widget > widgets;

    const SwiperPanel( { Key? key, required this.widgets } ) : super( key: key );
  
    @override
    Widget build(BuildContext context) {
        return Swiper(
            itemBuilder: ( BuildContext context, int index ) {
                return widgets[ index ];
            },
            itemCount: widgets.length,
            pagination: SwiperPagination( 
                builder: DotSwiperPaginationBuilder( 
                    activeColor: Style( ).theme.primaryColorDark, color: Style( ).theme.primaryColorLight 
                )
            ),
            control: const SwiperControl( ),
        );  
    }
}

