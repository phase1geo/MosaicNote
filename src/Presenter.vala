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
using WebKit;

public class Presenter : Window {

  private MainWindow _win;
  private Note       _note;
  private int        _current_row = 0;
  private WebView    _viewer;
  private string     _temp_dir;
  private Button     _next;
  private Button     _prev;
  private Label      _status;

  //-------------------------------------------------------------
  // Constructor
  public Presenter( MainWindow win, Note note ) {

    _win  = win;
    _note = note;

    var settings = new WebKit.Settings() {
      enable_javascript = true
    };

    _viewer = new WebView() {
      halign    = Align.FILL,
      valign    = Align.FILL,
      hexpand   = true,
      vexpand   = true,
      focusable = true,
      settings  = settings
    };

    _viewer.load_changed.connect((event) => {
      if( event == WebKit.LoadEvent.FINISHED ) {
        zoom_to_fit();
      }
    });

    _status = new Label( "" ) {
      halign = Align.START
    };

    _next = new Button.from_icon_name( "go-next-symbolic" ) {
      halign = Align.END,
      tooltip_markup = Utils.tooltip_with_accel( _( "Next Slide" ), "Right" )
    };
    _next.clicked.connect( action_show_next );

    _prev = new Button.from_icon_name( "go-previous-symbolic" ) {
      halign  = Align.END,
      hexpand = true,
      tooltip_markup = Utils.tooltip_with_accel( _( "Previous Slide" ), "Left" )
    };
    _prev.clicked.connect( action_show_prev );

    var close = new Button.from_icon_name( "window-close-symbolic" ) {
      halign = Align.END,
      tooltip_markup = Utils.tooltip_with_accel( _( "End Presentation" ), "Escape" )
    };
    close.clicked.connect( action_close );

    var bbox = new Box( Orientation.HORIZONTAL, 5 );
    bbox.append( _status );
    bbox.append( _prev );
    bbox.append( _next );
    bbox.append( close );

    var box = new Box( Orientation.VERTICAL, 5 ) {
      halign        = Align.FILL,
      valign        = Align.FILL,
      hexpand       = true,
      vexpand       = true,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    box.append( bbox );
    box.append( _viewer );

    child = box;

    // Make sure that the first slide is shown
    make_temp_dir();
    show_current_slide();

    add_keyboard_shortcuts();

    fullscreen();
    grab_focus();

  }

  //-------------------------------------------------------------
  // Adds keyboard shortcuts for the menu actions
  private void add_keyboard_shortcuts() {

    var controller = new EventControllerKey() {
      propagation_phase = PropagationPhase.CAPTURE
    };

    controller.key_pressed.connect((keyval, keycode, state) => {
      switch( keyval ) {
        case Gdk.Key.Right :
          action_show_next();
          return( true );
        case Gdk.Key.Left :
          action_show_prev();
          return( true );
        case Gdk.Key.Escape :
          action_close();
          return( true );
      }
      return( false );
    });

    ((Gtk.Widget) this).add_controller( controller );

  }

  //-------------------------------------------------------------
  // Creates a temporary directory containing the unarchived
  // Minder files
  private void make_temp_dir() {
    try {
      _temp_dir = DirUtils.make_tmp( "mosaic-note-XXXXXX" );
    } catch( FileError e ) {
      critical( e.message );
    }
  }

  //-------------------------------------------------------------
  // Overrides Pandoc's "readable document" CSS with presentation-
  // friendly styling before handing HTML to the WebView.
  private string make_presentation_html( string html ) {

    string override_css = """
    <style>
      html, body {
        margin: 0 !important;
        padding: 0 !important;
        box-sizing: border-box;
        width: 100% !important;
        height: 100vh !important;
        max-width: none !important;
        max-height: 100vh !important;
        overflow: hidden !important;
        font-size: 200% !important;
      }

      body {
        display: flex !important;
        flex-direction: column !important;
      }

      input[type="checkbox"],
      input[type="radio"] {
        appearance: none;
        -webkit-appearance: none;
        font-size: inherit !important;
        box-sizing: border-box !important;
        width: 0.7em !important;
        height: 0.7em !important;
        margin: 0 0.4em 0 0 !important;
        border: 0.08em solid currentColor;
        vertical-align: middle;
        position: relative;
        background: #fff;
        flex-shrink: 0;
      }

      input[type="checkbox"] { border-radius: 0.15em; }
      input[type="radio"]    { border-radius: 50%; }

      input[type="checkbox"]:checked,
      input[type="radio"]:checked {
        background: #1a1a1a;
      }

      input[type="checkbox"]:checked::after {
        content: "";
        position: absolute;
        left: 0.18em;
        top: 0.01em;
        width: 0.18em;
        height: 0.38em;
        border: solid white;
        border-width: 0 0.13em 0.13em 0;
        transform: rotate(45deg);
      }

      table {
        width: 100%;
        border-collapse: collapse;
        margin: 1em 0;
        font-size: 0.85em;
        box-shadow: 0 0 0 1px #1a1a1a;
        border-radius: 0.3em;
        overflow: hidden;
      }

      thead th {
        background: #1a1a1a;
        color: #fdfdfd;
        font-weight: bold;
        text-align: left;
        padding: 0.5em 0.75em;
        border-bottom: 2px solid #1a1a1a;
      }

      tbody td {
        padding: 0.5em 0.75em;
        border-bottom: 1px solid #d0d0d0;
        vertical-align: middle !important;
      }

      tbody tr:last-child td {
        border-bottom: none;
      }

      tbody tr:nth-child(even) {
        background: #f0f0f0;
      }

      tbody tr:hover {
        background: #e6e6e6;
      }

      /* The title: fixed height, small top margin, never shrinks */
      .title {
        flex: 0 0 auto !important;
        margin: 0.2em 0.3em 0.1em 0.3em !important;
        text-align: center;
      }

      /* Everything else, grouped into one flexible region that
         absorbs all remaining vertical space */
      .slide-content {
        flex: 1 1 auto !important;
        min-height: 0 !important;
        width: 100%;
        display: flex !important;
        flex-direction: column !important;
        align-items: center !important;
        justify-content: center !important;
        overflow: hidden !important;
        padding: 0 40px 20px 40px;
        box-sizing: border-box;
      }

      .slide-content img {
        max-width: 100% !important;
        max-height: 100% !important;
        width: auto !important;
        height: auto !important;
        object-fit: contain !important;
        flex: 1 1 auto;
        min-height: 0;
        display: block;
        margin: 0 auto;
      }

      .slide-content ul, .slide-content ol {
        flex: 0 0 auto;
        margin: 0.2em 0;
      }
    </style>
    <script>
      document.addEventListener('DOMContentLoaded', function() {
        var body = document.body;
        var title = body.querySelector('h1');
        var wrapper = document.createElement('div');
        wrapper.className = 'slide-content';

        // Move every sibling except the title into the wrapper,
        // preserving order.
        var nodes = Array.prototype.slice.call(body.childNodes);
        nodes.forEach(function(node) {
          if (node !== title) {
            wrapper.appendChild(node);
          }
        });

        if (title) {
          title.classList.add('title');
          body.appendChild(title);
        }
        body.appendChild(wrapper);

        var content = document.querySelector('.slide-content');
        if (!content) return;

        function overflowing() {
          return content.scrollHeight > content.clientHeight + 1;
        }

        function fitContent() {
          var maxPercent = 200;  // your normal base size, used when it fits
          var minPercent = 20;   // absolute floor, just to guarantee we terminate
          var lo = minPercent, hi = maxPercent, best = minPercent;

          // Binary search for the largest font-size percentage that
          // does not overflow.
          for (var i = 0; i < 8; i++) {
            var mid = Math.round((lo + hi) / 2);
            document.body.style.fontSize = mid + '%';

            if (overflowing()) {
              hi = mid - 1;
            } else {
              best = mid;
              lo = mid + 1;
            }
          }

          document.body.style.fontSize = best + '%';
        }

        fitContent();

        // Re-fit once every image on the slide has finished loading, in
        // case an image's final size changes how much room text has.
        var images = content.querySelectorAll('img');
        var pending = images.length;

        if (pending === 0) return;

        images.forEach(function(img) {
          if (img.complete) {
            pending--;
            if (pending === 0) fitContent();
          } else {
            img.addEventListener('load', function() {
              pending--;
              if (pending === 0) fitContent();
            });
            // Also count a failed image load as "settled" so we don't
            // wait forever on a broken image reference.
            img.addEventListener('error', function() {
              pending--;
              if (pending === 0) fitContent();
            });
          }
        });
      });
    </script>
    """;

    // Insert right before </head> so it overrides earlier rules
    // (later rules win on equal specificity/order).
    int idx = html.index_of( "</head>" );
    if( idx >= 0 ) {
      return html.substring( 0, idx ) + override_css + html.substring( idx );
    }
    return override_css + html; // fallback if no <head> found
  }

  //-------------------------------------------------------------
  // Displays the current slide.
  private void show_current_slide() {

    var langs    = new Gee.HashSet<string>();
    var item     = _note.get_item( _current_row, 0 );
    var markdown = item.get_markdown( _win.notebooks, true, true );
    var file     = Path.build_filename( _temp_dir, "slide.html" );

    if( item.item_type == NoteItemType.CODE ) {
      langs.add( ((NoteItemCode)item).lang );
    }

    Export.do_export( _win, ExportType.PRESENTER, file, markdown, langs, (filename) => {
      try {
        string html;
        if( FileUtils.get_contents( filename, out html ) ) {
          _viewer.zoom_level = 1.0;
          _viewer.load_html( make_presentation_html( html ), null );
        }
      } catch( FileError e ) {
        critical( e.message );
      }
    } );

    // Update the UI state
    _status.label = "%d / %d".printf( (_current_row + 1), _note.rows() );
    _next.sensitive = (_current_row + 1) < _note.rows();
    _prev.sensitive = (_current_row - 1) >= 0;

  }

  //-------------------------------------------------------------
  // Displays the next slide if there is a slide to show.
  private void action_show_next() {
    if( (_current_row + 1) < _note.rows() ) {
      _current_row++;
      show_current_slide();
    }
  }

  //-------------------------------------------------------------
  // Displays the previous slide if there is a slide to show.
  private void action_show_prev() {
    if( (_current_row - 1) >= 0 ) {
      _current_row--;
      show_current_slide();
    }
  }

  //-------------------------------------------------------------
  // Closes the presentation window and ends the presentation.
  private void action_close() {
    Utils.delete_directory( _temp_dir );
    destroy();
  }

  //-------------------------------------------------------------
  // Convert the javascript result into an appropriate zoom level
  // for the content.
  private void handle_javascript_zoom_result( JSC.Value result, int width, int height ) {

    var context      = result.get_context();
    var width_value  = result.object_get_property( "width" );
    var height_value = result.object_get_property( "height" );

    var content_width  = width_value.to_double();
    var content_height = height_value.to_double();

    if( (content_width <= 0) || (content_height <= 0) ) {
      return;
    }

    var zoom_x = (double)width  / content_width;
    var zoom_y = (double)height / content_height;
    var zoom   = Math.fmin( zoom_x, zoom_y );

    // Don't make the content absurdly small/large.
    zoom = Math.fmax( 0.1, Math.fmin( zoom, 5.0 ) );

    _viewer.zoom_level = zoom;

  }

  //-------------------------------------------------------------
  // Zooms the content to fit the window.
  private void zoom_to_fit () {

    var width  = _viewer.get_width();
    var height = _viewer.get_height();

    if( (width <= 0) || (height <= 0) ) {
      return;
    }

    string javascript = """
      ({
        width: Math.max(
          document.documentElement.scrollWidth,
          document.body ? document.body.scrollWidth : 0
        ),
        height: Math.max(
          document.documentElement.scrollHeight,
          document.body ? document.body.scrollHeight : 0
        )
      })
      """;

    _viewer.evaluate_javascript.begin( javascript, -1, null, null, null, (obj, res) => {
      try {
        var result = _viewer.evaluate_javascript.end (res);
        if( result != null ) {
          handle_javascript_zoom_result( result, width, height );
        }
      } catch( Error e ) {
        warning ("JavaScript error: %s", e.message);
      }
    });

  }

}
