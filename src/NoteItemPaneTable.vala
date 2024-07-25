/*
* Copyright (c) 2024 (https://github.com/phase1geo/MosaicNote)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using Gtk;
#if !GTK412
using Gee;
#endif

public class NoteItemPaneTable : NoteItemPane {

  private ColumnView _table;
  private int        _col_id = 0;
#if !GTK412
  private HashMap<string,ColumnViewColumn> _col_map;
#endif

  private const GLib.ActionEntry[] action_entries = {
    { "action_format_column",        action_format_column,        "s" },
    { "action_insert_column_before", action_insert_column_before, "s" },
    { "action_insert_column_after",  action_insert_column_after,  "s" },
    { "action_delete_column",        action_delete_column,        "s" },
  };

  private signal void auto_number_changed();

  private signal void column_title_changed( string id );
  private signal void column_type_changed( string id );
  private signal void column_justify_changed( string id );

	// Default constructor
	public NoteItemPaneTable( MainWindow win, NoteItem item, SpellChecker spell ) {

    base( win, item, spell );

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "table", actions );

  }

  //-------------------------------------------------------------
  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement ) {
    _table.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds the auto-number setting to the specified table settings
  // widgets.
  private void add_auto_number_setting( GLib.Menu menu, PopoverMenu popup_menu ) {

    var table_item = (NoteItemTable)item;

    var autonum_label = new Label( _( "Auto-number rows" ) ) {
      halign = Align.START,
      hexpand = true
    };

    var autonum_sw = new Switch() {
      halign = Align.END,
      active = table_item.auto_number
    };

    autonum_sw.notify["active"].connect(() => {
      table_item.auto_number = autonum_sw.active;
      auto_number_changed();
    });

    var autonum_box = new Box( Orientation.HORIZONTAL, 5 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    autonum_box.append( autonum_label );
    autonum_box.append( autonum_sw );

    var autonum_mi = new MenuItem( null, null );
    autonum_mi.set_attribute( "custom", "s", "autonum" );

    menu.append_item( autonum_mi );
    popup_menu.add_child( autonum_box, "autonum" );

  }

  //-------------------------------------------------------------
  // Create custom header when the pane is selected.
  protected override Widget create_header1() {

    var entry = new Entry() {
      has_frame = false,
      placeholder_text = _( "Description (optional)" ),
      halign = Align.FILL,
      hexpand = true,
      text = ((NoteItemTable)item).description
    };

    entry.activate.connect(() => {
      ((NoteItemTable)item).description = entry.text;
    });

    save.connect(() => {
      ((NoteItemTable)item).description = entry.text;
    });

    var menu = new GLib.Menu();
    var popup_menu = new PopoverMenu.from_model( menu );

    // Add the settings
    add_auto_number_setting( menu, popup_menu );

    var settings = new MenuButton() {
      halign       = Align.END,
      has_frame    = false,
      icon_name    = "emblem-system-symbolic",
      tooltip_text = _( "Table Controls" ),
      popover      = popup_menu
    };

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( entry );
    box.append( settings );

    return( box );

  }

#if GTK412
  //-------------------------------------------------------------
  // Returns the index of the column with the given ID.
  private int get_cv_column_index( string col_id ) {
    var store = (GLib.ListStore)_table.columns;
    for( int i=0; i<store.get_n_items(); i++ ) {
      var col = (ColumnViewColumn)store.get_item( i );
      if( col.id == col_id ) {
        return( i );
      }
    }
    return( -1 );
  }
#else
  private int get_cv_column_index( string col_id ) {
    var store    = (GLib.ListStore)_table.columns;
    var find_col = _col_map.get( col_id );
    for( int i=0; i<store.get_n_items(); i++ ) {
      var col = (store.get_item( i ) as ColumnViewColumn);
      if( col == null ) {
        stdout.printf( "li.item is not a ColumnViewColumn\n" );
      }
      if( col == find_col ) {
        return( i );
      }
    }
    return( -1 );
  }
#endif

  //-------------------------------------------------------------
  // Adds a new ColumnView column this will need to be called
  // when the user is adding a new column.
  private string add_cv_column( int index ) {

    var table_item = (NoteItemTable)item;
    var table_col  = table_item.get_column( index );
    var factory    = new SignalListItemFactory();
    var col_id_int = _col_id++;
    var col_id     = col_id_int.to_string();

    factory.setup.connect((obj) => {
      row_setup( index, col_id, obj );
    });
    factory.bind.connect((obj) => {
      row_bind( index, obj );
    });

    // Create menu
    var edit_menu = new GLib.Menu();
    edit_menu.append( _( "Format column" ), "table.action_format_column('%s')".printf( col_id ) );
    var ins_menu = new GLib.Menu();
    ins_menu.append( _( "Insert column before" ), "table.action_insert_column_before('%s')".printf( col_id ) );
    ins_menu.append( _( "Insert column after" ),  "table.action_insert_column_after('%s')".printf( col_id ) );
    var del_menu = new GLib.Menu();
    del_menu.append( _( "Remove column" ), "table.action_delete_column('%s')".printf( col_id ) );
    var head_menu = new GLib.Menu();
    head_menu.append_section( null, edit_menu );
    head_menu.append_section( null, ins_menu );
    head_menu.append_section( null, del_menu );

    var col = new ColumnViewColumn( table_col.header, factory ) {
#if GTK412
      id          = col_id,
#endif
      expand      = true,
      resizable   = true,
      header_menu = head_menu
    };

    column_title_changed.connect((id) => {
      if( id == col_id ) {
        col.title = table_col.header;
      }
    });

    _table.insert_column( index, col );

#if !GTK412
    _col_map.set( col_id, col );
#endif

    return( col_id );

  }

  //-------------------------------------------------------------
  // Removes the ColumnView column at the given index.
  private void remove_cv_column( int index ) {

    var columns = (GLib.ListStore)_table.columns;
    columns.remove( index );

  }

  //-------------------------------------------------------------
  // Adds the UI for the table panel.
  protected override Widget create_pane() {

    var table_item = (NoteItemTable)item;
    var selector   = new SingleSelection( table_item.model );

#if !GTK412
    _col_map = new HashMap<string,ColumnViewColumn>();
#endif    

    _table = new ColumnView( selector ) {
#if GTK412
      tab_behavior = ListTabBehavior.CELL,
#endif
      halign = Align.FILL,
      show_row_separators = true,
      show_column_separators = true
    };

    _table.set_size_request( -1, 300 );

    if( table_item.columns() == 0 ) {
      stdout.printf( "Make table\n" );
      // FOOBAR
    } else {
      for( int i=0; i<table_item.columns(); i++ ) {
        add_cv_column( i );
      }
    }

    /*
    if( image_item.uri == "" ) {
      image_dialog( image_item, _image );
    } else {
      _image.file = File.new_for_path( image_item.get_resource_filename() );
    }

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( _image );
    box.set_size_request( -1, 500 );
    box.add_css_class( "themed" );

    image_click.pressed.connect((n_press, x, y) => {
      if( n_press == 1 ) {
        _image.grab_focus();
      } else if( n_press == 2 ) {
        image_dialog( image_item, _image );
      }
    });

    image_focus.enter.connect(() => {
      set_as_current();
    });

    handle_key_events( _image );
    */

    return( _table );

  }

  //-------------------------------------------------------------
  // Saves the given text value to the cell associated with the given
  // list item and column index.
  private void save_to_cell( ListItem li, int column, string val ) {
    var table_item = (NoteItemTable)item; 
    var row = (int)li.position;
    table_item.set_cell( column, row, val );
  }

  //-------------------------------------------------------------
  // Creates an auto-numbered cell whose value is the position of the
  // list item in the list plus one.
  private Box setup_auto_number( string? num = null ) {

    var label = new Label( num ?? "" ) {
      valign = Align.START,
      // vexpand = true,
      wrap = false
    };

    var box = new Box( Orientation.VERTICAL, 0 ) {
      halign = Align.START
    };
    box.append( label );

    return( box );

  }

  //-------------------------------------------------------------
  // Setups up a text widget for the given cell.
  private TextView setup_text( int column, ListItem li ) {

    var text = new TextView() {
      halign = Align.FILL,
      hexpand = true,
      justification = ((NoteItemTable)item).get_column( column ).justify,
      wrap_mode = WrapMode.WORD
    };

    var focus_controller = new EventControllerFocus();
    focus_controller.leave.connect(() => {
      save_to_cell( li, column, text.buffer.text );
    });

    // If we need to save, check to see if a table cell has focus and
    // save its contents to the note item
    save.connect(() => {
      if( focus_controller.contains_focus ) {
        save_to_cell( li, column, text.buffer.text );
      }
    });

    text.add_controller( focus_controller );

    return( text );

  }

  //-------------------------------------------------------------
  // Returns the align value for the given Justification enumerated
  // value.
  private Align align_from_justify( Justification justify ) {
    switch( justify ) {
      case Justification.LEFT   :  return( Align.START );
      case Justification.CENTER :  return( Align.CENTER );
      case Justification.RIGHT  :  return( Align.END );
      default                   :  return( Align.START );
    }
  }

  //-------------------------------------------------------------
  // Sets up a checkbox for a given row.
  private CheckButton setup_checkbox( int column, ListItem li ) {

    var cb = new CheckButton() {
      halign = align_from_justify( ((NoteItemTable)item).get_column( column ).justify )
    };

    cb.notify["active"].connect(() => {
      save_to_cell( li, column, cb.active.to_string() );
    });

    return( cb );

  }

  //-------------------------------------------------------------
  // Row factory setup function
  private void row_setup( int column, string col_id, Object obj ) {

    var li         = (ListItem)obj;
    var table_item = (NoteItemTable)item;

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    if( (column == 0) && table_item.auto_number ) {
      box.append( setup_auto_number() );
    }

    switch( table_item.get_column( column ).data_type ) {
      case TableColumnType.TEXT     :  box.append( setup_text( column, li ) );      break;
      case TableColumnType.CHECKBOX :  box.append( setup_checkbox( column, li ) );  break;
      default                       :  assert_not_reached();
    }

    li.child = box;

    auto_number_changed.connect(() => {
      var col_index = get_cv_column_index( col_id );
      if( col_index == 0 ) {
        var b = (Box)li.child;
        if( table_item.auto_number ) {
          b.prepend( setup_auto_number( "%u.".printf( li.get_position() + 1 ) ) );
        } else {
          b.remove( b.get_first_child() );
        }
      }
    });

    column_justify_changed.connect((id) => {
      if( id == col_id ) {
        var justify = table_item.get_column( column ).justify;
        var child   = li.child.get_last_child();
        switch( table_item.get_column( column ).data_type ) {
          case TableColumnType.TEXT     :  ((TextView)child).justification = justify;  break;
          case TableColumnType.CHECKBOX :  ((CheckButton)child).halign = align_from_justify( justify );  break;
          default                       :  assert_not_reached();
        }
      }
    });

    column_type_changed.connect((id) => {
      if( id == col_id ) {
        var b = (Box)li.child;
        b.remove( b.get_last_child() );
        switch( table_item.get_column( column ).data_type ) {
          case TableColumnType.TEXT     :  b.append( setup_text( column, li ) );      break;
          case TableColumnType.CHECKBOX :  b.append( setup_checkbox( column, li ) );  break;
          default                       :  assert_not_reached();
        }
      }
    });

  }

  //-------------------------------------------------------------
  // Binds the associated text to the listitem value.
  private void bind_text( int column, ListItem li ) {
    var row  = (NoteItemTableRow)li.item;
    var text = (TextView)li.child.get_last_child();
    text.buffer.text = row.get_value( column );
  }

  //-------------------------------------------------------------
  // Binds the associated checkbutton to the listitem value.
  private void bind_checkbox( int column, ListItem li ) {
    var row      = (NoteItemTableRow)li.item;
    var checkbox = (CheckButton)li.child.get_last_child();
    checkbox.active = bool.parse( row.get_value( column ) );
  }

  //-------------------------------------------------------------
  // Row factory bind function
  private void row_bind( int column, Object obj ) {

    var li = (ListItem)obj;
    var table_item = (NoteItemTable)item;

    if( (column == 0) && table_item.auto_number ) {
      var lbl = (Label)li.child.get_first_child().get_first_child();
      lbl.label = "%u.".printf( li.get_position() + 1 );
    }

    switch( table_item.get_column( column ).data_type ) {
      case TableColumnType.TEXT     :  bind_text( column, li );      break;
      case TableColumnType.CHECKBOX :  bind_checkbox( column, li );  break;
      default                       :  assert_not_reached();
    }

  }

  //-------------------------------------------------------------
  // Displays the column formatting dialog window.
  private void show_column_format_dialog( string col_id ) {

    var table_item = (NoteItemTable)item;
    var index      = get_cv_column_index( col_id );
    var column     = table_item.get_column( index );

    var grid = new Grid() {
      margin_start    = 10,
      margin_end      = 10,
      margin_top      = 10,
      margin_bottom   = 10,
      row_homogeneous = true,
      column_spacing  = 10,
      row_spacing     = 10
    };

    var title_label = new Label( _( "Title:" ) ) {
      halign = Align.START,
      hexpand = true
    };
    grid.attach( title_label, 0, 0 );

    var title_entry = new Entry() {
      halign = Align.START,
      hexpand = true,
      text = column.header
    };
    grid.attach( title_entry, 1, 0 );

    title_entry.activate.connect(() => {
      column.header = title_entry.text;
      column_title_changed( col_id );
    });

    var type_label = new Label( _( "Content Type:" ) ) {
      halign = Align.START,
      hexpand = true
    };
    grid.attach( type_label, 0, 1 );

    string[] types = {};
    for( int i=0; i<TableColumnType.NUM; i++ ) {
      var col_type = (TableColumnType)i;
      types += col_type.label();
    }

    var type_menu = new DropDown.from_strings( types ) {
      halign = Align.START,
      hexpand = true,
      selected = column.data_type
    };
    grid.attach( type_menu, 1, 1 );

    type_menu.notify["selected"].connect(() => {
      column.data_type = (TableColumnType)type_menu.selected;
      column_type_changed( col_id );
    });

    var justify_label = new Label( _( "Justify:" ) ) {
      halign = Align.START,
      hexpand = true
    };
    grid.attach( justify_label, 0, 2 );

    var justify_menu = new DropDown.from_strings( { _( "Left" ), _( "Center" ), _( "Right" ) } ) {
      halign = Align.START,
      hexpand = true,
      selected = column.justify
    };
    grid.attach( justify_menu, 1, 2 );

    switch( column.justify ) {
      case Justification.LEFT   :  justify_menu.selected = 0;  break;
      case Justification.CENTER :  justify_menu.selected = 1;  break;
      case Justification.RIGHT  :  justify_menu.selected = 2;  break;
      default                   :  assert_not_reached();
    }

    justify_menu.notify["selected"].connect(() => {
      switch( justify_menu.selected ) {
        case 0 :  column.justify = Justification.LEFT;    break;
        case 1 :  column.justify = Justification.CENTER;  break;
        case 2 :  column.justify = Justification.RIGHT;   break;
      }
      column_justify_changed( col_id );
    });

    var dialog = new Window() {
      decorated = true,
      modal = true,
      destroy_with_parent = true,
      resizable = false,
      title = _( "Format Column" ),
      transient_for = win,
      child = grid
    };

    dialog.present();

  }

  //-------------------------------------------------------------
  // Edits the column title for the specified column.
  private void action_format_column( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var col_id = variant.get_string();
      show_column_format_dialog( col_id );
    }
  }

  //-------------------------------------------------------------
  // Inserts a new column at the specified index.
  private void action_insert_column_before( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var col_id     = variant.get_string();
      var index      = get_cv_column_index( col_id );
      var table_item = (NoteItemTable)item;
      table_item.insert_column( index, "", Gtk.Justification.LEFT );
      col_id = add_cv_column( index );
      show_column_format_dialog( col_id );
    }
  }

  //-------------------------------------------------------------
  // Inserts a new column at the specified index.
  private void action_insert_column_after( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var col_id     = variant.get_string();
      var index      = get_cv_column_index( col_id );
      var table_item = (NoteItemTable)item;
      table_item.insert_column( (index + 1), "", Gtk.Justification.LEFT );
      col_id = add_cv_column( index + 1 );
      show_column_format_dialog( col_id );
    }
  }

  //-------------------------------------------------------------
  // Removes the column at the specified index.
  private void action_delete_column( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var col_id     = variant.get_string();
      var index      = get_cv_column_index( col_id );
      var table_item = (NoteItemTable)item;
      table_item.delete_column( index );
      remove_cv_column( index );
    }
  }

}