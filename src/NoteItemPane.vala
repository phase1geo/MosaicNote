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
// Specifies how the insertion cursor should be placed when a pane
// containing text is given keyboard focus.
public enum TextCursorPlacement {
  START,
  END,
  NO_CHANGE
}

//-------------------------------------------------------------
// Base class for a single note item pane.  Contains shared functionality
// related to panes containing text.
public class NoteItemPane : Box {

  private MainWindow   _win;
  private NoteItem     _item;
  private SpellChecker _spell;
  private Box          _header;
  private Stack        _stack;

  private const GLib.ActionEntry[] action_entries = {
    { "action_add_item_above", action_add_item_above },
    { "action_add_item_below", action_add_item_below },
    { "action_delete_item",    action_delete_item },
  };

  protected MainWindow win {
    get {
      return( _win );
    }
  }
  public NoteItem item {
    get {
      return( _item );
    }
  }
  public NoteItemPane? prev_pane { get; set; default = null; }
  public NoteItemPane? next_pane { get; set; default = null; }

  public signal void add_item( bool above, NoteItemType? type );
  public signal void remove_item( bool forward );
  public signal void move_item( bool up );
  public signal void set_as_current();
  public signal void note_link_clicked( string link );

  //-------------------------------------------------------------
  // Saves all of the item data to the store item in preparation
  // for saving to the XML file.  Derived item panes should connect to
  // this signal.
  public signal void save();

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemPane( MainWindow win, NoteItem item, SpellChecker spell ) {

    Object(
      orientation: Orientation.VERTICAL,
      spacing: 0,
      // margin_top: 5,
      // margin_bottom: 5,
      margin_start: 5,
      margin_end: 5,
      halign: Align.FILL
    );

    _win   = win;
    _item  = item;
    _spell = spell;

    // Create the UI
    create_bar();

    // If we are being set as the current item, make sure that we are drawn as the current item
    set_as_current.connect(() => {
      add_css_class( "active-item" );
      _stack.visible_child_name = "selected";
      _stack.visible = true;
    });

    // Set the stage for menu actions
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "item", actions );

    // Add keyboard shortcuts
    add_keyboard_shortcuts();

  }

  //-------------------------------------------------------------
  // Adds keyboard shortcuts for the menu actions
  private void add_keyboard_shortcuts() {
    _win.application.set_accels_for_action( "item.action_add_item_above", { "<Control><Shift>Return" } );
    _win.application.set_accels_for_action( "item.action_add_item_below", { "<Shift>Return" } );
    _win.application.set_accels_for_action( "item.action_delete_item",    { "<Control>Delete" } );
  }

  //-------------------------------------------------------------
  // Clears the current indicator
  public void clear_current() {
    remove_css_class( "active-item" );
    if( item.expanded ) {
      if( (_stack.get_child_by_name( "unselected" ) != null) && show_header2() ) {
        _stack.visible_child_name = "unselected";
      } else {
        _stack.visible = false;
      }
    }
  }

  //-------------------------------------------------------------
  // Returns the text associated with this note item panel, if available
  public virtual GtkSource.View? get_text() {
    return( null );
  }

  //-------------------------------------------------------------
  // Sets the spellchecker for the current textview widget
  private void set_spellchecker() {

    var text = get_text();
    if( text == null ) {
      return;
    }

    var enabled = MosaicNote.settings.get_boolean( "enable-spellchecker" );

    _spell.detach();

    if( enabled ) {
      _spell.attach( text );
    } else {
      _spell.remove_highlights( text );
    }

  }

  //-------------------------------------------------------------
  // Grabs the focus of the note item at the specified position.
  public virtual void grab_item_focus( TextCursorPlacement placement ) {}

  //-------------------------------------------------------------
  // Places cursor in the given text based on the value of placement
  public void place_cursor( GtkSource.View text, TextCursorPlacement placement ) {
    if( placement != TextCursorPlacement.NO_CHANGE ) {
      TextIter iter;
      text.buffer.get_start_iter( out iter );
      text.buffer.place_cursor( iter );
    }
  }

  //-------------------------------------------------------------
  // Sets the height of the text widget
  private void set_text_height( GtkSource.View text ) {

    TextIter iter;
    Gdk.Rectangle location;

    text.buffer.get_start_iter( out iter );
    text.get_iter_location( iter, out location );
    text.set_size_request( -1, (location.height + 2) );

  }

  //-------------------------------------------------------------
  // Split the current item into two items at the insertion point.
  private void split_item() {

    // Get the current text widget and figure out the location of
    // the insertion cursor.
    var text   = get_text();
    var cursor = text.buffer.cursor_position;

    // Create a copy of the new item, assign it the text after
    // the insertion cursor, and remove the text after the insertion
    // cursor from the original item.
    item.content = text.buffer.text;
    var first    = item.content.substring( 0, cursor ); 
    var last     = item.content.substring( cursor );

    // Update the original text pane
    item.content = first;
    text.buffer.text = first;
    add_item( false, item.item_type );

    // Update the added text pane
    text = next_pane.get_text();
    next_pane.item.content = last;
    text.buffer.text = last;

    // Adjust the insertion cursor to the beginning of the new text
    next_pane.grab_item_focus( TextCursorPlacement.START );

  }

  //-------------------------------------------------------------
  // Joins the current item with the item above it if they are the same type.
  private bool join_items() {

    // If we are unable to join with anything, return false immediately
    if( (prev_pane == null) || (prev_pane.item.item_type != item.item_type) ) {
      return( false );
    }

    // Merge the note text, delete the note item and delete the item from the content area
    var above_text   = prev_pane.get_text();
    var text         = get_text();
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

    // Grab the above text widget for keyboard input
    prev_pane.grab_item_focus( TextCursorPlacement.NO_CHANGE );

    // Remove the current item
    remove_item( false );

    return( true );

  }

  //-------------------------------------------------------------
  // Adds keyboard events when this note item has keyboard input focus.
  // Events will add new items, delete the current item, or move the
  // input focus to the next or previous item.
  protected void handle_key_events( Widget w ) {

    var key = new EventControllerKey();

    w.add_controller( key );

    key.key_pressed.connect((keyval, keycode, state) => {
      var shift   = (bool)(state & Gdk.ModifierType.SHIFT_MASK);
      var control = (bool)(state & Gdk.ModifierType.CONTROL_MASK);
      switch( keyval ) {
        case Gdk.Key.Return :
          if( control && shift ) {
            add_item( true, null );
            return( true );
          } else if( shift ) {
            add_item( false, null );
            return( true );
          }
          break;
        case Gdk.Key.BackSpace :
          if( control ) {
            remove_item( false );
            return( true );
          }
          break;
        case Gdk.Key.Delete :
          if( control ) {
            remove_item( true );
            return( true );
          }
          break;
        case Gdk.Key.Up :
          if( prev_pane != null ) {
            if( control ) {
              move_item( true );
              return( true );
            } else {
              var text = get_text();
              if( text != null ) {
                TextIter iter;
                text.buffer.get_iter_at_mark( out iter, text.buffer.get_insert() );
                if( !iter.is_start() ) {
                  return( false );
                }
              }
              prev_pane.grab_item_focus( TextCursorPlacement.NO_CHANGE ); 
              return( true );
            }
          }
          return( false );
        case Gdk.Key.Down :
          if( next_pane != null ) {
            if( control ) {
              move_item( false );
              return( true );
            } else {
              var text = get_text();
              if( text != null ) {
                TextIter iter;
                text.buffer.get_iter_at_mark( out iter, text.buffer.get_insert() );
                if( !iter.is_end() ) {
                  return( false );
                }
              }
              next_pane.grab_item_focus( TextCursorPlacement.NO_CHANGE );
              return( true );
            }
          }
          return( false );
      }
      return( false );
    });
  }

  //-------------------------------------------------------------
  // Adds and handles any text events.
  private void handle_text_events( GtkSource.View text ) {

    var key = new EventControllerKey();

    text.add_controller( key );

    key.key_pressed.connect((keyval, keycode, state) => {
      var shift   = (bool)(state & Gdk.ModifierType.SHIFT_MASK);
      var control = (bool)(state & Gdk.ModifierType.CONTROL_MASK);
      switch( keyval ) {
        case Gdk.Key.slash :
          if( control ) {
            split_item();
            return( true );
          }
          break;
        case Gdk.Key.BackSpace :
          if( (prev_pane != null) && !control ) {
            TextIter cursor;
            text.buffer.get_iter_at_mark( out cursor, text.buffer.get_insert() );
            if( cursor.is_start() && join_items() ) {
              return( true );
            }
          }
          break;
        case Gdk.Key.Up :
          if( (prev_pane != null) && !control ) {
            TextIter cursor;
            text.buffer.get_iter_at_mark( out cursor, text.buffer.get_insert() );
            if( cursor.is_start() ) {
              prev_pane.grab_item_focus( TextCursorPlacement.END );
              return( true );
            }
          }
          break;
        case Gdk.Key.Down :
          if( (next_pane != null) && !control ) {
            TextIter cursor;
            text.buffer.get_iter_at_mark( out cursor, text.buffer.get_insert() );
            if( cursor.is_end() ) {
              next_pane.grab_item_focus( TextCursorPlacement.START );
              return( true );
            }
          }
          break;
      }
      return( false );
    });

  }

  //-------------------------------------------------------------
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

  //-------------------------------------------------------------
  // Creates a text box with syntax highlighting enabled for the given
  // language ID.  Note item panes that contain a text widget should
  // call this function to create and configure the text widget that
  // can be embedded in the pane.
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
      if( item.item_type.spell_checkable() ) {
        set_spellchecker();
      }
      set_as_current();
    });

    save.connect(() => {
      item.content = buffer.text;
    });

    MosaicNote.settings.changed["editor-line-spacing"].connect(() => {
      set_line_spacing( text );
    });

    // Attach the spell checker temporarily
    if( item.item_type.spell_checkable() ) {
      MosaicNote.settings.changed["enable-spellchecker"].connect(() => {
        set_spellchecker();
      });
    }

    var vim_key     = new EventControllerKey();
    var vim_context = new GtkSource.VimIMContext();
    vim_key.set_im_context( vim_context );
    vim_key.set_propagation_phase( PropagationPhase.CAPTURE );

    if( MosaicNote.settings.get_boolean( "editor-vim-mode" ) ) {
      vim_context.set_client_widget( text );
      text.add_controller( vim_key );
    }

    var style_mgr = new GtkSource.StyleSchemeManager();
    buffer.style_scheme = style_mgr.get_scheme( win.themes.get_current_theme() );
    win.themes.theme_changed.connect((theme) => {
      buffer.style_scheme = style_mgr.get_scheme( theme );
    });

    // Handle any changes to the Vim mode
    MosaicNote.settings.changed["editor-vim-mode"].connect(() => {
      if( MosaicNote.settings.get_boolean( "editor-vim-mode" ) ) {
        text.add_controller( vim_key );
        vim_context.set_client_widget( text );
      } else {
        text.remove_controller( vim_key );
        vim_context.set_client_widget( null );
      }
    });

    return( text );

  }

  //-------------------------------------------------------------
  // Adds a bar to the top of each section that will allow us to 
  // add UI elements to control the panel and provide an area for
  // panel data (if needed).
  private void create_bar() {

    var expand = new Button.with_label( item.expanded ? "\u23f7" : "\u23f5" ) {
      has_frame = false,
      halign = Align.START
    };

    var add_menu = new GLib.Menu();
    add_menu.append( _( "Add Block Above" ), "item.action_add_item_above" );
    add_menu.append( _( "Add Block Below" ), "item.action_add_item_below" );

    var del_menu = new GLib.Menu();
    del_menu.append( _( "Delete Block" ), "item.action_delete_item" );

    var menu = new GLib.Menu();
    menu.append_section( null, add_menu );
    menu.append_section( null, del_menu );

    var more = new MenuButton() {
      halign = Align.END,
      icon_name = "view-more-horizontal-symbolic",
      menu_model = menu
    };

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign        = Align.FILL,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    box.append( expand );
    box.append( create_header1() );
    box.append( more );

    var sep = new Separator( Orientation.HORIZONTAL );

    var header = new Box( Orientation.VERTICAL, 0 ) {
      halign = Align.FILL
    };

    header.append( sep );
    header.append( box );

    var header2 = create_header2();

    _stack = new Stack();
    _stack.add_named( header, "selected" );
    if( header2 != null ) {
      _stack.add_named( header2, "unselected" );
    }

    var pane = create_pane();
    pane.visible = item.expanded;

    expand.clicked.connect(() => {
      item.expanded = !item.expanded;
      pane.visible  = item.expanded;
      expand.label  = item.expanded ? "\u23f7" : "\u23f5";
    });

    append( _stack );
    append( pane );

  }

  //-------------------------------------------------------------
  // Optional area above pane where a single row of horizontal
  // UI elements can be placed.
  protected virtual Widget create_header1() {
    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL,
      hexpand = true
    };
    return( box );
  }

  //-------------------------------------------------------------
  // Creates the header that will be displayed when the pane is
  // expanded and not selected.
  protected virtual Widget? create_header2() {
    return( null );
  }

  //-------------------------------------------------------------
  // Returns true if the header2 should be displayed when the pane
  // is not the current pane.
  protected virtual bool show_header2() {
    return( false );
  }

  //-------------------------------------------------------------
  // Adds a new UML item at the given position in the content area
  protected virtual Widget create_pane() {
    return( null );
  }

  //-------------------------------------------------------------
  // Adds an item above this item
  private void action_add_item_above() {
    add_item( true, item.item_type );
  }

  //-------------------------------------------------------------
  // Adds an item below this item
  private void action_add_item_below() {
    add_item( false, item.item_type );
  }

  //-------------------------------------------------------------
  // Removes the current item
  private void action_delete_item() {
    remove_item( true );
  }

}