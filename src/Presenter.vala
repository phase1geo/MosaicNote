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

  private const GLib.ActionEntry[] action_entries = {
    { "action_show_next", action_show_next },
    { "action_show_prev", action_show_prev },
  };

  //-------------------------------------------------------------
  // Constructor
  public Presenter( MainWindow win, Note note ) {

    Object(
//      transient_for:  win//,
//      default_width:  600,
 //     default_height: 400
    );

    _win  = win;
    _note = note;

    var settings = new WebKit.Settings() {
      enable_javascript = false
    };

    _viewer = new WebView() {
      halign    = Align.FILL,
      valign    = Align.FILL,
      hexpand   = true,
      vexpand   = true,
      focusable = true,
      settings  = settings
    };

    _status = new Label( "" ) {
      halign = Align.START
    };

    _next = new Button.from_icon_name( "go-next-symbolic" ) {
      halign = Align.END,
      tooltip_text = _( "Next Slide" )
    };
    _next.clicked.connect( action_show_next );

    _prev = new Button.from_icon_name( "go-previous-symbolic" ) {
      halign  = Align.END,
      hexpand = true,
      tooltip_text = _( "Previous Slide" )
    };
    _prev.clicked.connect( action_show_prev );

    var close = new Button.from_icon_name( "window-close-symbolic" ) {
      halign = Align.END,
      tooltip_text = _( "End Presentation" )
    };
    close.clicked.connect(() => {
      Utils.delete_directory( _temp_dir );
      destroy();
    });

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

    // Set the stage for menu actions
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "presenter", actions );

    add_keyboard_shortcuts();

    fullscreen();
    grab_focus();

  }

  //-------------------------------------------------------------
  // Adds keyboard shortcuts for the menu actions
  private void add_keyboard_shortcuts() {

    var controller = new ShortcutController();

    controller.scope = ShortcutScope.GLOBAL;

    var next = new Shortcut(
      new KeyvalTrigger( Gdk.Key.Right, Gdk.ModifierType.CONTROL_MASK ),
      new NamedAction( "presenter.action_show_next" )
    );

    var prev = new Shortcut(
      new KeyvalTrigger( Gdk.Key.Left, Gdk.ModifierType.NO_MODIFIER_MASK ),
      new NamedAction( "presenter.action_show_prev" )
    );

    controller.add_shortcut( next );
    controller.add_shortcut( prev );

    add_controller( controller );

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
  // Displays the current slide.
  private void show_current_slide() {

    var langs    = new Gee.HashSet<string>();
    var item     = _note.get_item( _current_row, 0 );
    var markdown = item.to_markdown( _win.notebooks, true, true );
    var file     = Path.build_filename( _temp_dir, "slide.html" );

    if( item.item_type == NoteItemType.CODE ) {
      langs.add( ((NoteItemCode)item).lang );
    }

    Export.do_export( _win, ExportType.HTML, file, markdown, langs, (filename) => {
      try {
        string html;
        if( FileUtils.get_contents( filename, out html ) ) {
          _viewer.load_html( html, null );
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

}
