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
  private bool iter_within_link( GtkSource.View text, TextIter iter, out TextTag link_tag ) {
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
  // Adds a new Markdown item at the given position in the content area
  protected override void create_pane() {

    _text = create_text( "markdown" );
    _text.add_css_class( "markdown-text" );

    var click = new GestureClick();
    var motion = new EventControllerMotion();
    _text.add_controller( click );
    _text.add_controller( motion );

    motion.motion.connect((x, y) => {
      TextIter iter;
      TextTag  link_tag;
      if( _text.get_iter_at_location( out iter, (int)x, (int)y ) ) {
        if( iter_within_link( _text, iter, out link_tag ) ) {
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
          if( iter_within_link( _text, start, out link_tag ) ) {
            var end = start;
            start.backward_to_tag_toggle( link_tag );
            end.forward_to_tag_toggle( link_tag );
            Utils.open_url( _text.buffer.get_text( start, end, false ) );
          }
        }
      }
    });

    handle_key_events( _text );

    append( _text );

  }

}