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
using Gee;

//-------------------------------------------------------------
// Note item pane that represents asset links.
public class NoteItemPaneFlash : NoteItemPane {

  private Label          _h2_label;
  private Button         _add;
  private ListBox        _listbox;
  private Entry          _edit_side1;
  private GtkSource.View _edit_side2;
  private Stack          _test_stack;
  private Stack          _stack;
  private int            _edit_index = -1;

  private const GLib.ActionEntry[] action_entries = {
    { "action_remove_card", action_remove_card, "i" },
  };

  public NoteItemFlash flash_item {
    get {
      return( (NoteItemFlash)item );
    }
  }

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemPaneFlash( MainWindow win, NoteItem item, SpellChecker spell ) {
    base( win, item, spell );

    // Set the stage for menu actions
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "flash", actions );

  }

  //-------------------------------------------------------------
  // Destructor
  ~NoteItemPaneFlash() {
    if( MosaicNote.debug ) {
      stdout.printf( "NoteItemPaneFlash destructor called\n" );
    }
  }

  //-------------------------------------------------------------
  // Cleans up class to allow for proper destruction.
  public override void cleanup() {
    base.cleanup();
    insert_action_group( "flash", null );
  }

  //-------------------------------------------------------------
  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement, int offset = 0 ) {
    if( flash_item.size() > 0 ) {
      _listbox.grab_focus();
      _listbox.select_row( _listbox.get_row_at_index( 0 ) );
    } else {
      _add.grab_focus();
    }
  }

  //-------------------------------------------------------------
  // Adds the given asset to the listbox.
  public void add_card( string side1, string side2, bool add_to_item, int index = -1 ) {

    var label = new Label( side1 ) {
      halign = Align.START,
      hexpand = true
    };

    if( index == -1 ) {
      _listbox.append( label );
    } else {
      _listbox.insert( label, index );
    }

    if( add_to_item ) {
      flash_item.add_card( side1, side2, index );
    }

  }

  //-------------------------------------------------------------
  // Removes the asset at the given index.
  public void remove_card( int index ) {
    var row = _listbox.get_row_at_index( index );
    _listbox.remove( row );
  }

  //-------------------------------------------------------------
  // Returns true if the listbox will use the up key event.
  protected override bool handled_up() {
    var row = _listbox.get_selected_row();
    return( (row != null) && (row.get_index() > 0) );
  }

  //-------------------------------------------------------------
  // Returns true if the listbox will use the down key event.
  protected override bool handled_down() {
    var row = _listbox.get_selected_row();
    return( (row != null) && (row.get_index() < (flash_item.size() - 1)));
  }

  //-------------------------------------------------------------
  // Add elements to the note item header bar
  protected override Widget create_header1() {

    var default_text = _( "Description (Optional)" );

    var entry = new EditableLabel( (flash_item.description == "") ? default_text : flash_item.description ) {
      halign = Align.FILL,
      hexpand = true
    };

    var editing_id = entry.notify["editing"].connect(() => {
      if( !entry.editing ) {
        var text = (entry.text == default_text) ? "" : entry.text;
        if( flash_item.description != text ) {
          win.undo.add_item( new UndoItemDescChange( item, flash_item.description ) );
          flash_item.description = text;
          _h2_label.label = Utils.make_title( text );
        }
      }
    });
    add_signal( entry, editing_id );

    var save_id = save.connect(() => {
      var text = (entry.text == default_text) ? "" : entry.text;
      if( flash_item.description != text ) {
        win.undo.add_item( new UndoItemDescChange( item, flash_item.description ) );
        flash_item.description = text;
        _h2_label.label = Utils.make_title( text );
      }
    });
    add_signal( this, save_id );

    _add = new Button.from_icon_name( "list-add-symbolic" ) {
      halign       = Align.END,
      hexpand      = true,
      tooltip_text = _( "Add flash card" )
    };

    var add_id = _add.clicked.connect(() => {
      show_card_editor();
    });
    add_signal( _add, add_id );

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( entry );
    box.append( _add );

    return( box );

  }

  //-------------------------------------------------------------
  // Indicate that we have a valid header2.
  protected override bool header2_exists() {
    return( flash_item.description.chomp() != "" );
  }

  //-------------------------------------------------------------
  // Creates header bar shown when the pane is not selected
  protected override Widget? create_header2() {

    _h2_label = new Label( Utils.make_title( flash_item.description ) ) {
      use_markup = true,
      halign = Align.FILL,
      justify = Justification.CENTER
    };

    return( _h2_label );

  }

  //-------------------------------------------------------------
  // Called when our item box loses focus.
  public override void clear_current() {
    base.clear_current();
    _listbox.select_row( null );
  }

  //-------------------------------------------------------------
  // Creates a contextual menu for a given row in the listbox.
  private GLib.Menu create_contextual_menu( int pos ) {
    var del_menu = new GLib.Menu();
    del_menu.append( _( "Remove Card" ), "flash.action_remove_card(%d)".printf( pos ) );
    var menu = new GLib.Menu();
    menu.append_section( null, del_menu );
    return( menu );
  }

  private Widget create_card_list() {

    var label = new Label( Utils.make_title( _( "Cards" ) ) ) {
      halign     = Align.START,
      hexpand    = true,
      use_markup = true,
      can_focus  = true,
      focusable  = true,
      margin_start = 5
    };

    var focus       = new EventControllerFocus();
    var key         = new EventControllerKey();
    var right_click = new GestureClick() {
      button = Gdk.BUTTON_SECONDARY
    };

    _listbox = new ListBox() {
      halign  = Align.START,
      hexpand = true,
      selection_mode = SelectionMode.SINGLE,
      activate_on_single_click = false,
      margin_start = 10
    };
    _listbox.add_controller( key );
    _listbox.add_controller( focus );
    _listbox.add_controller( right_click );

    var row_id = _listbox.row_activated.connect((row) => {
      show_card_editor( row.get_index() );
    });
    add_signal( _listbox, row_id );

    var press_id = key.key_pressed.connect((keyval, keycode, state) => {
      var row = _listbox.get_selected_row();
      if( row != null ) {
        if( (keyval == Gdk.Key.Delete) || (keyval == Gdk.Key.BackSpace) ) {
          var index = row.get_index();
          win.undo.add_item( new UndoItemFlashRemove( this, flash_item, index ) );
          flash_item.remove_card( index );
          _listbox.remove( row );
          return( true );
        }
      }
      return( false );
    });
    add_signal( key, press_id );

    var enter_id = focus.enter.connect(() => {
      set_as_current( true );
    });
    add_signal( focus, enter_id );
    
    var right_click_id = right_click.pressed.connect((n_press, x, y) => {
      var row = _listbox.get_row_at_y( (int)y );
      if( row != null ) {
        Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
        _listbox.select_row( row );
        var popover = new PopoverMenu.from_model( create_contextual_menu( row.get_index() ) ) {
          pointing_to = rect,
          position    = PositionType.TOP
        };
        popover.set_parent( _listbox );
        popover.popup();
      }
    });
    add_signal( right_click, right_click_id );

    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    box.append( label );
    box.append( _listbox );

    for( int i=0; i<flash_item.size(); i++ ) {
      var card = flash_item.get_card( i );
      add_card( card.side1, card.side2, false );
    }

    handle_key_events( _listbox );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates the card editor pane.
  private Widget create_card_editor() {

    _edit_side1  = new Entry();
    var frame1 = new Frame( _( "Side 1" ) ) {
      halign  = Align.FILL,
      hexpand = true,
      child   = _edit_side1
    };

    _edit_side2 = create_text( "markdown" );
    var frame2 = new Frame( _( "Side 2" ) ) {
      halign = Align.FILL,
      valign = Align.FILL,
      child  = _edit_side2
    };

    var cancel = new Button.with_label( _( "Cancel" ) ) {
      halign = Align.END,
      hexpand = true
    };
    cancel.clicked.connect(() => {
      _stack.visible_child_name = "list";
    });

    var save = new Button.with_label( _( "Save" ) ) {
      halign = Align.END
    };
    save.clicked.connect(() => {
      if( _edit_index == -1 ) {
        add_card( _edit_side1.text, _edit_side2.buffer.text, true );
      } else {
        remove_card( _edit_index );
        flash_item.remove_card( _edit_index );
        add_card( _edit_side1.text, _edit_side2.buffer.text, true, _edit_index );
      }
      _stack.visible_child_name = "list";
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 );
    bbox.append( cancel );
    bbox.append( save );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( frame1 );
    box.append( frame2 );
    box.append( bbox );

    return( box );

  }

  //-------------------------------------------------------------
  // Displays the flash card test.
  private Widget create_test() {

    var box = new Box( Orientation.VERTICAL, 5 );

    return( box );

  }

  //-------------------------------------------------------------
  // Adds a new Markdown item at the given position in the content area
  protected override Widget create_pane() {

    _stack = new Stack() {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    _stack.add_named( create_card_list(),   "list" );
    _stack.add_named( create_card_editor(), "editor" );
    _stack.add_named( create_test(),        "test" );

    return( _stack );

  }

  //-------------------------------------------------------------
  // Displays the flash card editor.
  private void show_card_editor( int card_index = -1 ) {
    _edit_index = card_index;
    if( card_index >= 0 ) {
      var card = flash_item.get_card( card_index );
      _edit_side1.text        = card.side1;
      _edit_side2.buffer.text = card.side2;
    }
    _stack.visible_child_name = "editor";
  }

  //-------------------------------------------------------------
  // Performs text search over stored asset paths.
  public override void do_search( NoteSearchFunc command ) {
    for( int i=0; i<flash_item.size(); i++ ) {
      var card = flash_item.get_card( i );
      command( this, "flash:%d".printf( i ), card.side1, _listbox.get_row_at_index( i ).get_child() );
      command( this, "flash:%d".printf( i ), card.side2, _listbox.get_row_at_index( i ).get_child() );
    }
  }

  //-------------------------------------------------------------
  // Removes the given row from the file list.
  private void action_remove_card( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var index = variant.get_int32();
      win.undo.add_item( new UndoItemFlashRemove( this, flash_item, index ) );
      flash_item.remove_card( index );
      remove_card( index );
    }
  }

  //-------------------------------------------------------------
  // We won't have a copy to clipboard menu option so return null.
  protected override GLib.Menu? create_clipboard_menu() {
    return( null );
  }

}
