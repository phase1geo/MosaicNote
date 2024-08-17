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
  private Gdk.Cursor     _cursor_pointer;
  private Gdk.Cursor     _cursor_text;

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
    _text.grab_focus();
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
        <script type=\"text/javascript\" id=\"MathJax-script\" async
          src=\"https://cdn.jsdelivr.net/npm/mathjax@3/es5/startup.js\">
        </script>
        </head>
        <body>
          `%s`
        </body>
      </html>
    """.printf( text );
    stdout.printf( "html: %s\n", html );
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
    _web.set_size_request( -1, 200 );

    _web.decide_policy.connect((decision, type) => {
      stdout.printf( "type: %s\n", type.to_string() );
      if( type == WebKit.PolicyDecisionType.NAVIGATION_ACTION ) {
        var nav     = (WebKit.NavigationPolicyDecision)decision;
        var action  = nav.get_navigation_action();
        var request = action.get_request();
        var uri     = request.uri;
        stdout.printf( "In decide_policy, uri: %s\n", uri );
//        Utils.open_url( uri );
      }
      decision.use();
      return( false );
    });

    _web.load_failed.connect ((load_event, uri, load_error) => {
      if (load_error is WebKit.NetworkError.CANCELLED) {
        stdout.printf( "HERE B\n" );
          // Mostly initiated by JS redirects
          return false;
      } else if (load_error is WebKit.PolicyError.FRAME_LOAD_INTERRUPTED_BY_POLICY_CHANGE) {
        stdout.printf( "HERE C\n" );
          // A frame load is cancelled because of a download
          return false;
      } else if (load_error is WebKit.PolicyError.CANNOT_SHOW_URI) {
        stdout.printf( "HERE D\n" );
//          open_protocol (uri);
      } else {
        stdout.printf( "HERE E\n" );
      }

      return true;
    });

    _web.load_changed.connect((e) => {
      stdout.printf( "In load_changed, e: %s\n", e.to_string() );
    });

    _web.resource_load_started.connect((resource, request) => {
      stdout.printf( "resource_load_started, request: %s\n", request.uri );
    });

    // NOTE: If we switch things from a load_html to a load_uri, things work properly
    _web.load_uri( "file:///home/trevorw/index.html" );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( _text );
    box.append( _web );

    handle_key_events( _text );

    return( box );

  }

}