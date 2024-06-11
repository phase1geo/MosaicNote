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

public class NoteItemPanes : Box {

  private Note         _note;
  private int          _current_item = -1;
  private SpellChecker _spell;

  // Default constructor
  public NoteItemPanes() {

    // Initialize the spell checker
    initialize_spell_checker();

    add_css_class( "themed" );

    // Populates the UI with the current note content

  }

  private void initialize_spell_checker() {

    _spell = new SpellChecker();
    _spell.populate_extra_menu.connect( populate_extra_menu );

    update_spell_language();

  }

  private void populate_extra_menu( TextView view ) {

    var extra = new GLib.Menu();

    view.extra_menu = extra;

  }

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

  /* Sets the spellchecker for the current textview widget */
  private void set_spellchecker( GtkSource.View text ) {

    var enabled = MosaicNote.settings.get_boolean( "enable-spellchecker" );

    _spell.detach();

    if( enabled ) {
      _spell.attach( text );
    } else {
      _spell.remove_highlights( text );
    }

  }

  // Adds a new item of the given type at the given position
  public void add_new_item( NoteItemType type, int pos = -1 ) {
    var new_item = type.create( _note );
    _note.add_note_item( (uint)pos, new_item );
    add_item( new_item );
  }

  // Adds an item to the UI at the given position
  public void add_item( NoteItem item, int pos = -1 ) {

    NoteItemPane pane;
    switch( item.item_type ) {
      case NoteItemType.MARKDOWN :  pane = new NoteItemPaneMarkdown( item );  break;
      case NoteItemType.CODE     :  pane = new NoteItemPaneCode( item );      break;
      case NoteItemType.IMAGE    :  pane = new NoteItemPaneImage( item );     break;
      case NoteItemType.UML      :  pane = new NoteItemPaneUML( item );       break;
      default                    :  break;
    }

    pane.add_item.connect((above) => {
      var index = Utils.get_child_index( this, pane );
      add_new_item( NoteItemType.MARKDOWN, (above ? index : (index + 1)) );
    });

    pane.remove_item.connect(() => {
      var index = Utils.get_child_index( this, pane );
      remove( pane );
      _note.delete_note_item( index );
      if( get_pane( index ) != null ) {
        get_pane( index ).grab_focus_of_item();
      } else if( get_pane( index - 1 ) != null ) {
        get_pane( index - 1 ).grab_focus_of_item();
      } else {
        add_new_item( NoteItemType.MARKDOWN, -1 );
      }
    });

    pane.advance_to_next.connect((up) => {
      var index = Utils.get_child_index( this, pane );
      if( up && (index > 0) ) {
        _current_index = (index - 1);
      }
      if( !up && (index < (_note.size() - 1)) ) {
        _current_index = (index + 1);
      }
      _current_index = up ? (index - 1) : (index + 1);
      var pane = (NoteItemPane)Utils.get_child_at_index( this, _current_index );
      pane.grab_focus_of_item();
    });

    pane.set_as_current.connect(() => {
      _current_index = Utils.get_child_index( this, pane );
    });

    // Add the pane at the given position
    if( pos == -1 ) {
      append( w );
    } else if( pos == 0 ) {
      prepend( w );
    } else {
      var sibling = get_pane( pos - 1 );
      insert_child_after( w, sibling );
    }

    // Make sure that the new pane has the focus
    pane.grab_focus_of_item();

  }

  public void set_current_item_to_type( NoteItemType type ) {

    var new_item = type.create( _note );
    _note.convert_note_item( _current_item, new_item );

    var w = get_item( _current_item );
    remove( w );

    add_item( new_item, _current_item );

  }

  /* Adds the contents of the current note into the content area */
  private void populate( Note note ) {

    _note = note;

    Utils.clear_box( this );

    for( int i=0; i<_note.size(); i++ ) {
      add_item( _note.get_item( i ) );
    }

  }

  // Gets the next text item.
  public int get_next_text_item( int start_index, bool above ) {
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

  // Returns the item at the given position
  public NoteItemPane? get_pane( int pos ) {
    return( (NoteItemPane)Utils.get_child_at_index( this, pos ) );
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

  // Advances to the next or previous item content block, giving it keyboard
  // focus.
  private void advance_to_next( int index, bool up ) {
    var idx = index + (up ? -1 : 1);
    if( _note.get_item( idx ).item_type.is_text() ) {
      TextIter iter;
      var t = get_item_text( idx );
      if( up ) {
        t.buffer.get_end_iter( out iter );
      } else {
        t.buffer.get_start_iter( out iter );
      }
      t.buffer.place_cursor( iter );
      t.grab_focus();
    } else {
      var img = get_item_image( idx );
      img.grab_focus();
    }
  }

  private void set_toolbar_for_index( int index, GtkSource.View? view ) {
    var item = _note.get_item( index );
    if( item.item_type.is_text() ) {
      var toolbar = _toolbar_stack.get_child_by_name( item.item_type.to_string() );
      if( (toolbar as ToolbarMarkdown) != null ) {
        ((ToolbarMarkdown)toolbar).view = view;
      } else if( (toolbar as ToolbarCode) != null ) {
        ((ToolbarCode)toolbar).view = view;
      }
    }
  }

  // Sets the current item and updates the UI
  private void set_current_item( int index, GtkSource.View? view ) {
    _current_item = index;
    _item_selector.sensitive = (index != -1);
    if( index != -1 ) {
      var item = _note.get_item( index );
      _ignore = (_item_selector.selected != item.item_type);
      _item_selector.selected = item.item_type;
      set_toolbar_for_index( index, view );
      if( item.item_type.spell_checkable() ) {
        set_spellchecker( view );
      }
      _toolbar_stack.visible_child_name = item.item_type.to_string();
    }
  }

  private void update_theme( string theme ) {

    var style_mgr = GtkSource.StyleSchemeManager.get_default();
    var style     = style_mgr.get_scheme( theme );

    var font_family = MosaicNote.settings.get_string( "editor-font-family" );
    var font_size   = MosaicNote.settings.get_int( "editor-font-size" );

    var provider = new CssProvider();
    var css_data = """
      .markdown-text {
        font-family: %s;
        font-size: %dpt;
      }
      .code-text {
        font-family: monospace;
        font-size: %dpt;
      }
      .themed {
        background-color: %s;
      }
    """.printf( font_family, font_size, font_size, style.get_style( "text" ).background );
    provider.load_from_data( css_data.data );
    StyleContext.add_provider_for_display( get_display(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

    /* Update the affected content */
    if( _note != null ) {
      for( int i=0; i<_note.size(); i++ ) {
        get_pane( i ).set_buffer_style( style );
      }
    }

  }

}