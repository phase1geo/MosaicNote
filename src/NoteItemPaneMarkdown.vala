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

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemPaneMarkdown( MainWindow win, NoteItem item, SpellChecker spell ) {
    base( win, item, spell );
    _cursor_pointer = new Gdk.Cursor.from_name( "pointer", null );
    _cursor_text    = new Gdk.Cursor.from_name( "text", null );
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
  // Checks to see if we need to insert a new Markdown list item
  private bool check_for_markdown_list( TextBuffer buffer, ref TextIter iter, string? str ) {

    if( (str == "\n") || (str == "\t") || (str == null) ) {

      var start_iter = iter;
      var end_iter   = iter;
      start_iter.set_line_offset( 0 );
      end_iter.forward_to_line_end();

      try {

        MatchInfo match;
        var re   = new Regex("""^(\s*)(([*+-])|(\d+)\.)(\s+)""");
        var line = buffer.get_text( start_iter, end_iter, false );

        stdout.printf( "Checking line: (%s)\n", line );

        if( re.match( line, 0, out match ) ) {

          // If we using this function just to see if the given iter line
          // contains a list item, return the status of that now.
          if( str == null ) {
            return( true );
          }

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
              var leading  = match.fetch( 1 );
              var ul       = match.fetch( 3 );
              var ol       = match.fetch( 4 );
              var trailing = match.fetch( 5 );
              var ins_text = "\n" + leading;
              if( ul != "" ) {
                ins_text += ul;
              } else {
                var num = int.parse( ol ) + 1;
                ins_text += num.to_string() + ".";
              }
              ins_text += trailing;
              buffer.insert( ref iter, ins_text, ins_text.length );
              return( true );
            }

          // Otherwise, if the user is inserting a Tab character, so we
          // need to indent the current line
          } else {
            var prev_line = iter;
            prev_line.backward_line();
            if( check_for_markdown_list( buffer, ref prev_line, null ) ) {
              var leading  = match.fetch( 1 );
              var item     = match.fetch( 2 );
              var ul       = match.fetch( 3 );
              var ins_text = string.nfill( _text.tab_width, ' ' ) + leading;  // TODO - We might want to make the leading spaces configurable
              if( ul != "" ) {
                switch( ul ) {
                  case "-" :  ins_text += "*";  break;
                  case "*" :  ins_text += "+";  break;
                  default  :  ins_text += "-";  break;
                }
              } else {
                ins_text += "-";
              }
              var del_end  = start_iter;
              del_end.forward_chars( leading.char_count() + item.char_count() );
              buffer.delete( ref start_iter, ref del_end );
              buffer.insert( ref start_iter, ins_text, ins_text.length ); 
              return( true );
            }
          }

        }

      } catch( RegexError e ) {}

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
  // Adds a new Markdown item at the given position in the content area
  protected override Widget create_pane() {

    _text = create_text( "mosaic-markdown" );
    _text.add_css_class( "markdown-text" );

    _text.buffer.insert_text.connect( check_inserted_text );

    var click = new GestureClick();
    var motion = new EventControllerMotion();
    _text.add_controller( click );
    _text.add_controller( motion );

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

    handle_key_events( _text );

    return( _text );

  }

}