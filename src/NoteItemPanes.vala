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

//-------------------------------------------------------------
// Location of a note item in the panes box (row and column).
public class NoteItemPos {
  private bool _valid = false;
  private int  _row   = -1;
  private int  _col   = -1;
  public int row {
    get {
      return( _row );
    }
  }
  public int col {
    get {
      return( _col );
    }
  }
  public NoteItemPos() {}
  public bool is_valid() {
    return( _valid );
  }
  public void set_position( int row, int col ) {
    _valid = true;
    _row   = row;
    _col   = col;
  }
  public void set_position_from_pane( Widget pane ) {
    var pane_row = (NoteItemPaneRow)pane.get_parent().get_parent();
    var parent   = pane_row.get_parent();
    _valid       = true;
    _col         = pane_row.get_pane_col( pane );
    _row         = Utils.get_child_index( parent, pane_row );
  }
  public void clear_position() {
    _valid = false;
  }
  public NoteItemPaneRow? get_row_pane( Widget panes ) {
    if( !_valid ) return( null );
    return( (NoteItemPaneRow)Utils.get_child_at_index( panes, _row ) );
  }
  public NoteItemPane? get_pane( Widget panes ) {
    if( !_valid ) return( null );
    var row = (NoteItemPaneRow)Utils.get_child_at_index( panes, _row ); 
    return( (row != null) ? row.get_pane( _col ) : null );
  }
  public bool matches( NoteItemPos other ) {
    return( (_valid == other._valid) && (_row == other._row) && (_col == other._col) );
  }
  public NoteItemPos? get_next_pane( Widget panes ) {
    var pane_row = get_row_pane( panes );
    var pos      = new NoteItemPos();
    if( (_col + 1) < pane_row.size ) {
      pos.set_position( _row, (_col + 1) );
      return( pos );
    } else {
      pos.set_position( (_row + 1), 0 );
      return( (Utils.get_child_at_index( panes, (_row + 1) ) != null) ? pos : null );
    }
  }
  public NoteItemPos? get_prev_pane( Widget panes ) {
    var pane_row = get_row_pane( panes );
    var pos      = new NoteItemPos();
    if( (_col - 1) >= 0 ) {
      pos.set_position( _row, (_col - 1) );
      return( pos );
    } else if( (_row - 1) >= 0 ) {
      pane_row = (NoteItemPaneRow)Utils.get_child_at_index( panes, (_row - 1) );
      pos.set_position( (_row - 1), (pane_row.size - 1) );
      return( pos );
    } else {
      return( null );
    }
  }
}

//-------------------------------------------------------------
// Used to indicate a direction of movement.
public enum MoveDirection {
  UP,
  DOWN,
  LEFT,
  RIGHT
}

//-------------------------------------------------------------
// Contains all of the note item panes for a single note.  Handles
// any resources that are shared by multiple panes (i.e., spellchecker).
// Provides functionality for manipulating panes within the browser.
public class NoteItemPanes : Box {

  private MainWindow   _win;
  private Note         _note;
  private NoteItemPos  _current_item;
  private int          _rows = 0;
  private SpellChecker _spell;

  public signal void item_removed( NoteItemPane pane );
  public signal void item_selected( NoteItemPane pane );
  public signal void note_link_clicked( string link );
  public signal void see( int y, int height );
  public signal void show_images( Array<NoteItem> items, int index );

  public signal void save();

  //-------------------------------------------------------------
  // Default constructor
  public NoteItemPanes( MainWindow win ) {

    Object(
      orientation: Orientation.VERTICAL,
      spacing: 5
    );

    _win          = win;
    _current_item = new NoteItemPos();

    // Initialize the spell checker
    initialize_spell_checker();

    add_css_class( "themed" );

  }

  //-------------------------------------------------------------
  // Initializes the spell checker that could be used for this
  // note item pane.
  private void initialize_spell_checker() {

    _spell = new SpellChecker();
    _spell.populate_extra_menu.connect( populate_extra_menu );

    update_spell_language();

  }

  //-------------------------------------------------------------
  // Adding an extra menu for the given text widget.
  private void populate_extra_menu( TextView view ) {

    var extra = new GLib.Menu();
    view.extra_menu = extra;

    var pane = _current_item.get_pane( this );
    if( pane != null ) {
      pane.populate_extra_menu();
    }

  }

  //-------------------------------------------------------------
  // Updates the spelling language based on application gsettings
  private void update_spell_language() {

    var lang        = MosaicNote.settings.get_string( "spellchecker-language" );
    var lang_exists = false;

    if( lang == "system" ) {
      var env_lang = Environment.get_variable( "LANG" ).split( "." );
      lang = env_lang[0];
    }

    var lang_list = new Gee.ArrayList<string>();
    _spell.get_language_list( lang_list );

    /* Check to see if the given language exists */
    lang_list.foreach((elem) => {
      if( elem == lang ) {
        _spell.set_language( lang );
        lang_exists = true;
        return( false );
      }
      return( true );
    });

    /* Based on the search, set the language to use in the spell checker */
    if( lang_list.size == 0 ) {
      _spell.set_language( null );
    } else if( !lang_exists ) {
      _spell.set_language( lang_list.get( 0 ) );
    }

  }

  //-------------------------------------------------------------
  // Returns the number of rows stored in this structure
  public int rows() {
    return( _rows );
  }

  //-------------------------------------------------------------
  // Adds a new item of the given type at the given position
  public void add_new_item( NoteItemType type, int row = -1, int col = 0, bool add_to_row = false ) {
    NoteItemRow note_row;
    if( add_to_row && (_note.rows() > 0) ) {
      if( row == -1 ) {
        row = _note.rows() - 1;
      }
      note_row = _note.get_row( row );
    } else {
      note_row = new NoteItemRow( _note );
      _note.add_row( note_row, row );
      add_to_row = false;
    }
    var new_item = type.create( note_row );
    note_row.add_item( new_item, col );
    add_pane( new_item, row, col, add_to_row, true );
    _win.undo.add_item( new UndoItemAdd( _note, row, col ) );
  }

  //-------------------------------------------------------------
  // Adds an item to the UI at the given position.  Set pos to -1
  // to append the item at the end of the current item set.
  public void add_pane( NoteItem item, int row, int col, bool add_to_row, bool show ) {

    NoteItemPaneRow? row_pane = null;

    if( add_to_row ) {
      row_pane = (NoteItemPaneRow)Utils.get_child_at_index( this, row );
    } else {
      row_pane = new NoteItemPaneRow( item.row );
    }

    NoteItemPane pane;
    switch( item.item_type ) {
      case NoteItemType.MARKDOWN :  pane = new NoteItemPaneMarkdown( _win, item, _spell );  break;
      case NoteItemType.CODE     :  pane = new NoteItemPaneCode( _win, item, _spell );      break;
      case NoteItemType.IMAGE    :  pane = new NoteItemPaneImage( _win, item, _spell );     break;
      case NoteItemType.UML      :  pane = new NoteItemPaneUML( _win, item, _spell );       break;
      case NoteItemType.TABLE    :  pane = new NoteItemPaneTable( _win, item, _spell );     break;
      case NoteItemType.ASSETS   :  pane = new NoteItemPaneAssets( _win, item, _spell );    break;
      case NoteItemType.MATH     :  pane = new NoteItemPaneMath( _win, item, _spell );      break;
      default                    :  return;
    }

    pane.add_item.connect((dir, type) => {
      var row_box = pane.get_parent();
      var row_pos = Utils.get_child_index( this, row_box );
      var col_pos = Utils.get_child_index( row_box, pane ); 
      var use_row = true;
      switch( dir ) {
        case MoveDirection.UP    :  col_pos = 0;  use_row = false;  break;
        case MoveDirection.DOWN  :  col_pos = 0;  use_row = false;  row_pos++;  break;
        case MoveDirection.RIGHT :  col_pos++;  break;
        default                  :  break;
      }
      add_new_item( ((type == null) ? NoteItemType.MARKDOWN : type), row_pos, col_pos, use_row );
    });

    pane.remove_item.connect((forward, record_undo) => {
      var row_box = (NoteItemPaneRow)pane.get_parent();
      var row_pos = Utils.get_child_index( this, row_box );
      var col_pos = Utils.get_child_index( row_box, pane );
      var rows    = _rows;
      if( record_undo ) {
        _win.undo.add_item( new UndoItemDelete( _note, row_pos, col_pos ) );
      }
      item_removed( pane );
      row_box.delete_pane( col_pos );
      if( row_box.size == 0 ) {
        remove( row_box );
        _rows--;
      }
      _note.delete_item( row_pos, col_pos );
      if( (forward || (row_pos == 0)) && (get_pane( row_pos, 0 ) != null) ) {
        var next_pane = get_pane( row_pos, 0 );
        show_pane( next_pane );
        next_pane.grab_item_focus( TextCursorPlacement.NO_CHANGE );
      } else if( (!forward || (row_pos == (rows - 1))) && (get_pane( (row_pos - 1), 0 ) != null) ) {
        var prev_pane = get_pane( (row_pos - 1), 0 );
        show_pane( prev_pane );
        prev_pane.grab_item_focus( TextCursorPlacement.NO_CHANGE );
      } else {
        add_new_item( NoteItemType.MARKDOWN );
      }
    });

    pane.remove_row.connect(() => {
      stdout.printf( "Need to add code to remove row\n" );
    });

    pane.change_item.connect((type) => {
      set_current_item_to_type( type );
    });

    pane.move_item.connect((dir, record_undo) => {
      var row_box  = pane.get_parent();
      var curr_row = Utils.get_child_index( this, row_box );
      var curr_col = Utils.get_child_index( row_box, pane );
      var prev     = get_pane( curr_row - 1, 0 );
      var curr     = get_pane( curr_row, curr_col );
      var next     = get_pane( curr_row + 1, 0 );
      if( dir == MoveDirection.UP ) {
        curr.prev_pane = prev.prev_pane;
        curr.next_pane = prev;
        prev.prev_pane = curr;
        prev.next_pane = next;
        if( next != null ) {
          next.prev_pane = curr;
        }
        _note.move_row( curr_row, (curr_row - 1) );
        reorder_child_after( get_row( curr_row ), get_row( curr_row - 2 ) );
      } else {
        curr.prev_pane = next;
        curr.next_pane = next.next_pane;
        next.prev_pane = prev;
        next.next_pane = curr;
        if( prev != null ) {
          prev.next_pane = next;
        }
        _note.move_row( curr_row, (curr_row + 1) );
        reorder_child_after( get_row( curr_row ), get_row( curr_row + 1 ) );
      }
      show_pane( curr );
      if( record_undo ) {
        _win.undo.add_item( new UndoItemMove( _note, curr_row, (dir == MoveDirection.UP) ) );
      }
    });

    pane.set_as_current.connect((msg) => {
      if( !_current_item.is_valid() ) {
        _current_item.set_position_from_pane( pane );
        item_selected( pane );
      } else {
        var other_pane = _current_item.get_pane( this );
        if( other_pane != null ) {
          other_pane.clear_current();
        }
        _current_item.set_position_from_pane( pane );
        item_selected( pane );
      }
      show_pane( pane );
    });

    pane.note_link_clicked.connect((link) => {
      note_link_clicked( link );
    });

    pane.show_image.connect(() => {
      var items = new Array<NoteItem>();
      items.append_val( item );
      show_images( items, 0 );
    });

    save.connect(() => {
      pane.save();
    });

    row_pane.add_pane( pane, col );

    // Add the pane at the given position
    if( !add_to_row ) {
      if( row == 0 ) {
        var first_pane = get_pane( 0, 0 );
        if( first_pane != null ) {
          first_pane.prev_pane = pane;
          pane.next_pane = first_pane;
        }
        prepend( row_pane );
      } else {
        var sibling_row = get_row( row - 1 );
        insert_child_after( row_pane, sibling_row );
        /* TODO
        pane.prev_pane = sibling;
        pane.next_pane = sibling.next_pane;
        sibling.next_pane = pane;
        */
      }
      _rows++;
    }

    // Make sure that the pane is within view
    if( show ) {
      show_pane( pane );
    }

    // Make sure that the new pane has the focus
    if( !_note.locked ) {
      if( show ) {
        pane.grab_item_focus( TextCursorPlacement.START );
      }
    } else {
      pane.clear_current();
    }

  }

  //-------------------------------------------------------------
  // Clears the current item.
  public void clear_current_item() {
    if( _current_item.is_valid() ) {
      var pane = _current_item.get_pane( this );
      if( pane != null ) {
        pane.clear_current();
      }
      _current_item.clear_position();
    }
  }

  //-------------------------------------------------------------
  // Changes the currently selected item to the given pane type
  public void set_current_item_to_type( NoteItemType type ) {
    if( _current_item.is_valid() ) {

      var row = _current_item.row;
      var col = _current_item.col;

      // Create the new item
      var note_row = _note.get_row( row );
      var new_item = type.create( note_row );
      note_row.convert_note_item( col, new_item );

      // Remove the old pane from the pane row
      var row_pane = _current_item.get_row_pane( this );
      row_pane.delete_pane( col );

      // Add the modified pane back into the pane row
      add_pane( new_item, row, col, true, true );
    }
  }

  //-------------------------------------------------------------
  // Adds the contents of the current note into the content area
  public void populate( Note note ) {

    _note = note;
    _rows = 0;

    Utils.clear_box( this );

    for( int i=0; i<_note.rows(); i++ ) {
      var row = _note.get_row( i );
      for( int j=0; j<row.size(); j++ ) {
        add_pane( _note.get_item( i, j ), i, j, (j > 0), false );
      }
    }

    // Make sure that the first item has the focus
    if( _note.rows() > 0 ) {
      get_pane( 0, 0 ).grab_item_focus( TextCursorPlacement.START );
    }

  }

  //-------------------------------------------------------------
  // Returns the row at the given location.
  public NoteItemPaneRow? get_row( int pos ) {
    return( (NoteItemPaneRow)Utils.get_child_at_index( this, pos ) );
  }

  //-------------------------------------------------------------
  // Returns the pane at the given row/col location.
  public NoteItemPane? get_pane( int row, int col ) {
    var row_pane = get_row( row );
    return( (row_pane != null) ? row_pane.get_pane( col ) : null );
  }

  //-------------------------------------------------------------
  // Returns the pane associated with the given NoteItem.
  public NoteItemPane? get_pane_from_item( NoteItem item ) {
    int row, col;
    if( _note.get_item_location( item, out row, out col ) ) {
      return( get_pane( row, col ) );
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Makes sure that the given pane is within view.
  public void show_pane( NoteItemPane pane ) {

    Timeout.add( 100, () => {
      Allocation child_alloc, parent_alloc;

      get_allocation( out parent_alloc );
      pane.get_allocation( out child_alloc );

      see( (child_alloc.y + parent_alloc.y), child_alloc.height );

      return( false );
    });

  }

}
