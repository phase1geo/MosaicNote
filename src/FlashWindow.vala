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
  private AutoFitLabel                 _question;
  private AutoFitLabel                 _answer;
  private AutoFitLabel                 _choice_question;
  private AutoFitLabel                 _choice_a;
  private AutoFitLabel                 _choice_b;
  private AutoFitLabel                 _choice_c;
  private AutoFitLabel                 _choice_d;
  private Button                       _choice_next;
  private AutoFitLabel                 _result;
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
      default_width: 800,
      default_height: 600
    );

    _item = item;

    _test_stack = new Stack() {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    _test_stack.add_named( create_test_start(),    "start" );
    _test_stack.add_named( create_test_question(), "question" );
    _test_stack.add_named( create_test_answer(),   "answer" );
    _test_stack.add_named( create_test_choice(),   "choice" );
    _test_stack.add_named( create_test_result(),   "result" );

    child = _test_stack;

    update_title();

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
        _choice_a.opacity = 1.0;
        _choice_b.opacity = 1.0;
        _choice_c.opacity = 1.0;
        _choice_d.opacity = 1.0;
        _choice_a.visible = (a != null);
        _choice_b.visible = (b != null);
        _choice_c.visible = (c != null);
        _choice_d.visible = (d != null);
        _choice_next.opacity = 0.0;
        _choice_next.sensitive = false;
        break;
    }

    _test_in_question = true;

    if( _test_type == FlashTestType.CHOICE ) {
      _test_stack.visible_child_name = "choice";
      _choice_question.grab_focus();
    } else {
      _test_stack.visible_child_name = "question";
      _question.grab_focus();
    }

    update_title();

  }

  //-------------------------------------------------------------
  // Marks and grades the user-selected choice for the given
  // multiple choice answer.
  private void grade_choice( NoteItemFlashCard card, AutoFitLabel label, string prefix, int answer, int choice, ref bool correct ) {
    var answer_str = (_choice_question.label == card.side1) ? card.side2 : card.side1;
    if( label.label == prefix.printf( answer_str ) ) {
      label.label = "<span foreground=\"green\">\u2714 %s</span>".printf( label.label );
      correct = (choice == answer);
    } else if( choice == answer ) {
      label.label = "<span foreground=\"red\">\u2718 %s</span>".printf( label.label );
    } else {
      label.opacity = 0.5;
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
        grade_choice( card, _choice_a, _( "a) %s" ), 0, choice, ref correct );
        grade_choice( card, _choice_b, _( "b) %s" ), 1, choice, ref correct );
        grade_choice( card, _choice_c, _( "c) %s" ), 2, choice, ref correct );
        grade_choice( card, _choice_d, _( "d) %s" ), 3, choice, ref correct );
        _choice_next.opacity   = 1.0;
        _choice_next.sensitive = true;
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

    var type_box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.CENTER,
      valign = Align.CENTER,
      vexpand = true
    };
    type_box.append( type_lbl );
    type_box.append( type_dd );

    var run = new Button.with_mnemonic( _( "_Take Quiz" ) ) {
      halign = Align.CENTER,
      valign = Align.END,
      use_underline = true
    };

    run.clicked.connect(() => {
      initialize_test();
      show_question();
    });

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( type_box );
    box.append( run );

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

    _question = new AutoFitLabel( "" ) {
      focusable = true,
      halign = Align.CENTER,
      valign = Align.CENTER,
      vexpand = true
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
      valign = Align.CENTER,
      vexpand = true
    };

    var wrong = new Button.with_mnemonic( _( "_Wrong" ) ) {
      halign = Align.START,
      use_underline = true
    };
    wrong.add_css_class( "wrong-answer" );

    wrong.clicked.connect(() => {
      _test_results.wrong++;
      show_next();
    });

    var right = new Button.with_mnemonic( _( "_Correct" ) ) {
      halign = Align.END,
      use_underline = true
    };
    right.add_css_class( "right-answer" );

    right.clicked.connect(() => {
      _test_results.right++;
      show_next();
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.CENTER,
      valign = Align.END
    };
    bbox.append( wrong );
    bbox.append( right );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( _answer );
    box.append( bbox );

    var key = new EventControllerKey();
    box.add_controller( key );
    key.key_pressed.connect((keyval, keymod, state) => {
      switch( keyval ) {
        case Gdk.Key.w :  wrong.clicked();  return( true );
        case Gdk.Key.c :  right.clicked();  return( true );
        default        :  return( false );
      }
    });

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
      }
    });

  }

  //-------------------------------------------------------------
  // Create a multiple choice UI for up to 4 choices.
  private Widget create_test_choice() {

    _choice_question = new AutoFitLabel( "" ) {
      halign        = Align.FILL,
      valign        = Align.FILL,
      vexpand       = true,
      focusable     = true,
      margin_top    = 10,
      margin_bottom = 10
    };

    _choice_a = new AutoFitLabel( "" ) {
      halign = Align.FILL,
      valign = Align.FILL,
      vexpand = true,
    };
    _choice_b = new AutoFitLabel( "" ) {
      halign = Align.FILL,
      valign = Align.FILL,
      vexpand = true,
    };
    _choice_c = new AutoFitLabel( "" ) {
      halign = Align.FILL,
      valign = Align.FILL,
      vexpand = true,
    };
    _choice_d = new AutoFitLabel( "" ) {
      halign = Align.FILL,
      valign = Align.FILL,
      vexpand = true,
    };

    configure_choice_answer( _choice_a, 0 );
    configure_choice_answer( _choice_b, 1 );
    configure_choice_answer( _choice_c, 2 );
    configure_choice_answer( _choice_d, 3 );

    _choice_next = new Button.with_label( _( "Next" ) ) {
      halign = Align.CENTER,
      margin_top = 10,
      opacity = 0.0,
      sensitive = false
    };
    _choice_next.clicked.connect(() => {
      show_next();
    });

    var box = new Box( Orientation.VERTICAL, 5 ) {
      focusable = true,
      halign = Align.CENTER
    };
    box.append( _choice_question );
    box.append( _choice_a );
    box.append( _choice_b );
    box.append( _choice_c );
    box.append( _choice_d );
    box.append( _choice_next );
    box.set_size_request( 500, -1 );

    var key = new EventControllerKey();
    box.add_controller( key );
    key.key_pressed.connect((keyval, keymod, state) => {
      if( _test_in_question ) {
        switch( keyval ) {
          case Gdk.Key.a :  show_answer( 0 );  return( true );  break;
          case Gdk.Key.b :  show_answer( 1 );  return( true );  break;
          case Gdk.Key.c :  show_answer( 2 );  return( true );  break;
          case Gdk.Key.d :  show_answer( 3 );  return( true );  break;
          default        :  return( false );
        }
      } else if( (keyval == Gdk.Key.space) || (keyval == Gdk.Key.Return) ) {
        show_next();
        return( true );
      }
      return( false );
    });

    return( box );

  }

  //-------------------------------------------------------------
  // Creates the test result frame.
  private Widget create_test_result() {

    _result = new AutoFitLabel( "" ) {
      halign = Align.CENTER,
      valign = Align.CENTER,
      vexpand = true
    };

    var done = new Button.with_mnemonic( _( "_Done" ) ) {
      use_underline = true
    };
    done.clicked.connect(() => {
      destroy();
    });

    var retake = new Button.with_mnemonic( _( "_Retake" ) ) {
      use_underline = true
    };
    retake.clicked.connect(() => {
      initialize_test();
      show_question();
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.CENTER,
      valign = Align.END,
    };
    bbox.append( retake );
    bbox.append( done );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( _result );
    box.append( bbox );

    var key = new EventControllerKey();
    box.add_controller( key );
    key.key_pressed.connect((keyval, keymod, state) => {
      switch( keyval ) {
        case Gdk.Key.d :  done.clicked();    return( true );
        case Gdk.Key.r :  retake.clicked();  return( true );
        default        :  return( false );
      }
    });

    return( box );

  }

}
