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

public enum MarkdownLinkType {
  NOTE_LINK,
  HEADER_LINK,
  FOOTNOTE,
  URL
}

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

  }

  //-------------------------------------------------------------
  // Destructor
  ~NoteItemPaneMarkdown() {
    if( MosaicNote.debug ) {
      stdout.printf( "NoteItemPaneMarkdown destroyed\n" );
    }
  }

  //-------------------------------------------------------------
  // Returns the stored text widget
  public override GtkSource.View? get_text() {
    return( _text );
  }

  //-------------------------------------------------------------
  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement, int offset = 0 ) {
    place_cursor( _text, placement, offset );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Returns the location of the top of the insertion point.
  public override double get_show_offset() {
    return( get_cursor_y_pos( _text ) );
  }

  //-------------------------------------------------------------
  // Populates the extra menu of the text widget.
  public override void populate_extra_menu() {

    var markup = new GLib.Menu();
    markup.append( _( "Bold" ),          "win.action_text_bold" );
    markup.append( _( "Italicize" ),     "win.action_text_italicize" );
    markup.append( _( "Strikethrough" ), "win.action_text_strike" );
    markup.append( _( "Highlight" ),     "win.action_text_highlight" );
    markup.append( _( "Add Link" ),      "win.action_text_link" );
    markup.append( _( "Add Footnote" ),  "win.action_text_footnote" );

    var task = new GLib.Menu();
    task.append( _( "Toggle Task" ), "win.action_text_toggle_task" );

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
      if( (tag.name == null) && tag.underline_set ) {
        within_link = true;
        found_tag = tag;
      }
    });
    link_tag = found_tag;
    return( within_link );
  }

  //-------------------------------------------------------------
  // Returns the link information for the link located at the given
  // iter.
  private void get_link_info( TextIter iter, TextTag link_tag, out MarkdownLinkType link_type, out string link ) {
    var start = iter;
    var end   = start;
    start.forward_char();
    start.backward_to_tag_toggle( link_tag );
    end.forward_to_tag_toggle( link_tag );
    link = _text.buffer.get_text( start, end, false ).strip();
    if( within_note_link( start, end ) ) {
      link_type = MarkdownLinkType.NOTE_LINK;
    } else if( within_footnote_ref( start, end ) ) {
      link_type = MarkdownLinkType.FOOTNOTE;
    } else if( link.has_prefix("#") ) {
      link_type = MarkdownLinkType.HEADER_LINK;
      link      = link.substring( link.index_of_nth_char( 1 ) );
    } else {
      link_type = MarkdownLinkType.URL;
    }
  }

  //-------------------------------------------------------------
  // Returns true if the clickable link is a note link.
  private bool within_note_link( TextIter start, TextIter end ) {
    var bstart = start;
    var bend   = end;
    bstart.backward_chars( 2 );
    bend.forward_chars( 2 );
    return( (_text.buffer.get_text( bstart, start, false ) == "[[") &&
            (_text.buffer.get_text( end, bend, false ) == "]]") );
  }

  //-------------------------------------------------------------
  // Returns true if the clickable link is a footnote reference.
  private bool within_footnote_ref( TextIter start, TextIter end ) {
    var bstart = start;
    var bend   = end;
    bstart.backward_chars( 2 );
    bend.forward_chars( 1 );
    return( (_text.buffer.get_text( bstart, start, false ) == "[^") &&
            (_text.buffer.get_text( end, bend, false ) == "]") );
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
  // If we are inserting multiple characters at a time, we will assume
  // a paste or drag event, so we will need to 
  private bool check_for_paste( TextBuffer buffer, ref TextIter iter, string str ) {

    var settings = MosaicNote.settings;

    if( (str.char_count() > 1) && settings.get_boolean( "enable-markdown-block-char" ) ) {

      // Create the version of the text that will normally get inserted
      var text        = _text.buffer.text;
      var char_offset = iter.get_offset();
      var byte_offset = text.index_of_nth_char( char_offset );
      text = text.splice( byte_offset, byte_offset, str );

      // Parse the entirety of the modified text.  If the note contains more than one block
      // or the block is not a Markdown block, modify the current note with the new blocks,
      // refresh the note UI, and tell the calling code to stop completing the insert.
      var parser = new NoteParser();
      var note   = parser.parse_markdown( item.row.note.notebook, text, false );

      if( (note.rows() > 1) ||
          ((note.rows() == 1) && (note.get_item( 0, 0 ).item_type != NoteItemType.MARKDOWN)) ||
          (note.footnotes.size > 0) ) {

        int row_pos, col_pos;
        if( item.row.note.get_item_location( item, out row_pos, out col_pos ) ) {

          var start_row = 0;

          // Remove the existing item
          item.row.note.delete_item( row_pos, col_pos );

          if( col_pos > 0 ) {
            item.row.note.add_item( note.get_item( 0, 0 ), row_pos, col_pos, true );
            start_row = 1;
          }

          for( int i=start_row; i<note.rows(); i++ ) {
            item.row.note.add_row( note.get_row( i ), (row_pos + i) );
          }

          // Re-populate the note
          win.note.items.populate( item.row.note );

          // Merge the footnotes
          var footnotes_changed = false;
          note.footnotes.map_iterator().foreach((k, v) => {
            footnotes_changed |= item.row.note.add_footnote( k, v );
            return( true );
          });

          // If the footnotes have changed, update the footnotes section
          if( footnotes_changed ) {
            win.note.add_footnotes();
          }

          // Set the insertion cursor to the correct location, give the new pane focus, and
          // grab keyboard focus
          var pane = win.note.items.get_pane( row_pos, col_pos );
          pane.grab_item_focus( TextCursorPlacement.AT_OFFSET, char_offset );
          pane.set_as_current( true, "check-for-paste" );

          return( true );

        }

      }

    }

    return( false );

  }

  //-------------------------------------------------------------
  // Checks the given text string to see if it contains the value
  // necessary for inserting a new block if we are inserting
  // one character.
  private bool check_for_block_change( TextBuffer buffer, ref TextIter iter, string str ) {
    var settings = MosaicNote.settings;
    if( iter.starts_line() && iter.ends_line() && (str.char_count() == 1) ) {
      var new_type  = NoteItemType.parse_char( str.get_char( 0 ) );
      var pos       = new NoteItemPos.from_pane( this );
      if( new_type == NoteItemType.MARKDOWN ) {
        if( settings.get_boolean( "split-markdown-by-header" ) ) {
          if( buffer.text != "" ) {
            Idle.add(() => {
              TextIter start_iter;
              split_item();
              var next_pane = pos.get_next_pane( NoteItemPos.row_box_from_pane( this ) );
              var next_buf = next_pane.get_text().buffer;
              next_buf.get_iter_at_offset( out start_iter, 0 );
              next_buf.insert( ref start_iter, str, str.length );
              return( false );
            });
            return( true );
          }
        }
      } else if( (new_type != NoteItemType.NUM) && settings.get_boolean( "enable-markdown-block-char" ) ) {
        if( buffer.text == "" ) {
          Idle.add(() => {
            change_item( new_type );
            return( false );
          });
          return( true );;
        } else {
          var is_end = iter.is_end();
          split_item();
          if( is_end ) {
            var next_pane = pos.get_next_pane( NoteItemPos.row_box_from_pane( this ) );
            next_pane.remove_item( false, false );
          }
          add_item( MoveDirection.DOWN, new_type );
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
  // Checks the given text string to see if it contains a footnote
  // reference.  Converts it to a clickable footnote link.
  private bool check_for_footnote( TextBuffer buffer, ref TextIter iter, string str ) {

    // FOOBAR

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
            Idle.add(() => {
              start_iter.forward_chars( match.fetch( 1 ).char_count() );
              buffer.delete( ref start_iter, ref end_iter );
              return( false );
            });
            return( true );

          // Otherwise, create the list item on the new line  
          } else {
            Idle.add(() => {
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
              buffer.insert( ref start_iter, ins_text, ins_text.length );
              return( false );
            });
            return( true );
          }

        // Otherwise, if the user is inserting a Tab character, so we
        // need to indent the current line
        } else {

          var start_fill = string.nfill( _text.tab_width, ' ' );

          if( match.fetch( 8 ) != "" ) {
            Idle.add(() => {
              buffer.insert( ref start_iter, start_fill, start_fill.length ); 
              return( false );
            });
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
              Idle.add(() => {
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
                return( false );
              });
              return( true );

            // If the previous and current lines will be at the same level of
            // indentation, make the current line match the previous line
            } else if( prev_match.fetch( 1 ).length == (match.fetch( 1 ).length + start_fill.length) ) {
              Idle.add(() => {
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
                return( false );
              });
              return( true );

            // Otherwise, just go ahead and insert the start_fill
            } else {
              Idle.add(() => {
                buffer.insert( ref start_iter, start_fill, start_fill.length ); 
                return( false );
              });
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
      action_set_enabled( "win.action_toggle_task", enabled );
      _last_checked_line = cursor.get_line();
    }

  }

  //-------------------------------------------------------------
  // Toggles the task on the current line if one exists.
  public bool toggle_task() {

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
    if( check_for_paste( buffer, ref iter, str ) ||
        check_for_block_change( buffer, ref iter, str ) ||
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
    var bold_id = bold.clicked.connect( insert_bold );
    add_signal( bold, bold_id );

    var italics = new Button() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Italic" ), "<Control>i" ),
      child = create_label( " <i>I</i> " )
    };
    var italics_id = italics.clicked.connect( insert_italics );
    add_signal( italics, italics_id );

    var strike = new Button() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Strikethrough" ), "<Control>minus" ),
      child = create_label( " <s>S</s>" )
    };
    var strike_id = strike.clicked.connect( insert_strike );
    add_signal( strike, strike_id );

    var code = new Button() {
      has_frame = false,
      tooltip_text = _( "Code Block" ),
      child = create_label( "{ }" )
    };
    var code_id = code.clicked.connect( insert_code );
    add_signal( code, code_id );

    var hilite = new Button() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Highlight" ), "<Control>h" ),
      child = create_label( "<span background='#ffff0080'> <b>H</b> </span>" )
    };
    var hilite_id = hilite.clicked.connect( insert_highlight );
    add_signal( hilite, hilite_id );

    var link = new Button.from_icon_name( "insert-link-symbolic" ) {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Add Link" ), "<Control>l" )
    };
    var link_id = link.clicked.connect( insert_link );
    add_signal( link, link_id );

    var footnote = new Button.with_label( "\u2020" ) {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Add Footnote" ), "<Control>t" )
    };
    var footnote_id = footnote.clicked.connect( insert_footnote_ref );
    add_signal( footnote, footnote_id );

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( bold );
    box.append( italics );
    box.append( strike );
    box.append( code );
    box.append( hilite );
    box.append( link );
    box.append( footnote );

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
  public void insert_bold() {
    MarkdownFuncs.insert_bold_text( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds italic Markdown syntax around currently selected code.
  public void insert_italics() {
    MarkdownFuncs.insert_italicize_text( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds strikethrough Markdown syntax around currently selected code.
  public void insert_strike() {
    MarkdownFuncs.insert_strikethrough_text( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds code Markdown syntax around currently selected code.
  public void insert_code() {
    MarkdownFuncs.insert_code_text( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds code highlighting syntax around currently selected text.
  public void insert_highlight() {
    MarkdownFuncs.insert_highlight_text( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds link Markdown syntax around currently selected code.
  public void insert_link() {
    MarkdownFuncs.insert_link_text( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds footnote reference Markdown syntax around currently
  // selected text.
  public void insert_footnote_ref() {
    MarkdownFuncs.insert_footnote_ref( _text, _text.buffer );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Returns true if the given tag potentially indicates an
  // underlined header.
  private bool is_tag_header_underline( TextTag tag ) {

    var green = Gdk.RGBA();
    green.parse( "#2E8B57" );  // This value comes from the style sheet

    return(
      tag.foreground_set &&
      tag.foreground_rgba.equal( green ) &&
      (tag.weight == Pango.Weight.BOLD)
    );

  }

  //-------------------------------------------------------------
  // Returns true if the given tag potentially indicates a definition
  // list item.
  private bool is_tag_def_list( TextTag tag ) {

    var magenta = Gdk.RGBA();
    magenta.parse( "#FF00FF" );

    return( tag.foreground_set && tag.foreground_rgba.equal( magenta ) );

  }

  //-------------------------------------------------------------
  // Checks the given tag and text to see if a header underline
  // is occurring.  If so, tag the line above it with the appropriate
  // header tag.
  private void handle_underline_header_tag_add( TextBuffer buffer, TextTag tag, TextIter start, TextIter end ) {

    // If the tag starts on a linestart and is styled as an underline, continue.
    if( start.starts_line() && (is_tag_header_underline( tag ) || is_tag_def_list( tag )) ) {

      // Next, check to see if the first character is an = or a - character
      var line = buffer.get_text( start, end, true );
      var tag_name = line.has_prefix( "=" ) ? "ul_header1" :
                     line.has_prefix( "-" ) ? "ul_header2" :
                     line.has_prefix( ":" ) ? "definition" : "";
      if( tag_name != "" ) {

        // Position the header_start/end to get the previous line of text
        TextIter header_start, header_end;
        header_start = start;
        header_end   = end;
        header_end.set_line_offset( 0 );
        if( header_start.backward_line() && header_end.backward_line() && (header_end.ends_line() || header_end.forward_to_line_end()) ) {

          // If the previous line of text is not empty, tag it with the appropriate tag
          var header_text = buffer.get_text( header_start, header_end, true ).strip();
          if( (header_text != "") && !header_text.has_prefix( "=" ) && !header_text.has_prefix( "-" ) && !header_text.has_prefix( ":" ) ) {
            buffer.apply_tag_by_name( tag_name, header_start, header_end );
          }
        }
      }
    }

  }

  //-------------------------------------------------------------
  // Checks the given tag and text to see if a header underline
  // is being removed.  Removes header tag of line above in this
  // case.
  private void handle_underline_header_tag_remove( TextBuffer buffer, TextTag tag, TextIter start, TextIter end ) {

    if( is_tag_header_underline( tag ) || is_tag_def_list( tag ) ) {
      TextIter header_start, header_end;
      header_start = start;
      header_end   = end;
      header_end.set_line_offset( 0 );
      if( header_start.backward_line() && header_end.backward_line() && (header_end.ends_line() || header_end.forward_to_line_end()) ) {
        buffer.remove_tag_by_name( "ul_header1", header_start, header_end );
        buffer.remove_tag_by_name( "ul_header2", header_start, header_end );
      }
    }

  }

  //-------------------------------------------------------------
  // Called when text is deleted.  If we are deleting the last
  // text from a given line, check to see if the text would be
  // a header underline character and clean up the line above.
  private void handle_underline_header_delete( TextBuffer buffer, TextIter start, TextIter end ) {

    var line = buffer.get_text( start, end, true ).strip();
    if( start.starts_line() && end.ends_line() && (line.has_prefix( "=" ) || line.has_prefix( "-" )) ) {
      TextIter header_start, header_end;
      header_start = start;
      header_end   = end;
      header_end.set_line_offset( 0 );
      if( header_start.backward_line() && header_end.backward_line() && (header_end.ends_line() || header_end.forward_to_line_end()) ) {
        buffer.remove_tag_by_name( "ul_header1", header_start, header_end );
        buffer.remove_tag_by_name( "ul_header2", header_start, header_end );
      }
    }

  }

  private void handle_def_list_delete( TextBuffer buffer, TextIter start, TextIter end ) {

    var line = buffer.get_text( start, end, true ).strip();
    if( start.starts_line() && line.has_prefix( ":" ) ) {
      TextIter def_start, def_end;
      def_start = start;
      def_end   = end;
      def_end.set_line_offset( 0 );
      if( def_start.backward_line() && def_end.backward_line() && (def_end.ends_line() || def_end.forward_to_line_end()) ) {
        buffer.remove_tag_by_name( "definition", def_start, def_end );
      }
    }

  }

  //-------------------------------------------------------------
  // Adds a new Markdown item at the given position in the content area
  protected override Widget create_pane() {

    _text = create_text( "mosaic-markdown", "mosaic-markdown" );
    _text.add_css_class( "markdown-text" );

    var buffer = (GtkSource.Buffer)_text.buffer;
    var insert_id = buffer.insert_text.connect( check_inserted_text );
    add_signal( buffer, insert_id );

    var cursor_id = buffer.cursor_moved.connect( handle_cursor_moved );
    add_signal( buffer, cursor_id );

    var click  = new GestureClick();
    var motion = new EventControllerMotion();
    var key    = new EventControllerKey();
    _text.add_controller( click );
    _text.add_controller( motion );
    _text.add_controller( key );

    buffer.create_tag( "ul_header1", "scale", Pango.Scale.XX_LARGE, "weight", Pango.Weight.BOLD );
    buffer.create_tag( "ul_header2", "scale", Pango.Scale.X_LARGE, "weight", Pango.Weight.BOLD );
    buffer.create_tag( "definition", "scale", Pango.Scale.LARGE, "weight", Pango.Weight.BOLD );

    var apply_tag_id = buffer.apply_tag.connect((tag, start, end) => {
      handle_underline_header_tag_add( buffer, tag, start, end );
    });
    add_signal( buffer, apply_tag_id );

    var remove_tag_id = buffer.remove_tag.connect((tag, start, end) => {
      handle_underline_header_tag_remove( buffer, tag, start, end );
    });
    add_signal( buffer, remove_tag_id );

    var delete_range_id = buffer.delete_range.connect((start, end) => {
      handle_underline_header_delete( buffer, start, end );
      handle_def_list_delete( buffer, start, end );
    });
    add_signal( buffer, delete_range_id );

    var motion_id = motion.motion.connect((x, y) => {
      TextIter iter;
      TextTag  link_tag;
      if( _text.get_iter_at_location( out iter, (int)x, (int)y ) ) {
        if( iter_within_link( iter, out link_tag ) ) {
          MarkdownLinkType link_type;
          string link;
          _text.set_cursor( _cursor_pointer );
          get_link_info( iter, link_tag, out link_type, out link );
          if( link_type == MarkdownLinkType.FOOTNOTE ) {
            var footnotes = item.row.note.footnotes;
            var tooltip   = "<i>Click to edit footnote</i>";
            if( footnotes.has_key( link ) ) {
              tooltip = footnotes.get( link ) + "\n\n" + tooltip;
            }
            _text.tooltip_markup = tooltip;
          }
          return;
        }
      }
      _text.set_cursor( _cursor_text );
      _text.tooltip_markup = null;
    });
    add_signal( motion, motion_id );

    var released_id = click.released.connect((n_press, x, y) => {
      if( n_press == 1 ) {
        TextIter start;
        TextTag  link_tag;
        if( _text.get_iter_at_location( out start, (int)x, (int)y ) ) {
          if( iter_within_link( start, out link_tag ) ) {
            MarkdownLinkType link_type;
            string link;
            get_link_info( start, link_tag, out link_type, out link );
            switch( link_type ) {
              case MarkdownLinkType.NOTE_LINK   :  note_link_clicked( link );  break;
              case MarkdownLinkType.HEADER_LINK :  header_link_clicked( link );  break;
              case MarkdownLinkType.FOOTNOTE    :  footnote_clicked( link );  break;
              default                           :  Utils.open_url( link );  break;
            }
          }
        }
      }
    });
    add_signal( click, released_id );

    var key_press_id = key.key_pressed.connect((keyval, keycode, state) => {
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
        case Gdk.Key.minus :
          if( control ) {
            insert_strike();
            return( true );
          }
          break;
        case Gdk.Key.h :
          if( control ) {
            insert_highlight();
            return( true );
          }
          break;
        case Gdk.Key.l :
          if( control ) {
            insert_link();
            return( true );
          }
          break;
        case Gdk.Key.t :
          if( control ) {
            insert_footnote_ref();
            return( true );
          }
          break;
      }
      return( false );
    });
    add_signal( key, key_press_id );

    handle_key_events( _text );

    return( _text );

  }

  public override void do_search( NoteSearchFunc command ) {
    command( this, "text", item.content, _text );
  }

}
