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
public class NoteItemPaneMath : NoteItemPane {

  private WebKit.WebView _web;
  private GtkSource.View _text;
  private Button         _help;
  private Gdk.Cursor     _cursor_pointer;
  private Gdk.Cursor     _cursor_text;

  private NoteItemMath math_item {
    get {
      return( (NoteItemMath)item );
    }
  }

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemPaneMath( MainWindow win, NoteItem item, SpellChecker spell ) {
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
    _text.visible = true;
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Called when our item box loses focus.
  public override void clear_current() {
    base.clear_current();
    _text.visible = false;
  }

  //-------------------------------------------------------------
  // Create custom header when the pane is selected.
  protected override Widget create_header1() {

    var entry = new EditableLabel( (math_item.description == "") ? _( "Description (optional)" ) : math_item.description ) {
      halign = Align.FILL,
      hexpand = true
    };

    entry.changed.connect(() => {
      math_item.description = entry.text;
    });

    save.connect(() => {
      math_item.description = entry.text;
    });

    _help = new Button.from_icon_name( "dialog-information-symbolic" ) {
      halign = Align.END,
      tooltip_text = _( "Open AsciiMath documentation in browser" )
    };

    _help.clicked.connect(() => {
      Utils.open_url( "https://asciimath.org/#syntax" );
    });

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( entry );
    box.append( _help );

    return( box );

  }

  //-------------------------------------------------------------
  // Create custom header when the pane is not selected.
  protected override Widget? create_header2() {

    var label = new Label( Utils.make_title( math_item.description ) ) {
      use_markup = true,
      halign = Align.START,
      hexpand = true
    };

    return( label );

  }

  //-------------------------------------------------------------
  // Loads the given HTML into the web viewer.
  private void load_html( string text ) {
    var html = """
      <!DOCTYPE html>
      <html>
        <head>
        <script>
          MathJax = {
            loader: {load: ['input/asciimath', 'output/chtml', 'ui/menu']},
          };
        </script>
        <script type='text/javascript' id='MathJax-script' async
          src='https://cdn.jsdelivr.net/npm/mathjax@3/es5/startup.js'>
        </script>
        </head>
        <body>
          `%s`
        </body>
      </html>
    """.printf( text );
    _web.load_html( html, null );
  }

  //-------------------------------------------------------------
  // Adds a new Markdown item at the given position in the content area
  protected override Widget create_pane() {

    _text = create_text();

    _text.buffer.changed.connect(() => {
      load_html( _text.buffer.text );
    });

    var web_settings = new WebKit.Settings() {
      enable_javascript = true,
      enable_mediasource = true,
      allow_file_access_from_file_urls = true
    };
    _web = new WebKit.WebView() {
      halign = Align.FILL,
      valign = Align.FILL,
      settings = web_settings
    };
    _web.set_size_request( -1, 100 );

    var web_click = new GestureClick();
    _web.add_controller( web_click );

    web_click.pressed.connect((n_press, x, y) => {
      set_as_current();
      _text.visible = true;
      _text.grab_focus();
    });

    if( math_item.content != "" ) {
      load_html( math_item.content );
    }

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( _text );
    box.append( _web );

    handle_key_events( _text );
    handle_key_events( _web );

    return( box );

  }

}