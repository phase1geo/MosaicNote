/*
* Copyright (c) 2023 (https://github.com/phase1geo/Journaler)
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
using Gdk;

public class MainWindow : Gtk.ApplicationWindow {

  private GLib.Settings   _settings;
  private Favorites       _favorites;
  private NotebookTree    _notebooks;
  private FullTags        _full_tags;
  private Notebook?       _notebook = null;

  private ShortcutsWindow _shortcuts = null;
  private Sidebar         _sidebar;
  private NotesPanel      _notes;
  private NotePanel       _note;
  private Paned           _notes_pw;
  private Paned           _sidebar_pw;

  private const GLib.ActionEntry[] action_entries = {
    { "action_save",        action_save },
    { "action_quit",        action_quit },
    { "action_shortcuts",   action_shortcuts },
    { "action_preferences", action_preferences },
  };

  private bool on_elementary = Gtk.Settings.get_default().gtk_icon_theme_name == "elementary";

  public GLib.Settings settings {
    get {
      return( _settings );
    }
  }

  public Favorites favorites {
    get {
      return( _favorites );
    }
  }

  public NotebookTree notebooks {
    get {
      return( _notebooks );
    }
  }

  public FullTags full_tags {
    get {
      return( _full_tags );
    }
  }

  /* Create the main window UI */
  public MainWindow( Gtk.Application app, GLib.Settings settings ) {

    Object( application: app );

    _settings = settings;

    var window_w = settings.get_int( "window-w" );
    var window_h = settings.get_int( "window-h" );

    /* Create the header bar */
    var header = new HeaderBar() {
      show_title_buttons = true,
      title_widget = new Gtk.Label( _( "MosaicNote" ) )
    };
    set_titlebar( header );

    /* Set the main window data */
    set_default_size( window_w, window_h );

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "win", actions );

    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    /* Load application data */
    _favorites = new Favorites();
    _notebooks = new NotebookTree();
    _full_tags = new FullTags();

    /* Create title toolbar */
    // TODO

    /* Create content area */
    _sidebar = new Sidebar( this );
    _sidebar.set_size_request( 200, -1 );
    _notes   = new NotesPanel();
    _notes.set_size_request( 200, -1 );
    _note    = new NotePanel( this );

    _sidebar.selected_notebook.connect((nb) => {
      _notebook = nb;
      _notes.populate_with_notebook( nb );
    });

    _notes.note_selected.connect((note) => {
      _note.populate_with_note( note );
    });

    _notes_pw = new Paned( Orientation.HORIZONTAL ) {
      start_child        = _notes,
      end_child          = _note,
      resize_start_child = false,
      resize_end_child   = true
    };

    _sidebar_pw = new Paned( Orientation.HORIZONTAL ) {
      start_child        = _sidebar,
      end_child          = _notes_pw,
      resize_start_child = false,
      resize_end_child   = true
    };

    // Make the sidebar paned window the child of the window
    child = _sidebar_pw;

    show();

    /* Handle any request to close the window */
    close_request.connect(() => {
      action_save();
      return( false );
    });

    /* Loads the application-wide CSS */
    load_css();

  }

  /* Loads the application-wide CSS */
  private void load_css() {

    // var provider = new CssProvider();
    // provider.load_from_resource( "/com/github/phase1geo/mosaic-note/Application.css" );
    // StyleContext.add_provider_for_display( get_display(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

  }

  /* Returns the name of the icon to use for a headerbar icon */
  private string get_header_icon_name( string icon_name, string? symbolic = null ) {
    if( symbolic == null ) {
      return( "%s%s".printf( icon_name, (on_elementary ? "" : "-symbolic") ) );
    } else {
      return( on_elementary ? icon_name : symbolic );
    }
  }

  /* Adds keyboard shortcuts for the menu actions */
  private void add_keyboard_shortcuts( Gtk.Application app ) {

    app.set_accels_for_action( "win.action_save",                { "<Control>s" } );
    app.set_accels_for_action( "win.action_quit",                { "<Control>q" } );
    app.set_accels_for_action( "win.action_shortcuts",           { "<Control>question" } );
    app.set_accels_for_action( "win.action_preferences",         { "<Control>comma" } );

  }

  /* Save everything */
  public void action_save() {
    _favorites.save();
    _notebooks.save();
    _notebooks.save_notebooks();
    _full_tags.save();
  }

  /* Called when the user uses the Control-q keyboard shortcut */
  private void action_quit() {
    GtkSource.finalize();
    destroy();
  }

  /* Displays the shortcuts cheatsheet */
  private void action_shortcuts() {

    var builder = new Builder.from_resource( "/com/github/phase1geo/mosaic-note/shortcuts.ui" );
    _shortcuts = builder.get_object( "shortcuts" ) as ShortcutsWindow;

    _shortcuts.transient_for = this;
    _shortcuts.view_name     = null;
    _shortcuts.show();

    _shortcuts.close_request.connect(() => {
      _shortcuts = null;
      return( false );
    });

  }

  /* Displays the preferences window and then handles its closing */
  private void action_preferences() {

    /* TODO
    _prefs = new Preferences( this, _journals );
    _prefs.show();

    _prefs.close_request.connect(() => {
      Idle.add(() => {
        if( is_active ) {
          _prefs = null;
          return( false );
        }
        return( true );
      });
      return( false );
    });
    */

  }

  /* Generate a notification */
  public void notification( string title, string msg, NotificationPriority priority = NotificationPriority.NORMAL ) {
    GLib.Application? app = null;
    @get( "application", ref app );
    if( app != null ) {
      var notification = new Notification( title );
      notification.set_body( msg );
      notification.set_priority( priority );
      app.send_notification( "com.github.phase1geo.mosaic-note", notification );
    }
  }

}

