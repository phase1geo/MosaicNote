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

public class NoteItemPane : Box {

  private NoteItem _item;

  protected NoteItem item {
    get {
      return( _item );
    }
  }

  public signal void add_item( bool above );
  public signal void remove_item();
  public signal void advance_to_next( bool up );
  public signal void set_as_current();

	// Default constructor
	public NoteItemPane( NoteItem item ) {

    Object(
      orientation: Orientation.VERTICAL,
      spacing: 5,
      margin_top: 5,
      margin_bottom: 5,
      margin_start: 5,
      margin_end: 5
    );

    _item = item;

    // Create the UI
    create_pane();

  }

  // Gets the next text item.
  // TBD
  private int get_next_text_item( int start_index, bool above ) {
    if( above ) {
      var index = (start_index - 1);
      while( (index >= 0) && !_note.get_item( index ).item_type.is_text() ) {
        index--;
      }
      return( index );
    } else {
      var index = (start_index + 1);
      while( (index < _note.size()) && !_note.get_item( index ).item_type.is_text() ) {
        index++;
      }
      return( (index == _note.size()) ? -1 : index );
    }
  }

  // Grabs the focus of the note item at the specified position.
  public virtual void grab_focus_of_item() {}

  // Sets the height of the text widget
  private void set_text_height( GtkSource.View text ) {

    TextIter iter;
    Gdk.Rectangle location;

    text.buffer.get_start_iter( out iter );
    text.get_iter_location( iter, out location );
    text.set_size_request( -1, (location.height + 2) );

  }

  // Split the current item into two items at the insertion point.
  private void split_item( int index ) {

    // Get the current text widget and figure out the location of
    // the insertion cursor.
    var text   = get_item_text( index );
    var cursor = text.buffer.cursor_position;

    // Create a copy of the new item, assign it the text after
    // the insertion cursor, and remove the text after the insertion
    // cursor from the original item.
    var item     = _note.get_item( index );
    item.content = text.buffer.text;
    var first    = item.content.substring( 0, cursor ); 
    var last     = item.content.substring( cursor );
    var new_item = item.item_type.create( _note );

    item.content = first;
    new_item.content = last;
    _note.add_note_item( (uint)(index + 1), new_item );

    // Update the original item contents and add the new item
    // after the original.
    text.buffer.text = item.content;
    insert_content_item( new_item, (index + 1) );
    text = get_item_text( index + 1 );

    // Adjust the insertion cursor to the beginning of the new text
    TextIter iter;
    text.buffer.get_start_iter( out iter );
    text.buffer.place_cursor( iter );

    text.grab_focus();

  }

  // Joins the item at the given index with the item above it.
  private bool join_items( int index ) {

    // Find the item above the current one that matches the type
    var above_index = get_next_text_item( index, true );

    // If we are unable to join with anything, return false immediately
    if( above_index == -1 ) {
      return( false );
    }

    // Merge the note text, delete the note item and delete the item from the content area
    var above_text   = get_item_text( above_index );
    var text         = get_item_text( index );
    var text_to_move = text.buffer.text;

    if( text_to_move != "" ) {

      // Update above text UI
      TextIter iter;
      above_text.buffer.get_end_iter( out iter );
      var above_end = above_text.buffer.create_mark( "__end", iter, true );
      above_text.buffer.insert( ref iter, text.buffer.text, text.buffer.text.length );
      above_text.buffer.get_iter_at_mark( out iter, above_end );
      above_text.buffer.place_cursor( iter );
      above_text.buffer.delete_mark( above_end );

    }

    // Remove the current item
    _note.delete_note_item( (uint)index );
    _content.remove( get_item( index ) );

    // Grab the above text widget for keyboard input
    above_text.grab_focus();

    return( true );

  }

  // Adds keyboard events when this note item has keyboard input focus.
  // Events will add new items, delete the current item, or move the
  // input focus to the next or previous item.
  protected void handle_key_events( Widget w ) {

    var key = new EventControllerKey();

    w.add_controller( key );

    key.key_pressed.connect((keyval, keycode, state) => {
      var shift   = (bool)(state & Gdk.ModifierType.SHIFT_MASK);
      var control = (bool)(state & Gdk.ModifierType.CONTROL_MASK);
      var index   = Utils.get_child_index( _content, w );
      switch( keyval ) {
        case Gdk.Key.Return :
          if( control && shift ) {
            add_item( index, true );
            return( true );
          } else if( shift ) {
            add_item( index, false );
            return( true );
          }
          break;
        case Gdk.Key.BackSpace :
          if( control ) {
            remove_item( index );
            return( true );
          }
          break;
        case Gdk.Key.Delete :
          if( control ) {
            remove_item( index );
            return( true );
          }
          break;
        case Gdk.Key.Up :
          if( index > 0 ) {
            if ( control ) {
              _note.move_item( index, (index - 1) );
              var item = get_item( index );
              _content.reorder_child_after( item, get_item( index - 2 ) );
              return( true );
            } else {
              advance_to_next( index, true );
              return( true );
            }
          }
          return( false );
        case Gdk.Key.Down :
          if( index < (_note.size() - 1) ) {
            if( control ) {
              _note.move_item( index, (index + 1) );
              var item = get_item( index );
              _content.reorder_child_after( item, get_item( index + 1 ) );
              return( true );
            } else {
              stdout.printf( "B Calling advance_to_next, index: %d\n", index );
              advance_to_next( index, false );
              return( true );
            }
          }
          return( false );
      }
      return( false );
    });
  }

  // Adds and handles any text events.
  private void handle_text_events( GtkSource.View text ) {

    var key = new EventControllerKey();

    text.add_controller( key );

    key.key_pressed.connect((keyval, keycode, state) => {
      var shift   = (bool)(state & Gdk.ModifierType.SHIFT_MASK);
      var control = (bool)(state & Gdk.ModifierType.CONTROL_MASK);
      var parent  = text.parent;
      var index   = Utils.get_child_index( _content, parent );
      while( (parent == null) || (index == -1) ) {
        parent = parent.parent;
        index  = Utils.get_child_index( _content, parent );
      }
      switch( keyval ) {
        case Gdk.Key.slash :
          if( control ) {
            split_item( index );
            return( true );
          }
          break;
        case Gdk.Key.BackSpace :
          if( (index > 0) && !control ) {
            TextIter cursor;
            text.buffer.get_iter_at_mark( out cursor, text.buffer.get_insert() );
            if( cursor.is_start() && join_items( index ) ) {
              return( true );
            }
          }
          break;
        case Gdk.Key.Up :
          if( (index > 0) && !control ) {
            TextIter cursor;
            text.buffer.get_iter_at_mark( out cursor, text.buffer.get_insert() );
            if( cursor.is_start() ) {
              advance_to_next( index, true );
              return( true );
            }
          }
          break;
        case Gdk.Key.Down :
          if( (index < (_note.size() - 1)) && !control ) {
            TextIter cursor;
            text.buffer.get_iter_at_mark( out cursor, text.buffer.get_insert() );
            if( cursor.is_end() ) {
              stdout.printf( "A Calling advance_to_next, index: %d\n", index );
              advance_to_next( index, false );
              return( true );
            }
          }
          break;
      }
      return( false );
    });

  }

  // Adds line spacing
  private void set_line_spacing( GtkSource.View text ) {

    var wrap    = MosaicNote.settings.get_int( "editor-line-spacing" );
    var spacing = (item.item_type == NoteItemType.MARKDOWN) ? (wrap * 4) : wrap;
    var above   = ((spacing % 2) == 0) ? (spacing / 2) : ((spacing - 1) / 2);
    var below   = spacing - above;

    text.pixels_above_lines = above;
    text.pixels_below_lines = below;
    text.pixels_inside_wrap = wrap;

  }

  protected GtkSource.View create_text( string lang_id ) {

    var lang_mgr = GtkSource.LanguageManager.get_default();
    var lang     = lang_mgr.get_language( lang_id );

    var buffer = new GtkSource.Buffer.with_language( lang ) {
      highlight_syntax = true,
      enable_undo      = true,
      text             = item.content
    };

    var focus = new EventControllerFocus();
    var text = new GtkSource.View.with_buffer( buffer ) {
      halign    = Align.FILL,
      valign    = Align.FILL,
      vexpand   = true,
      editable  = true,
      enable_snippets = true,
      margin_top    = 5,
      margin_bottom = 5,
      margin_start  = 5,
      margin_end    = 5
    };

    item.item_type.initialize_text( text );

    set_line_spacing( text );
    set_text_height( text );
    handle_text_events( text );

    text.add_controller( focus );

    focus.enter.connect(() => {
      set_as_current();
      add_css_class( "active-item" );
    });

    focus.leave.connect(() => {
      item.content = buffer.text;
      remove_css_class( "active-item" );
    });

    MosaicNote.settings.changed["editor-line-spacing"].connect(() => {
      set_line_spacing( text );
    });

    // Attach the spell checker temporarily
    if( item.item_type.spell_checkable() ) {
      set_spellchecker( text );
      MosaicNote.settings.changed["enable-spellchecker"].connect(() => {
        set_spellchecker( text );
      });
    }

    var im_context = new GtkSource.VimIMContext();
    im_context.set_client_widget( text );

    var key = new EventControllerKey();
    key.set_im_context( im_context );
    key.set_propagation_phase( PropagationPhase.CAPTURE );

    if( MosaicNote.settings.get_boolean( "editor-vim-mode" ) ) {
      text.add_controller( key );
    }

    MosaicNote.settings.changed["default-theme"].connect(() => {
      buffer.style_scheme = scheme_mgr.get_scheme( MosaicNote.settings.get_string( "default-theme" ) );
    });

    // Handle any changes to the Vim mode
    MosaicNote.settings.changed["editor-vim-mode"].connect(() => {
      if( MosaicNote.settings.get_boolean( "editor-vim-mode" ) ) {
        text.add_controller( key );
      } else {
        text.remove_controller( key );
      }
    });

    return( text );

  }

  public virtual void set_buffer_style( GtkSource.StyleScheme style ) {}

  // Returns any CSS data that is required for this pane
  public virtual string get_css_data() {
    return( "" );
  }

  // Adds a new UML item at the given position in the content area
  public virtual void create_pane() {}

}