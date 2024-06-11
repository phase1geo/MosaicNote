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

public class NoteItemPaneMarkdown : NoteItemPane {

  private GtkSource.View _text;

  private SpellChecker _spell;

	// Default constructor
	public NoteItemPaneMarkdown( NoteItem item ) {

    base( item );

  }

  // Grabs the focus of the note item at the specified position.
  public override void grab_focus_of_item() {
    _text.grab_focus();
  }

  public override string get_css_data() {
    var font_family = MosaicNote.settings.get_string( "editor-font-family" );
    var font_size   = MosaicNote.settings.get_int( "editor-font-size" );
    var css_data = """
      .markdown-text {
        font-family: %s;
        font-size: %dpt;
      }
    """.printf( font_family, font_size );
  }

  public override void set_buffer_style( GtkSource.StyleScheme style ) {
    var buffer = (GtkSource.Buffer)_text.buffer;
    buffer.style_scheme = style;
  }

  // Adds a new Markdown item at the given position in the content area
  private override void create_pane() {

    _text = create_text( "markdown" );
    var buffer    = (GtkSource.Buffer)text.buffer;

    var style_mgr = new GtkSource.StyleSchemeManager();
    var style     = style_mgr.get_scheme( _win.themes.get_current_theme() );
    buffer.style_scheme = style;

    text.add_css_class( "markdown-text" );

    handle_key_events( _text );

    append( _text );

  }

}