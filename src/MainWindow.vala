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
  // private Favorites       _favorites;
  private NotebookTree    _notebooks;
  private SmartNotebooks  _smart_notebooks;
  private FullTags        _full_tags;
  private Themes          _themes;

  private ShortcutsWindow _shortcuts = null;
  private SidebarNew      _sidebar;
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

  public Themes themes {
    get {
      return( _themes );
    }
  }

  /*
  public Favorites favorites {
    get {
      return( _favorites );
    }
  }
  */

  public NotebookTree notebooks {
    get {
      return( _notebooks );
    }
  }

  public SmartNotebooks smart_notebooks {
    get {
      return( _smart_notebooks );
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
    // _favorites       = new Favorites();
    _notebooks       = new NotebookTree();
    _full_tags       = new FullTags( _notebooks );
    _smart_notebooks = new SmartNotebooks( _notebooks );
    _themes          = new Themes();

    /* Create title toolbar */
    header.pack_end( create_miscellaneous() );

    /* Create content area */
    _sidebar = new SidebarNew( this );
    _notes   = new NotesPanel( this );
    _note    = new NotePanel( this );

    _sidebar.notebook_selected.connect((nb) => {
      var notebook = (nb as Notebook);
      _notes.populate_with_notebook( nb );
      if( notebook != null ) {
        MosaicNote.settings.set_int( "last-notebook", notebook.id );
      }
    });

    _notes.note_selected.connect((note) => {
      _note.populate_with_note( note );
      MosaicNote.settings.set_int( "last-note", ((note == null) ? -1 : note.id) );
    });

    _note.tag_added.connect((tag, note_id) => {
      _full_tags.add_tag( tag, note_id );
    });

    _note.tag_removed.connect((tag, note_id) => {
      _full_tags.delete_tag( tag, note_id );
    });

    _note.save_note.connect((note) => {
      _smart_notebooks.handle_note( note );
    });

    _notes_pw = new Paned( Orientation.HORIZONTAL ) {
      start_child        = _notes,
      end_child          = _note,
      resize_start_child = false,
      resize_end_child   = true,
      position           = settings.get_int( "notes-width" )
    };

    _sidebar_pw = new Paned( Orientation.HORIZONTAL ) {
      start_child        = _sidebar,
      end_child          = _notes_pw,
      resize_start_child = false,
      resize_end_child   = true,
      position           = settings.get_int( "sidebar-width" )
    };

    // Make the sidebar paned window the child of the window
    child = _sidebar_pw;

    // Select the notebook and note that was last saved (if valid)
    // TBD - _sidebar.select_notebook_and_note( settings.get_int( "last-notebook" ), settings.get_int( "last-note" ) );

    show();

    /* Handle any request to close the window */
    close_request.connect(() => {
      int width, height;
      get_default_size( out width, out height );
      settings.set_int( "window-w", width );
      settings.set_int( "window-h", height );
      settings.set_int( "sidebar-width", _sidebar_pw.position );
      settings.set_int( "notes-width", _notes_pw.position );
      action_save();
      return( false );
    });

    /* Loads the application-wide CSS */
    load_css();

  }

  /* Loads the application-wide CSS */
  private void load_css() {

    var provider = new CssProvider();
    provider.load_from_resource( "/com/github/phase1geo/mosaic-note/Application.css" );
    StyleContext.add_provider_for_display( get_display(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

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

    app.set_accels_for_action( "win.action_save",        { "<Control>s" } );
    app.set_accels_for_action( "win.action_quit",        { "<Control>q" } );
    app.set_accels_for_action( "win.action_shortcuts",   { "<Control>question" } );
    app.set_accels_for_action( "win.action_preferences", { "<Control>comma" } );

  }

  /* Creates the miscellaneous menu and menu button for the header bar */
  private Widget create_miscellaneous() {

    var menu = new GLib.Menu();
    var img  = new Image.from_icon_name( get_header_icon_name( "emblem-system" ) );

    menu.append( _( "Shorcuts Cheatsheet…" ), "win.action_shortcuts" );
    menu.append( _( "Preferences…" ), "win.action_preferences" );

    var mb = new MenuButton() {
      has_frame = !on_elementary,
      child = img,
      menu_model = menu
    };

    return( mb );

  }

  /* Save everything */
  public void action_save() {
    // _favorites.save();
    _notebooks.save();
    _notebooks.save_notebooks();
    _full_tags.save();
    _smart_notebooks.save();
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
    var prefs = new Preferences( this );
    prefs.show();
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

