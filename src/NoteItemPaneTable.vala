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
    { "action_insert_column_before", action_insert_column_before, "s" },
    { "action_insert_column_after",  action_insert_column_after,  "s" },
    { "action_delete_column",        action_delete_column,        "s" },
  };

	// Default constructor
	public NoteItemPaneTable( MainWindow win, NoteItem item, SpellChecker spell ) {

    base( win, item, spell );

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "table", actions );

  }

  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement ) {
    _table.grab_focus();
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

    return( entry );

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
  private void add_cv_column( int index ) {

    var table_item = (NoteItemTable)item;
    var col_index  = index;
    var table_col  = table_item.get_column( index );
    var factory    = new SignalListItemFactory();
    var col_id_int = _col_id++;
    var col_id     = col_id_int.to_string();

    factory.setup.connect((obj) => {
      row_setup( index, obj );
    });
    factory.bind.connect((obj) => {
      row_bind( index, obj );
    });

    // Create menu
    var ins_menu = new GLib.Menu();
    ins_menu.append( _( "Insert column before" ), "table.action_insert_column_before('%s')".printf( col_id ) );
    ins_menu.append( _( "Insert column after" ),  "table.action_insert_column_after('%s')".printf( col_id ) );
    var del_menu = new GLib.Menu();
    del_menu.append( _( "Remove column" ), "table.action_delete_column('%s')".printf( col_id ) );
    var head_menu = new GLib.Menu();
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

    _table.insert_column( index, col );

#if !GTK412
    _col_map.set( col_id, col );
#endif

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
  // Row factory setup function
  private void row_setup( int column, Object obj ) {

    var column_index = column;
    var li   = (ListItem)obj;
    var text = new TextView() {
      justification = ((NoteItemTable)item).get_column( column ).justify
    };

    var focus_controller = new EventControllerFocus();
    focus_controller.leave.connect(() => {
      save_to_cell( li, column_index, text.buffer.text );
    });

    // If we need to save, check to see if a table cell has focus and
    // save its contents to the note item
    save.connect(() => {
      if( focus_controller.contains_focus ) {
        save_to_cell( li, column_index, text.buffer.text );
      }
    });

    text.add_controller( focus_controller );

    li.child = text;

  }

  //-------------------------------------------------------------
  // Row factory bind function
  private void row_bind( int column, Object obj ) {
    var li   = (ListItem)obj;
    var row  = (NoteItemTableRow)li.item;
    var text = (li.child as TextView);
    text.buffer.text = row.get_value( column );
  }

  //-------------------------------------------------------------
  // Inserts a new column at the specified index.
  private void action_insert_column_before( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var col_id     = variant.get_string();
      var index      = get_cv_column_index( col_id );
      var table_item = (NoteItemTable)item;
      table_item.insert_column( index, "", Gtk.Justification.LEFT );
      add_cv_column( index );
    }
  }

  //-------------------------------------------------------------
  // Inserts a new column at the specified index.
  private void action_insert_column_after( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var col_id     = variant.get_string();
      var index      = get_cv_column_index( col_id );
      var table_item = (NoteItemTable)item;
      stdout.printf( "In action_insert_column_after, current index: %d\n", index );
      table_item.insert_column( (index + 1), "", Gtk.Justification.LEFT );
      add_cv_column( index + 1 );
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