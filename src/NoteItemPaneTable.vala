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

public class NoteItemPaneTable : NoteItemPane {

  private ColumnView _table;

	// Default constructor
	public NoteItemPaneTable( MainWindow win, NoteItem item, SpellChecker spell ) {
    base( win, item, spell );
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

  //-------------------------------------------------------------
  // Adds the UI for the table panel.
  protected override Widget create_pane() {

    var table_item = (NoteItemTable)item;
    var selector   = new SingleSelection( table_item.model );

    _table = new ColumnView( selector ) {
      show_row_separators = true,
      halign = Align.FILL,
#if GTK412
      tab_behavior = ListTabBehavior.CELL,
#endif
      show_column_separators = true
    };

    _table.set_size_request( -1, 500 );

    if( table_item.columns() == 0 ) {
      stdout.printf( "Make table\n" );
      // FOOBAR
    } else {
      stdout.printf( "Table columns: %d\n", table_item.columns() );
      for( int i=0; i<table_item.columns(); i++ ) {
        var index     = i;
        var table_col = table_item.get_column( i );
        var factory   = new SignalListItemFactory();
        factory.setup.connect((obj) => {
          row_setup( index, obj );
        });
        factory.bind.connect((obj) => {
          row_bind( index, obj );
        });
        var col = new ColumnViewColumn( table_col.header, factory ) {
          expand    = true,
          resizable = true
        };
        _table.append_column( col );
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

}