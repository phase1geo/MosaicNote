/*
* Copyright (c) 2024-2026 (https://github.com/phase1geo/MosaicNote)
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
  public NoteItemPos.from_pane( NoteItemPane pane ) {
    var pane_row = (NoteItemPaneRow)pane.get_parent().get_parent();
    var parent   = pane_row.get_parent();
    _valid       = true;
    _col         = pane_row.get_pane_col( pane );
    _row         = Utils.get_child_index( parent, pane_row );
  }
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
  public NoteItemPane? get_next_pane( Widget panes, bool vertical = true ) {
    if( vertical ) {
      var pane_row = (NoteItemPaneRow)Utils.get_child_at_index( panes, (_row + 1) );
      return( (pane_row == null) ? null : pane_row.get_pane( _col ) );
    } else {
      var pane_row = (NoteItemPaneRow)Utils.get_child_at_index( panes, _row );
      return( (pane_row == null) ? null : pane_row.get_pane( _col + 1 ) );
    }
  }
  public NoteItemPane? get_prev_pane( Widget panes, bool vertical = true ) {
    if( vertical ) {
      var pane_row = (NoteItemPaneRow)Utils.get_child_at_index( panes, (_row - 1) );
      return( (pane_row == null) ? null : pane_row.get_pane( _col ) );
    } else {
      var pane_row = (NoteItemPaneRow)Utils.get_child_at_index( panes, _row );
      return( (pane_row == null) ? null : pane_row.get_pane( _col - 1 ) );
    }
  }
  public static Widget row_box_from_pane( Widget pane ) {
    return( pane.get_parent().get_parent().get_parent() );
  }
  public string to_string() {
    return( "valid: %s, row: %d, col: %d".printf( _valid.to_string(), _row, _col ) );
  }
}

//-------------------------------------------------------------
// Used to indicate a direction of movement.
public enum MoveDirection {
  UP,
  DOWN,
  LEFT,
  RIGHT;

  public string to_string() {
    switch( this ) {
      case UP    :  return( "up" );
      case DOWN  :  return( "down" );
      case LEFT  :  return( "left" );
      case RIGHT :  return( "right" );
      default    :  assert_not_reached();
    }
  }

  public bool is_vertical() {
    return( (this == UP) || (this == DOWN) );
  }

  public bool is_horizontal() {
    return( (this == LEFT) || (this == RIGHT) );
  }
}

//-------------------------------------------------------------
// Contains all of the note item panes for a single note.  Handles
// any resources that are shared by multiple panes (i.e., spellchecker).
// Provides functionality for manipulating panes within the browser.
public class NoteItemPanes : Box {

  private MainWindow    _win;
  private Note          _note;
  private NoteItemPane? _current_item = null;
  private int           _rows = 0;
  private SpellChecker  _spell;

  public signal void item_removed( NoteItemPane pane );
  public signal void item_selected( NoteItemPane pane );
  public signal void note_link_clicked( string link );
  public signal void footnote_clicked( string link );
  public signal void see( int y, int height );
  public signal void show_images( Array<NoteItem> items, int index );
  public signal void update_all_footnotes();

  public signal void save();

  //-------------------------------------------------------------
  // Default constructor
  public NoteItemPanes( MainWindow win ) {

    Object(
      orientation: Orientation.VERTICAL,
      spacing: 5
    );

    _win = win;

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

    if( _current_item != null ) {
      _current_item.populate_extra_menu();
    }

  }

  //-------------------------------------------------------------
  // Returns the text that is currently being edited.
  public NoteItemPane get_current_pane() {
    return( _current_item );
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

    // Check to see if the given language exists
    lang_list.foreach((elem) => {
      if( elem == lang ) {
        _spell.set_language( lang );
        lang_exists = true;
        return( false );
      }
      return( true );
    });

    // Based on the search, set the language to use in the spell checker
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
    var new_pane = add_pane( new_item, row, col, add_to_row, true );
    new_pane.set_as_current( "add-new-item" );
    _win.undo.add_item( new UndoItemAdd( _note, row, col ) );
  }

  //-------------------------------------------------------------
  // Adds an item to the UI at the given position.  Set pos to -1
  // to append the item at the end of the current item set.
  public NoteItemPane? add_pane( NoteItem item, int row, int col, bool add_to_row, bool show ) {

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
      default                    :  return( null );
    }

    pane.add_item.connect((dir, type) => {
      var pos     = new NoteItemPos.from_pane( pane );
      var row_pos = pos.row;
      var col_pos = pos.col;
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
      var pos      = new NoteItemPos.from_pane( pane );
      var pane_row = (NoteItemPaneRow)pane.get_parent().get_parent();
      var row_pos  = pos.row;
      var col_pos  = pos.col;
      var rows     = _rows;
      if( record_undo ) {
        _win.undo.add_item( new UndoItemDelete( _note, pos.row, pos.col ) );
      }
      item_removed( pane );
      pane_row.delete_pane( pos.col );
      if( pane_row.size == 0 ) {
        remove( pane_row );
        _rows--;
      }
      _note.delete_item( pos.row, pos.col );
      if( (forward || (pos.row == 0)) && (get_pane( pos.row, 0 ) != null) ) {
        var next_pane = get_pane( pos.row, 0 );
        show_pane( next_pane );
        next_pane.grab_item_focus( TextCursorPlacement.NO_CHANGE );
      } else if( (!forward || (pos.row == (rows - 1))) && (get_pane( (pos.row - 1), 0 ) != null) ) {
        var prev_pane = get_pane( (pos.row - 1), 0 );
        show_pane( prev_pane );
        prev_pane.grab_item_focus( TextCursorPlacement.NO_CHANGE );
      } else {
        add_new_item( NoteItemType.MARKDOWN );
      }
    });

    pane.remove_row.connect((forward, record_undo) => {
      var pos      = new NoteItemPos.from_pane( pane );
      var pane_row = (NoteItemPaneRow)pane.get_parent().get_parent();
      var row_pos  = pos.row;
      var rows     = _rows;
      if( record_undo ) {
        _win.undo.add_item( new UndoRowDelete( _note, pos.row ) );
      }
      remove( pane_row );
      _rows--;
      _note.delete_row( pos.row );
      if( (forward || (pos.row == 0)) && (get_pane( pos.row, 0 ) != null) ) {
        var next_pane = get_pane( pos.row, 0 );
        show_pane( next_pane );
        next_pane.grab_item_focus( TextCursorPlacement.NO_CHANGE );
      } else if( (!forward || (pos.row == (rows - 1))) && (get_pane( (pos.row - 1), 0 ) != null) ) {
        var prev_pane = get_pane( (pos.row - 1), 0 );
        show_pane( prev_pane );
        prev_pane.grab_item_focus( TextCursorPlacement.NO_CHANGE );
      } else {
        add_new_item( NoteItemType.MARKDOWN );
      }
    });

    pane.change_item.connect((type) => {
      set_current_item_to_type( type );
    });

    pane.move_item.connect((move_row, dir, record_undo) => {
      var pos   = new NoteItemPos.from_pane( pane );
      var moved = false;

      stdout.printf( "In move_item, move_row: %s, dir: %s, record: %s\n", move_row.to_string(), dir.to_string(), record_undo.to_string() );

      // If we need to move the entire current row, do that now
      if( move_row ) {
        moved = move_item_row( pos.row, dir );

      // If we need to move just the current item, do that now
      } else {
        moved = move_item( pos.row, pos.col, dir );
      }

      // Make sure the pane is in view
      show_pane( pane );

      // Record the move
      if( record_undo && moved ) {
        _win.undo.add_item( new UndoItemMove( pane, move_row, dir ) );
      }

    });

    pane.set_as_current.connect((msg) => {
      if( _current_item == null ) {
        _current_item = pane;
        item_selected( pane );
      } else {
        if( _current_item != pane ) {
          if( _current_item != null ) {
            _current_item.clear_current();
            update_all_footnotes();
          }
          _current_item = pane;
          item_selected( pane );
        }
      }
      show_pane( pane );
    });

    pane.note_link_clicked.connect((link) => {
      note_link_clicked( link );
    });

    pane.footnote_clicked.connect((link) => {
      footnote_clicked( link );
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
        prepend( row_pane );
      } else {
        var sibling_row = get_row( row - 1 );
        insert_child_after( row_pane, sibling_row );
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

    return( pane );

  }

  //-------------------------------------------------------------
  // Moves the given item's row up or down (based on direction).
  private bool move_item_row( int row, MoveDirection dir ) {

    // Move the given row up, if possible
    if( (dir == MoveDirection.UP) && (row > 0) ) {
      _note.move_row( row, (row - 1) );
      reorder_child_after( get_row( row ), get_row( row - 2 ) );
      return( true );

    // Move the given row down, if possible
    } else if( (dir == MoveDirection.DOWN) && ((row + 1) < _note.rows()) ) {
      _note.move_row( row, (row + 1) );
      reorder_child_after( get_row( row ), get_row( row + 1 ) );
      return( true );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Moves the current item to the location determined by dir.
  private bool move_item( int row, int col, MoveDirection dir ) {

    int new_row, new_col;
    bool add_to_row;

    // Figure out how to make the move
    _note.plan_move( row, col, dir, out new_row, out new_col, out add_to_row );

    stdout.printf( "In move_item, row: %d, col: %d, dir: %s, new_row: %d, row_col: %d, add: %s\n",
      row, col, dir.to_string(), new_row, new_col, add_to_row.to_string() );

    // Move the note item
    _note.move_item( row, col, new_row, new_col, add_to_row );

    // Move the pane to the new row, if necessary
    if( (row != new_row) || !add_to_row ) {
      var pane = get_pane( row, col );
      get_row( row ).delete_pane( col );
      if( get_row( row ).size == 0 ) {
        remove( get_row( row ) );
      }
      if( !add_to_row ) {
        var row_pane = new NoteItemPaneRow( _note.get_row( new_row ) );
        insert_child_after( row_pane, get_row( new_row - 1 ) );
        _rows++;
      }
      get_row( new_row ).add_pane( pane, new_col );
      return( true );

    // Move the pane within the current row, if necessary
    } else if( col != new_col ) {
      get_row( row ).move_pane( col, (dir == MoveDirection.LEFT) );
      return( true );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Clears the current item.
  public void clear_current_item() {
    if( _current_item != null ) {
      _current_item.clear_current();
      _current_item = null;
    }
  }

  //-------------------------------------------------------------
  // Changes the currently selected item to the given pane type
  public void set_current_item_to_type( NoteItemType type ) {

    if( _current_item != null ) {

      var pos = new NoteItemPos.from_pane( _current_item );

      // Create the new item
      var note_row = _note.get_row( pos.row );
      var new_item = type.create( note_row );
      note_row.convert_note_item( pos.col, new_item );

      // Remove the old pane from the pane row
      var row_pane = (NoteItemPaneRow)_current_item.get_parent().get_parent();
      row_pane.delete_pane( pos.col );

      // Add the modified pane back into the pane row
      var new_pane = add_pane( new_item, pos.row, pos.col, true, true );
      new_pane.set_as_current( "add-new-item" );

    }

  }

  //-------------------------------------------------------------
  // Adds the contents of the current note into the content area
  public void populate( Note note ) {

    NoteItemPane? first = null;

    _note = note;
    _rows = 0;

    Utils.clear_box( this );

    for( int i=0; i<_note.rows(); i++ ) {
      var row = _note.get_row( i );
      for( int j=0; j<row.size(); j++ ) {
        add_pane( _note.get_item( i, j ), i, j, (j > 0), false );
      }
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
      Graphene.Rect child_rect;
      if( pane.compute_bounds( this, out child_rect ) ) {
        Allocation parent_alloc;
        get_allocation( out parent_alloc );
        see( (int)(child_rect.get_y() + parent_alloc.y), (int)child_rect.get_height() );
      }
      return( false );
    });

  }

}
