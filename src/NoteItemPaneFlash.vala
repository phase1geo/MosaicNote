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

public enum FlashTestType {
  QA,
  AQ,
  MIXED,
  CHOICE,
  NUM;

  public string label() {
    switch( this ) {
      case QA     :  return( _( "Question - Answer" ) );
      case AQ     :  return( _( "Answer - Question" ) );
      case MIXED  :  return( _( "Mixed Question/Answer" ) );
      case CHOICE :  return( _( "Multiple Choice" ) );
      default     :  assert_not_reached();
    }
  }
}

public class FlashTestResults {
  public int right { set; get; default = 0; }
  public int wrong { set; get; default = 0; }
  public FlashTestResults() {}
}

//-------------------------------------------------------------
// Note item pane that represents asset links.
public class NoteItemPaneFlash : NoteItemPane {

  private SimpleActionGroup _actions;
  private Label             _h2_label;
  private Button            _add;
  private ListBox           _listbox;
  private Entry             _edit_side1;
  private GtkSource.View    _edit_side2;
  private Stack             _stack;
  private int               _edit_index = -1;
  private Stack             _test_stack;
  private AutoFitLabel      _question;
  private AutoFitLabel      _answer;
  private AutoFitLabel      _choice_question;
  private AutoFitLabel      _choice_a;
  private AutoFitLabel      _choice_b;
  private AutoFitLabel      _choice_c;
  private AutoFitLabel      _choice_d;
  private AutoFitLabel      _result;
  private int                          _test_index = 0;
  private bool                         _test_in_question = false;
  private FlashTestType                _test_type  = FlashTestType.QA;
  private GLib.List<NoteItemFlashCard> _test_cards;
  private FlashTestResults             _test_results;

  private const GLib.ActionEntry[] action_entries = {
    { "action_remove_card", action_remove_card, "i" },
    { "action_add_defs_from_note", action_add_defs_from_note },
    { "action_add_defs_from_notebook", action_add_defs_from_notebook },
    { "action_add_defs_from_clipboard", action_add_defs_from_clipboard },
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
    _actions = new SimpleActionGroup ();
    _actions.add_action_entries( action_entries, this );
    insert_action_group( "flash", _actions );

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

    var add_right_click = new GestureClick() {
      button = Gdk.BUTTON_SECONDARY
    };
    _add.add_controller( add_right_click );

    var popover = new PopoverMenu.from_model( null ) {
      position   = PositionType.TOP,
      menu_model = create_add_contextual_menu()
    };
    popover.set_parent( _add );

    var add_right_id = add_right_click.released.connect((n_press, x, y) => {
      var clipboard = Gdk.Display.get_default().get_clipboard();
      var nb          = win.smart_notebooks.get_definitions_notebook();
      var enable_note = (nb.count() > 0);
      var enable_cb   = clipboard.get_formats().contain_gtype( Type.STRING );
      set_action_enable( "action_add_defs_from_note",      enable_note );
      set_action_enable( "action_add_defs_from_notebook",  enable_note );
      set_action_enable( "action_add_defs_from_clipboard", enable_cb );
      popover.popup();
    });
    add_signal( add_right_click, add_right_id );

    var run = new Button.with_label( _( "Quiz" ) ) {
      halign = Align.END
    };
    run.clicked.connect(() => {
      _test_stack.visible_child_name = "start";
      _stack.visible_child_name      = "test";
    });

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( entry );
    box.append( _add );
    box.append( run );

    return( box );

  }

  //-------------------------------------------------------------
  // Sets the enablement an action.
  private void set_action_enable( string action_str, bool enabled ) {
    var action = (SimpleAction)_actions.lookup_action( action_str );
    action.set_enabled( enabled );
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

    var run = new Button.with_label( _( "Quiz" ) ) {
      halign = Align.END,
      hexpand = true
    };
    run.clicked.connect(() => {
      _stack.visible_child_name = "test";
    });

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( _h2_label );
    box.append( run );

    return( box );

  }

  //-------------------------------------------------------------
  // Called when our item box loses focus.
  public override void clear_current() {
    base.clear_current();
    _listbox.select_row( null );
  }

  //-------------------------------------------------------------
  // Creates contextual menu associated with the add button.
  private GLib.Menu create_add_contextual_menu() {
    var menu = new GLib.Menu();
    menu.append( _( "Add Markdown Definitions From Note" ),      "flash.action_add_defs_from_note" );
    menu.append( _( "Add Markdown Definitions From Notebook" ),  "flash.action_add_defs_from_notebook" );
    menu.append( _( "Add Markdown Definitions From Clipboard" ), "flash.action_add_defs_from_clipboard" );
    return( menu );
  }

  //-------------------------------------------------------------
  // Creates a contextual menu for a given row in the listbox.
  private GLib.Menu create_list_contextual_menu( int pos ) {
    var del_menu = new GLib.Menu();
    del_menu.append( _( "Remove Card" ), "flash.action_remove_card(%d)".printf( pos ) );
    var menu = new GLib.Menu();
    menu.append_section( null, del_menu );
    return( menu );
  }

  //-------------------------------------------------------------
  // Creates the listbox containing all of the cards.
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
        var popover = new PopoverMenu.from_model( create_list_contextual_menu( row.get_index() ) ) {
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
  // Randomize the cards
  private void initialize_test() {

    _test_index   = 0;
    _test_results = new FlashTestResults();
    _test_cards   = new GLib.List<NoteItemFlashCard>();

    for( int i=0; i<flash_item.size(); i++ ) {
      var card = flash_item.get_card( i );
      _test_cards.append( card );
    }
    _test_cards.sort((a, b) => {
      return( Random.boolean() ? -1 : 1 );
    });

  }

  //-------------------------------------------------------------
  // Generates random answers for the given card for multiple
  // choice questions.
  private void gen_choices( NoteItemFlashCard good_card, out string? a, out string? b, out string? c, out string? d ) {

    a = good_card.side2;
    b = null;
    c = null;
    d = null;

    var bad_cards = new GLib.List<NoteItemFlashCard>();
    for( int i=0; i<flash_item.size(); i++ ) {
      var card = flash_item.get_card( i );
      if( card != good_card ) {
        bad_cards.append( card );
      }
    }
    if( bad_cards.length() > 0 ) {
      bad_cards.sort((a, b) => {
        return( Random.boolean() ? -1 : 1 );
      });
      var choices = (int)((bad_cards.length() < 3) ? (bad_cards.length() + 1) : 4);
      var rn = Random.int_range( 0, choices );
      a = (rn == 0) ? good_card.side2 : bad_cards.nth_data( 0 ).side2;
      b = (rn == 1) ? good_card.side2 : bad_cards.nth_data( (rn < 1) ? 0 : 1 ).side2;
      if( choices >= 3 ) {
        c = (rn == 2) ? good_card.side2 : bad_cards.nth_data( (rn < 2) ? 1 : 2 ).side2;
      }
      if( choices == 4 ) {
        d = (rn == 3) ? good_card.side2 : bad_cards.nth_data( (rn < 3) ? 2 : 3 ).side2;
      }
    }
  }

  //-------------------------------------------------------------
  // Shows the question frame.
  private void show_question() {

    var card = _test_cards.nth_data( _test_index );

    switch( _test_type ) {
      case QA    :  _question.label = card.side1;  break;
      case AQ    :  _question.label = card.side2;  break;
      case MIXED :  _question.label = Random.boolean() ? card.side1 : card.side2;  break;
      default    :
        string? a, b, c, d;
        gen_choices( card, out a, out b, out c, out d );
        _choice_question.label = card.side1;
        _choice_a.label = a ?? "";
        _choice_b.label = b ?? "";
        _choice_c.label = c ?? "";
        _choice_d.label = d ?? "";
        _choice_a.visible = (a != null);
        _choice_b.visible = (b != null);
        _choice_c.visible = (c != null);
        _choice_d.visible = (d != null);
        break;
    }

    _test_in_question = true;

    if( _test_type == FlashTestType.CHOICE ) {
      _test_stack.visible_child_name = "choice";
    } else {
      _test_stack.visible_child_name = "question";
    }

  }

  //-------------------------------------------------------------
  // Marks and grades the user-selected choice for the given
  // multiple choice answer.
  private void grade_choice( NoteItemFlashCard card, AutoFitLabel label, int answer, int choice, ref bool correct ) {
    if( label.label == card.side2 ) {
      label.label = "<span foreground=\"green\">%s</span>".printf( label.label );
      correct = (choice == answer);
    } else if( choice == answer ) {
      label.label = "<span foreground=\"red\">%s</span>".printf( label.label );
    }
  }

  //-------------------------------------------------------------
  // Displays the anser frame.
  private void show_answer( int choice ) {

    var card    = _test_cards.nth_data( _test_index );
    var correct = false;

    switch( _test_type ) {
      case QA    :  _answer.label = card.side2;  break;
      case AQ    :  _answer.label = card.side1;  break;
      case MIXED :  _answer.label = (card.side1 == _question.label) ? card.side2 : card.side1;  break;
      default    :
        grade_choice( card, _choice_a, 0, choice, ref correct );
        grade_choice( card, _choice_b, 1, choice, ref correct );
        grade_choice( card, _choice_c, 2, choice, ref correct );
        grade_choice( card, _choice_d, 3, choice, ref correct );
        break;
    }

    _test_in_question = false;

    if( _test_type == FlashTestType.CHOICE ) {
      _test_results.wrong += !correct ? 1 : 0;
      _test_results.right +=  correct ? 1 : 0;
    } else {
      _test_stack.visible_child_name = "answer";
    }

  }

  //-------------------------------------------------------------
  // Displays the results frame.
  private void show_results() {

    _result.label = "%d of %d (%d%%) correct".printf(
      _test_results.right, (int)_test_cards.length(),
      (int)(((double)_test_results.right / _test_cards.length()) * 100)
    );
    _test_stack.visible_child_name = "result";

  }

  //-------------------------------------------------------------
  // Displays the next
  private void show_next() {

    _test_index++;

    if( (int)_test_cards.length() == _test_index ) {
      show_results();
    } else {
      show_question();
    }

  }

  //-------------------------------------------------------------
  // Displays the test start page.
  private Widget create_test_start() {

    var type_lbl = new Label( _( "Quiz Type" ) ) {
      halign = Align.START
    };

    string[] types = {};
    for( int i=0; i<FlashTestType.NUM; i++ ) {
      var tt = (FlashTestType)i;
      types += tt.label();
    }
    var type_dd = new DropDown.from_strings( types ) {
      halign = Align.START
    };
    type_dd.notify["selected"].connect(() => {
      _test_type = (FlashTestType)type_dd.selected;
    });

    var type_box = new Box( Orientation.HORIZONTAL, 5 );
    type_box.append( type_lbl );
    type_box.append( type_dd );

    var run = new Button.with_label( _( "Run Quiz" ) );
    run.clicked.connect(() => {
      initialize_test();
      show_question();
    });

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( type_box );
    box.append( run );

    return( box );

  }

  //-------------------------------------------------------------
  // Displays the question slide.
  private Widget create_test_question() {

    _question = new AutoFitLabel( "" ) {
      focusable = true,
      halign = Align.CENTER,
      valign = Align.CENTER
    };

    var click = new GestureClick();
    _question.add_controller( click );
    click.pressed.connect( show_answer );

    var key = new EventControllerKey();
    _question.add_controller( key );
    key.key_pressed.connect((keyval, keymod, state) => {
      if( (keyval == Gdk.Key.space) || (keyval == Gdk.Key.Return) ) {
        show_answer( -1 );
        return( true );
      }
      return( false );
    });

    return( _question );

  }

  //-------------------------------------------------------------
  // Displays the answer to the question slide.
  private Widget create_test_answer() {

    _answer = new AutoFitLabel( "" ) {
      halign = Align.CENTER,
      valign = Align.CENTER
    };

    var wrong = new Button.with_label( _( "Wrong" ) ) {
      halign = Align.START
    };

    wrong.clicked.connect(() => {
      _test_results.wrong++;
      show_next();
    });

    var right = new Button.with_label( _( "Correct" ) ) {
      halign = Align.END
    };

    right.clicked.connect(() => {
      _test_results.right++;
      show_next();
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 );
    bbox.append( wrong );
    bbox.append( right );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( _answer );
    box.append( bbox );

    return( box );

  }

  //-------------------------------------------------------------
  // Configures the given choice widget.
  private void configure_choice_answer( AutoFitLabel label, int choice ) {

    var click = new GestureClick();
    label.add_controller( click );

    click.pressed.connect((n_press, x, y) => {
      if( _test_in_question ) {
        show_answer( choice );
      } else {
        show_next();
      }
    });

  }

  private Widget create_test_choice() {

    _choice_question = new AutoFitLabel( "" ) {
      margin_bottom = 10
    };
    _choice_a = new AutoFitLabel( "" );
    _choice_b = new AutoFitLabel( "" );
    _choice_c = new AutoFitLabel( "" );
    _choice_d = new AutoFitLabel( "" );

    configure_choice_answer( _choice_a, 0 );
    configure_choice_answer( _choice_b, 1 );
    configure_choice_answer( _choice_c, 2 );
    configure_choice_answer( _choice_d, 3 );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( _choice_question );
    box.append( _choice_a );
    box.append( _choice_b );
    box.append( _choice_c );
    box.append( _choice_d );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates the test result frame.
  private Widget create_test_result() {

    _result = new AutoFitLabel( "" );

    var done = new Button.with_label( _( "Done" ) );
    done.clicked.connect(() => {
      _stack.visible_child_name = "list";
    });

    var retake = new Button.with_label( _( "Retake" ) );
    retake.clicked.connect(() => {
      initialize_test();
      show_question();
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 );
    bbox.append( retake );
    bbox.append( done );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( _result );
    box.append( bbox );

    return( box );

  }

  //-------------------------------------------------------------
  // Displays the flash card test.
  private Widget create_test() {

    _test_stack = new Stack();
    _test_stack.add_named( create_test_start(),    "start" );
    _test_stack.add_named( create_test_question(), "question" );
    _test_stack.add_named( create_test_answer(),   "answer" );
    _test_stack.add_named( create_test_choice(),   "choice" );
    _test_stack.add_named( create_test_result(),   "result" );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( _test_stack );

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
    } else {
      _edit_side1.text        = "";
      _edit_side2.buffer.text = "";
    }
    _stack.visible_child_name = "editor";
    _edit_side1.grab_focus();
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
  // Parses the given string for Markdown definitions.  When a
  // definition is found, it is added to the list of flash cards.
  private void add_defs_from_string( string str ) {

    var lines  = str.split( "\n" );
    var in_def = false;
    var slide1 = "";
    var slide2 = "";

    foreach( var line in lines ) {
      var stripped = line.strip();
      if( stripped != "" ) {
        if( line.has_prefix( ": " ) ) {
          in_def = true;
          var start = line.index_of_nth_char( 2 );
          slide2 = line.substring( start ).strip();
        } else if( in_def ) {
          slide2 += "\n" + stripped;
        } else if( slide1 == "" ) {
          slide1 = stripped;
        } else {
          slide1 += "\n" + stripped;
        }
      } else {
        if( in_def ) {
          add_card( slide1, slide2, true );
          in_def = false;
        }
        slide1 = "";
        slide2 = "";
      }
    }

    if( in_def ) {
      add_card( slide1, slide2, true );
    }

  }

  //-------------------------------------------------------------
  // Parses the note to find any definitions found within its Markdown
  // items.  If any definitions are found, they are added to the list.
  private void add_defs_from_note( Note note ) {
    for( int i=0; i<note.rows(); i++ ) {
      var row = note.get_row( i );
      for( int j=0; j<row.size(); j++ ) {
        var item = row.get_item( j );
        if( item.item_type == NoteItemType.MARKDOWN ) {
          add_defs_from_string( item.content );
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Asks the user to select a note from a list that contains
  // potential definitions.  If the selected note contains a
  // definition, those definitions are added as cards to our list.
  private void action_add_defs_from_note() {

    var nb    = win.smart_notebooks.get_definitions_notebook();
    var model = nb.get_model();

    var string_list = new Array<string>();
    for( int i=0; i<model.get_n_items(); i++ ) {
      var note = (Note)model.get_item( i );
      string_list.append_val( note.title );
    }

    // Display list of notes with search field in a window
    win.choose_from_list.begin( _( "Choose Note" ), string_list, (obj, res) => {
      var index = win.choose_from_list.end( res );
      if( index >= 0 ) {
        var note = (Note)model.get_item( index );
        add_defs_from_note( note );
      }
    });

  }

  //-------------------------------------------------------------
  // Asks the user to select a notebook known to contain potential
  // Markdown definitions.  If a notebook is selected, all notes
  // within the notebook are parsed for definitions and added as
  // cards to our list.
  private void action_add_defs_from_notebook() {

    var nb    = win.smart_notebooks.get_definitions_notebook();
    var model = nb.get_model();

    var ids         = new Gee.HashSet<int>();
    var notebooks   = new Array<Notebook>();
    var string_list = new Array<string>();
    for( int i=0; i<model.get_n_items(); i++ ) {
      var note = (Note)model.get_item( i );
      if( !ids.contains( note.notebook.id ) ) {
        ids.add( note.notebook.id );
        notebooks.append_val( note.notebook );
        string_list.append_val( note.notebook.name );
      }
    }

    // Display list of notebooks with search field in a window
    win.choose_from_list.begin( _( "Choose Notebook" ), string_list, (obj, res) => {
      var index = win.choose_from_list.end( res );
      if( index >= 0 ) {
        var selected_nb = notebooks.index( index );
        for( int i=0; i<model.get_n_items(); i++ ) {
          var note = (Note)model.get_item( i );
          if( note.notebook == selected_nb ) {
            add_defs_from_note( note );
          }
        }
      }
    });

  }

  //-------------------------------------------------------------
  // Takes the text that is on the clipboard
  private void action_add_defs_from_clipboard() {

    var clipboard = Gdk.Display.get_default().get_clipboard();

    if( clipboard.get_formats().contain_gtype( Type.STRING ) ) {
      clipboard.read_text_async.begin( null, (obj,res) => {
        try {
          var str = clipboard.read_text_async.end( res );
          add_defs_from_string( str );
        } catch( Error e ) {}
      });
    }

  }

  //-------------------------------------------------------------
  // We won't have a copy to clipboard menu option so return null.
  protected override GLib.Menu? create_clipboard_menu() {
    return( null );
  }

}
