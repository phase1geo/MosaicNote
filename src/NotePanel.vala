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

public class NotePanel : Box {

  private Note  _note;

  private MainWindow _win;
  private Stack      _stack;

  private DropDown _item_selector;
  private Stack    _toolbar_stack;
  private Entry    _title;
  private Box      _created_box;
  private Label    _created;
  private Box      _content;
  private int      _current_item = -1;
  private bool     _ignore = false;

  private SpellChecker _spell;

	// Default constructor
	public NotePanel( MainWindow win ) {

    Object(
      orientation: Orientation.VERTICAL,
      spacing: 5,
      margin_top: 5,
      margin_bottom: 5,
      margin_start: 5,
      margin_end: 5
    );

    _win = win;

    _stack = new Stack() {
      hhomogeneous = true,
      vhomogeneous = true,
      halign       = Align.FILL,
      valign       = Align.FILL
    };

    _stack.add_named( create_blank_ui(), "blank" );
    _stack.add_named( create_note_ui(), "note" );
    _stack.visible_child_name = "blank";

    append( _stack );

    // Initialize the spell checker
    initialize_spell_checker();

    // Handle any theme updates
    update_theme();
    MosaicNote.settings.changed.connect((key) => {
      switch( key ) {
        case "editor-font-family" :
        case "editor-font-size"   :  update_theme();  break;
      }
    });

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


  // Creates the blank UI
  private Widget create_blank_ui() {

    var none = new Label( _( "No Note Selected" ) );

    return( none );

  }

  // Creates the note UI
  private Widget create_note_ui() {

    string[] item_types = {};
    for( int i=0; i<NoteItemType.NUM; i++ ) {
      var type = (NoteItemType)i;
      item_types += type.label();
    }

    _item_selector = new DropDown.from_strings( item_types ) {
      halign = Align.START,
      show_arrow = true,
      selected = 0,
      sensitive = false
    };

    _item_selector.notify["selected"].connect(() => {
      if( _ignore ) {
        _ignore = false;
        return;
      }
      var type     = (NoteItemType)_item_selector.get_selected();
      var new_item = type.create();
      _note.convert_note_item( _current_item, new_item );

      var w = get_item( _current_item );
      _content.remove( w );
      switch( type ) {
        case NoteItemType.MARKDOWN :  add_markdown_item( (NoteItemMarkdown)new_item, _current_item );  break;
        case NoteItemType.CODE     :  add_code_item( (NoteItemCode)new_item, _current_item );  break;
        case NoteItemType.IMAGE    :  add_image_item( (NoteItemImage)new_item, _current_item );  break;
        default                    :  break;
      }
      grab_focus_of_item( _current_item );
    });

    // Create the toolbar stack for each item type
    _toolbar_stack = new Stack() {
      halign = Align.FILL,
      hexpand = true
    };
    _toolbar_stack.add_named( new ToolbarItem(), "none" );
    for( int i=0; i<NoteItemType.NUM; i++ ) {
      var type = (NoteItemType)i;
      _toolbar_stack.add_named( type.create_toolbar(), type.to_string() );
    }
    _toolbar_stack.visible_child_name = "none";

    var created_lbl = new Label( _( "Created:" ) );
    _created = new Label( "" );
    _created_box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.END,
      hexpand = true,
      visible = false
    };
    _created_box.append( created_lbl );
    _created_box.append( _created );

    var hbox = new Box( Orientation.HORIZONTAL, 10 ) {
      halign = Align.FILL
    };
    hbox.append( _item_selector );
    hbox.append( _toolbar_stack );
    hbox.append( _created_box );

    _title = new Entry() {
      has_frame = false,
      placeholder_text = _( "Title (Optional)" ),
      halign = Align.FILL
    };
    _title.add_css_class( "note-title" );

    _title.activate.connect(() => {
      if( _note != null ) {
        _note.title = _title.text;
      }
      grab_focus_of_item( 0 );
    });

    var separator1 = new Separator( Orientation.HORIZONTAL );
    var separator2 = new Separator( Orientation.HORIZONTAL );

    _content = new Box( Orientation.VERTICAL, 10 ) {
      halign = Align.FILL,
      valign = Align.START,
      vexpand = true,
      margin_bottom = 200
    };

    var sw = new ScrolledWindow() {
      halign = Align.FILL,
      valign = Align.FILL,
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = _content
    };

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( hbox );
    box.append( separator1 );
    box.append( _title );
    box.append( separator2 );
    box.append( sw );

    return( box );

	}

  // Populates the note panel UI with the contents of the provided note.  If note is
  // null, clears the UI.
  public void populate_with_note( Note? note ) {

    _note = note;

    if( _note != null ) {

      _created_box.visible = true;
      _created.label = note.created.format( "%b%e, %Y" );
      _title.text    = note.title;
      _title.grab_focus();
      _stack.visible_child_name = "note";

      populate_content();

    } else {
      _stack.visible_child_name = "blank";
    }

  }

  /* Adds the contents of the current note into the content area */
  private void populate_content() {
    Utils.clear_box( _content );
    for( int i=0; i<_note.size(); i++ ) {
      insert_content_item( _note.get_item( i ) );
    }
  }

  /* Inserts the given NoteItem at the given position */
  private Widget insert_content_item( NoteItem item, int pos = -1 ) {
    switch( item.item_type ) {
      case NoteItemType.MARKDOWN :  return( add_markdown_item( (NoteItemMarkdown)item, pos ) );
      case NoteItemType.CODE     :  return( add_code_item( (NoteItemCode)item, pos ) );
      case NoteItemType.IMAGE    :  return( add_image_item( (NoteItemImage)item, pos ) );
      default                    :  assert_not_reached();
    }
  }

  // Gets the next text item.
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

  // Returns the item at the given position
  private Widget? get_item( int pos ) {
    return( Utils.get_child_at_index( _content, pos ) );
  }

  // Returns the text item at the given index if it exists; otherwise, returns null.
  private GtkSource.View get_item_text( int pos ) {
    var w = get_item( pos );
    return( Utils.get_child_at_index( w, 0 ) as GtkSource.View );
  }

  // Returns the image item at the given index if it exists; otherwise, returns null.
  private Picture get_item_image( int pos ) {
    var w = get_item( pos );
    return( Utils.get_child_at_index( w, 0 ) as Picture );
  }

  // Grabs the focus of the note item at the specified position.
  private void grab_focus_of_item( int pos ) {
    if( _note.get_item( pos ).item_type.is_text() ) {
      get_item_text( pos ).grab_focus();
    } else {
      get_item_image( pos ).grab_focus();
    }
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
    var ins_index = above ? index : (index + 1);
    _note.add_note_item( (uint)ins_index, item );
    add_markdown_item( item, ins_index );
    grab_focus_of_item( ins_index );
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
    var new_item = item.item_type.create();

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

  // Adds and handles any text events.
  private void handle_text_events( GtkSource.View text ) {

    var key = new EventControllerKey();

    text.add_controller( key );

    key.key_pressed.connect((keyval, keycode, state) => {
      var shift   = (bool)(state & Gdk.ModifierType.SHIFT_MASK);
      var control = (bool)(state & Gdk.ModifierType.CONTROL_MASK);
      var index   = Utils.get_child_index( _content, text.parent );
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
        case Gdk.Key.slash :
          if( control ) {
            split_item( index );
            return( true );
          }
          break;
        case Gdk.Key.BackSpace :
          if( index > 0 ) {
            TextIter cursor;
            text.buffer.get_iter_at_mark( out cursor, text.buffer.get_insert() );
            if( cursor.is_start() && join_items( index ) ) {
              return( true );
            }
          }
          break;
        case Gdk.Key.Up :
          if( index > 0 ) {
            if( control ) {
              _note.move_item( index, (index - 1) );
              var w = get_item( index );
              _content.reorder_child_after( w, get_item( index - 2 ) );
              return( true );
            } else {
              TextIter cursor;
              text.buffer.get_iter_at_mark( out cursor, text.buffer.get_insert() );
              if( cursor.is_start() ) {
                index = get_next_text_item( index, true );
                if( index != -1 ) {
                  TextIter iter;
                  var t = get_item_text( index );
                  t.buffer.get_end_iter( out iter );
                  t.buffer.place_cursor( iter );
                  t.grab_focus();
                  return( true );
                }
              }
            }
          }
          return( false );
        case Gdk.Key.Down :
          if( index < (_note.size() - 1) ) {
            if( control ) {
              _note.move_item( index, (index + 1) );
              var w = get_item( index );
              _content.reorder_child_after( w, get_item( index + 1 ) );
              return( true );
            } else {
              TextIter cursor;
              text.buffer.get_iter_at_mark( out cursor, text.buffer.get_insert() );
              if( cursor.is_end() ) {
                index = get_next_text_item( index, false );
                if( index != -1 ) {
                  TextIter iter;
                  var t = get_item_text( index );
                  t.buffer.get_start_iter( out iter );
                  t.buffer.place_cursor( iter );
                  t.grab_focus();
                  return( true );
                }
              }
            }
          }
          return( false );
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
      var sibling = get_item( pos - 1 );
      _content.insert_child_after( w, sibling );
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

  private void set_line_spacing( NoteItem item, GtkSource.View text ) {

    var wrap    = MosaicNote.settings.get_int( "editor-line-spacing" );
    var spacing = (item.item_type == NoteItemType.MARKDOWN) ? (wrap * 4) : wrap;
    var above   = ((spacing % 2) == 0) ? (spacing / 2) : ((spacing - 1) / 2);
    var below   = spacing - above;

    text.pixels_above_lines = above;
    text.pixels_below_lines = below;
    text.pixels_inside_wrap = wrap;

  }

  private Widget add_text_item( NoteItem item, string lang_id, int pos = -1 ) {

    var lang_mgr = GtkSource.LanguageManager.get_default();
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
      editable  = true,
      enable_snippets = true,
      margin_top = 5,
      margin_bottom = 5,
      margin_start  = 5,
      margin_end    = 5
    };

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( text );

    item.item_type.initialize_text( text );

    set_line_spacing( item, text );
    set_text_height( text );
    handle_text_events( text );

    text.add_controller( focus );

    focus.enter.connect(() => {
      set_current_item( Utils.get_child_index( _content, box ), text );
      box.add_css_class( "active-item" );
    });

    focus.leave.connect(() => {
      item.content = buffer.text;
      box.remove_css_class( "active-item" );
    });

    MosaicNote.settings.changed["editor-line-spacing"].connect(() => {
      set_line_spacing( item, text );
    });

    // Attach the spell checker temporarily
    if( item.item_type.spell_checkable() ) {
      set_spellchecker( text );
      MosaicNote.settings.changed["enable-spellchecker"].connect(() => {
        set_spellchecker( text );
      });
    }

    add_item_to_content( box, pos );

    return( box );

  }

  private void update_theme() {

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
    """.printf( font_family, font_size, font_size );
    provider.load_from_data( css_data.data );
    StyleContext.add_provider_for_display( get_display(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

  }

  // Adds a new Markdown item at the given position in the content area
  private Widget add_markdown_item( NoteItemMarkdown item, int pos = -1 ) {
    var frame = add_text_item( item, "markdown", pos );
    var text   = (GtkSource.View)Utils.get_child_at_index( frame, 0 );
    text.add_css_class( "markdown-text" );
    return( frame );
  }

  private Widget add_code_item( NoteItemCode item, int pos = -1 ) {

    var frame  = add_text_item( item, item.lang, pos );
    var text   = (GtkSource.View)Utils.get_child_at_index( frame, 0 );
    var buffer = (GtkSource.Buffer)text.buffer;

    var scheme_mgr = new GtkSource.StyleSchemeManager();
    var scheme     = scheme_mgr.get_scheme( MosaicNote.settings.get_string( "default-theme" ) );
    buffer.style_scheme = scheme;

    text.add_css_class( "code-text" );

    var im_context = new GtkSource.VimIMContext();
    im_context.set_client_widget( text );

    var key = new EventControllerKey();
    key.set_im_context( im_context );
    key.set_propagation_phase( PropagationPhase.CAPTURE );

    // TODO - Handle command_bar_text and command_text

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

    return( frame );

  }

  private Widget add_image_item( NoteItemImage item, int pos = -1 ) {

    var image = new Picture() {
      halign = Align.FILL,
      valign = Align.FILL // ,
    };

    if( item.uri == "" ) {

      var dialog = Utils.make_file_chooser( _( "Open Image" ), _win, FileChooserAction.OPEN, _( "Open" ) );

      dialog.response.connect((id) => {
        if( id == ResponseType.ACCEPT ) {
          var file = dialog.get_file();
          if( file != null ) {
            item.uri = file.get_uri();
            image.file = file;
          }
        } else {
          stdout.printf( "NEED TO REMOVE IMAGE ITEM\n" );
        }
        dialog.destroy();
      });

      dialog.show();

    } else {

      image.file = File.new_for_uri( item.uri );

    }

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( image );
    box.set_size_request( -1, 500 );

    add_item_to_content( box, pos );

    return( box );

  }

}