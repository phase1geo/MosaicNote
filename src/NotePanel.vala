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

public class NotePanel : Box {

  private Note? _note = null;

  private MainWindow _win;
  private Stack      _stack;
  private SearchBox  _search;

  private TagBox        _tags;
  private DropDown      _item_selector;
  private Stack         _toolbar_stack;
  private Button        _favorite;
  private Button        _locked;
  private Entry         _title;
  private Box           _created_box;
  private Label         _created;
  private NoteItemPanes _content;
  private Button        _hist_prev;
  private Button        _hist_next;
  private bool          _ignore = false;

  public SearchBox search {
    get {
      return( _search );
    }
  }

  public signal void tag_added( string name, int note_id );
  public signal void tag_removed( string name, int note_id );
  public signal void note_saved( Note note );
  public signal void note_link_clicked( string link, Note note );
  public signal void search_hidden();

  public signal void save();

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

    // Initialize the language manager
    initialize_languages();

    _stack = new Stack() {
      hhomogeneous = true,
      vhomogeneous = true,
      halign       = Align.FILL,
      valign       = Align.FILL
    };

    _stack.add_named( create_blank_ui(),  "blank" );
    _stack.add_named( create_note_ui(),   "note" );
    _stack.add_named( create_search_ui(), "search" );
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

    _tags = new TagBox( _win );
    _tags.added.connect((tag) => {
      tag_added( tag, _note.id );
    });
    _tags.removed.connect((tag) => {
      tag_removed( tag, _note.id );
    });
    _tags.changed.connect(() => {
      _note.tags.copy( _tags.tags );
    });

    var export = new Button.from_icon_name( "document-export-symbolic" ) {
      has_frame = false,
      halign = Align.END,
      tooltip_text = _( "Export note" ),
      margin_start = 5
    };
    export.clicked.connect( export_note );

    _favorite = new Button.from_icon_name( "non-starred-symbolic" ) {
      has_frame = false,
      halign = Align.END,
      tooltip_text = _( "Add to Favorites" ),
    };
    _favorite.clicked.connect(() => {
      if( _favorite.icon_name == "non-starred-symbolic" ) {
        _favorite.icon_name = "starred-symbolic";
        _note.favorite = true;
      } else {
        _favorite.icon_name = "non-starred-symbolic";
        _note.favorite = false;
      }
    });

    _locked = new Button.from_icon_name( "changes-allow-symbolic" ) {
      has_frame = false,
      halign = Align.END,
      tooltip_text = _( "Lock Note" ),
      margin_end = 5
    };
    _locked.clicked.connect(() => {
      set_locked( !_note.locked );
    });

    var tbox = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL
    };
    tbox.append( _tags );
    tbox.append( export );
    tbox.append( _favorite );
    tbox.append( _locked );
    tbox.append( _hist_prev );
    tbox.append( _hist_next );

    handle_nonitem_focus( tbox );

    string[] item_types = {};
    for( int i=0; i<NoteItemType.NUM; i++ ) {
      var type = (NoteItemType)i;
      item_types += type.label();
    }

    _item_selector = new DropDown.from_strings( item_types ) {
      halign = Align.START,
      show_arrow = true,
      selected = 0,
      sensitive = false
    };

    _item_selector.notify["selected"].connect(() => {
      if( _ignore ) {
        _ignore = false;
        return;
      }
      _content.set_current_item_to_type( (NoteItemType)_item_selector.get_selected() );
    });

    // Create the toolbar stack for each item type
    _toolbar_stack = new Stack() {
      halign = Align.FILL,
      hexpand = true
    };

    _toolbar_stack.add_named( new ToolbarItem(), "none" );

    for( int i=0; i<NoteItemType.NUM; i++ ) {
      var type = (NoteItemType)i;
      var toolbar = type.create_toolbar();
      _toolbar_stack.add_named( toolbar, type.to_string() );
    }
    _toolbar_stack.visible_child_name = "none";

    var created_lbl = new Label( _( "Created:" ) );
    _created = new Label( "" );
    _created_box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.END,
      hexpand = true,
      visible = false
    };
    _created_box.append( created_lbl );
    _created_box.append( _created );

    var hbox = new Box( Orientation.HORIZONTAL, 10 ) {
      halign = Align.FILL
    };
    hbox.append( _item_selector );
    hbox.append( _toolbar_stack );
    hbox.append( _created_box );

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
        _note.title = _title.text;
        note_saved( _note );
      }
      _content.get_pane( 0 ).grab_item_focus( TextCursorPlacement.START );
    });

    var separator1 = new Separator( Orientation.HORIZONTAL );

    _content = new NoteItemPanes( _win ) {
      halign = Align.FILL,
      valign = Align.START,
      vexpand = true,
      margin_bottom = 200
    };
    _content.item_selected.connect((pane) => {
      set_toolbar_for_pane( pane );
    });
    _content.note_link_clicked.connect((link) => {
      note_link_clicked( link, _note );
    });

    var cbox = new Box( Orientation.VERTICAL, 5 );
    cbox.add_css_class( "themed" );
    cbox.append( _title );
    cbox.append( _content );

    var sw = new ScrolledWindow() {
      halign = Align.FILL,
      valign = Align.FILL,
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = cbox
    };

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( tbox );
    box.append( hbox );
    box.append( separator1 );
    box.append( sw );

    save.connect(() => {
      if( _note != null ) {
        _note.tags.copy( _tags.tags );
        _note.title = _title.text;
        _content.save();
        note_saved( _note );
      }
    });

    return( box );

	}

  //-------------------------------------------------------------
  // Sets the lock status to the given value and updates the
  // sensitivity of the UI to allow/disallow note data changes.
  private void set_locked( bool lock ) {

    _locked.icon_name = lock ? "changes-prevent-symbolic" : "changes-allow-symbolic";
    _note.locked      = lock;

    // Lock down UI
    _tags.sensitive          = !lock;
    _title.parent.sensitive  = !lock;  // Covers title and content areas
    _favorite.sensitive      = !lock;
    _item_selector.sensitive = !lock;
    _toolbar_stack.sensitive = !lock;

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
      _item_selector.sensitive = false;
      _content.clear_current_item();
      _toolbar_stack.visible_child_name = "none";
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

      _created_box.visible = true;
      _created.label = note.created.format( "%b%e, %Y" );
      _title.text    = note.title;
      _tags.clear_tags();
      _tags.add_tags( note.tags );
      _favorite.icon_name = _note.favorite ? "starred-symbolic" : "non-starred-symbolic";
      _stack.visible_child_name = "note";
      _note.reviewed();

      _content.populate( _note );

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
    stdout.printf( "In update_tags (%s)\n", _note.tags.to_markdown() );
    _tags.clear_tags();
    _tags.add_tags( _note.tags );
  }

  //-------------------------------------------------------------
  // Displays the associated toolbar for the specified pane.  If pane
  // is null, displays the default (blank) toolbar.
  private void set_toolbar_for_pane( NoteItemPane? pane ) {
    if( pane != null ) {
      var toolbar = (ToolbarItem)_toolbar_stack.get_child_by_name( pane.item.item_type.to_string() );
      _item_selector.sensitive = true;
      toolbar.text = pane.get_text();
      toolbar.item = pane.item;
      _ignore = (_item_selector.selected != pane.item.item_type);
      _item_selector.selected = pane.item.item_type;
      _toolbar_stack.visible_child_name = pane.item.item_type.to_string();
    } else {
      _item_selector.sensitive = false;
      _toolbar_stack.visible_child_name = "none";
    }
  }

  //-------------------------------------------------------------
  // Exports the given note
  private void export_note() {

#if GTK410
    var dialog = Utils.make_file_chooser( _( "Export" ), _( "Export" ) );

    dialog.save.begin( _win, null, (obj, res) => {
      try {
        var file = dialog.save.end( res );
        if( file != null ) {
          Export.export( file.get_path(), _note );
        }
      } catch( Error e ) {}
    });
#else
    var dialog = Utils.make_file_chooser( _( "Export" ), _win, FileChooserAction.SAVE, _( "Export" ) );

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        var file = dialog.get_file();
        if( file != null ) {
          Export.export( file.get_path(), _note );
        }
      }
      dialog.destroy();
    });

    dialog.show();
#endif

  }

}