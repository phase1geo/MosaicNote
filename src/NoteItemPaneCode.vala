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

public class NoteItemPaneCode : NoteItemPane {

  private GtkSource.View _text;

	// Default constructor
	public NoteItemPaneCode( MainWindow win, NoteItem item, SpellChecker spell ) {
    base( win, item, spell );
  }

  // Returns the text associated with this panel item
  public override GtkSource.View? get_text() {
    return( _text );
  }

  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement ) {
    place_cursor( _text, placement );
    _text.grab_focus();
  }

  // Returns any CSS data that this pane requires
  public static string get_css_data() {
    var font_size = MosaicNote.settings.get_int( "editor-font-size" );
    var css_data = """
      .code-text {
        font-family: monospace;
        font-size: %dpt;
      }
    """.printf( font_size );
    return( css_data );
  }

  protected override Widget create_pane() {

    var code_item = (NoteItemCode)item;

    _text = create_text( code_item.lang );
    var buffer = (GtkSource.Buffer)_text.buffer;

    var scheme_mgr = new GtkSource.StyleSchemeManager();
    var scheme     = scheme_mgr.get_scheme( MosaicNote.settings.get_string( "default-theme" ) );
    buffer.style_scheme = scheme;

    _text.add_css_class( "code-text" );

    MosaicNote.settings.changed["default-theme"].connect(() => {
      buffer.style_scheme = scheme_mgr.get_scheme( MosaicNote.settings.get_string( "default-theme" ) );
    });

    // Add the handle events
    handle_key_events( _text );

    return( _text );

  }

}