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

  private TagBox        _tags;
  private DropDown      _item_selector;
  private Stack         _toolbar_stack;
  private Button        _favorite;
  private Entry         _title;
  private Box           _created_box;
  private Label         _created;
  private NoteItemPanes _content;
  private bool          _ignore = false;

  public signal void tag_added( string name, int note_id );
  public signal void tag_removed( string name, int note_id );
  public signal void save_note( Note note );
  public signal void note_link_clicked( string link, int note_id );

  public signal void save();

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

    _stack.add_named( create_blank_ui(), "blank" );
    _stack.add_named( create_note_ui(), "note" );
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

  // Initialize the language manager to include the specialty languages that MosaicNote
  // provides (includes PlantUML and Mosaic-Markdown).
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
    provider.load_from_data( css_data.data );
    StyleContext.add_provider_for_display( get_display(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

  }

  // Creates the blank UI
  private Widget create_blank_ui() {

    var none = new Label( _( "No Note Selected" ) );
    none.add_css_class( "note-title" );

    return( none );

  }

  // Creates the note UI
  private Widget create_note_ui() {

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
      tooltip_text = _( "Export note" )
    };
    export.clicked.connect( export_note );

    _favorite = new Button.from_icon_name( "non-starred-symbolic" ) {
      has_frame = false,
      halign = Align.END,
      tooltip_text = _( "Add to Favorites" )
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

    var tbox = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL
    };
    tbox.append( _tags );
    tbox.append( export );
    tbox.append( _favorite );

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
        save_note( _note );
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
      note_link_clicked( link, _note.id );
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
      _note.tags.copy( _tags.tags );
      _note.title = _title.text;
      _content.save();
    });

    return( box );

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

  // Populates the note panel UI with the contents of the provided note.  If note is
  // null, clears the UI.
  public void populate_with_note( Note? note ) {

    if( _note != null ) {
      save_note( _note );
    }

    _note = note;

    if( _note != null ) {

      _created_box.visible = true;
      _created.label = note.created.format( "%b%e, %Y" );
      _title.text    = note.title;
      _title.grab_focus();
      _tags.clear_tags();
      _tags.add_tags( note.tags );
      _favorite.icon_name = _note.favorite ? "starred-symbolic" : "non-starred-symbolic";
      _stack.visible_child_name = "note";
      _note.reviewed();

      _content.populate( _note );

    } else {
      _stack.visible_child_name = "blank";
    }

  }

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

  // Exports the given note
  private void export_note() {

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

  }

}