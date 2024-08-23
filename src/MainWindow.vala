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
using Gdk;
using Gee;

public enum PanelMode {
  ALL,
  NO_SIDEBAR,
  NOTE_ONLY;

  public string to_string() {
    switch( this ) {
      case ALL        :  return( "all" );
      case NO_SIDEBAR :  return( "no-sidebar" );
      case NOTE_ONLY  :  return( "note-only" );
      default         :  assert_not_reached();
    }
  }

  public static PanelMode parse( string val ) {
    switch( val ) {
      case "all"        :  return( ALL );
      case "no-sidebar" :  return( NO_SIDEBAR );
      case "note-only"  :  return( NOTE_ONLY );
      default           :  return( ALL );
    }
  }

  public PanelMode next_mode() {
    switch( this ) {
      case ALL          :  return( NO_SIDEBAR );
      case NO_SIDEBAR   :  return( NOTE_ONLY );
      case NOTE_ONLY    :  return( ALL );
      default           :  assert_not_reached();
    }
  }

  public PanelMode previous_mode() {
    switch( this ) {
      case ALL          :  return( NOTE_ONLY );
      case NO_SIDEBAR   :  return( ALL );
      case NOTE_ONLY    :  return( NO_SIDEBAR );
      default           :  assert_not_reached();
    }
  }

  public bool show_sidebar() {
    return( this == ALL );
  }

  public bool show_notes() {
    return( (this == ALL) || (this == NO_SIDEBAR) );
  }

}

public class MainWindow : Gtk.ApplicationWindow {

  private GLib.Settings   _settings;
  private NotebookTree    _notebooks;
  private SmartNotebooks  _smart_notebooks;
  private FullTags        _full_tags;
  private Themes          _themes;
  private SmartParser     _parser;
  private NoteHistory     _history;
  private PanelMode       _panel_mode;
  private bool            _ignore = false;

  private ShortcutsWindow _shortcuts = null;
  private Sidebar         _sidebar;
  private NotesPanel      _notes;
  private NotePanel       _note;
  private Paned           _notes_pw;
  private Paned           _sidebar_pw;
  private ToggleButton    _search_mb;
  private UndoBuffer      _undo;
  private Button          _undo_btn;
  private Button          _redo_btn;

  private const GLib.ActionEntry[] action_entries = {
    { "action_save",           action_save },
    { "action_quit",           action_quit },
    { "action_shortcuts",      action_shortcuts },
    { "action_preferences",    action_preferences },
    { "action_search",         action_search },
    { "action_next_panels",    action_next_panels },
    { "action_prev_panels",    action_prev_panels },
    { "action_set_panel_mode", action_set_panel_mode, "i" },
    { "action_undo",           action_undo },
    { "action_redo",           action_redo },
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

  public Sidebar sidebar {
    get {
      return( _sidebar );
    }
  }

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

  public NotesPanel notes {
    get {
      return( _notes );
    }
  }

  public NotePanel note {
    get {
      return( _note );
    }
  }

  public FullTags full_tags {
    get {
      return( _full_tags );
    }
  }

  public SmartParser parser {
    get {
      return( _parser );
    }
  }

  public NoteHistory history {
    get {
      return( _history );
    }
  }

  public UndoBuffer undo {
    get {
      return( _undo );
    }
  }

  //-------------------------------------------------------------
  // Create the main window UI
  public MainWindow( Gtk.Application app, GLib.Settings settings ) {

    Object( application: app );

    _settings   = settings;
    _panel_mode = PanelMode.parse( settings.get_string( "panel-mode" ) );

    _undo = new UndoBuffer( this );
    _undo.buffer_changed.connect( do_buffer_changed );

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
    _notebooks       = new NotebookTree();
    _full_tags       = new FullTags( _notebooks );
    _smart_notebooks = new SmartNotebooks( _notebooks );
    _themes          = new Themes();
    _parser          = new SmartParser( _notebooks );
    _history         = new NoteHistory();

    /* Create title toolbar */
    _undo_btn = new Button.from_icon_name( "edit-undo-symbolic" ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "Undo" ), "<Control>z" ),
      sensitive = false
    };
    _undo_btn.clicked.connect( action_undo );

    _redo_btn = new Button.from_icon_name( "edit-redo-symbolic" ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "Redo" ), "<Control><Shift>z" ),
      sensitive = false
    };
    _redo_btn.clicked.connect( action_redo );

    header.pack_start( create_panel_layout() );
    header.pack_start( _undo_btn );
    header.pack_start( _redo_btn );
    header.pack_end( create_miscellaneous() );
    header.pack_end( create_search() );

    /* Create content area */
    _sidebar = new Sidebar( this );
    _notes   = new NotesPanel( this );
    _note    = new NotePanel( this );

    _sidebar.notebook_selected.connect((nb) => {
      if( nb != null ) {
        var node = (nb as NotebookTree.Node);
        _ignore = true;
        _notes.populate_with_notebook( nb );
        _notes.select_row( 0 );
        if( node != null ) {
          MosaicNote.settings.set_int( "last-notebook", node.get_notebook().id );
        }
      } else {
        _notes.populate_with_notebook( nb );
      }
    });

    _notes.note_selected.connect((note) => {
      if( _ignore ) {
        _ignore = false;
        return;
      }
      _note.populate_with_note( note, true );
      MosaicNote.settings.set_int( "last-note", ((note == null) ? -1 : note.id) );
    });

    _note.tag_added.connect((tag, note_id) => {
      _full_tags.add_tag( tag, note_id );
    });

    _note.tag_removed.connect((tag, note_id) => {
      _full_tags.delete_tag( tag, note_id );
      _notes.update_notes();
    });

    _note.note_saved.connect((note, orig_link_titles) => {
      if( orig_link_titles != null ) {
        update_note_links( note, orig_link_titles );
      }
      _notes.update_notes();
      _smart_notebooks.handle_note( note );
    });

    _note.note_link_clicked.connect((link, start_note) => {
      var note = _notebooks.find_note_by_title( link );
      var nb   = start_note.notebook;
      if( note == null ) {
        note = new Note( nb );
        note.title = link;
        nb.add_note( note );
      }
      _sidebar.select_notebook( nb );
      _notes.select_note( note.id, true );
    });

    _note.search_hidden.connect(() => {
      _search_mb.active = false;
    });

    _history.goto_note.connect((note) => {
      _sidebar.select_notebook( note.notebook );
      _notes.select_note( note.id, true );
    });

    _notes_pw = new Paned( Orientation.HORIZONTAL ) {
      start_child        = _notes,
      end_child          = _note,
      resize_start_child = false,
      resize_end_child   = true,
      shrink_start_child = false,
      position           = settings.get_int( "notes-width" )
    };

    _sidebar_pw = new Paned( Orientation.HORIZONTAL ) {
      start_child        = _sidebar,
      end_child          = _notes_pw,
      resize_start_child = false,
      resize_end_child   = true,
      shrink_start_child = false,
      position           = settings.get_int( "sidebar-width" )
    };

    // Make the sidebar paned window the child of the window
    child = _sidebar_pw;

    // Array the panel layout
    arrange_panels();

    show();

    // Select the notebook and note that was last saved (if valid)
    var last_notebook_id = settings.get_int( "last-notebook" );
    var last_notebook    = _notebooks.find_notebook( last_notebook_id );
    if( last_notebook != null ) {
      var last_note_id = settings.get_int( "last-note" );
      _sidebar.select_notebook( last_notebook );
      _notes.select_note( last_note_id, true );
    }

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

  //-------------------------------------------------------------
  // Loads the application-wide CSS
  private void load_css() {
    var provider = new CssProvider();
    provider.load_from_resource( "/com/github/phase1geo/mosaic-note/Application.css" );
    StyleContext.add_provider_for_display( get_display(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );
  }

  //-------------------------------------------------------------
  // Update the note links associated with the given note.
  private void update_note_links( Note note, HashSet<string> orig_link_titles ) {
    var note_titles = new HashSet<string>();
    note.get_note_links( note_titles );
    note_titles.foreach((title) => {
      if( orig_link_titles.contains( title ) ) {
        orig_link_titles.remove( title );
      } else {
        var linked_note = _notebooks.find_note_by_title( title );
        if( linked_note != null ) {
          linked_note.add_referred( note.id );
        }
      }
      return( true );
    });
    orig_link_titles.foreach((title) => {
      var linked_note = _notebooks.find_note_by_title( title );
      if( linked_note != null ) {
        linked_note.remove_referred( note.id );
      }
      return( true );
    });
  }

  //-------------------------------------------------------------
  // Attempts to display the note with the given ID.  If the note
  // was found, return true.  If the note ID could not be found,
  // return false.
  public bool show_note( int id ) {
    var note = _notebooks.find_note_by_id( id );
    if( note != null ) {
      _sidebar.select_notebook( note.notebook );
      _notes.select_note( note.id, true );
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns the name of the icon to use for a headerbar icon
  private string get_header_icon_name( string icon_name, string? symbolic = null ) {
    if( symbolic == null ) {
      return( "%s%s".printf( icon_name, (on_elementary ? "" : "-symbolic") ) );
    } else {
      return( on_elementary ? icon_name : symbolic );
    }
  }

  //-------------------------------------------------------------
  // Adds keyboard shortcuts for the menu actions
  private void add_keyboard_shortcuts( Gtk.Application app ) {

    app.set_accels_for_action( "win.action_save",        { "<Control>s" } );
    app.set_accels_for_action( "win.action_quit",        { "<Control>q" } );
    app.set_accels_for_action( "win.action_shortcuts",   { "<Control>question" } );
    app.set_accels_for_action( "win.action_preferences", { "<Control>comma" } );
    app.set_accels_for_action( "win.action_search",      { "<Control>f" } );
    app.set_accels_for_action( "win.action_next_panels", { "<Control>b" } );
    app.set_accels_for_action( "win.action_prev_panels", { "<Control><Shift>b" } );
    app.set_accels_for_action( "win.action_undo",        { "<Control>z" } );
    app.set_accels_for_action( "win.action_redo",        { "<Control><Shift>z" } );

  }

  //-------------------------------------------------------------
  // Creates the search UI and returns the menubutton that will go
  // into the header bar to invoke this interface.
  private Widget create_search() {

    _search_mb = new ToggleButton() {
      has_frame = !on_elementary,
      icon_name = get_header_icon_name( "system-search" ),
      tooltip_markup = Utils.tooltip_with_accel( _( "Search notes" ), "<control>f" )
    };

    _search_mb.toggled.connect(() => {
      if( _search_mb.active ) {
        _sidebar.clear_selection();
        _note.show_search();
      } else {
        _note.hide_search();
      }
    });

    return( _search_mb );

  }

  //-------------------------------------------------------------
  // Creates the panel layout UI menubutton.
  private Widget create_panel_layout() {

    var menu = new GLib.Menu();
    menu.append( _( "Show all panels" ),      "win.action_set_panel_mode(%d)".printf( PanelMode.ALL ) );
    menu.append( _( "Show note panel only" ), "win.action_set_panel_mode(%d)".printf( PanelMode.NOTE_ONLY ) );
    menu.append( _( "Do not show sidebar" ),  "win.action_set_panel_mode(%d)".printf( PanelMode.NO_SIDEBAR ) );

    var mb = new MenuButton() {
      has_frame = !on_elementary,
      icon_name  = themes.dark_mode ? "panel-layout-dark-symbolic" : "panel-layout-light-symbolic",
      tooltip_markup = Utils.tooltip_with_accel( _( "Change Panel Layout" ), "<control>b" ),
      menu_model = menu
    };

    themes.theme_changed.connect((theme) => {
      mb.icon_name = themes.dark_mode ? "panel-layout-dark-symbolic" : "panel-layout-light-symbolic";
    });

    return( mb );

  }

  //-------------------------------------------------------------
  // Creates the miscellaneous menu and menu button for the header
  // bar
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

  //-------------------------------------------------------------
  // Save everything
  public void action_save() {
    _note.save();
    _notebooks.save();
    _notebooks.save_notebooks();
    _full_tags.save();
    _smart_notebooks.save();
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-q keyboard shortcut
  private void action_quit() {
    GtkSource.finalize();
    destroy();
  }

  //-------------------------------------------------------------
  // Displays the shortcuts cheatsheet
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

  //-------------------------------------------------------------
  // Displays the preferences window and then handles its closing
  private void action_preferences() {
    var prefs = new Preferences( this );
    prefs.show();
  }

  //-------------------------------------------------------------
  // Activates the note search UI.
  private void action_search() {
    _search_mb.active = true;
  }

  //-------------------------------------------------------------
  // Arrange the panels according to the current panel mode.
  private void arrange_panels() {
    _sidebar.visible = _panel_mode.show_sidebar();
    _notes.visible   = _panel_mode.show_notes();
  }

  //-------------------------------------------------------------
  // Sets the panel mode to a specific value.
  private void action_set_panel_mode( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      _panel_mode = (PanelMode)variant.get_int32();
      _settings.set_string( "panel-mode", _panel_mode.to_string() );
      arrange_panels();
    }
  }

  //-------------------------------------------------------------
  // Show the next panel arrangement.
  private void action_next_panels() {
    _panel_mode = _panel_mode.next_mode();
    _settings.set_string( "panel-mode", _panel_mode.to_string() );
    arrange_panels();
  }

  //-------------------------------------------------------------
  // Show the previous panel arrangement.
  private void action_prev_panels() {
    _panel_mode = _panel_mode.previous_mode();
    _settings.set_string( "panel-mode", _panel_mode.to_string() );
    arrange_panels();
  }

  //-------------------------------------------------------------
  // Undoes the last undoable action.
  private void action_undo() {
    _undo.undo();
  }

  //-------------------------------------------------------------
  // Redoes the action last undone.
  private void action_redo() {
    _undo.redo();
  }

  //-------------------------------------------------------------
  // Called whenever the undo buffer changes state.  Updates the
  // state of the undo and redo buffer buttons.
  public void do_buffer_changed( UndoBuffer buf ) {
    _undo_btn.set_sensitive( buf.undoable() );
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( buf.undo_tooltip(), "<Control>z" ) );
    _redo_btn.set_sensitive( buf.redoable() );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( buf.redo_tooltip(), "<Control><Shift>z" ) );
  }

  //-------------------------------------------------------------
  // Generate a notification.
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

