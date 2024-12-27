// ignore_for_file: constant_identifier_names, slash_for_doc_comments

import 'package:diagram_editor/diagram_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_const.dart';
import 'app_presenter.dart';
import 'package:base/base.dart';
import 'note_presenter.dart';

const double COMPONENT_WIDTH = 400;
const double COMPONENT_HEIGHT = 300;
const double WIDTH_OFFSET = COMPONENT_WIDTH + 10;
const double HEIGHT_OFFSET = COMPONENT_HEIGHT + 10;

class NoteDiagramEditor extends StatefulWidget {

    const NoteDiagramEditor( { super.key } );

    @override
    State< NoteDiagramEditor > createState( ) => _DiagramEditorState( );
}

class _DiagramEditorState extends State< NoteDiagramEditor > {
    EditorPolicySet policySet = EditorPolicySet( );
    late DiagramEditorContext diagramEditorContext;

    @override
    void initState( ) {
        diagramEditorContext = DiagramEditorContext( policySet: policySet );
        super.initState( );
    }

    @override
    Widget build( BuildContext context ) {
        var presenter = context.watch< NotePresenter >( );
        policySet.presenter = presenter;
        var diagramEditor = DiagramEditor( diagramEditorContext: diagramEditorContext );
        var padding = Padding( padding: const EdgeInsets.all( 16 ), child: diagramEditor );
        var gd = GestureDetector(
            onSecondaryTap: ( ) { 
                policySet.refresh( ); 
            },
            child: padding
        );
        return IndexedStack( 
            index: presenter.stackIndex, 
            children: [ 
                SafeArea( child: Stack( children: [ Container( ), gd ] ) ), //???
                policySet.selectedComponentId == null ? 
                    Container( ) : 
                    NoteForm( )
            ]
        );
   }
}

class EditorPolicySet extends PolicySet with CanvasControlPolicy {
    String? selectedComponentId;
    late NotePresenter presenter;
    late Offset lastFocalPoint;

    @override
    initializeDiagramEditor( ) {
        Functions.put( 'delete', delete );
        Functions.put( 'startEdit', startEdit );
        Functions.put( 'endEdit', endEdit );
        Functions.put( 'changeFilter', changeFilter );
        Functions.put( 'getFilter', getFilter );
        addComponents( );
    }

    @override
    Widget showComponentBody( ComponentData componentData ) {
        switch( componentData.type ) {
            case 'card':
                return Note( componentData: componentData );
            default:
                return const SizedBox.shrink( );
        }
    }

    @override
    showCustomWidgetWithComponentDataOver( context, componentData ) {
        return resizeCorner( componentData );
    }

    /**
     * Deletes the specified component and based on custom data
     */
    void delete( String componentId ) {
        selectComponent( componentId );
        presenter.delete( getItemIndex( componentId ) );
        refresh( );
    }

    /**
     * Starts editing the specified component 
     */
    void startEdit( String componentId ) {
        selectComponent( componentId );
        presenter.startEdit( getItemIndex( componentId ) );
    }

    /**
     * Ends editing component 
     * ok the end editing approving flag
     */
    void endEdit( bool ok ) {
        selectComponent( selectedComponentId! );
        presenter.endEdit( ok );
        if( ok ) {
            refresh( );
        }
    }

    void changeFilter( String name ) {
        presenter.changeFilter( name );
        refresh( );     // ???
    }

    List< String > getFilter( ) {
        return presenter.getFilter( );
    }

    @override
    onCanvasTapUp( TapUpDetails details ) {
        if( selectedComponentId != null ) {
            getComponent( selectedComponentId ).data.selected = false;
            selectedComponentId = null;
        }
        var itemIndex = presenter.add( );
        var componentData = createComponent( 
            canvasReader.state.fromCanvasCoordinates( details.localPosition ), 
            presenter.get( itemIndex )
        );
        componentData.data.customData.index = itemIndex + 1;
        canvasWriter.model.addComponent( componentData );
    }

    @override
    onComponentTap( String componentId ) {
        if( selectedComponentId != null ) {
            if( selectedComponentId != componentId ) {
                // selects another note
                presenter.onSelect( getItemIndex( selectedComponentId ), getItemIndex( componentId ) );
            }
            // if tap on already selected, do nothing
        } else {
            // there is no previous selected note
            presenter.onSelect( null, getItemIndex( componentId ) );
        }
        selectComponent( componentId );
    }

    @override
    onComponentScaleStart( componentId, details ) {
        lastFocalPoint = details.localFocalPoint;
    }

    @override
    onComponentScaleUpdate( componentId, details ) {
        Offset positionDelta = details.localFocalPoint - lastFocalPoint;
        canvasWriter.model.moveComponent( componentId, positionDelta );
        lastFocalPoint = details.localFocalPoint;
    }

    /**
     * Selects component with specified id
     */
    void selectComponent( String componentId ) {
        var component = getComponent( componentId );
        if( selectedComponentId == null ) {
            component.data.selected = true;
            selectedComponentId = componentId;
        } else {
            if( selectedComponentId == componentId ) {
                component.data.selected = !component.data.selected;
                selectedComponentId = component.data.selected ? componentId : null;
            } else {
                var selectedComponent = getComponent( selectedComponentId );
                selectedComponent.data.selected = false;
                selectedComponent.updateComponent( );
                component.data.selected = true;
                selectedComponentId = componentId;
            }
        }
        presenter.selectedIndex = selectedComponentId == null ? -1 : getItemIndex( selectedComponentId );
        component.updateComponent( );
    }

    /**
     * Deletes all components from canvas
     */
    void deleteAllComponents( ) {
        selectedComponentId = null;
        canvasWriter.model.removeAllComponents( );
    }

    /**
     * Refreshes canvas
     */
    void refresh( ) {
        deleteAllComponents( );
        addComponents( );
    }

    /**
     * Returns component by it's id
     */
    ComponentData getComponent( componentId ) {
        return canvasReader.model.getComponent( componentId );
    }

    /**
     * Returns component custom data item index
     * componentId the component id
     */
    int getItemIndex( componentId ) {
        return getComponent( componentId ).data.customData.index - 1;
    }

    /**
     * Adds components based on data items from list to the canvas
     */
    void addComponents( ) {
        late Offset offset;
        var row = 0;
        var list = presenter.list;
        for( var itemIndex = 0; itemIndex < list.length; itemIndex++ ) {
            if( itemIndex % 4 == 0 ) {
                offset = Offset( 0.0, row * HEIGHT_OFFSET );
                row++;
            }
            var componentData = createComponent( offset, list[ itemIndex ] );
            componentData.data.customData.index = itemIndex + 1;
            if( componentData.data.selected ) {
                selectedComponentId = componentData.id;
            }
            canvasWriter.model.addComponent( componentData );
            offset = offset.translate( WIDTH_OFFSET, 0.0 );
        }
    }

    Widget resizeCorner( ComponentData componentData ) {
        var rightCorner = componentData.position + componentData.size.bottomRight( Offset.zero );
        Offset bottomRightCorner = canvasReader.state.toCanvasCoordinates( rightCorner );
        var mouseRegion = Container(
            width: 24,
            height: 24,
            color: Colors.transparent,
            child: Center(
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration( 
                        color: Colors.transparent, 
                        border: Border.all( color: Colors.transparent ) 
                    )
                )
            )
        );
        return Positioned(
            left: bottomRightCorner.dx - 12,
            top: bottomRightCorner.dy - 12,
            child: GestureDetector(
                onPanUpdate: ( dragDetails ) {
                    canvasWriter.model.resizeComponent(
                        componentData.id, dragDetails.delta / canvasReader.state.scale
                    );
                },
                child: MouseRegion( cursor: SystemMouseCursors.resizeDownRight, child: mouseRegion, )
            )
        );
    }
}

/**
 * Creates component
 * position the component position in the canvas
 * item the custom data bounded to the component
 */
ComponentData createComponent( Offset position, dynamic item ) {
    var componentData = ComponentData(
        position: position,
        size: const Size( COMPONENT_WIDTH, COMPONENT_HEIGHT ),
        minSize: const Size( COMPONENT_WIDTH, COMPONENT_HEIGHT ),
        data: item,
        type: 'card',
    );
    return componentData;
}

class Note extends StatelessWidget {
    final ComponentData componentData;

    const Note( { super.key, required this.componentData } );

    @override
    Widget build( BuildContext context ) {
        var presenter = context.watch< NotePresenter >( );
        var border = Border.all(
            width: 1,
            color: componentData.data.selected ? Colors.pink : Style.theme.primaryColor
        );
        var decoration = BoxDecoration(
            borderRadius: BorderRadius.circular( 20 ),
            border: border,
            color: Colors.white.withOpacity( 1.0 )
        );
        var title = Text( 
            componentData.data.customData.title, 
            style: Style.theme.textTheme.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis 
        );
        var divider = Divider( 
            color: Style.theme.primaryColor, 
            thickness: 1, 
            height: 2, 
            indent: 24, endIndent: 24 
        );
        var description = Text( 
            componentData.data.customData.description, 
            style: Style.listTileStyle, 
            maxLines: 2, 
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left
        );
        var count = Text( 
            ( componentData.data.customData.index ).toString( ), 
            style: Style.theme.textTheme.labelSmall 
        );
        var editBtn = Focus(
            descendantsAreFocusable: false,
            canRequestFocus: false,
            child: IconButton( 
                onPressed: ( ) { 
                    if( componentData.data.selected ) {
                        presenter.startEdit( presenter.selectedIndex );
                    } else {
                        Functions.get( 'startEdit' )( componentData.id );
                    }
                }, 
                icon: Icon( Icons.edit_note, color: Style.theme.primaryColor ),
                tooltip: "edit note"
            )
        );
        var deleteBtn = Focus(
            descendantsAreFocusable: false,
            canRequestFocus: false,
            child: IconButton( 
                onPressed: ( ) { 
                    Functions.get( 'delete' )( componentData.id );
                }, 
                icon: Icon( Icons.highlight_off, color: Style.theme.primaryColor ),
                tooltip: "delete note"
            )
       );
        var topRow = Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [ count, Row( children: [ editBtn, deleteBtn ] ) ]
        );
        var chipLists = < Widget > [];
        var attributeNames = [ ROLE, DETAIL, LOCATION, ACTION_TIME ];
        for( var attributeName in attributeNames ) {
            var pattern = getPattern( NOTE )[ attributeName ]!;
            var chipList = ChipListField( 
                value: componentData.data.customData.attributes[ attributeName ],
                pattern: pattern,
                isSelected: _isChipSelected,
                onSelected: _onChipSelected,
                showCheckmark: false
            );
            chipLists.add( chipList );
        }
        var note = Container(
            decoration: decoration,
            child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                    Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB( 12, 0, 0, 0 ),
                        child: topRow
                    ),
                    Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB( 12, 0, 12, 6 ),
                        child: Center( child: title )
                    ),
                    divider,
                    Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB( 12, 6, 12, 0 ),
                        child: description
                    ),
                    Expanded(
                        child: SizedBox(
                            height: 140,
                            child: ListView( scrollDirection: Axis.horizontal, children: chipLists )
                        )
                    )
                ]
            )
        );
        return Visibility( 
            visible: presenter.applyFilter( componentData.data.customData.index - 1 ), 
            child: note 
        ); 
    }

    /**
     * see [FilterChip.selected]
     */
    bool _isChipSelected( String name ) {
        return Functions.get( 'getFilter' )( ).contains( name );
    }

    /**
    * see [FilterChip.onSelected]
    */
	void _onChipSelected( ListItem listItem ) {
        var name = listItem.customData.attributes[ 'name' ];
        Functions.get( 'changeFilter' )( name );
	}
}

/**
 * The note form 
 * item the selected note
 */
class NoteForm extends BaseForm< NotePresenter > {

    NoteForm( { super.key } );

    @override
    Field createField( String attributeName, int index ) {
        Field field;
        var pattern = getPattern( NOTE )[ attributeName ]!;
        var note = agent.presenter.get( index ).customData;

        switch( pattern.style ) {
            case TEXT_FIELD:
                field = Field.textField( 
                    value: note.attributes[ attributeName ], 
                    pattern: pattern
                );
               break;
            case CHIP_LIST_FIELD:
                isSelected( name ) {
                    var list = note.attributes[ attributeName ] as List< ListItem >;
                    if( list.isEmpty ) {
                        return false;
                    } 
                    return list.any( ( e ) => e.customData.attributes[ 'name' ] == name );
                }
                onSelected( listItem ) {
                    agent.presenter.update( attributeName, listItem, true );
                }
                field = Field.chipListField(
                    value: AppPresenter( ).getData( attributeName ), 
                    pattern: pattern,
                    isSelected: isSelected,
                    onSelected: onSelected
                );
                break;
            default:
                field = Field( followup: pattern.style ?? "" );
        }
        return field;
    }

    @override
    void onCancel( ) {
        Functions.get( 'endEdit' )( false );
    }

    @override
    void onOK( ) {
        super.onOK( );
        Functions.get( 'endEdit' )( true );
    }
}






