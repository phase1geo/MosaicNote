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
    // base();
  }

  //-------------------------------------------------------------
  // Returns the result of comparing the two notes based on the current
  // sort_type and ascend value.
  public override Ordering compare( Object? a, Object? b ) {
    return( Ordering.from_cmpfunc( sort_type.do_compare( (Note)a, (Note)b, ascend ) ) );
  }

}

public class NotesPanel : Box {

  private MainWindow    _win;
	private BaseNotebook? _bn = null;
	private ListBox       _list;
  private SortListModel _model;
  private Button        _add;
  private bool          _ignore      = false;
  private MenuButton    _sort;
  private NoteSorter    _sorter;

  private const GLib.ActionEntry[] action_entries = {
    { "action_set_sort_type",      action_set_sort_type, "i" },
    { "action_set_sort_direction", action_set_sort_direction, "i" },
  };

	public signal void note_selected( Note? note );

	// Default constructor
	public NotesPanel( MainWindow win ) {

		Object( orientation: Orientation.VERTICAL, spacing: 5 );

    _win = win;

		_list = new ListBox() {
			valign = Align.FILL,
      vexpand = true,
			selection_mode = SelectionMode.BROWSE,
      show_separators = true
		};

    _sorter = new NoteSorter();
    _model  = new SortListModel( null, _sorter );

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
      } else {
  			if( row == null ) {
          note_selected( null );
        } else {
    			note_selected( (Note)_model.get_item( row.get_index() ) );
        }
        _list.grab_focus();
      }
  	});

		_add = new Button.from_icon_name( "list-add-symbolic" ) {
      has_frame = false,
      margin_start = 5,
      margin_top = 5,
      margin_bottom = 5,
      halign = Align.START,
			tooltip_text = _( "Add new note" ),
      sensitive = false
		};

		_add.clicked.connect(() => {
      var nb = bn_is_node() ? ((NotebookTree.Node)_bn).get_notebook() : (Notebook)_bn;
			var note = new Note( nb );
			nb.add_note( note );
      populate_with_notebook( _bn );
      _list.select_row( _list.get_row_at_index( nb.count() - 1 ) );
		});

    var actions = new SimpleActionGroup();

    // Create sorting menu
    var sort_menu = create_sort_menu( actions );

    _sort = new MenuButton() {
      has_frame  = false,
      icon_name  = "view-sort-descending-symbolic",
      halign     = Align.END,
      hexpand    = true,
      menu_model = sort_menu,
      sensitive  = false
    };

		var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
			valign = Align.END
		};

		bbox.append( _add );
    bbox.append( _sort );

		append( _list );
		append( bbox );

    /* Set the stage for menu actions */
    actions.add_action_entries( action_entries, this );
    insert_action_group( "notes", actions );

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
      }
    });

    descending.activate.connect(() => {
      if( _sorter.ascend ) {
        descending.set_state( new Variant.boolean( true ) );
        ascending.set_state( new Variant.boolean( false ) );
        _sorter.ascend = false;
        _sorter.changed( SorterChange.INVERTED );
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
    var row = _list.get_selected_row();
    if( row != null ) {
      var pos = row.get_index();
      _model.items_changed( pos, 1, 1 );
      _list.select_row( _list.get_row_at_index( pos ) );
    }
  }

  //-------------------------------------------------------------
	// Populates the notes list from the given notebook
  public void populate_with_notebook( BaseNotebook? bn ) {
    _bn = bn;
    if( bn != null ) {
      _model.set_model( bn.get_model() );
      _list.bind_model( _model, create_note );
      var sensitive = bn_is_node() || (bn_is_notebook() && (_win.notebooks.inbox == (Notebook)_bn));
      _add.sensitive  = sensitive;
      _sort.sensitive = sensitive;
    } else {
      _model.set_model( null );
      _list.bind_model( null, create_note );
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
      note_selected( null );
    }
  }

  //-------------------------------------------------------------
  // Selects the row with the given note ID.
  public void select_note( int note_id, bool show_note ) {
    for( int i=0; i<_model.get_n_items(); i++ ) {
      var note = (Note)_model.get_object( i );
      if( note.id == note_id ) {
        _ignore = !show_note;
        _list.select_row( _list.get_row_at_index( i ) );
        return;
      }
    }
  }

  //-------------------------------------------------------------
  // Adds the given note
  private Box create_note( Object obj ) {

    var note = (Note)obj;
    var show_title = Utils.make_title( (note.title == "") ? _( "Untitled Note" ) : note.title );

  	var title = new Label( show_title ) {
      use_markup = true,
      xalign = 0,
      ellipsize = Pango.EllipsizeMode.END
    };

    var preview = new Label( "<small>" + note.created.format( "%b%e, %Y") + "</small>" ) {
      use_markup = true,
      xalign = 0,
      ellipsize = Pango.EllipsizeMode.END
    };

    var box = new Box( Orientation.VERTICAL, 5 ) {
    	margin_top = 5,
    	margin_bottom = 5,
    	margin_start = 5,
    	margin_end = 5
    };
    box.append( title );
    box.append( preview );

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

    return( box );

  }

  //-------------------------------------------------------------
  // Deletes the currently selected note and moves it to the trash
  // (unless the currently displayed notebook is the trash).
  private void action_delete() {
    var row = _list.get_selected_row();
    if( row != null ) {
      var note = (Note)_model.get_item( row.get_index() );
      _win.smart_notebooks.remove_note( note );
      _win.full_tags.delete_note_tags( note );
      if( note.notebook == _win.notebooks.trash ) {
        note.notebook.delete_note( note );
      } else {
        _win.notebooks.trash.move_note( note );
      }
      populate_with_notebook( _bn );
    }
  }

  //-------------------------------------------------------------
  // Sets the sort type of the model sorter to the associated value.
  private void action_set_sort_type( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      _sorter.sort_type = (NoteSortType)variant.get_int32();
      _sorter.changed( SorterChange.DIFFERENT );
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
    }
  }

}