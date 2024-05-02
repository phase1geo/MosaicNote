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

public class TextItem : Box {

  public NoteItem       _item;
  public GtkSource.View _text;

	// Default constructor
	public TextItem( NoteItem item ) {

    _item = item;

    var buffer = new GtkSource.Buffer();
    _text = new GtkSource.View.with_buffer( buffer );

  }

  // Sets the height of the text widget
  private void set_text_height( GtkSource.View text ) {

    TextIter iter;
    Gdk.Rectangle location;

    text.buffer.get_start_iter( out iter );
    text.get_iter_location( iter, out location );
    text.set_size_request( -1, (location.height + 2) );

  }

  // Adds a new item above or below the item at the given index.
  private void add_item( int index, bool above ) {

    var item = new NoteItemMarkdown();
    _note.add_note_item( (uint)(above ? index : (index + 1)), item );
    var w = add_markdown_item( item, (above ? index : (index + 1)) );
    w.grab_focus();

  }

  // Split the current item into two items at the insertion point.
  private void split_item( int index ) {

    // Get the current text widget and figure out the location of
    // the insertion cursor.
    var text   = (GtkSource.View)Utils.get_child_at_index( _content, index );
    var cursor = text.buffer.cursor_position;

    // Create a copy of the new item, assign it the text after
    // the insertion cursor, and remove the text after the insertion
    // cursor from the original item.
    var item     = _note.get_item( index );
    var first    = item.content.substring( 0, cursor ); 
    var last     = item.content.substring( cursor );
    var new_item = item.item_type.create();

    item.content = first;
    new_item.content = last;
    _note.add_note_item( (uint)(index + 1), new_item );

    // Update the original item contents and add the new item
    // after the original.
    text.buffer.text = item.content;
    text = (GtkSource.View)insert_content_item( new_item, (index + 1) );

    // Adjust the insertion cursor to the beginning of the new text
    TextIter iter;
    var insert = text.buffer.get_insert();
    text.buffer.get_start_iter( out iter );
    text.buffer.move_mark( insert, iter );

    text.grab_focus();

  }

  // Joins the item at the given index with the item above it.
  private bool join_items( int index ) {

    // Find the item above the current one that matches the type
    var above_index = (index - 1);
    var item_type   = _note.get_item( index ).item_type;
    while( (above_index >= 0) && (_note.get_item( above_index ).item_type != item_type) ) {
      above_index--;
    }

    // If we are unable to join with anything, return false immediately
    if( above_index == -1 ) {
      return( false );
    }

    // Merge the note text, delete the note item and delete the item from the content area
    var above_text   = (GtkSource.View)Utils.get_child_at_index( _content, above_index );
    var text         = (GtkSource.View)Utils.get_child_at_index( _content, index );
    var text_to_move = text.buffer.text;

    if( text_to_move != "" ) {

      // Update notes
      _note.get_item( above_index ).content += text_to_move;

      // Update above text UI
      TextIter iter;
      var insert = above_text.buffer.get_insert();
      above_text.buffer.get_iter_at_mark( out iter, insert );
      above_text.buffer.text += text.buffer.text;
      above_text.buffer.move_mark( insert, iter );

    }

    // Remove the current item
    _note.delete_note_item( (uint)index );
    _content.remove( text );

    // Grab the above text widget for keyboard input
    above_text.grab_focus();

    return( true );

  }

  // Adds and handles any text events.
  private void handle_text_events( GtkSource.View text ) {

    var key = new EventControllerKey();

    text.add_controller( key );

    key.key_pressed.connect((keyval, keycode, state) => {
      var shift   = (bool)(state & Gdk.ModifierType.SHIFT_MASK);
      var control = (bool)(state & Gdk.ModifierType.CONTROL_MASK);
      var index   = Utils.get_child_index( _content, text );
      switch( keyval ) {
        case Gdk.Key.Return : 
          if( control && shift ) {
            add_item( index, true );
            return( true );
          } else if( control ) {
            add_item( index, false );
            return( true );
          } else if( shift ) {
            split_item( index );
            return( true );
          }
          break;
        case Gdk.Key.BackSpace :
          if( index > 0 ) {
            TextIter start;
            text.buffer.get_iter_at_offset( out start, 0 );
            if( start.is_cursor_position() && join_items( index ) ) {
              return( true );
            }
          }
          break;
      }
      return( false );
    });

  }

  // Adds the given item
  private void add_item_to_content( Widget w, int pos = -1 ) {
    if( pos == -1 ) {
      _content.append( w );
    } else if( pos == 0 ) {
      _content.prepend( w );
    } else {
      var sibling = Utils.get_child_at_index( _content, (pos - 1) );
      _content.insert_child_after( w, sibling );
    }
  }

  // Sets the current item and updates the UI
  private void set_current_item( int index ) {
    _current_item = index;
    _item_selector.sensitive = (index != -1);
    if( index != -1 ) {
      var item = _note.get_item( index );
      _ignore = true;
      _item_selector.selected = item.item_type;
    }
  }

  private GtkSource.View add_text_item( NoteItem item, string lang_id, int pos = -1 ) {

    var lang_mgr = new GtkSource.LanguageManager();
    var lang     = lang_mgr.get_language( lang_id );

    var buffer   = new GtkSource.Buffer.with_language( lang ) {
      highlight_syntax = true,
      enable_undo      = true,
      text             = item.content
    };

    var focus = new EventControllerFocus();
    var text = new GtkSource.View.with_buffer( buffer ) {
      halign    = Align.FILL,
      valign    = Align.FILL,
      vexpand   = true,
      editable  = true
    };

    item.item_type.initialize_text( text );

    set_text_height( text );
    handle_text_events( text );

    text.add_controller( focus );

    focus.enter.connect(() => {
      set_current_item( Utils.get_child_index( _content, text ) );

      // Make the UI display Markdown toolbar
      // text.has_frame = true;
    });

    focus.leave.connect(() => {
      item.content = buffer.text;
    });

    add_item_to_content( text, pos );

    return( text );

  }

  // Adds a new Markdown item at the given position in the content area
  private Widget add_markdown_item( NoteItemMarkdown item, int pos = -1 ) {

    var text = add_text_item( item, "markdown", pos );

    return( text );

  }

  private Widget add_code_item( NoteItemCode item, int pos = -1 ) {

    var text = add_text_item( item, item.lang, pos );
    var buffer = (GtkSource.Buffer)text.buffer;

    var scheme_mgr = new GtkSource.StyleSchemeManager();
    var scheme     = scheme_mgr.get_scheme( "oblivion" );
    buffer.style_scheme = scheme;

    /*
    var scheme_ids = scheme_mgr.get_scheme_ids();
    foreach( var scheme_id in scheme_ids ) {
      stdout.printf( "  scheme_id: %s\n", scheme_id );
    }
    */

    return( text );

  }

  private Widget add_image_item( NoteItemImage item, int pos = -1 ) {

    var label = new Label( "This is an image" );

    add_item_to_content( label, pos );

    return( label );

  }

}