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

  private Note?      _note = null;

  private MainWindow _win;
  private Stack      _stack;

  private TagBox   _tags;
  private DropDown _item_selector;
  private Stack    _toolbar_stack;
  private Button   _favorite;
  private Entry    _title;
  private Box      _created_box;
  private Label    _created;
  private Box      _content;
  private int      _current_item = -1;
  private bool     _ignore = false;

  private SpellChecker _spell;

  public signal void tag_added( string name, int note_id );
  public signal void tag_removed( string name, int note_id );
  public signal void save_note( Note note );

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

    // Initialize the language manager
    initialize_languages();

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

    // Initialize the theme
    update_theme( _win.themes.get_current_theme() );

    // Handle any theme updates
    MosaicNote.settings.changed.connect((key) => {
      switch( key ) {
        case "editor-font-family" :
        case "editor-font-size"   :  update_theme( _win.themes.get_current_theme() );  break;
      }
    });

    _win.themes.theme_changed.connect((theme) => {
      update_theme( theme );
    });

  }

  // Initialize the language manager to include the specialty languages that MosaicNote
  // provides (includes PlantUML).
  private void initialize_languages() {

    foreach( var data_dir in Environment.get_system_data_dirs() ) {
      var path = GLib.Path.build_filename( data_dir, "mosaic-note", "gtksourceview-5" );
      if( FileUtils.test( path, FileTest.EXISTS ) ) {
        var lang_path = GLib.Path.build_filename( path, "language-specs" );
        var manager   = GtkSource.LanguageManager.get_default();
        manager.append_search_path( lang_path );
        break;
      }
    }

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
    none.add_css_class( "note-title" );

    return( none );

  }

  // Creates the note UI
  private Widget create_note_ui() {

    _tags = new TagBox( _win );
    _tags.added.connect((tag) => {
      tag_added( tag, _note.id );
    });
    _tags.removed.connect((tag) => {
      tag_removed( tag, _note.id );
    });
    _tags.changed.connect(() => {
      _note.tags.copy( _tags.tags );
    });

    var export = new Button.from_icon_name( "document-export-symbolic" ) {
      has_frame = false,
      halign = Align.END,
      tooltip_text = _( "Export note" )
    };
    export.clicked.connect( export_note );

    _favorite = new Button.from_icon_name( "non-starred-symbolic" ) {
      has_frame = false,
      halign = Align.END,
      tooltip_text = _( "Add to Favorites" )
    };
    _favorite.clicked.connect(() => {
      if( _favorite.icon_name == "non-starred-symbolic" ) {
        _favorite.icon_name = "starred-symbolic";
        _note.favorite = true;
      } else {
        _favorite.icon_name = "non-starred-symbolic";
        _note.favorite = false;
      }
    });

    var tbox = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL
    };
    tbox.append( _tags );
    tbox.append( export );
    tbox.append( _favorite );

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
      var new_item = type.create( _note );
      _note.convert_note_item( _current_item, new_item );

      var w = get_item( _current_item );
      _content.remove( w );
      switch( type ) {
        case NoteItemType.MARKDOWN :  add_markdown_item( (NoteItemMarkdown)new_item, _current_item );  break;
        case NoteItemType.CODE     :  add_code_item( (NoteItemCode)new_item, _current_item );          break;
        case NoteItemType.IMAGE    :  add_image_item( (NoteItemImage)new_item, _current_item );        break;
        case NoteItemType.UML      :  add_uml_item( (NoteItemUML)new_item, _current_item );            break;
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
    _title.add_css_class( "themed" );

    _title.activate.connect(() => {
      if( _note != null ) {
        _note.title = _title.text;
        save_note( _note );
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
    _content.add_css_class( "themed" );

    var cbox = new Box( Orientation.VERTICAL, 5 );
    cbox.add_css_class( "themed" );
    cbox.append( _title );
    cbox.append( separator2 );
    cbox.append( _content );

    var sw = new ScrolledWindow() {
      halign = Align.FILL,
      valign = Align.FILL,
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = cbox
    };

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( tbox );
    box.append( hbox );
    box.append( separator1 );
    box.append( sw );

    return( box );

	}

  // Populates the note panel UI with the contents of the provided note.  If note is
  // null, clears the UI.
  public void populate_with_note( Note? note ) {

    if( _note != null ) {
      save_note( _note );
    }

    _note = note;

    if( _note != null ) {

      _created_box.visible = true;
      _created.label = note.created.format( "%b%e, %Y" );
      _title.text    = note.title;
      _title.grab_focus();
      _tags.clear_tags();
      _tags.add_tags( note.tags );
      _favorite.icon_name = _note.favorite ? "starred-symbolic" : "non-starred-symbolic";
      _stack.visible_child_name = "note";
      _note.reviewed();

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
      case NoteItemType.UML      :  return( add_uml_item( (NoteItemUML)item, pos ) );
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
    var item_type = _note.get_item( pos ).item_type;
    if( item_type.is_text() ) {
      get_item_text( pos ).grab_focus();
    } else if( item_type == NoteItemType.UML ) {
      var stack = (Stack)get_item( pos );
      stack.visible_child_name = "input";
      var w = Utils.get_child_at_index( stack.get_child_by_name( "input" ), 1 );
      w.grab_focus();
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
    var item = new NoteItemMarkdown( _note );
    var ins_index = above ? index : (index + 1);
    _note.add_note_item( (uint)ins_index, item );
    add_markdown_item( item, ins_index );
    grab_focus_of_item( ins_index );
  }

  // Removes the item at the given index
  private void remove_item( int index ) {
    var item = get_item( index );
    if( item != null ) {
      _content.remove( item );
      _note.delete_note_item( index );
      if( get_item( index ) != null ) {
        grab_focus_of_item( index );
      } else if( get_item( index - 1 ) != null ) {
        grab_focus_of_item( index - 1 );
      } else {
        var note_item = new NoteItemMarkdown( _note );
        _note.add_note_item( 0, note_item );
        add_markdown_item( note_item, 0 );
        grab_focus_of_item( 0 );
      }
    }
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
          if( control ) {
            remove_item( index );
            return( true );
          } else if( index > 0 ) {
            TextIter cursor;
            text.buffer.get_iter_at_mark( out cursor, text.buffer.get_insert() );
            if( cursor.is_start() && join_items( index ) ) {
              return( true );
            }
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

  private Widget add_text_item( NoteItem item, string lang_id ) {

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

    return( box );

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
        if( _note.get_item( i ).item_type == NoteItemType.MARKDOWN ) {
          var text = get_item_text( i );
          var buffer = (GtkSource.Buffer)text.buffer;
          buffer.style_scheme = style;
        }
      }
    }

  }

  // Adds a new Markdown item at the given position in the content area
  private Widget add_markdown_item( NoteItemMarkdown item, int pos = -1 ) {

    var frame     = add_text_item( item, "markdown" );
    var text      = (GtkSource.View)Utils.get_child_at_index( frame, 0 );
    var buffer    = (GtkSource.Buffer)text.buffer;
    var style_mgr = new GtkSource.StyleSchemeManager();
    var style     = style_mgr.get_scheme( _win.themes.get_current_theme() );

    buffer.style_scheme = style;
    text.add_css_class( "markdown-text" );

    add_item_to_content( frame, pos );

    return( frame );

  }

  private Widget add_code_item( NoteItemCode item, int pos = -1 ) {

    var frame  = add_text_item( item, item.lang );
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

    add_item_to_content( frame, pos );

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
    box.add_css_class( "themed" );

    add_item_to_content( box, pos );

    return( box );

  }

  // Adds a new UML item at the given position in the content area
  private Widget add_uml_item( NoteItemUML item, int pos = -1 ) {

    var image_click = new GestureClick();
    var image = new Picture() {
      halign = Align.FILL,
      valign = Align.FILL
    };
    image.add_controller( image_click );

    var label = new Label( _( "UML Diagram Input" ) ) {
      halign  = Align.START,
      hexpand = true
    };
    var help = new Button.with_label( _( "UML Syntax" ) ) {
      halign = Align.END
    };
    help.clicked.connect(() => {
      Utils.open_url( "https://plantuml.com/" );
    });
    var show = new Button.with_label( _( "Show Diagram" ) ) {
      halign = Align.END
    };

    var hbox = new Box( Orientation.HORIZONTAL, 5 );
    hbox.append( label );
    hbox.append( help );
    hbox.append( show );

    var input     = add_text_item( item, "plantuml" );
    var text      = (GtkSource.View)Utils.get_child_at_index( input, 0 );
    var buffer    = (GtkSource.Buffer)text.buffer;
    var style_mgr = new GtkSource.StyleSchemeManager();
    var style     = style_mgr.get_scheme( _win.themes.get_current_theme() );

    buffer.style_scheme = style;
    text.add_css_class( "code-text" );

    var tbox = new Box( Orientation.VERTICAL, 5 );
    tbox.append( hbox );
    tbox.append( input );

    var loading = new Label( _( "Generating Diagram..." ) ) {
      halign = Align.CENTER,
      valign = Align.CENTER
    };
    loading.add_css_class( "note-title" );

    var stack = new Stack();
    stack.add_named( tbox, "input" );
    stack.add_named( loading, "loading" );
    stack.add_named( image, "image" );

    show.clicked.connect(() => {
      stack.visible_child_name = "loading";
      if( item.content == buffer.text ) {
        item.update_diagram();
      } else {
        item.content = buffer.text;
      }
    });

    item.diagram_updated.connect((filename) => {
      if( filename != null ) {
        stdout.printf( "filename: %s\n", filename );
        image.file = File.new_for_path( filename );
        stack.visible_child_name = "image";
      } else {
        stack.visible_child_name = "input";
      }
    });

    image_click.pressed.connect((n_press, x, y) => {
      if( n_press == 2 ) {
        stack.visible_child_name = "input";
        text.grab_focus();
      }
    });

    // Load the image and make it visible (if it exists); otherwise, display the input field.
    if( FileUtils.test( item.get_resource_filename(), FileTest.EXISTS ) ) {
      image.file = File.new_for_path( item.get_resource_filename() );
      stack.visible_child_name = "image";
    } else {
      stack.visible_child_name = "input";
    }

    add_item_to_content( stack, pos );

    return( stack );

  }

  // Exports the given note
  private void export_note() {

    var dialog = Utils.make_file_chooser( _( "Export" ), _win, FileChooserAction.SAVE, _( "Export" ) );

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        var file = dialog.get_file();
        if( file != null ) {
          Export.export( file.get_path(), _note );
        }
      }
      dialog.destroy();
    });

    dialog.show();

  }

}