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
using Gee;

//-------------------------------------------------------------
// Note item pane that represents Markdown text.  Contains proper
// syntax highlighting as well as support for clicking highlighted
// links.
public class NoteItemPaneMarkdown : NoteItemPane {

  private GtkSource.View _text;
  private Gdk.Cursor     _cursor_pointer;
  private Gdk.Cursor     _cursor_text;
  private Regex          _list_re;
  private int            _last_checked_line = -1;

  private const GLib.ActionEntry[] action_entries = {
    { "action_bold_text",      action_bold_text },
    { "action_italicize_text", action_italicize_text },
    { "action_strike_text",    action_strike_text },
    { "action_highlight_text", action_highlight_text },
    { "action_toggle_task",    action_toggle_task },
  };

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemPaneMarkdown( MainWindow win, NoteItem item, SpellChecker spell ) {

    base( win, item, spell );

    _cursor_pointer = new Gdk.Cursor.from_name( "pointer", null );
    _cursor_text    = new Gdk.Cursor.from_name( "text", null );

    try {
      // 1 = leading whitespace
      // 2 = unordered/ordered list item and/or task
      // 3 = unordered list item with optional task
      // 4 = unordered list item
      // 5 = whitespace between list item and task
      // 6 = task following unordered list item
      // 7 = ordered list item number
      // 8 = standalone task
      // 9 = trailing whitespace
      _list_re = new Regex("""^(\s*)((([*+-])(\s*)(\[.\]))|(\d+)\.|(\[.\]))(\s+)""");
    } catch( RegexError e ) {}

    add_keyboard_shortcuts( win.application );

  }

  //-------------------------------------------------------------
  // Adds keyboard shortcuts for the menu actions
  private void add_keyboard_shortcuts( Gtk.Application app ) {
    app.set_accels_for_action( "markdown.action_bold_text",      { "<Control>b" } );
    app.set_accels_for_action( "markdown.action_italicize_text", { "<Control>i" } );
    app.set_accels_for_action( "markdown.action_strike_text",    { "<Control>asciitilde" } );
    app.set_accels_for_action( "markdown.action_highlight_text", { "<Control>equal" } );
    app.set_accels_for_action( "markdown.action_toggle_task",    { "<Control>d" } );
  }

  //-------------------------------------------------------------
  // Returns the stored text widget
  public override GtkSource.View? get_text() {
    return( _text );
  }

  //-------------------------------------------------------------
  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement ) {
    place_cursor( _text, placement );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Populates the extra menu of the text widget.
  public override void populate_extra_menu() {

    var markup = new GLib.Menu();
    markup.append( _( "Bold" ),          "markdown.action_bold_text" );
    markup.append( _( "Italicize" ),     "markdown.action_italicize_text" );
    markup.append( _( "Strikethrough" ), "markdown.action_strike_text" );
    markup.append( _( "Highlight" ),     "markdown.action_highlight_text" );

    var task = new GLib.Menu();
    task.append( _( "Toggle Task" ), "markdown.action_toggle_task" );

    var extra = new GLib.Menu();
    extra.append_section( null, markup );
    extra.append_section( null, task );

    _text.extra_menu = extra;

  }

  //-------------------------------------------------------------
  // Returns CSS data that we need for rendering ourselves
  public static string get_css_data() {
    var font_family = MosaicNote.settings.get_string( "editor-font-family" );
    var font_size   = MosaicNote.settings.get_int( "editor-font-size" );
    var css_data = """
      .markdown-text {
        font-family: %s;
        font-size: %dpt;
      }
    """.printf( font_family, font_size );
    return( css_data );
  }

  //-------------------------------------------------------------
  // Returns true if the given text iterator is within a link.
  private bool iter_within_link( TextIter iter, out TextTag link_tag ) {
    TextTag found_tag = null;
    var within_link = false;
    var tags = iter.get_tags();
    tags.foreach((tag) => {
      if( (tag.name == null) && tag.foreground_set && tag.underline_set ) {
        within_link = true;
        found_tag = tag;
      }
    });
    link_tag = found_tag;
    return( within_link );
  }

  //-------------------------------------------------------------
  // Returns true if the
  private bool within_note_link( TextIter start, TextIter end ) {
    var bstart = start;
    var bend   = end;
    bstart.backward_chars( 2 );
    bend.forward_chars( 2 );
    return( (_text.buffer.get_text( bstart, start, false ) == "[[") &&
            (_text.buffer.get_text( end, bend, false ) == "]]") );
  }

  //-------------------------------------------------------------
  // Returns true if the line containing the given match is within
  // a Markdown link.
  private bool within_markdown_link( string line, MatchInfo match ) {
    int start_pos, end_pos;
    match.fetch_pos( 0, out start_pos, out end_pos );
    var line_start = line.slice( 0, start_pos );
    return( Regex.match_simple( """\]\s*\(\s*$""", line_start ) );
  }

  //-------------------------------------------------------------
  // Checks the given text string to see if it contains the value
  // necessary for inserting a new block.
  private bool check_for_block_change( TextBuffer buffer, ref TextIter iter, string str ) {
    var settings = MosaicNote.settings;
    if( iter.starts_line() && iter.ends_line() ) {
      var new_type = NoteItemType.parse_char( str.get_char( 0 ) );
      if( new_type == NoteItemType.MARKDOWN ) {
        if( settings.get_boolean( "split-markdown-by-header" ) ) {
          if( buffer.text != "" ) {
            TextIter start_iter;
            split_item();
            var next_buf = next_pane.get_text().buffer;
            next_buf.get_iter_at_offset( out start_iter, 0 );
            next_buf.insert( ref start_iter, str, str.length );
            Signal.stop_emission_by_name( buffer, "insert_text" );
            return( true );
          }
        }
      } else if( (new_type != NoteItemType.NUM) && settings.get_boolean( "enable-markdown-block-char" ) ) {
        if( buffer.text == "" ) {
          change_item( new_type );
          buffer.text = str;
          Signal.stop_emission_by_name( buffer, "insert_text" );
          return( true );;
        } else {
          var is_end = iter.is_end();
          split_item();
          if( is_end ) {
            next_pane.remove_item( false, false );
          }
          add_item( false, new_type );
          return( true );
        }
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Checks the given text string to see if it contains a note link
  // URI.  Converts it to a clickable note link.
  private bool check_for_note_link( TextBuffer buffer, ref TextIter iter, string str ) {

    if( str.contains( "mosaicnote://show-note?id=" ) ) {

      var offset = iter.get_offset();

      Idle.add(() => {
        TextIter start_iter;
        buffer.get_iter_at_offset( out start_iter, offset );
        var end_iter = start_iter;
        start_iter.set_line_offset( 0 );
        end_iter.forward_to_line_end();
        try {
          MatchInfo match;
          var line = buffer.get_text( start_iter, end_iter, false );
          var re = new Regex( """(\[\[)?mosaicnote://show-note\?id=(\d+)(\]\])?""" );
          if( re.match( line, 0, out match ) && !within_markdown_link( line, match ) ) {
            var note_id = int.parse( match.fetch( 2 ) );
            var note = win.notebooks.find_note_by_id( note_id );
            if( note != null ) {
              int start_pos, end_pos;
              var replace_str = "[[%s]]".printf( note.title );
              match.fetch_pos( 0, out start_pos, out end_pos );
              start_iter.set_line_offset( start_pos );
              end_iter.set_line_offset( end_pos );
              buffer.delete( ref start_iter, ref end_iter );
              buffer.insert_text( ref start_iter, replace_str, replace_str.length );
            }
          }
        } catch( RegexError e ) {}
        return( false );
      });

      return( true );

    }

    return( false );

  }

  //-------------------------------------------------------------
  // Returns true if the given line contains a Markdown list item
  // and/or task.  Populates the given MatchInfo structure with
  // the matching details.
  private bool get_markdown_list_item( TextBuffer buffer, ref TextIter iter, out string line, out MatchInfo match ) {

    var start_iter = iter;
    var end_iter   = iter;
    start_iter.set_line_offset( 0 );
    end_iter.forward_to_line_end();

    line = buffer.get_text( start_iter, end_iter, false );

    return( _list_re.match( line, 0, out match ) );

  }

  //-------------------------------------------------------------
  // Checks to see if we need to insert a new Markdown list item
  private bool check_for_markdown_list( TextBuffer buffer, ref TextIter iter, string str ) {

    if( (str == "\n") || (str == "\t") ) {

      MatchInfo match;
      string line;

      if( get_markdown_list_item( buffer, ref iter, out line, out match ) ) {

        var start_iter = iter;
        var end_iter   = iter;
        start_iter.set_line_offset( 0 );
        end_iter.forward_to_line_end();

        // If the user is inserting a newline character, either add a new
        // list item or delete the current list item
        if( str == "\n" ) {

          // If we have only the list item on the line, clear the list item
          if( match.fetch( 0 ) == line ) {
            start_iter.forward_chars( match.fetch( 1 ).char_count() );
            buffer.delete( ref start_iter, ref end_iter );
            return( true );

          // Otherwise, create the list item on the new line  
          } else {
            var ins_text = "\n" + match.fetch( 1 );
            if( match.fetch( 3 ) != "" ) {
              ins_text += match.fetch( 3 );
            } else if( match.fetch( 8 ) != "" ) {
              ins_text += "[ ]";  // New tasks should be unfinished
            } else {
              var num = int.parse( match.fetch( 7 ) ) + 1;
              ins_text += num.to_string() + ".";
            }
            ins_text += match.fetch( 9 );
            buffer.insert( ref iter, ins_text, ins_text.length );
            return( true );
          }

        // Otherwise, if the user is inserting a Tab character, so we
        // need to indent the current line
        } else {

          var start_fill = string.nfill( _text.tab_width, ' ' );

          if( match.fetch( 8 ) != "" ) {
            buffer.insert( ref start_iter, start_fill, start_fill.length ); 
            return( true );
          }

          MatchInfo prev_match;
          string prev_line = "";
          var prev_iter = iter;
          prev_iter.backward_line();

          if( get_markdown_list_item( buffer, ref prev_iter, out prev_line, out prev_match ) ) {

            // If the current and previous lines are at the same level, we need
            // to change the current line to indent
            if( prev_match.fetch( 1 ).length == match.fetch( 1 ).length ) {
              var ins_text = start_fill + match.fetch( 1 );
              switch( prev_match.fetch( 4 ) ) {
                case "-" :  ins_text += "*";  break;
                case "*" :  ins_text += "+";  break;
                default  :  ins_text += "-";  break;
              }
              if( match.fetch( 6 ) != "" ) {
                ins_text += match.fetch( 5 ) + match.fetch( 6 );
              }
              ins_text += match.fetch( 9 );
              var del_end = start_iter;
              del_end.forward_chars( match.fetch( 0 ).char_count() );
              buffer.delete( ref start_iter, ref del_end );
              buffer.insert( ref start_iter, ins_text, ins_text.length );
              return( true );

            // If the previous and current lines will be at the same level of
            // indentation, make the current line match the previous line
            } else if( prev_match.fetch( 1 ).length == (match.fetch( 1 ).length + start_fill.length) ) {
              var ins_text = prev_match.fetch( 1 );
              if( prev_match.fetch( 2 ) != "" ) {
                ins_text += prev_match.fetch( 4 );
              } else {
                var num = int.parse( prev_match.fetch( 7 ) ) + 1;
                ins_text += num.to_string() + ". ";
              } 
              ins_text += match.fetch( 5 ) + match.fetch( 6 ) + match.fetch( 9 );
              var del_end = start_iter;
              del_end.forward_chars( match.fetch( 0 ).char_count() );
              buffer.delete( ref start_iter, ref del_end );
              buffer.insert( ref start_iter, ins_text, ins_text.length );
              return( true );

            // Otherwise, just go ahead and insert the start_fill
            } else {
              buffer.insert( ref start_iter, start_fill, start_fill.length ); 
              return( true );
            }

          }

        }

      }

    }

    return( false );

  }

  //-------------------------------------------------------------
  // Takes the given task string and returns the toggled version
  // of that task.
  private string get_toggled_task( string task ) {
    switch( task ) {
      case "[ ]" :  return( "[x]" );
      default    :  return( "[ ]" );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the current line has a task can be toggled.
  private void handle_cursor_moved() {

    MatchInfo match;
    TextIter  cursor;
    var buffer = (GtkSource.Buffer)_text.buffer;
    var line   = "";

    buffer.get_iter_at_mark( out cursor, buffer.get_insert() );

    if( cursor.get_line() != _last_checked_line ) {
      var enabled = get_markdown_list_item( buffer, ref cursor, out line, out match ) &&
                    ((match.fetch( 6 ) != "") || (match.fetch( 8 ) != ""));
      action_set_enabled( "markdown.action_toggle_task", enabled );
      _last_checked_line = cursor.get_line();
    }

  }

  //-------------------------------------------------------------
  // Toggles the task on the current line if one exists.
  private bool toggle_task() {

    MatchInfo match;
    TextIter  cursor;
    var buffer = (GtkSource.Buffer)_text.buffer;
    var line   = "";

    buffer.get_iter_at_mark( out cursor, buffer.get_insert() );

    if( get_markdown_list_item( buffer, ref cursor, out line, out match ) ) {
      int start_pos, end_pos;
      var start_iter = cursor;
      var end_iter   = cursor;
      var task       = "";
      if( match.fetch( 6 ) != "" ) {
        match.fetch_pos( 6, out start_pos, out end_pos );
        task = get_toggled_task( match.fetch( 6 ) );
      } else if( match.fetch( 8 ) != "" ) {
        match.fetch_pos( 8, out start_pos, out end_pos );
        task = get_toggled_task( match.fetch( 8 ) );
      } else {
        return( false );
      }
      buffer.get_iter_at_line_offset( out start_iter, cursor.get_line(), start_pos );
      buffer.get_iter_at_line_offset( out end_iter, cursor.get_line(), end_pos );
      buffer.delete( ref start_iter, ref end_iter );
      buffer.insert( ref start_iter, task, task.length );
      return( true );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Checks the inserted text.  If the inserted text needs to be modified,
  // we will setup a second insertion after Idle which will delete and
  // replace the existing text.
  private void check_inserted_text( ref TextIter iter, string str, int strlen ) {
    var buffer = (GtkSource.Buffer)_text.buffer;
    if( check_for_block_change( buffer, ref iter, str ) ||
        check_for_markdown_list( buffer, ref iter, str ) ) {
      Signal.stop_emission_by_name( buffer, "insert_text" );
      return;
    }
    if( check_for_note_link( buffer, ref iter, str ) ) {
      return;
    }
  }

  //-------------------------------------------------------------
  // Adds an optional description entry field for the code.
  protected override Widget create_header1() {

    var bold = new Button() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Bold" ), "<Control>b" ),
      child = create_label( " <b>B</b> " )
    };
    bold.clicked.connect( insert_bold );

    var italics = new Button() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Italic" ), "<Control>i" ),
      child = create_label( " <i>I</i> " )
    };
    italics.clicked.connect( insert_italics );

    var strike = new Button() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Strikethrough" ), "<Control>asciitilde" ),
      child = create_label( " <s>S</s>" )
    };
    strike.clicked.connect( insert_strike );

    var code = new Button() {
      has_frame = false,
      tooltip_text = _( "Code Block" ),
      child = create_label( "{ }" )
    };
    code.clicked.connect( insert_code );

    var hilite = new Button() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Highlight" ), "<Control>equal" ),
      child = create_label( "<span background='#ffff00'> <b>H</b> </span>" )
    };
    hilite.clicked.connect( insert_highlight );

    var link = new Button.from_icon_name( "insert-link-symbolic" ) {
      has_frame = false,
      tooltip_text = _( "Add Link" )
    };
    link.clicked.connect( insert_link );

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( bold );
    box.append( italics );
    box.append( strike );
    box.append( code );
    box.append( hilite );
    box.append( link );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates a button label.
  private Widget create_label( string markup ) {
    var lbl = new Label( "<span size=\"large\">" + markup + "</span>" ) {
      use_markup = true
    };
    return( lbl );
  }

  //-------------------------------------------------------------
  // Adds bold Markdown syntax around currently selected code.
  private void insert_bold() {
    MarkdownFuncs.insert_bold_text( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds italic Markdown syntax around currently selected code.
  private void insert_italics() {
    MarkdownFuncs.insert_italicize_text( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds strikethrough Markdown syntax around currently selected code.
  private void insert_strike() {
    MarkdownFuncs.insert_strikethrough_text( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds code Markdown syntax around currently selected code.
  private void insert_code() {
    MarkdownFuncs.insert_code_text( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds code highlighting syntax around currently selected text.
  private void insert_highlight() {
    MarkdownFuncs.insert_highlight_text( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds link Markdown syntax around currently selected code.
  private void insert_link() {
    MarkdownFuncs.insert_link_text( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds a new Markdown item at the given position in the content area
  protected override Widget create_pane() {

    _text = create_text( "mosaic-markdown" );
    _text.add_css_class( "markdown-text" );

    var buffer = (GtkSource.Buffer)_text.buffer;
    buffer.insert_text.connect( check_inserted_text );
    buffer.cursor_moved.connect( handle_cursor_moved );

    var click  = new GestureClick();
    var motion = new EventControllerMotion();
    var key    = new EventControllerKey();
    _text.add_controller( click );
    _text.add_controller( motion );
    _text.add_controller( key );

    motion.motion.connect((x, y) => {
      TextIter iter;
      TextTag  link_tag;
      if( _text.get_iter_at_location( out iter, (int)x, (int)y ) ) {
        if( iter_within_link( iter, out link_tag ) ) {
          _text.set_cursor( _cursor_pointer );
        } else {
          _text.set_cursor( _cursor_text );
        }
      } else {
        _text.set_cursor( _cursor_text );
      }
    });

    click.released.connect((n_press, x, y) => {
      if( n_press == 1 ) {
        TextIter start;
        TextTag  link_tag;
        if( _text.get_iter_at_location( out start, (int)x, (int)y ) ) {
          if( iter_within_link( start, out link_tag ) ) {
            var end = start;
            start.backward_to_tag_toggle( link_tag );
            end.forward_to_tag_toggle( link_tag );
            var link = _text.buffer.get_text( start, end, false ).strip();
            if( within_note_link( start, end ) ) {
              note_link_clicked( link );
            } else {
              Utils.open_url( link );
            }
          }
        }
      }
    });

    key.key_pressed.connect((keyval, keycode, state) => {
      var control = (bool)(state & Gdk.ModifierType.CONTROL_MASK);
      var shift   = (bool)(state & Gdk.ModifierType.SHIFT_MASK);
      switch( keyval ) {
        case Gdk.Key.d :
          if( control ) {
            toggle_task();
            return( true );
          }
          break;
        case Gdk.Key.b :
          if( control ) {
            insert_bold();
            return( true );
          }
          break;
        case Gdk.Key.i :
          if( control ) {
            insert_italics();
            return( true );
          }
          break;
        case Gdk.Key.asciitilde :
          if( control ) {
            insert_strike();
            return( true );
          }
          break;
        case Gdk.Key.equal :
          if( control ) {
            insert_highlight();
            return( true );
          }
          break;
        case Gdk.Key.z :
          if( control ) {
            if( shift ) {
              buffer.redo();
            } else {
              buffer.undo();
            }
            return( true );
          }
          break;
      }
      return( false );
    });

    handle_key_events( _text );

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, _text );
    insert_action_group( "markdown", actions );

    return( _text );

  }

  //-------------------------------------------------------------
  // Emboldens selected text.
  private void action_bold_text() {
    insert_bold();
  }

  //-------------------------------------------------------------
  // Italicizes selected text.
  private void action_italicize_text() {
    insert_italics();
  }

  //-------------------------------------------------------------
  // Strikes through selected text.
  private void action_strike_text() {
    insert_strike();
  }

  //-------------------------------------------------------------
  // Highlights selected text.
  private void action_highlight_text() {
    insert_highlight();
  }

  //-------------------------------------------------------------
  // Toggles the current task
  private void action_toggle_task() {
    toggle_task();
  }

}
