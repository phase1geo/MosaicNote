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

public class NotePanel : Box {

  private Note? _note = null;

  private MainWindow _win;
  private Stack      _stack;
  private SearchBox  _search;
  private ImageView  _image_viewer;

  private TagBox          _tags;
  private Button          _favorite;
  private Button          _locked;
  private Entry           _title;
  private NoteItemPanes   _content;
  private Button          _hist_prev;
  private Button          _hist_next;
  private ListBox         _references;
  private bool            _ignore = false;
  private HashSet<string> _orig_link_titles;

  private const GLib.ActionEntry[] action_entries = {
    { "action_copy_note_link",   action_copy_note_link },
    { "action_save_as_template", action_save_as_template },
    { "action_export_as",        action_export_as, "i" },
  };

  public TagBox tags {
    get {
      return( _tags );
    }
  }

  public SearchBox search {
    get {
      return( _search );
    }
  }

  public Entry title {
    get {
      return( _title );
    }
  }

  public NoteItemPanes items {
    get {
      return( _content );
    }
  }

  public signal void tag_added( string name, int note_id );
  public signal void tag_removed( string name, int note_id );
  public signal void favorite_changed( Note note );
  public signal void note_saved( Note note, HashSet<string>? orig_link_titles );
  public signal void note_link_clicked( string link, Note note );
  public signal void search_hidden();
  public signal void note_item_removed( NoteItem item );

  public signal void save();
  public signal void save_as_template( Note note );

  //-------------------------------------------------------------
	// Default constructor
	public NotePanel( MainWindow win ) {

    Object(
      orientation: Orientation.VERTICAL,
      spacing: 5,
      margin_top: 5,
      margin_bottom: 5,
      margin_start: 5,
      margin_end: 5
    );

    _win = win;
    _orig_link_titles = new HashSet<string>();

    // Initialize the language manager
    initialize_languages();

    _stack = new Stack() {
      hhomogeneous = true,
      vhomogeneous = true,
      halign       = Align.FILL,
      valign       = Align.FILL
    };

    _image_viewer = new ImageView( win );
    _image_viewer.viewer_closed.connect(() => {
      _stack.visible_child_name = "note";
    });

    _stack.add_named( create_blank_ui(),  "blank" );
    _stack.add_named( create_note_ui(),   "note" );
    _stack.add_named( create_search_ui(), "search" );
    _stack.add_named( _image_viewer,      "imageview" );
    _stack.visible_child_name = "blank";

    append( _stack );

    // Initialize the theme
    update_theme( _win.themes.get_current_theme() );

    // Handle any theme updates
    MosaicNote.settings.changed.connect((key) => {
      switch( key ) {
        case "editor-font-family" :
        case "editor-font-size"   :  update_theme( _win.themes.get_current_theme() );  break;
      }
    });

    _win.themes.theme_changed.connect((theme) => {
      update_theme( theme );
    });

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "note", actions );

  }

  //-------------------------------------------------------------
  // Initialize the language manager to include the specialty
  // languages that MosaicNote provides (includes PlantUML and
  // Mosaic-Markdown).
  private void initialize_languages() {

    foreach( var data_dir in Environment.get_system_data_dirs() ) {
      var path = GLib.Path.build_filename( data_dir, "mosaic-note", "gtksourceview-5" );
      if( FileUtils.test( path, FileTest.EXISTS ) ) {
        var lang_path = GLib.Path.build_filename( path, "language-specs" );
        var manager   = GtkSource.LanguageManager.get_default();
        manager.append_search_path( lang_path );
        break;
      }
    }

  }

  //-------------------------------------------------------------
  // Updates the CSS controlling the display of the note items
  // and updates the style context for the specified theme name.
  private void update_theme( string theme ) {

    var style_mgr = GtkSource.StyleSchemeManager.get_default();
    var style     = style_mgr.get_scheme( theme );

    var provider = new CssProvider();
    var css_data = """
      %s
      %s
      .themed {
        background-color: %s;
      }
    """.printf( NoteItemPaneMarkdown.get_css_data(), NoteItemPaneCode.get_css_data(), style.get_style( "text" ).background );
#if GTK412
    provider.load_from_string( css_data );
#else
    provider.load_from_data( css_data.data );
#endif
    StyleContext.add_provider_for_display( get_display(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

  }

  //-------------------------------------------------------------
  // Creates the blank UI
  private Widget create_blank_ui() {

    var none = new Label( _( "No Note Selected" ) );
    none.add_css_class( "note-title" );

    return( none );

  }

  //-------------------------------------------------------------
  // Creates the note UI
  private Widget create_note_ui() {

    _tags = new TagBox( _win );
    _tags.added.connect((tag) => {
      _win.undo.add_item( new UndoTagAdd( _note, tag ) );
      tag_added( tag, _note.id );
    });
    _tags.removed.connect((tag) => {
      _win.undo.add_item( new UndoTagDelete( _note, tag ) );
      tag_removed( tag, _note.id );
    });
    _tags.changed.connect(() => {
      _note.tags.copy( _tags.tags );
    });

    _favorite = new Button.from_icon_name( "non-starred-symbolic" ) {
      has_frame = false,
      halign = Align.END,
      tooltip_text = _( "Add To Favorites" ),
      margin_start = 5
    };
    _favorite.clicked.connect(() => {
      if( _favorite.icon_name == "non-starred-symbolic" ) {
        _favorite.icon_name = "starred-symbolic";
        _favorite.tooltip_text = _( "Remove From Favorites" );
        _note.favorite = true;
      } else {
        _favorite.icon_name = "non-starred-symbolic";
        _favorite.tooltip_text = _( "Add To Favorites" );
        _note.favorite = false;
      }
      favorite_changed( _note );
    });

    var export_menu = new GLib.Menu();
    for( int i=0; i<ExportType.NUM; i++ ) {
      var etype = (ExportType)i;
      export_menu.append( etype.label(), "note.action_export_as(%d)".printf( i ) );
    }

    var more_menu = new GLib.Menu();
    more_menu.append( _( "Copy Note Link" ), "note.action_copy_note_link" );
    more_menu.append( _( "Save Note As Template" ), "note.action_save_as_template" );
    more_menu.append_submenu( _( "Export Note As" ), export_menu );
    // more_menu.append( _( "Lock note" ), "note.action_lock" );

    var more = new MenuButton() {
      has_frame  = false,
      icon_name  = "open-menu-symbolic",
      margin_end = 5,
      menu_model = more_menu
    };

    _hist_prev = new Button.from_icon_name( "go-previous-symbolic" ) {
      sensitive = false,
      has_frame = false,
      tooltip_text = _( "Show Last Viewed Note" ),
      margin_start = 5
    };
    _hist_prev.clicked.connect(() => {
      _win.history.go_backward();
    });

    _hist_next = new Button.from_icon_name( "go-next-symbolic" ) {
      sensitive = false,
      has_frame = false,
      tooltip_text = _( "Show Next Viewed Note" ),
      margin_end = 5
    };
    _hist_next.clicked.connect(() => {
      _win.history.go_forward();
    });

    var tbox = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL
    };
    tbox.append( _tags );
    tbox.append( _favorite );
    tbox.append( more );
    tbox.append( _hist_prev );
    tbox.append( _hist_next );

    handle_nonitem_focus( tbox );

    _title = new Entry() {
      has_frame = false,
      placeholder_text = _( "Title (Optional)" ),
      halign = Align.FILL
    };
    _title.add_css_class( "note-title" );
    _title.add_css_class( "themed" );

    handle_nonitem_focus( _title );

    _title.activate.connect(() => {
      if( _note != null ) {
        _win.undo.add_item( new UndoTitleChange( _note ) );
        _note.title = _title.text;
        note_saved( _note, null );
      }
      _content.get_pane( 0 ).grab_item_focus( TextCursorPlacement.START );
    });

    var separator1 = new Separator( Orientation.HORIZONTAL );

    _content = new NoteItemPanes( _win ) {
      halign = Align.FILL,
      valign = Align.START,
      vexpand = true,
    };
    _content.item_removed.connect((pane) => {
      note_item_removed( pane.item );
    });
    _content.note_link_clicked.connect((link) => {
      note_link_clicked( link, _note );
    });
    _content.show_images.connect((items, index) => {
      _image_viewer.populate( items, index );
      _stack.visible_child_name = "imageview";
    });

    var references = create_references();

    var cbox = new Box( Orientation.VERTICAL, 5 );
    cbox.add_css_class( "themed" );
    cbox.append( _title );
    cbox.append( _content );
    cbox.append( references );

    var sw = new ScrolledWindow() {
      halign = Align.FILL,
      valign = Align.FILL,
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = cbox
    };

    _content.see.connect((y, height) => {
      var dy  = (double)y;
      var dh  = (double)height;
      var adj = sw.vadjustment;
      if( (adj.value > dy) || ((dy + dh) >= (adj.value + adj.page_size)) ) {
        adj.value = dy;
      }
    });

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( tbox );
    box.append( separator1 );
    box.append( sw );

    save.connect(() => {
      if( _note != null ) {
        _note.tags.copy( _tags.tags );
        _note.title = _title.text;
        _content.save();
        note_saved( _note, _orig_link_titles );
      }
    });

    return( box );

	}

  //-------------------------------------------------------------
  // Creates the list of notes which contain links to this note.
  private Box create_references() {

    var label = new Label( Utils.make_title( _( "Notes Linked To This Note" ) ) ) {
      halign = Align.START,
      use_markup = true
    };

    var sep = new Separator( Orientation.HORIZONTAL );

    _references = new ListBox() {
      halign = Align.START,
      selection_mode = SelectionMode.NONE
    };

    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_top = 20,
      margin_bottom = 200
    };
    box.append( label );
    box.append( sep );
    box.append( _references );

    return( box );

  }

  //-------------------------------------------------------------
  // Adds the list of notes that reference
  private void add_references() {
    Utils.clear_listbox( _references );
    if( _note.referred.size == 0 ) {
      var label = new Label( _( "<i>None</i>" ) ) {
        use_markup = true,
        margin_top = 5,
        margin_bottom = 5
      };
      _references.append( label );
    } else {
      _note.referred.foreach((id) => {
        var ref_note = _win.notebooks.find_note_by_id( id );
        if( ref_note != null ) {
          var dash = new Label( "-" );
          var link = new LinkButton( (ref_note.title == "") ? _( "Untitled Note" ) : ref_note.title );
          link.activate_link.connect(() => {
            _win.sidebar.select_notebook( ref_note.notebook );
            _win.notes.select_note( ref_note.id, true );
            return( true );
          });
          var box = new Box( Orientation.HORIZONTAL, 5 ) {
            margin_top = 5,
            margin_bottom = 5
          };
          box.append( dash );
          box.append( link );
          _references.append( box );
        }
        return( true );
      });
    }
  }

  //-------------------------------------------------------------
  // Sets the lock status to the given value and updates the
  // sensitivity of the UI to allow/disallow note data changes.
  private void set_locked( bool lock ) {

    // _locked.icon_name = lock ? "changes-prevent-symbolic" : "changes-allow-symbolic";
    _note.locked      = lock;

    // Lock down UI
    _tags.sensitive          = !lock;
    _title.parent.sensitive  = !lock;  // Covers title and content areas
    _favorite.sensitive      = !lock;

  }

  //-------------------------------------------------------------
  // Displays the search UI within the note panel area.
  private SearchBox create_search_ui() {

    _search = new SearchBox( _win ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    _search.hide_search.connect(() => {
      hide_search();
    });

    return( _search );

  }

  //-------------------------------------------------------------
  // Shows the search UI.
  public void show_search( string search_str = "" ) {
    if( _stack.visible_child_name != "search" ) {
      _search.initialize( search_str );
      _stack.visible_child_name = "search";
    }
  }

  //-------------------------------------------------------------
  // Hides the search UI.
  public void hide_search() {
    if( _stack.visible_child_name == "search" ) {
      _stack.visible_child_name = "blank";
      search_hidden();
    }
  }

  //-------------------------------------------------------------
  // Should be called for widgets that are not associated with
  // note item panes.
  private void handle_nonitem_focus( Widget w ) {

    var focus = new EventControllerFocus();
    w.add_controller( focus );

    focus.enter.connect(() => {
      _content.clear_current_item();
    });

  }

  //-------------------------------------------------------------
  // Populates the note panel UI with the contents of the provided note.  If note is
  // null, clears the UI.  If add_to_history is set, we will add this note
  // to the note history.
  public void populate_with_note( Note? note, bool add_to_history ) {

    // If we are populating with the same note as before, return immediately
    if( _note == note ) {
      return;
    }

    // If we had a previously displayed note, save it before populating with the new note
    if( _note != null ) {
      save();
    }

    _note = note;

    if( _note != null ) {

      _title.text    = note.title;
      _tags.clear_tags();
      _tags.add_tags( note.tags );
      _favorite.icon_name = _note.favorite ? "starred-symbolic" : "non-starred-symbolic";
      _stack.visible_child_name = "note";
      _note.reviewed();

      _content.populate( _note );

      _orig_link_titles.clear();
      _note.get_note_links( _orig_link_titles );
      add_references();

      // Update the note history
      if( add_to_history ) {
        _win.history.push_note( _note );
      }
      _hist_prev.sensitive = _win.history.can_go_backward();
      _hist_next.sensitive = _win.history.can_go_forward();

      // Make sure that the title bar has the keyboard focus if it is empty
      if( (_title.text == "") && !_note.locked ) {
        _title.grab_focus();
      }

      set_locked( _note.locked );

    } else {

      _stack.visible_child_name = "blank";

    }

  }

  //-------------------------------------------------------------
  // Updating the tags in the current note.
  public void update_tags() {
    _tags.clear_tags();
    _tags.add_tags( _note.tags );
  }

  //-------------------------------------------------------------
  // Copies a Markdown link to open this note from a different
  // application.
  private void action_copy_note_link() {
    var uri = "mosaicnote://show-note?id=%d".printf( _note.id );
    Gdk.Display.get_default().get_clipboard().set_text( uri );
  }

  //-------------------------------------------------------------
  // Saves this note as a template.
  private void action_save_as_template() {
    save();
    save_as_template( _note );
  }

  //-------------------------------------------------------------
  // Exports the given note
  private void export_note( ExportType etype ) {
    save();
    Export.export_note( _win, etype, _note );
  }

  //-------------------------------------------------------------
  // Export as the given variant.
  private void action_export_as( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var etype = (ExportType)variant.get_int32();
      export_note( etype );
    }
  }
}