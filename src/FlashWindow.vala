/*
* Copyright (c) 2026 (https://github.com/phase1geo/MosaicNote)
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

public class FlashWindow : Window {

  private NoteItemFlash                _item;
  private Stack                        _test_stack;
  private Box                          _header_box;
  private Label                        _progress_label;
  private ProgressBar                  _progress;
  private Label                        _question;
  private Box                          _question_box;
  private Label                        _answer;
  private Box                          _answer_box;
  private Label                        _choice_question;
  private Box                          _choice_box;
  private Button                       _choice_a;
  private Button                       _choice_b;
  private Button                       _choice_c;
  private Button                       _choice_d;
  private Button                       _choice_next;
  private Label                        _choice_hint;
  private Label                        _result;
  private Label                        _result_detail;
  private Box                          _result_box;
  private int                          _test_index = -1;
  private bool                         _test_in_question = false;
  private FlashTestType                _test_type  = FlashTestType.QA;
  private GLib.List<NoteItemFlashCard> _test_cards;
  private FlashTestResults             _test_results;

  public FlashWindow( MainWindow win, NoteItemFlash item ) {
    Object(
      title: _( "Flash Card Quiz" ),
      transient_for: win,
      modal: true,
      default_width: 640,
      default_height: 480,
      width_request: 480,
      height_request: 380
    );

    _item = item;

    add_css_styling();

    _test_stack = new Stack() {
      transition_type     = StackTransitionType.SLIDE_LEFT_RIGHT,
      transition_duration = 200,
      vexpand       = true,
      margin_start  = 20,
      margin_end    = 20,
      margin_top    = 10,
      margin_bottom = 20
    };

    _test_stack.add_named( create_test_start(),    "start" );
    _test_stack.add_named( create_test_question(), "question" );
    _test_stack.add_named( create_test_answer(),   "answer" );
    _test_stack.add_named( create_test_choice(),   "choice" );
    _test_stack.add_named( create_test_result(),   "result" );

    var main_box = new Box( Orientation.VERTICAL, 0 );
    main_box.append( create_header() );
    main_box.append( _test_stack );

    child = main_box;

    var win_key = new EventControllerKey();
    main_box.add_controller( win_key );
    win_key.key_pressed.connect((keyval, keymod, state) => {
      if( keyval == Gdk.Key.Escape ) {
        close();
        return( true );
      }
      return( false );
    });

    update_title();

  }

  //-------------------------------------------------------------
  // Loads a small stylesheet to give the quiz a friendlier,
  // more legible look and to provide visual feedback for
  // correct/incorrect multiple-choice answers.
  private void add_css_styling() {

    var provider = new CssProvider();
    provider.load_from_string( """
      @define-color flash_success #2ec27e;
      @define-color flash_error #e01b24;

      .flash-title {
        font-size: 1.4em;
        font-weight: 700;
      }

      .flash-subtitle {
        opacity: 0.7;
      }

      .flash-hint {
        font-size: 0.85em;
        opacity: 0.55;
      }

      .flash-question {
        font-size: 1.5em;
        font-weight: 600;
      }

      .flash-card {
        background-color: alpha(currentColor, 0.05);
        border-radius: 12px;
        padding: 28px;
      }

      .flash-choice {
        padding: 12px 16px;
        border-radius: 10px;
      }

      .flash-choice.correct-choice {
        background-color: alpha(@flash_success, 0.25);
        color: @flash_success;
        font-weight: 600;
      }

      .flash-choice.incorrect-choice {
        background-color: alpha(@flash_error, 0.25);
        color: @flash_error;
        font-weight: 600;
      }

      .flash-result-score {
        font-size: 2.6em;
        font-weight: 800;
      }

      .flash-result-score.good {
        color: @flash_success;
      }

      .flash-result-score.bad {
        color: @flash_error;
      }
    """ );

    StyleContext.add_provider_for_display(
      Gdk.Display.get_default(),
      provider,
      Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    );

  }

  //-------------------------------------------------------------
  // Creates the persistent progress header shown while a quiz
  // question is on screen (hidden on the start and result pages).
  private Widget create_header() {

    _progress_label = new Label( "" ) {
      halign  = Align.START,
      hexpand = true
    };
    _progress_label.add_css_class( "flash-hint" );

    _progress = new ProgressBar() {
      hexpand   = true,
      show_text = false
    };

    _header_box = new Box( Orientation.VERTICAL, 4 ) {
      margin_start = 20,
      margin_end   = 20,
      margin_top   = 16,
      visible      = false
    };
    _header_box.append( _progress_label );
    _header_box.append( _progress );

    return( _header_box );

  }

  //-------------------------------------------------------------
  // Sets the title of this window
  private void update_title() {
    title = (_test_index == -1)
            ? _( "Flash Card Quiz" )
            : _( "Flash Card Quiz (%d of %d)" ).printf( (_test_index + 1), _item.size() );
  }

  //-------------------------------------------------------------
  // Randomize the cards
  private void initialize_test() {

    _test_index   = 0;
    _test_results = new FlashTestResults();
    _test_cards   = new GLib.List<NoteItemFlashCard>();

    for( int i=0; i<_item.size(); i++ ) {
      var card = _item.get_card( i );
      _test_cards.append( card );
    }
    _test_cards.sort((a, b) => {
      return( Random.boolean() ? -1 : 1 );
    });

  }

  //-------------------------------------------------------------
  // Generates random answers for the given card for multiple
  // choice questions.
  private void gen_choices( NoteItemFlashCard good_card, bool use_side1, out string? a, out string? b, out string? c, out string? d ) {

    a = good_card.side2;
    b = null;
    c = null;
    d = null;

    var bad_cards = new GLib.List<NoteItemFlashCard>();
    for( int i=0; i<_item.size(); i++ ) {
      var card = _item.get_card( i );
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
      if( use_side1 ) {
        a = (rn == 0) ? good_card.side1 : bad_cards.nth_data( 0 ).side1;
        b = (rn == 1) ? good_card.side1 : bad_cards.nth_data( (rn < 1) ? 0 : 1 ).side1;
        if( choices >= 3 ) {
          c = (rn == 2) ? good_card.side1 : bad_cards.nth_data( (rn < 2) ? 1 : 2 ).side1;
        }
        if( choices == 4 ) {
          d = (rn == 3) ? good_card.side1 : bad_cards.nth_data( (rn < 3) ? 2 : 3 ).side1;
        }
      } else {
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
  }

  //-------------------------------------------------------------
  // Resets a multiple-choice button back to its unanswered state.
  private void reset_choice_button( Button btn, bool card_visible ) {
    btn.remove_css_class( "correct-choice" );
    btn.remove_css_class( "incorrect-choice" );
    btn.opacity   = 1.0;
    btn.sensitive = true;
    btn.visible   = card_visible;
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
        var use_side1 = Random.boolean();
        gen_choices( card, use_side1, out a, out b, out c, out d );
        _choice_question.label = use_side1 ? card.side2 : card.side1;
        _choice_a.label = _( "a) %s" ).printf( a ?? "" );
        _choice_b.label = _( "b) %s" ).printf( b ?? "" );
        _choice_c.label = _( "c) %s" ).printf( c ?? "" );
        _choice_d.label = _( "d) %s" ).printf( d ?? "" );
        reset_choice_button( _choice_a, a != null );
        reset_choice_button( _choice_b, b != null );
        reset_choice_button( _choice_c, c != null );
        reset_choice_button( _choice_d, d != null );
        _choice_next.opacity   = 0.0;
        _choice_next.sensitive = false;
        _choice_hint.label     = _( "Press A, B, C or D to answer" );
        break;
    }

    _test_in_question = true;

    _header_box.visible    = true;
    _progress_label.label  = _( "Card %d of %d" ).printf( (_test_index + 1), (int)_test_cards.length() );
    _progress.fraction      = (double)_test_index / (double)_test_cards.length();

    if( _test_type == FlashTestType.CHOICE ) {
      _test_stack.visible_child_name = "choice";
      _choice_box.grab_focus();
    } else {
      if( _test_stack.visible_child_name == "answer" ) {
        _test_stack.set_visible_child_full( "question", StackTransitionType.SLIDE_LEFT );
      } else {
        _test_stack.visible_child_name = "question";
      }
      _question_box.grab_focus();
    }

    update_title();

  }

  //-------------------------------------------------------------
  // Marks and grades the user-selected choice for the given
  // multiple choice answer.
  private void grade_choice( NoteItemFlashCard card, Button btn, string prefix, int answer, int choice, ref bool correct ) {
    var answer_str = (_choice_question.label == card.side1) ? card.side2 : card.side1;
    if( btn.label == prefix.printf( answer_str ) ) {
      btn.label = "\u2714  %s".printf( btn.label );
      btn.add_css_class( "correct-choice" );
      correct = (choice == answer);
    } else if( choice == answer ) {
      btn.label = "\u2718  %s".printf( btn.label );
      btn.add_css_class( "incorrect-choice" );
    } else {
      btn.opacity = 0.5;
    }
  }

  //-------------------------------------------------------------
  // Displays the answer frame.
  private void show_answer( int choice ) {

    var card    = _test_cards.nth_data( _test_index );
    var correct = false;

    switch( _test_type ) {
      case QA    :  _answer.label = card.side2;  break;
      case AQ    :  _answer.label = card.side1;  break;
      case MIXED :  _answer.label = (card.side1 == _question.label) ? card.side2 : card.side1;  break;
      default    :
        grade_choice( card, _choice_a, _( "a) %s" ), 0, choice, ref correct );
        grade_choice( card, _choice_b, _( "b) %s" ), 1, choice, ref correct );
        grade_choice( card, _choice_c, _( "c) %s" ), 2, choice, ref correct );
        grade_choice( card, _choice_d, _( "d) %s" ), 3, choice, ref correct );
        _choice_a.sensitive    = false;
        _choice_b.sensitive    = false;
        _choice_c.sensitive    = false;
        _choice_d.sensitive    = false;
        _choice_next.opacity   = 1.0;
        _choice_next.sensitive = true;
        _choice_hint.label     = _( "Press N, Space or Enter for the next question" );
        _choice_box.grab_focus();
        break;
    }

    _test_in_question = false;

    if( _test_type == FlashTestType.CHOICE ) {
      _test_results.wrong += !correct ? 1 : 0;
      _test_results.right +=  correct ? 1 : 0;
    } else {
      _test_stack.visible_child_name = "answer";
      _answer_box.grab_focus();
    }

  }

  //-------------------------------------------------------------
  // Displays the results frame.
  private void show_results() {

    var total   = (int)_test_cards.length();
    var percent = (int)(((double)_test_results.right / total) * 100);

    _result.label = "%d%%".printf( percent );
    _result.remove_css_class( "good" );
    _result.remove_css_class( "bad" );
    _result.add_css_class( (percent >= 70) ? "good" : "bad" );

    _result_detail.label = _( "%d of %d correct" ).printf( _test_results.right, total );

    _test_stack.visible_child_name = "result";
    _header_box.visible = false;
    _result_box.grab_focus();

    _test_index = -1;
    update_title();

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

    var icon = new Image.from_icon_name( "dialog-question-symbolic" ) {
      pixel_size = 48,
      halign     = Align.CENTER
    };
    icon.add_css_class( "dim-label" );

    var title = new Label( _( "Ready to test yourself?" ) ) {
      halign = Align.CENTER
    };
    title.add_css_class( "flash-title" );

    var subtitle = new Label( _( "%d cards in this deck" ).printf( _item.size() ) ) {
      halign     = Align.CENTER,
      margin_top = 4
    };
    subtitle.add_css_class( "flash-subtitle" );

    var type_lbl = new Label( _( "Quiz Type" ) ) {
      halign = Align.START
    };

    string[] types = {};
    for( int i=0; i<FlashTestType.NUM; i++ ) {
      var tt = (FlashTestType)i;
      types += tt.label();
    }
    var type_dd = new DropDown.from_strings( types ) {
      halign = Align.CENTER
    };
    type_dd.notify["selected"].connect(() => {
      _test_type = (FlashTestType)type_dd.selected;
    });

    var type_box = new Box( Orientation.HORIZONTAL, 10 ) {
      halign     = Align.CENTER,
      margin_top = 24
    };
    type_box.append( type_lbl );
    type_box.append( type_dd );

    var run = new Button.with_mnemonic( _( "_Take Quiz" ) ) {
      halign        = Align.CENTER,
      use_underline = true,
      margin_top    = 20
    };
    run.add_css_class( "suggested-action" );
    run.add_css_class( "pill" );

    run.clicked.connect(() => {
      initialize_test();
      show_question();
    });

    var hint = new Label( _( "Press T, Space or Enter to begin" ) ) {
      halign     = Align.CENTER,
      margin_top = 8
    };
    hint.add_css_class( "flash-hint" );

    var box = new Box( Orientation.VERTICAL, 2 ) {
      halign  = Align.CENTER,
      valign  = Align.CENTER,
      vexpand = true
    };
    box.append( icon );
    box.append( title );
    box.append( subtitle );
    box.append( type_box );
    box.append( run );
    box.append( hint );

    var key = new EventControllerKey();
    box.add_controller( key );
    key.key_pressed.connect((keyval, keymod, state) => {
      if( (keyval == Gdk.Key.t) || (keyval == Gdk.Key.Return) || (keyval == Gdk.Key.space) ) {
        run.clicked();
        return( true );
      }
      return( false );
    });

    return( box );

  }

  //-------------------------------------------------------------
  // Displays the question slide.
  private Widget create_test_question() {

    _question = new Label( "" ) {
      halign    = Align.FILL,
      valign    = Align.CENTER,
      justify   = Justification.CENTER,
      wrap      = true,
      vexpand   = true
    };
    _question.add_css_class( "flash-question" );
    _question.add_css_class( "flash-card" );

    var hint = new Label( _( "Click, press Space or Enter to reveal the answer" ) ) {
      halign     = Align.CENTER,
      margin_top = 12
    };
    hint.add_css_class( "flash-hint" );

    _question_box = new Box( Orientation.VERTICAL, 0 ) {
      focusable = true
    };
    _question_box.append( _question );
    _question_box.append( hint );

    var click = new GestureClick();
    _question_box.add_controller( click );
    click.pressed.connect( show_answer );

    var key = new EventControllerKey();
    _question_box.add_controller( key );
    key.key_pressed.connect((keyval, keymod, state) => {
      if( (keyval == Gdk.Key.space) || (keyval == Gdk.Key.Return) ) {
        show_answer( -1 );
        return( true );
      }
      return( false );
    });

    return( _question_box );

  }

  //-------------------------------------------------------------
  // Displays the answer to the question slide.
  private Widget create_test_answer() {

    _answer = new Label( "" ) {
      halign  = Align.FILL,
      valign  = Align.CENTER,
      justify = Justification.CENTER,
      wrap    = true,
      vexpand = true
    };
    _answer.add_css_class( "flash-question" );
    _answer.add_css_class( "flash-card" );

    var wrong = new Button.with_mnemonic( _( "_Wrong" ) ) {
      halign        = Align.START,
      use_underline = true
    };
    wrong.add_css_class( "destructive-action" );
    wrong.add_css_class( "pill" );

    wrong.clicked.connect(() => {
      _test_results.wrong++;
      show_next();
    });

    var right = new Button.with_mnemonic( _( "_Correct" ) ) {
      halign        = Align.END,
      use_underline = true
    };
    right.add_css_class( "suggested-action" );
    right.add_css_class( "pill" );

    right.clicked.connect(() => {
      _test_results.right++;
      show_next();
    });

    var hint = new Label( _( "Press W for wrong, C for correct" ) ) {
      halign = Align.CENTER
    };
    hint.add_css_class( "flash-hint" );

    var bbox = new Box( Orientation.HORIZONTAL, 10 ) {
      halign  = Align.CENTER,
      valign  = Align.END,
      vexpand = true
    };
    bbox.append( wrong );
    bbox.append( right );

    _answer_box = new Box( Orientation.VERTICAL, 8 ) {
      focusable = true
    };
    _answer_box.append( _answer );
    _answer_box.append( hint );
    _answer_box.append( bbox );

    var key = new EventControllerKey();
    _answer_box.add_controller( key );
    key.key_pressed.connect((keyval, keymod, state) => {
      switch( keyval ) {
        case Gdk.Key.w :  wrong.clicked();  return( true );
        case Gdk.Key.c :  right.clicked();  return( true );
        default        :  return( false );
      }
    });

    return( _answer_box );

  }

  //-------------------------------------------------------------
  // Creates a single multiple-choice answer button.
  private Button create_choice_button() {

    var btn = new Button.with_label( "" ) {
      halign = Align.FILL
    };
    btn.add_css_class( "flash-choice" );

    var lbl = btn.get_child() as Label;
    if( lbl != null ) {
      lbl.wrap    = true;
      lbl.xalign  = 0;
      lbl.justify = Justification.LEFT;
    }

    return( btn );

  }

  //-------------------------------------------------------------
  // Configures the given choice widget.
  private void configure_choice_answer( Button btn, int choice ) {

    btn.clicked.connect(() => {
      if( _test_in_question ) {
        show_answer( choice );
      }
    });

  }

  //-------------------------------------------------------------
  // Create a multiple choice UI for up to 4 choices.
  private Widget create_test_choice() {

    _choice_question = new Label( "" ) {
      halign        = Align.FILL,
      valign        = Align.FILL,
      vexpand       = true,
      wrap          = true,
      justify       = Justification.CENTER,
      margin_top    = 10,
      margin_bottom = 10
    };
    _choice_question.add_css_class( "flash-question" );

    _choice_a = create_choice_button();
    _choice_b = create_choice_button();
    _choice_c = create_choice_button();
    _choice_d = create_choice_button();

    configure_choice_answer( _choice_a, 0 );
    configure_choice_answer( _choice_b, 1 );
    configure_choice_answer( _choice_c, 2 );
    configure_choice_answer( _choice_d, 3 );

    _choice_next = new Button.with_label( _( "Next" ) ) {
      halign     = Align.CENTER,
      margin_top = 10,
      opacity    = 0.0,
      sensitive  = false
    };
    _choice_next.add_css_class( "suggested-action" );
    _choice_next.add_css_class( "pill" );
    _choice_next.clicked.connect(() => {
      show_next();
    });

    var hint = new Label( _( "Press A, B, C or D to answer" ) ) {
      halign     = Align.CENTER,
      margin_top = 4
    };
    hint.add_css_class( "flash-hint" );
    _choice_hint = hint;

    _choice_box = new Box( Orientation.VERTICAL, 8 ) {
      focusable = true,
      halign    = Align.CENTER,
      valign    = Align.CENTER
    };
    _choice_box.append( _choice_question );
    _choice_box.append( _choice_a );
    _choice_box.append( _choice_b );
    _choice_box.append( _choice_c );
    _choice_box.append( _choice_d );
    _choice_box.append( hint );
    _choice_box.append( _choice_next );
    _choice_box.set_size_request( 500, -1 );

    var key = new EventControllerKey();
    _choice_box.add_controller( key );
    key.key_pressed.connect((keyval, keymod, state) => {
      if( _test_in_question ) {
        switch( keyval ) {
          case Gdk.Key.a :  show_answer( 0 );  return( true );
          case Gdk.Key.b :  show_answer( 1 );  return( true );
          case Gdk.Key.c :  show_answer( 2 );  return( true );
          case Gdk.Key.d :  show_answer( 3 );  return( true );
          default        :  return( false );
        }
      } else if( (keyval == Gdk.Key.n) || (keyval == Gdk.Key.space) || (keyval == Gdk.Key.Return) ) {
        show_next();
        return( true );
      }
      return( false );
    });

    return( _choice_box );

  }

  //-------------------------------------------------------------
  // Creates the test result frame.
  private Widget create_test_result() {

    _result = new Label( "" ) {
      halign = Align.CENTER,
      valign = Align.END
    };
    _result.add_css_class( "flash-result-score" );

    _result_detail = new Label( "" ) {
      halign = Align.CENTER,
      valign = Align.START
    };
    _result_detail.add_css_class( "flash-subtitle" );

    var done = new Button.with_mnemonic( _( "_Done" ) ) {
      use_underline = true
    };
    done.add_css_class( "pill" );
    done.clicked.connect(() => {
      destroy();
    });

    var retake = new Button.with_mnemonic( _( "_Retake" ) ) {
      use_underline = true
    };
    retake.add_css_class( "pill" );
    retake.add_css_class( "suggested-action" );
    retake.clicked.connect(() => {
      initialize_test();
      show_question();
    });

    var bbox = new Box( Orientation.HORIZONTAL, 10 ) {
      halign     = Align.CENTER,
      valign     = Align.END,
      margin_top = 20
    };
    bbox.append( retake );
    bbox.append( done );

    var hint = new Label( _( "Press D for Done, R to Retake" ) ) {
      halign     = Align.CENTER,
      margin_top = 8
    };
    hint.add_css_class( "flash-hint" );

    _result_box = new Box( Orientation.VERTICAL, 4 ) {
      focusable = true,
      halign    = Align.CENTER,
      valign    = Align.CENTER,
      vexpand   = true
    };
    _result_box.append( _result );
    _result_box.append( _result_detail );
    _result_box.append( bbox );
    _result_box.append( hint );

    var key = new EventControllerKey();
    _result_box.add_controller( key );
    key.key_pressed.connect((keyval, keymod, state) => {
      switch( keyval ) {
        case Gdk.Key.d :  done.clicked();    return( true );
        case Gdk.Key.r :  retake.clicked();  return( true );
        default        :  return( false );
      }
    });

    return( _result_box );

  }

}
