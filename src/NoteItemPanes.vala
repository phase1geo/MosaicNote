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
// Contains all of the note item panes for a single note.  Handles
// any resources that are shared by multiple panes (i.e., spellchecker).
// Provides functionality for manipulating panes within the browser.
public class NoteItemPanes : Box {

  private MainWindow   _win;
  private Note         _note;
  private int          _current_item = -1;
  private int          _size         = 0;
  private SpellChecker _spell;

  public signal void item_selected( NoteItemPane pane );
  public signal void note_link_clicked( string link );
  public signal void see( int y, int height );

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

    var pane = get_pane( _current_item );
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
  // Returns the number of panes stored in this structure
  public int size() {
    return( _size );
  }

  //-------------------------------------------------------------
  // Adds a new item of the given type at the given position
  public void add_new_item( NoteItemType type, int pos = -1 ) {
    var new_item = type.create( _note );
    _note.add_note_item( (uint)pos, new_item );
    add_item( new_item, pos );
    _win.undo.add_item( new UndoItemAdd( _note, ((pos == -1) ? (_size - 1) : pos) ) );
  }

  //-------------------------------------------------------------
  // Adds an item to the UI at the given position
  public void add_item( NoteItem item, int pos = -1 ) {

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

    pane.add_item.connect((above, type) => {
      var index = Utils.get_child_index( this, pane );
      add_new_item( ((type == null) ? NoteItemType.MARKDOWN : type), (above ? index : (index + 1)) );
      // pane.set_as_current( "pane.add_item (%s)".printf( item.content ) );
    });

    pane.remove_item.connect((forward, record_undo) => {
      var index = Utils.get_child_index( this, pane );
      var size  = _size;
      if( record_undo ) {
        _win.undo.add_item( new UndoItemDelete( _note, index ) );
      }
      remove( pane );
      _size--;
      _note.delete_note_item( index );
      if( (forward || (index == 0)) && (get_pane( index ) != null) ) {
        var next_pane = get_pane( index );
        show_pane( next_pane );
        next_pane.grab_item_focus( TextCursorPlacement.NO_CHANGE );
      } else if( (!forward || (index == (size - 1))) && (get_pane( index - 1 ) != null) ) {
        var prev_pane = get_pane( index - 1 );
        show_pane( prev_pane );
        prev_pane.grab_item_focus( TextCursorPlacement.NO_CHANGE );
      } else {
        add_new_item( NoteItemType.MARKDOWN, 0 );
      }
    });

    pane.change_item.connect((type) => {
      set_current_item_to_type( type );
    });

    pane.move_item.connect((up, record_undo) => {
      var index = Utils.get_child_index( this, pane );
      var prev  = get_pane( index - 1 );
      var curr  = get_pane( index );
      var next  = get_pane( index + 1 );
      if( up ) {
        curr.prev_pane = prev.prev_pane;
        curr.next_pane = prev;
        prev.prev_pane = curr;
        prev.next_pane = next;
        if( next != null ) {
          next.prev_pane = curr;
        }
        _note.move_item( index, (index - 1) );
        reorder_child_after( get_pane( index ), get_pane( index - 2 ) );
      } else {
        curr.prev_pane = next;
        curr.next_pane = next.next_pane;
        next.prev_pane = prev;
        next.next_pane = curr;
        if( prev != null ) {
          prev.next_pane = next;
        }
        _note.move_item( index, (index + 1) );
        reorder_child_after( get_pane( index ), get_pane( index + 1 ) );
      }
      show_pane( curr );
      if( record_undo ) {
        _win.undo.add_item( new UndoItemMove( _note, index, up ) );
      }
    });

    pane.set_as_current.connect((msg) => {
      if( _current_item == -1 ) {
        _current_item = Utils.get_child_index( this, pane );
        item_selected( pane );
      } else if( _current_item != Utils.get_child_index( this, pane ) ) {
        var other_pane = (NoteItemPane)Utils.get_child_at_index( this, _current_item );
        if( other_pane != null ) {
          other_pane.clear_current();
        }
        _current_item = Utils.get_child_index( this, pane );
        item_selected( pane );
      }
      show_pane( pane );
    });

    pane.note_link_clicked.connect((link) => {
      note_link_clicked( link );
    });

    save.connect(() => {
      pane.save();
    });

    // Add the pane at the given position
    if( pos == -1 ) {
      var last_pane = get_pane( _size - 1 );
      if( last_pane != null ) {
        last_pane.next_pane = pane;
        pane.prev_pane = last_pane;
      }
      append( pane );
    } else if( pos == 0 ) {
      var first_pane = get_pane( 0 );
      if( first_pane != null ) {
        first_pane.prev_pane = pane;
        pane.next_pane = first_pane;
      }
      prepend( pane );
    } else {
      var sibling = get_pane( pos - 1 );
      insert_child_after( pane, sibling );
      pane.prev_pane = sibling;
      pane.next_pane = sibling.next_pane;
      sibling.next_pane = pane;
    }

    _size++;

    // Make sure that the pane is within view
    show_pane( pane );

    // Make sure that the new pane has the focus
    if( !_note.locked ) {
      pane.grab_item_focus( TextCursorPlacement.START );
    } else {
      pane.clear_current();
    }

  }

  //-------------------------------------------------------------
  // Clears the current item.
  public void clear_current_item() {
    if( _current_item != -1 ) {
      var pane = (NoteItemPane)Utils.get_child_at_index( this, _current_item );
      pane.clear_current();
      _current_item = -1;
    }
  }

  //-------------------------------------------------------------
  // Changes the currently selected item to the given pane type
  public void set_current_item_to_type( NoteItemType type ) {

    var new_item = type.create( _note );
    _note.convert_note_item( _current_item, new_item );

    var pane = get_pane( _current_item );
    remove( pane );
    _size--;

    add_item( new_item, _current_item );

  }

  //-------------------------------------------------------------
  // Adds the contents of the current note into the content area
  public void populate( Note note ) {

    _note = note;
    _size = 0;

    Utils.clear_box( this );

    for( int i=0; i<_note.size(); i++ ) {
      add_item( _note.get_item( i ) );
    }

  }

  //-------------------------------------------------------------
  // Returns the item at the given position
  public NoteItemPane? get_pane( int pos ) {
    return( (NoteItemPane)Utils.get_child_at_index( this, pos ) );
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