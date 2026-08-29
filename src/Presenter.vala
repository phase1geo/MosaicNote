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

  private const GLib.ActionEntry[] action_entries = {
    { "action_show_next", action_show_next },
    { "action_show_prev", action_show_prev },
  };

  //-------------------------------------------------------------
  // Constructor
  public Presenter( MainWindow win, Note note ) {

    Object(
      transient_for: win
    );

    _win  = win;
    _note = note;

    var settings = new WebKit.Settings() {
      enable_javascript = false
    };

    _viewer = new WebView() {
      focusable = true,
      settings  = settings
    };

    child = _viewer;

    // Make sure that the first slide is shown
    make_temp_dir();
    show_current_slide();

    // Set the stage for menu actions
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "presenter", actions );

    add_keyboard_shortcuts();

  }

  //-------------------------------------------------------------
  // Adds keyboard shortcuts for the menu actions
  private void add_keyboard_shortcuts() {

    var app = _win.application;

    stdout.printf( "HERE\n" );
    app.set_accels_for_action( "presenter.action_show_next", { "<Control>Right" } );
    app.set_accels_for_action( "presenter.action_show_prev", { "<Control>Left" } );

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

    stdout.printf( "Showing current slide\n" );

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

  }

  //-------------------------------------------------------------
  // Displays the next slide if there is a slide to show.
  private void action_show_next() {
    stdout.printf( "Show next\n" );
    if( (_current_row + 1) < _note.rows() ) {
      _current_row++;
      show_current_slide();
    }
  }

  //-------------------------------------------------------------
  // Displays the previous slide if there is a slide to show.
  private void action_show_prev() {
    stdout.printf( "Show previous\n" );
    if( (_current_row - 1) >= 0 ) {
      _current_row--;
      show_current_slide();
    }
  }

}
