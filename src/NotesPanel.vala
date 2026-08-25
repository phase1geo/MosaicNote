/*
* Copyright (c) 2024-2026 (https://github.com/phase1geo/MosaicNote)
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

public enum NoteSortType {
  TITLE,
  CREATED,
  UPDATED,
  VIEWED,
  NUM;

  public string to_string() {
    switch( this ) {
      case TITLE   :  return( "title" );
      case CREATED :  return( "created" );
      case UPDATED :  return( "updated" );
      case VIEWED  :  return( "viewed" );
      default      :  assert_not_reached();
    }
  }

  public string label() {
    switch( this ) {
      case TITLE   :  return( _( "Title" ) );
      case CREATED :  return( _( "Date Created" ) );
      case UPDATED :  return( _( "Date Last Updated" ) );
      case VIEWED  :  return( _( "Date Last Viewed" ) );
      default      :  assert_not_reached();
    }
  }

  public static NoteSortType parse( string val ) {
    switch( val ) {
      case "title"   :  return( TITLE );
      case "created" :  return( CREATED );
      case "updated" :  return( UPDATED );
      case "viewed"  :  return( VIEWED );
      default        :  return( TITLE );
    }
  }

  //-------------------------------------------------------------
  // Compares the note titles in ascending order.
  private int title_compare_ascend( Note a, Note b ) {
    return( strcmp( a.title, b.title ) );
  }

  //-------------------------------------------------------------
  // Compares the note titles in descending order.
  private int title_compare_descend( Note a, Note b ) {
    return( strcmp( b.title, a.title ) );
  }

  //-------------------------------------------------------------
  // Compares two dates.
  private int date_compare( DateTime a, DateTime b ) {
    return( (int)(a.to_unix() - b.to_unix()) );
  }

  //-------------------------------------------------------------
  // Compares creation dates of two notes in ascending order.
  private int created_compare_ascend( Note a, Note b ) {
    return( date_compare( a.created, b.created ) );
  }

  //-------------------------------------------------------------
  // Compares creation dates of two notes in descending order.
  private int created_compare_descend( Note a, Note b ) {
    return( date_compare( b.created, a.created ) );
  }

  //-------------------------------------------------------------
  // Compares update dates of two notes in ascending order.
  private int updated_compare_ascend( Note a, Note b ) {
    return( date_compare( a.updated, b.updated ) );
  }

  //-------------------------------------------------------------
  // Compares update dates of two notes in descending order.
  private int updated_compare_descend( Note a, Note b ) {
    return( date_compare( b.updated, a.updated ) );
  }

  //-------------------------------------------------------------
  // Compares last viewed dates of two notes in ascending order.
  private int viewed_compare_ascend( Note a, Note b ) {
    return( date_compare( a.viewed, b.viewed ) );
  }

  //-------------------------------------------------------------
  // Compares last viewed dates of two notes in descending order.
  private int viewed_compare_descend( Note a, Note b ) {
    return( date_compare( b.viewed, a.viewed ) );
  }

  //-------------------------------------------------------------
  // Returns the comparison function based on this value and
  // the ascend.
  public int do_compare( Note a, Note b, bool ascend ) {
    if( ascend ) {
      switch( this ) {
        case TITLE   :  return( title_compare_ascend( a, b ) );
        case CREATED :  return( created_compare_ascend( a, b ) );
        case UPDATED :  return( updated_compare_ascend( a, b ) );
        case VIEWED  :  return( viewed_compare_ascend( a, b ) );
        default      :  assert_not_reached();
      }
    } else {
      switch( this ) {
        case TITLE   :  return( title_compare_descend( a, b ) );
        case CREATED :  return( created_compare_descend( a, b ) );
        case UPDATED :  return( updated_compare_descend( a, b ) );
        case VIEWED  :  return( viewed_compare_descend( a, b ) );
        default      :  assert_not_reached();
      }
    }
  }
}

public class NoteSorter : Sorter {

  public NoteSortType sort_type { get; set; default = NoteSortType.CREATED; }
  public bool         ascend    { get; set; default = false; }

  //-------------------------------------------------------------
  // Default constructor
  public NoteSorter() {
    sort_type = NoteSortType.parse( MosaicNote.settings.get_string( "notes-sort-type" ) );
    ascend    = MosaicNote.settings.get_boolean( "notes-sort-ascending" );
  }

  //-------------------------------------------------------------
  // Returns the result of comparing the two notes based on the current
  // sort_type and ascend value.
  public override Ordering compare( Object? a, Object? b ) {
    return( Ordering.from_cmpfunc( sort_type.do_compare( (Note)a, (Note)b, ascend ) ) );
  }

}

public class NotesPanel : Box {

  private MainWindow        _win;
	private BaseNotebook?     _bn = null;
	private ListBox           _list;
  private SortListModel     _model;
  private Button            _add;
  private bool              _ignore      = false;
  private MenuButton        _sort;
  private NoteSorter        _sorter;
  private SimpleActionGroup _actions;
  private Note?             _selected_note = null;
  private bool              _restoring_selection = false;
  private bool              _adding_note = false;

  private const GLib.ActionEntry[] action_entries = {
    { "action_duplicate_note",         action_duplicate_note, "i" },
    { "action_delete_note",            action_delete_note, "i" },
    { "action_add_note_from_template", action_add_note_from_template, "i" },
    { "action_import_note",            action_import_note },
    { "action_set_sort_type",          action_set_sort_type, "i" },
    { "action_set_sort_direction",     action_set_sort_direction, "i" },
  };

  public BaseNotebook? current {
    get {
      return( _bn );
    }
  }

  public signal void note_added( Note note );
  public signal void note_deleted( Note note );
  public signal void note_moved( Notebook from_notebook, Note note );
	public signal void note_selected( Note? note, bool note_focus );

  //-------------------------------------------------------------
	// Default constructor
	public NotesPanel( MainWindow win ) {

		Object( orientation: Orientation.VERTICAL, spacing: 5 );

    _win = win;

		_list = new ListBox() {
			valign = Align.FILL,
      vexpand = true,
      focusable = true,
			selection_mode = SelectionMode.BROWSE,
      show_separators = true,
      activate_on_single_click = true
		};

    _sorter = new NoteSorter();
    _model  = new SortListModel( null, _sorter );

    _list.bind_model( _model, create_note );

    var list_key = new EventControllerKey();
    _list.add_controller( list_key );

    list_key.key_pressed.connect((keyval, keycode, state) => {
      if( (keyval == Gdk.Key.Delete) || (keyval == Gdk.Key.BackSpace) ) {
        action_delete();
        return( true );
      }
      return( false );
    });

		_list.row_selected.connect((row) => {
      if( _ignore ) {
        _ignore = false;
        return;
      }
      if( _restoring_selection ) {
        return;
      }
      if( row != null ) {
        var note = (Note)_model.get_item( row.get_index() );
        _selected_note = note;
  			note_selected( note, false );
      }
  	});

    var sw = new ScrolledWindow() {
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = _list
    };

    _actions = new SimpleActionGroup();

		_add = new Button.from_icon_name( "list-add-symbolic" ) {
      has_frame = false,
      margin_end = 5,
      margin_top = 5,
      margin_bottom = 5,
      halign = Align.END,
      hexpand = true,
			tooltip_markup = Utils.tooltip_with_accel( _( "Add new note" ), "<Control>n" ),
      sensitive = false
		};

    var right_click = new GestureClick() {
      button = Gdk.BUTTON_SECONDARY
    };
    _add.add_controller( right_click );

    var templates_menu = new GLib.Menu();

    var add_menu = new GLib.Menu();
    add_menu.append_submenu( _( "Add Note From Template" ), templates_menu );
    add_menu.append( _( "Import Note" ), "notes.action_import_note" );

    var popover = new PopoverMenu.from_model( null ) {
      menu_model = add_menu,
      position   = PositionType.TOP
    };
    popover.set_parent( _add );

    right_click.released.connect((n_press, x, y) => {
      templates_menu.remove_all();
      for( int i=0; i<_win.notebooks.templates.count(); i++ ) {
        var note = _win.notebooks.templates.get_note( i );
        templates_menu.append( note.title, "notes.action_add_note_from_template(%d)".printf( i ) );
      }
      popover.popup();
    });

		_add.clicked.connect(() => {
      add_new_note_to_current_notebook();
		});

    var add_drop_file = new DropTarget( typeof(File), Gdk.DragAction.COPY );
    _add.add_controller( add_drop_file );
    add_drop_file.enter.connect( add_drop_enter );
    add_drop_file.leave.connect( add_drop_leave );
    add_drop_file.drop.connect( add_drop_file_dropped );

    var add_drop_text = new DropTarget( typeof(string), Gdk.DragAction.COPY );
    _add.add_controller( add_drop_text );
    add_drop_text.enter.connect( add_drop_enter );
    add_drop_text.leave.connect( add_drop_leave );
    add_drop_text.drop.connect( add_drop_text_dropped );

    // Create sorting menu
    var sort_menu = create_sort_menu( _actions );

    _sort = new MenuButton() {
      has_frame     = false,
      icon_name     = "view-sort-descending-symbolic",
      halign        = Align.START,
      margin_start  = 5,
      margin_top    = 5,
      margin_bottom = 5,
      menu_model    = sort_menu,
      sensitive     = false,
      tooltip_text  = _( "Change sort order" ),
      direction     = ArrowType.UP
    };

		var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
			valign = Align.END
		};

    bbox.append( _sort );
    bbox.append( _add );

    append( bbox );
		append( sw );

    // Set the stage for menu actions
    _actions.add_action_entries( action_entries, this );
    insert_action_group( "notes", _actions );

    MosaicNote.settings.changed["notes-show-preview"].connect(() => {
      if( _bn != null ) {
        _model.set_model( null );
        _model.set_model( _bn.get_model() );
      }
    });
    MosaicNote.settings.changed["notes-preview-lines"].connect(() => {
      if( _bn != null ) {
        _model.set_model( null );
        _model.set_model( _bn.get_model() );
      }
    });

	}

  //-------------------------------------------------------------
  // Called whenever something is dragged over the add button.
  private Gdk.DragAction add_drop_enter( double x, double y ) {
    _add.add_css_class( "drop-area" );
    return( Gdk.DragAction.COPY );
  }

  //-------------------------------------------------------------
  // Called whenever a drag leaves the add button.
  private void add_drop_leave() {
    _add.remove_css_class( "drop-area" );
  }

  //-------------------------------------------------------------
  // Handles a drop operation of a file over the add button.
  private bool add_drop_file_dropped( Value val, double x, double y ) {
    var file = (val as File);
    var nb   = bn_is_node() ? ((NotebookTree.Node)_bn).get_notebook() : (Notebook)_bn;
    if( file != null ) {
      Import.do_file_import( nb, file, (notebook, note, last) => {
        if( note != null ) {
          notebook.add_note( note );
          _win.undo.add_item( new UndoNoteAdd( note ) );
          note_added( note );
        }
      });
      add_drop_leave();
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Handles a drop operation of a file over the add button.
  private bool add_drop_text_dropped( Value val, double x, double y ) {
    var text = (val as string);
    var nb   = bn_is_node() ? ((NotebookTree.Node)_bn).get_notebook() : (Notebook)_bn;
    if( text != null ) {
      Import.do_text_import( nb, text, (notebook, note, last) => {
        if( note != null ) {
          notebook.add_note( note );
          _win.undo.add_item( new UndoNoteAdd( note ) );
          note_added( note );
        }
      });
      add_drop_leave();
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns the index of the note with the given ID in the sorted
  // list model.
  private int get_index_of( int note_id ) {
    for( int i=0; i<_model.get_n_items(); i++ ) {
      var note = (Note)_model.get_item( i );
      if( note.id == note_id ) {
        return( i );
      }
    }
    return( -1 );
  }

  //-------------------------------------------------------------
  // Creates the sorting menu actions.
  private GLib.Menu create_sort_menu( SimpleActionGroup action_group ) {

    SimpleAction[] type_actions = {};

    var sort_types = new GLib.Menu();

    // Create sort type menu items
    for( int i=0; i<NoteSortType.NUM; i++ ) {
      var sort_type = (NoteSortType)i;
      var action = new SimpleAction.stateful( sort_type.to_string(), null, new Variant.boolean( _sorter.sort_type == sort_type ) );
      action.activate.connect(() => {
        var state = action.get_state();
        var b     = state.get_boolean();
        action.set_state( new Variant.boolean( !b ) );
      });
      action_group.add_action( action );
      sort_types.append( sort_type.label(), "notes.%s".printf( sort_type.to_string() ) );
      type_actions += action;
    }

    var index = 0;
    foreach( var action in type_actions ) {
      var sort_type = (NoteSortType)index++;
      action.activate.connect(() => {
        if( _sorter.sort_type != sort_type ) {
          foreach( var a in type_actions ) {
            a.set_state( new Variant.boolean( false ) );
          }
          action.set_state( new Variant.boolean( true ) );
          _sorter.sort_type = sort_type;
          _sorter.changed( SorterChange.DIFFERENT );
          MosaicNote.settings.set_string( "notes-sort-type", _sorter.sort_type.to_string() );
        }
      });
    }

    // Create sort direction menu items
    var ascending  = new SimpleAction.stateful( "ascending", null, new Variant.boolean( _sorter.ascend ) );
    var descending = new SimpleAction.stateful( "descending", null, new Variant.boolean( !_sorter.ascend ) );

    ascending.activate.connect(() => {
      if( !_sorter.ascend ) {
        ascending.set_state( new Variant.boolean( true ) );
        descending.set_state( new Variant.boolean( false ) );
        _sorter.ascend = true;
        _sorter.changed( SorterChange.INVERTED );
        MosaicNote.settings.set_boolean( "notes-sort-ascending", true );
      }
    });

    descending.activate.connect(() => {
      if( _sorter.ascend ) {
        descending.set_state( new Variant.boolean( true ) );
        ascending.set_state( new Variant.boolean( false ) );
        _sorter.ascend = false;
        _sorter.changed( SorterChange.INVERTED );
        MosaicNote.settings.set_boolean( "notes-sort-ascending", false );
      }
    });

    action_group.add_action( ascending );
    action_group.add_action( descending );

    var dir_types  = new GLib.Menu();
    dir_types.append( _( "Ascending" ), "notes.ascending" );
    dir_types.append( _( "Descending" ), "notes.descending" );

    var sort_menu = new GLib.Menu();
    sort_menu.append_section( null, sort_types );
    sort_menu.append_section( null, dir_types );

    return( sort_menu );

  }

  //-------------------------------------------------------------
  // Returns true if the stored base notebook is from the notebook tree.
  private bool bn_is_node() {
    return( (_bn != null) && ((_bn as NotebookTree.Node) != null) );
  }

  //-------------------------------------------------------------
  // Returns true if the stored base notebook is a notebook (i.e., inbox
  // or trash).
  private bool bn_is_notebook() {
    return( (_bn != null) && ((_bn as Notebook) != null) );
  }

  //-------------------------------------------------------------
  // Update UI from the current notebook
  public void update_notes() {

    if( _selected_note == null ) {
      return;
    }

    var note_id = _selected_note.id;
    var pos     = get_index_of( note_id );

    if( pos >= 0 ) {
      _model.items_changed( pos, 1, 1 );

      // The model change may have caused the ListBox to lose
      // its selection. Restore the row corresponding to the
      // same note.
      Idle.add(() => {
        var index = get_index_of( note_id );
        if( index >= 0 ) {
          var row = _list.get_row_at_index( index );
          if( (row != null) && (_list.get_selected_row() != row) ) {
            _restoring_selection = true;
            _list.select_row( row );
            _restoring_selection = false;
          }
        }
        return( false );
      });

    }

  }

  //-------------------------------------------------------------
	// Populates the notes list from the given notebook
  public void populate_with_notebook( BaseNotebook? bn, bool force = false ) {
    if( ((_bn == bn) && ((bn as SmartNotebook) == null)) || force ) return;
    _bn = bn;
    if( bn != null ) {
      _model.set_model( bn.get_model() );
      var sensitive = bn_is_node() || (bn_is_notebook() && ((_win.notebooks.inbox == (Notebook)_bn) || (_win.notebooks.templates == (Notebook)_bn)));
      _add.sensitive  = sensitive;
      _sort.sensitive = sensitive;
      Idle.add(() => {
        _list.grab_focus();
        return( false );
      });
    } else {
      _model.set_model( null );
      _add.sensitive  = false;
      _sort.sensitive = false;
    }
  }

  //-------------------------------------------------------------
  // Selects the row at the given index.
  public void select_row( int index ) {
    var row = _list.get_row_at_index( index );
    if( row != null ) {
      _list.select_row( row );
    } else {
      note_selected( null, false );
    }
  }

  //-------------------------------------------------------------
  // Selects the row with the given note ID.
  public void select_note( int note_id, bool show_note ) {
    var index = get_index_of( note_id );
    if( index != -1 ) {
      _ignore = !show_note;
      _list.select_row( _list.get_row_at_index( index ) );
    }
  }

  //-------------------------------------------------------------
  // Adds the given note
  private Box create_note( Object obj ) {

    var note = (Note)obj;
    var show_title = Utils.make_title( (note.title == "") ? _( "Untitled Note" ) : note.title );

  	var title = new Label( show_title ) {
      halign = Align.FILL,
      hexpand = true,
      use_markup = true,
      xalign = 0,
      ellipsize = Pango.EllipsizeMode.END
    };

    Box? preview_box = null;

    if( MosaicNote.settings.get_boolean( "notes-show-preview" ) ) {

      var ptext  = note.get_preview_text();
      var pimage = note.get_preview_image_filename();

      preview_box = new Box( Orientation.HORIZONTAL, 5 ) {
        margin_start = 5
      };

      if( ptext != null ) {
        var lines = MosaicNote.settings.get_int( "notes-preview-lines" );
        ptext = ptext.replace( "<", "&lt;" ).replace( ">", "&gt;" );
        var label = new Label( "<small><i>%s</i></small>".printf( ptext ) ) {
          halign = Align.FILL,
          hexpand = true,
          use_markup = true,
          wrap = (lines > 1),
          wrap_mode = Pango.WrapMode.WORD_CHAR,
          lines = lines,
          xalign = 0,
          ellipsize = Pango.EllipsizeMode.END
        };
        preview_box.append( label );
      }

      if( pimage != null ) {
        var picture = new Image.from_file( pimage ) {
          halign = Align.END,
          hexpand = (ptext == null),
          valign = Align.START,
          vexpand = true
        };
        picture.set_size_request( 80, 80 );
        preview_box.append( picture );
      }

    }

    var created = new Label( "<small>" + note.created.format( "%b%e, %Y") + "</small>" ) {
      halign = Align.START,
      use_markup = true,
      xalign = 0,
      ellipsize = Pango.EllipsizeMode.END
    };

    var notebook = new Label( "<small>" + note.notebook.name + "</small>" ) {
      halign = Align.END,
      hexpand = true,
      use_markup = true,
      xalign = 0,
      ellipsize = Pango.EllipsizeMode.START
    };

    var info = new Box( Orientation.HORIZONTAL, 5 );
    info.append( created );
    info.append( notebook );

    var box = new Box( Orientation.VERTICAL, 5 ) {
    	margin_top = 5,
    	margin_bottom = 5,
    	margin_start = 5,
    	margin_end = 5
    };
    box.append( title );
    if( preview_box != null ) {
      box.append( preview_box );
    }
    box.append( info );

    var drag = new DragSource() {
      actions = Gdk.DragAction.MOVE
    };
    box.add_controller( drag );

    drag.prepare.connect((d) => {
      var val = Value( Type.OBJECT );
      val.set_object( note );
      var cp = new Gdk.ContentProvider.for_value( val );
      return( cp );
    });

    drag.drag_end.connect((d, del_data) => {
      try {
        var val = Value( Type.OBJECT );
        if( d.content.get_value( ref val ) ) {
          var nb = bn_is_node() ? ((NotebookTree.Node)_bn).get_notebook() : (Notebook)_bn;
          note_moved( nb, (Note)val.get_object() );
        }
      } catch( Error e ) {}
    });

    var right = new GestureClick() {
      button = Gdk.BUTTON_SECONDARY
    };
    box.add_controller( right );

    var edit_menu = new GLib.Menu();
    edit_menu.append( _( "Duplicate Note" ), "notes.action_duplicate_note(%d)".printf( note.id ) );

    var del_menu = new GLib.Menu();
    del_menu.append( _( "Delete Note" ), "notes.action_delete_note(%d)".printf( note.id ) );

    var menu = new GLib.Menu();
    menu.append_section( null, edit_menu );
    menu.append_section( null, del_menu );

    var popover = new PopoverMenu.from_model( null ) {
      has_arrow = false,
      menu_model = menu
    };
    popover.set_parent( box );

    right.pressed.connect((n_press, x, y) => {
      popover.popup();
    });

    return( box );

  }

  //-------------------------------------------------------------
  // Adds the given note to the notebook and notes panel.
  public void add_note( Note note ) {
    if( note.notebook == _win.notebooks.trash ) {
      note.notebook.move_note( note );
      note_added( note );
    } else {
      note.notebook.add_note( note );
      note_added( note );
    }
  }

  //-------------------------------------------------------------
  // Deletes the given note.  If move_to_trash is true, it will
  // move the note to the trash notebook; otherwise, it will be
  // permanently removed.
  public void delete_note( Note note, bool move_to_trash ) {
    var index = get_index_of( note.id );
    if( index != -1 ) {
      if( (index + 1) < _model.get_n_items() ) {
        _selected_note = (Note)_model.get_item( index + 1 );
      } else if( _model.get_n_items() > 1 ) {
        _selected_note = (Note)_model.get_item( index - 1 );
      } else {
        _selected_note = null;
      }
      if( (note.notebook == _win.notebooks.trash) || !move_to_trash ) {
        note.notebook.delete_note( note );
      } else {
        _win.notebooks.trash.move_note( note );
      }
      note_deleted( note );
    }
  }

  //-------------------------------------------------------------
  // Adds a new note to the current notebook if the notebook can
  // be added to.
  public void add_new_note_to_current_notebook() {
    if( _add.sensitive ) {
      var nb   = bn_is_node() ? ((NotebookTree.Node)_bn).get_notebook() : (Notebook)_bn;
      var note = new Note( nb );
      stdout.printf( "Adding note true\n" );
      _adding_note = true;
      nb.add_note( note );
      _win.undo.add_item( new UndoNoteAdd( note ) );
      note_added( note );
      stdout.printf( "Adding note false\n" );
      _adding_note = false;
    }
  }

  //-------------------------------------------------------------
  // Deletes the currently selected note and moves it to the trash
  // (unless the currently displayed notebook is the trash).
  private void action_delete() {
    _win.note.save();
    var note = _selected_note;
    if( note != null ) {
      _win.undo.add_item( new UndoNoteDelete( note ) );
      delete_note( note, true );
    }
  }

  //-------------------------------------------------------------
  // Duplicates the note with the passed in ID.
  private void action_duplicate_note( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var id    = variant.get_int32();
      var index = get_index_of( id );
      if( index != -1 ) {
        var note     = (Note)_model.get_item( index );
        var nb       = bn_is_node() ? ((NotebookTree.Node)_bn).get_notebook() : (Notebook)_bn;
        var new_note = new Note.copy( nb, note );
        nb.add_note( new_note );
        _win.undo.add_item( new UndoNoteAdd( note ) );
        note_added( note );
      }
    }
  }

  //-------------------------------------------------------------
  // Deletes the note with the passed in ID.
  private void action_delete_note( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var id    = variant.get_int32();
      var index = get_index_of( id );
      if( index != -1 ) {
        var note = (Note)_model.get_item( index );
        _win.undo.add_item( new UndoNoteDelete( note ) );
        delete_note( note, true );
      }
    }
  }

  //-------------------------------------------------------------
  // Adds a new note from an existing template.
  private void action_add_note_from_template( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var index = variant.get_int32();
      var note  = _win.notebooks.templates.get_note( index );
      if( note != null ) {
        var nb = bn_is_node() ? ((NotebookTree.Node)_bn).get_notebook() : (Notebook)_bn;
        nb.add_note( note );
        _win.undo.add_item( new UndoNoteAdd( note ) );
        note_added( note );
      }
    }
  }

  //-------------------------------------------------------------
  // Imports a note from the filesystem.
  private void action_import_note() {
    var nb = bn_is_node() ? ((NotebookTree.Node)_bn).get_notebook() : (Notebook)_bn;
    Import.import_notes( _win, nb, (notebook, note, last) => {
      if( note != null ) {
        notebook.add_note( note );
        _win.undo.add_item( new UndoNoteAdd( note ) );
        note_added( note );
      }
    });
  }

  //-------------------------------------------------------------
  // Sets the sort type of the model sorter to the associated value.
  private void action_set_sort_type( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      _sorter.sort_type = (NoteSortType)variant.get_int32();
      _sorter.changed( SorterChange.DIFFERENT );
      MosaicNote.settings.set_string( "notes-sort-type", _sorter.sort_type.to_string() );
    }
  }

  //-------------------------------------------------------------
  // Sets the sort order of the model sorter.  Updates the sort
  // icon to match.
  private void action_set_sort_direction( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      _sorter.ascend = (variant.get_int32() == 1);
      _sort.icon_name = _sorter.ascend ? "view-sort-ascending-symbolic" : "view-sort-descending-symbolic";
      _sorter.changed( SorterChange.INVERTED );
      MosaicNote.settings.set_boolean( "notes-sort-ascending", _sorter.ascend );
    }
  }

}
