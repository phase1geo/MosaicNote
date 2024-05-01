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

  private Stack _stack;

  private DropDown _item_selector;
  private Entry    _title;
  private Box      _created_box;
  private Label    _created;
  private Box      _content;
  private int      _current_item = -1;

	// Default constructor
	public NotePanel() {

    Object(
      orientation: Orientation.VERTICAL,
      spacing: 5,
      margin_top: 5,
      margin_bottom: 5,
      margin_start: 5,
      margin_end: 5
    );

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

  }

  // Creates the blank UI
  private Widget create_blank_ui() {

    var none = new Label( _( "No Note Selected" ) );

    return( none );

  }

  // Creates the note UI
  private Widget create_note_ui() {

    string[] item_types = { _( "Markdown" ), _( "Code" ), _( "Image" ) };

    _item_selector = new DropDown.from_strings( item_types ) {
      halign = Align.START,
      show_arrow = true,
      selected = 0,
      sensitive = false
    };

    _item_selector.notify["selected"].connect(() => {
      stdout.printf( "Item selector activated\n" );
      NoteItem new_item;
      switch( _item_selector.get_selected() ) {
        case 0 :  new_item = new NoteItemMarkdown();  break;
        case 1 :  new_item = new NoteItemCode();  break;
        case 2 :  new_item = new NoteItemImage();  break;
        default :  assert_not_reached();
      }
      stdout.printf( "Converting note item: %d\n", _current_item );
      _note.convert_note_item( _current_item, new_item );

      var w = Utils.get_child_at_index( _content, _current_item );
      _content.remove( w );
      switch( _item_selector.get_selected() ) {
        case 0 :  w = add_markdown_item( (NoteItemMarkdown)new_item, _current_item );  break;
        case 1 :  w = add_code_item( (NoteItemCode)new_item, _current_item );  break;
        case 2 :  w = add_image_item( (NoteItemImage)new_item, _current_item );  break;
        default :  assert_not_reached();
      }
      w.grab_focus();

    });

    var created_lbl = new Label( _( "Created:" ) );
    _created = new Label( "" );
    _created_box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.END,
      hexpand = true,
      visible = false
    };
    _created_box.append( created_lbl );
    _created_box.append( _created );

    var hbox = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL
    };
    hbox.append( _item_selector );
    hbox.append( _created_box );

    _title = new Entry() {
      has_frame = false,
      placeholder_text = _( "Title (Optional)" ),
      halign = Align.FILL
    };

    _title.activate.connect(() => {
      if( _note != null ) {
        _note.title = _title.text;
      }
      var first_item = Utils.get_child_at_index( _content, 0 );
      first_item.grab_focus();
    });

    var separator = new Separator( Orientation.HORIZONTAL );

    _content = new Box( Orientation.VERTICAL, 5 ) {
      halign = Align.FILL,
      valign = Align.START,
      vexpand = true
    };

    var sw = new ScrolledWindow() {
      halign = Align.FILL,
      valign = Align.FILL,
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = _content
    };

    // Add an initial markdown item
    add_markdown_item( null );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( hbox );
    box.append( _title );
    box.append( separator );
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

  private void populate_content() {

    Utils.clear_box( _content );

    if( _note.size() > 0 ) {
      for( int i=0; i<_note.size(); i++ ) {
        var item = _note.get_item( i );
        switch( item.name ) {
          case "markdown" :  add_markdown_item( (NoteItemMarkdown)item );  break;
          case "code"     :  add_code_item( (NoteItemCode)item );          break;
          case "image"    :  add_image_item( (NoteItemImage)item );        break;
          default         :  assert_not_reached();
        }
      }
    } else {
      add_markdown_item( null );
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

  private void handle_text_events( GtkSource.View text ) {

    var key = new EventControllerKey();

    text.add_controller( key );

    key.key_pressed.connect((keyval, keycode, state) => {
      if( (bool)(state & Gdk.ModifierType.SHIFT_MASK) && (keyval == Gdk.Key.Return) ) {
        var index = Utils.get_child_index( _content, text );
        var item  = new NoteItemCode();
        _note.add_note_item( (uint)(index + 1), item );
        var w = add_code_item( item, index );
        w.grab_focus();
        return( true );
      }
      return( false );
    });

  }

  private void add_item_to_content( Widget w, int pos = -1 ) {
    if( pos == -1 ) {
      _content.append( w );
    } else {
      var sibling = Utils.get_child_at_index( _content, pos );
      _content.insert_child_after( w, sibling );
    }
  }

  // Sets the current item and updates the UI
  private void set_current_item( int index ) {
    _current_item = index;
    _item_selector.sensitive = (index != -1);
    if( index != -1 ) {
      var item = _note.get_item( index );
      switch( item.name ) {
        case "markdown" :  _item_selector.selected = 0;  break;
        case "code"     :  _item_selector.selected = 1;  break;
        case "image"    :  _item_selector.selected = 2;  break;
        default         :  assert_not_reached();
      }
    }
  }

  private Widget add_markdown_item( NoteItemMarkdown? item, int pos = -1 ) {

    var lang_mgr = new GtkSource.LanguageManager();
    var lang     = lang_mgr.get_language( "markdown" );

    var buffer   = new GtkSource.Buffer.with_language( lang ) {
      highlight_syntax = true,
      enable_undo      = true,
      text             = (item == null) ? "" : item.content
    };

    var focus = new EventControllerFocus();
    var text = new GtkSource.View.with_buffer( buffer ) {
      halign    = Align.FILL,
      valign    = Align.FILL,
      vexpand   = true,
      wrap_mode = WrapMode.WORD,
      editable  = true
    };

    set_text_height( text );
    handle_text_events( text );

    text.add_controller( focus );

    focus.enter.connect(() => {
      set_current_item( Utils.get_child_index( _content, text ) );

      // Make the UI display Markdown toolbar
      // text.has_frame = true;
    });

    focus.leave.connect(() => {
      if( item != null ) {
        item.content = buffer.text;
      }
    });

    add_item_to_content( text, pos );

    return( text );

  }

  private Widget add_code_item( NoteItemCode? item, int pos = -1 ) {

    var lang_mgr = new GtkSource.LanguageManager();
    var lang     = lang_mgr.get_language( item.lang );

    var scheme_mgr = new GtkSource.StyleSchemeManager();
    /*
    var scheme_ids = scheme_mgr.get_scheme_ids();
    foreach( var scheme_id in scheme_ids ) {
      stdout.printf( "  scheme_id: %s\n", scheme_id );
    }
    */
    var scheme     = scheme_mgr.get_scheme( "oblivion" );

    var buffer   = new GtkSource.Buffer.with_language( lang ) {
      highlight_syntax = true,
      enable_undo      = true,
      style_scheme     = scheme,
      text             = (item == null) ? "" : item.content
    };

    var focus = new EventControllerFocus();
    var text = new GtkSource.View.with_buffer( buffer ) {
      halign    = Align.FILL,
      valign    = Align.FILL,
      vexpand   = true,
      wrap_mode = WrapMode.NONE,
      editable  = true,
      show_line_numbers = true,
      show_line_marks = true,
      auto_indent = true,
      indent_width = 3,
      insert_spaces_instead_of_tabs = true,
      smart_backspace = true,
      tab_width = 3,
      monospace = true
    };

    set_text_height( text );
    handle_text_events( text );

    text.add_controller( focus );

    focus.enter.connect(() => {
      set_current_item( Utils.get_child_index( _content, text ) );
      // Make the UI display Markdown toolbar
    });

    focus.leave.connect(() => {
      if( item != null ) {
        item.content = buffer.text;
      }
    });

    add_item_to_content( text, pos );

    return( text );

  }

  private Widget add_image_item( NoteItemImage item, int pos = -1 ) {

    var label = new Label( "This is an image" );

    add_item_to_content( label, pos );

    return( label );

  }

}