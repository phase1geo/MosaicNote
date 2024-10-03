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

public class LabelNotebook : BaseNotebook {
  public LabelNotebook( string label ) {
    base( label );
  }
}

public class HiddenNotebook : BaseNotebook {
  public HiddenNotebook() {
    base( "" );
  }
}

public class HiddenSmartNotebook : BaseNotebook {
  public HiddenSmartNotebook() {
    base( "" );
  }
}

public class Sidebar : Box {

	private MainWindow     _win;
	private GLib.ListStore _store;
  private TreeListModel  _model;
	private ListView       _list_view;
  private MenuButton     _add_nb_btn;
  private bool           _adding = false;
  private int            _notebook_add_pos = -1;
  private int            _smart_add_pos = -1;
  private BaseNotebook?  _selected_notebook = null;

  private const GLib.ActionEntry[] action_entries = {
    { "action_add_sub_notebook",       action_add_sub_notebook, "i" },
    { "action_rename_notebook",        action_rename_notebook, "i" },
    { "action_delete_notebook",        action_delete_notebook, "i" },
    { "action_save_search",            action_save_search, "i" },
    { "action_edit_search",            action_edit_search, "i" },
    { "action_empty_trash",            action_empty_trash },
    { "action_add_new_notebook",       action_add_new_notebook },
    { "action_add_new_smart_notebook", action_add_new_smart_notebook },
  };

  private signal void add_requested( int pos );
  private signal void rename_requested( int pos );
  private signal void save_search_requested( int pos );
  private signal void edit_search_requested( int pos );

  public signal void notebook_selected( BaseNotebook? nb );
  public signal void save_search();

	// Default constructor
	public Sidebar( MainWindow win ) {

		Object( orientation: Orientation.VERTICAL, spacing: 5 );

		_win = win;

    MosaicNote.settings.changed["sidebar-show-tags"].connect(() => {
      populate_tree();
    });

    var factory = new SignalListItemFactory();
    factory.setup.connect( setup_tree );
    factory.bind.connect( bind_tree );
    
    _store        = new GLib.ListStore( typeof( BaseNotebook ) );
    _model        = new TreeListModel( _store, false, false, add_tree_node );
    var selection = new SingleSelection( _model ) {
      autoselect = false,
      can_unselect = true
    };

    selection.selection_changed.connect((pos, num) => {
      var row = _model.get_row( selection.selected );
      if( row != null ) {
        _selected_notebook = (BaseNotebook)row.get_item();
      } else {
        _selected_notebook = null;
      }
      notebook_selected( _selected_notebook );
    });

    _win.notebooks.changed.connect(() => {
      update_notes_panel( selection.selected );
      populate_tree();
    });
    _win.smart_notebooks.changed.connect(() => {
      update_notes_panel( selection.selected );
      populate_tree();
    });
    _win.full_tags.changed.connect(() => {
      update_notes_panel( selection.selected );
      populate_tree();
    });
    _win.galleries.changed.connect(() => {
      populate_tree();
    });

		_list_view = new ListView( selection, factory ) {
			single_click_activate = false
		};

    _list_view.add_css_class( _win.themes.dark_mode ? "sidebar-dark" : "sidebar-light" );

    _win.themes.theme_changed.connect((theme) => {
      _list_view.remove_css_class( _win.themes.dark_mode ? "sidebar-light" : "sidebar-dark" );
      _list_view.add_css_class( _win.themes.dark_mode ? "sidebar-dark" : "sidebar-light" );
    });

		_list_view.activate.connect((pos) => {
			var row = _model.get_row( pos );
			_selected_notebook = (BaseNotebook)row.get_item();
			notebook_selected( _selected_notebook );
		});

    var sw = new ScrolledWindow() {
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      valign = Align.FILL,
      vexpand = true,
      child = _list_view
    };

    append( sw );

    var add_menu = new GLib.Menu();
    add_menu.append( _( "New Notebook" ),       "sidebar.action_add_new_notebook" );
    add_menu.append( _( "New Smart Notebook" ), "sidebar.action_add_new_smart_notebook" );

    _add_nb_btn = new MenuButton() {
      icon_name = "list-add-symbolic",
  		halign = Align.START,
  		margin_start = 5,
  		margin_top = 5,
  		margin_bottom = 5,
  		has_frame = false,
      direction = ArrowType.UP,
      menu_model = add_menu
  	};

  	var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
  		valign = Align.END,
  	};
  	bbox.append( _add_nb_btn );

  	append( bbox );

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "sidebar", actions );

    // Go ahead and populate ourselves to get started
    populate_tree();

	}

  //-------------------------------------------------------------
  // Update the notes panel for the currently selected row (if a
  // row is currently selected).
  private void update_notes_panel( uint selected ) {
    var row = _model.get_row( selected );
    if( row != null ) {
      _selected_notebook = (BaseNotebook)row.get_item();
      notebook_selected( _selected_notebook );
    }
  }

  //-------------------------------------------------------------
	// Populates the notebook tree with the updated version of win.notebooks
	private void populate_tree() {

		_store.remove_all();

		var library = new LabelNotebook( _( "Library" ) );
		_store.append( library );

    _store.append( _win.notebooks.inbox );

		for( int i=0; i<_win.smart_notebooks.size(); i++ ) {
      var notebook = _win.smart_notebooks.get_notebook( i );
      if( notebook.notebook_type.in_library( notebook ) ) {
      	_store.append( notebook );
      }
		}

    _store.append( _win.notebooks.templates );
    _store.append( _win.notebooks.trash );

		var notebooks = new LabelNotebook( _( "Notebooks" ) );
		_store.append( notebooks );

		for( int i=0; i<_win.notebooks.size(); i++ ) {
			var node = _win.notebooks.get_node( i );
			_store.append( node );
  	}

    var new_notebook = new HiddenNotebook();
    _notebook_add_pos = (int)_store.get_n_items();
    _store.append( new_notebook );

    var smart = new LabelNotebook( _( "Smart Notebooks" ) );
    _store.append( smart );

    for( int i=0; i<_win.smart_notebooks.size(); i++ ) {
      var notebook = _win.smart_notebooks.get_notebook( i );
      if( notebook.notebook_type == SmartNotebookType.USER ) {
        _store.append( notebook );
      }
    }

    var new_smart = new HiddenSmartNotebook();
    _smart_add_pos = (int)_store.get_n_items();
    _store.append( new_smart );

    if( MosaicNote.settings.get_boolean( "sidebar-show-galleries" ) ) {

      var galleries = new LabelNotebook( _( "Galleries" ) );
      _store.append( galleries );

      for( int i=0; i<_win.galleries.size(); i++ ) {
        var gallery = _win.galleries.get_gallery( i );
        _store.append( gallery );
      }

    }

    if( MosaicNote.settings.get_boolean( "sidebar-show-tags" ) ) {

    	var tags = new LabelNotebook( _( "Tags" ) );
    	_store.append( tags );

  		for( int i=0; i<_win.full_tags.size(); i++ ) {
  			_store.append( _win.full_tags.get_tag( i ) );
  		}

    }

	}

  //-------------------------------------------------------------
  // Returns true if the given base notebook is a child standard user
  // notebook.
  private bool nb_is_node( BaseNotebook nb ) {
    return( (nb as NotebookTree.Node) != null );
  }

  //-------------------------------------------------------------
  // Returns true if the given base notebook is the inbox.
  private bool nb_is_inbox( BaseNotebook nb ) {
    var notebook = (nb as Notebook);
    return( (notebook != null) && (notebook == _win.notebooks.inbox) );
  }

  //-------------------------------------------------------------
  // Returns true if the given base notebook is the trash notebook.
  private bool nb_is_trash( BaseNotebook nb ) {
    var notebook = (nb as Notebook);
    return( (notebook != null) && (notebook == _win.notebooks.trash) );
  }

  //-------------------------------------------------------------
  // Returns true if the given base notebook is the templates notebook.
  private bool nb_is_templates( BaseNotebook nb ) {
    var notebook = (nb as Notebook);
    return( (notebook != null) && (notebook == _win.notebooks.templates) );
  }

  //-------------------------------------------------------------
  // Returns true if the given base notebook is a smart notebook
  // with the given type.
  private bool nb_is_smart( BaseNotebook nb, SmartNotebookType nb_type ) {
    var smart = (nb as SmartNotebook);
    return( (smart != null) && (smart.notebook_type == nb_type) );
  }

  //-------------------------------------------------------------
  // Returns true if the given base notebook is a hidden notebook.
  private bool nb_is_hidden( BaseNotebook nb ) {
    return( (nb as HiddenNotebook) != null );
  }

  //-------------------------------------------------------------
  // Returns true if the given base notebook is a tag.
  private bool nb_is_tag( BaseNotebook nb ) {
    return( (nb as FullTag) != null );
  }

  //-------------------------------------------------------------
  // Sets up the sidebar widgets.
	private void setup_tree( Object obj ) {

		var item = (ListItem)obj;

    var label = new Label( null ) {
    	halign = Align.START,
      ellipsize = Pango.EllipsizeMode.END
    };

    var count = new Label( null ) {
    	halign = Align.END,
    	hexpand = true,
    	margin_end = 5
    };

    count.add_css_class( "tag-count" );
    count.add_css_class( _win.themes.dark_mode ? "tag-count-dark" : "tag-count-light" );

  	_win.themes.theme_changed.connect((theme) => {
  		count.remove_css_class( _win.themes.dark_mode ? "tag-count-light" : "tag-count-dark" );
  		count.add_css_class( _win.themes.dark_mode ? "tag-count-dark" : "tag-count-light" );
 		});

    var click = new GestureClick() {
      button = Gdk.BUTTON_SECONDARY
    };
    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.add_css_class( "row-border" );
    box.add_controller( click );
    box.append( label );
    box.append( count );

    var drop = new DropTarget( Type.OBJECT, Gdk.DragAction.MOVE );
    box.add_controller( drop );

    drop.enter.connect((x, y) => {
      box.add_css_class( "drop-area" );
      box.remove_css_class( "row-border" );
      return( Gdk.DragAction.MOVE );
    });

    drop.leave.connect(() => {
      box.remove_css_class( "drop-area" );
      box.add_css_class( "row-border" );
    });

    drop.accept.connect((d) => {
      var row = (TreeListRow)item.get_item();
      var nb  = (BaseNotebook)row.get_item();
      return( nb_is_node( nb ) || nb_is_inbox( nb ) || nb_is_trash( nb ) || nb_is_templates( nb ) ||
              nb_is_smart( nb, SmartNotebookType.FAVORITE ) || nb_is_tag( nb ) );
    });

    drop.drop.connect((val, x, y) => {
      var row  = (TreeListRow)item.get_item();
      var nb   = (BaseNotebook)row.get_item();
      var note = (val.get_object() as Note);
      if( note != null ) {
        if( nb_is_node( nb ) ) {
          var node = (NotebookTree.Node)nb;
          move_note_to_notebook( note, node.get_notebook() );
          return( true );
        } else if( nb_is_inbox( nb ) ) {
          var notebook = (Notebook)nb;
          move_note_to_notebook( note, notebook );
          return( true );
        } else if( nb_is_trash( nb ) && !note_in_trash( note ) ) {
          var notebook = (Notebook)nb;
          move_note_to_notebook( note, notebook );
          return( true );
        } else if( nb_is_templates( nb ) ) {
          var notebook = (Notebook)nb;
          move_note_to_notebook( note, notebook );
        } else if( nb_is_smart( nb, SmartNotebookType.FAVORITE ) && !note_in_trash( note ) ) {
          note.favorite = true;
          _win.smart_notebooks.handle_note( note );
          return( false );
        } else if( nb_is_tag( nb ) && !note_in_trash( note ) ) {
          var notebook = (FullTag)nb;
          notebook.add_note_id( note.id );
          note.tags.add_tag( notebook.name );
          _win.note.update_tags();
          return( false );
        }
      }
      box.remove_css_class( "drop-area" );
      box.add_css_class( "row-border" );
      return( false );
    });

    var popover = new PopoverMenu.from_model( null );
    popover.set_parent( box );

    click.pressed.connect((n_press, x, y) => {
      var row = (TreeListRow)item.get_item();
      var nb  = (BaseNotebook)row.get_item();
      if( nb_is_node( nb ) ) {
        var top_menu = new GLib.Menu();
        top_menu.append( _( "New Sub-Notebook" ), "sidebar.action_add_sub_notebook(%u)".printf( item.position ) );
        top_menu.append( _( "Rename Notebook" ), "sidebar.action_rename_notebook(%u)".printf( item.position ) );
        var bot_menu = new GLib.Menu();
        bot_menu.append( _( "Delete Notebook" ), "sidebar.action_delete_notebook(%u)".printf( item.position ) );
        var menu = new GLib.Menu();
        menu.append_section( null, top_menu );
        menu.append_section( null, bot_menu );
        popover.menu_model = menu;
        popover.popup();
      } else if( nb_is_trash( nb ) ) {
        var menu = new GLib.Menu();
        menu.append( _( "Empty Trash" ), "sidebar.action_empty_trash" );
        popover.menu_model = menu;
        popover.popup();
      } else if( nb_is_smart( nb, SmartNotebookType.SEARCH ) ) {
        var menu = new GLib.Menu();
        menu.append( _( "Edit Search Criteria" ), "sidebar.action_edit_search(%u)".printf( item.position ) );
        menu.append( _( "Save Search as Smart Notebook" ), "sidebar.action_save_search(%u)".printf( item.position ) );
        popover.menu_model = menu;
        popover.popup();
      } else if( nb_is_smart( nb, SmartNotebookType.USER ) ) {
        var top_menu = new GLib.Menu();
        top_menu.append( _( "Edit Match Criteria" ), "sidebar.action_edit_search(%u)".printf( item.position ) );
        top_menu.append( _( "Rename Smart Notebook" ), "sidebar.action_rename_notebook(%u)".printf( item.position ) );
        var bot_menu = new GLib.Menu();
        bot_menu.append( _( "Delete Smart Notebook" ), "sidebar.action_delete_notebook(%u)".printf( item.position ) );
        var menu = new GLib.Menu();
        menu.append_section( null, top_menu );
        menu.append_section( null, bot_menu );
        popover.menu_model = menu;
        popover.popup();
      }
    });

    var stack = new Stack() {
      hhomogeneous = true,
      vhomogeneous = false
    };

    var key = new EventControllerKey();
    var entry = new Entry() {
      placeholder_text = _( "Enter Notebook Name" )
    };
    entry.add_controller( key );

    entry.activate.connect(() => {
      var row = (TreeListRow)item.get_item();
      var nb  = (BaseNotebook)row.get_item();
      if( nb_is_node( nb ) || nb_is_smart( nb, SmartNotebookType.USER ) ) {
        if( entry.text.chomp() != "" ) {
          nb.name = entry.text;
        }
        stack.visible_child_name = "display";
      } else if( nb_is_smart( nb, SmartNotebookType.SEARCH ) ) {
        if( entry.text.chomp() != "" ) {
          var new_nb = new SmartNotebook.copy( entry.text, (nb as SmartNotebook) );
          _win.smart_notebooks.add_notebook( new_nb );
        }
      } else if( nb_is_hidden( nb ) ) {
        if( entry.text.chomp() != "" ) {
          var new_nb = new Notebook( entry.text );
          row = row.get_parent();
          if( row == null ) {
            _win.notebooks.add_notebook( new_nb );
          } else {
            var parent = (NotebookTree.Node)row.get_item();
            parent.add_notebook( new_nb );
          }
        }
        stack.visible = false;
      } else {
        if( entry.text.chomp() != "" ) {
          var new_nb = new SmartNotebook( entry.text, SmartNotebookType.USER, _win.notebooks );
          _win.smart_notebooks.add_notebook( new_nb );
          _win.note.search.notebook = new_nb;
          _win.note.show_search( new_nb.extra );
        }
      }
    });

    key.key_released.connect((keyval, keycode, state) => {
      var row = (TreeListRow)item.get_item();
      var nb  = (BaseNotebook)row.get_item();
      if( keyval == Gdk.Key.Escape ) {
        stack.visible_child_name = "display";
        if( nb.name == "" ) {
          stack.visible = false;
        }
      }
    });

    stack.add_named( box, "display" );
    stack.add_named( entry, "rename" );
    stack.visible_child_name = "display";

    var expander = new TreeExpander() {
    	margin_top = 2,
    	margin_bottom = 2,
    	child = stack
    };

    item.child = expander;

    // Handle any add requests to an add notebook
    add_requested.connect((pos) => {
      if( pos == item.position ) {
        stack.visible = true;
        entry.text = "";
        entry.grab_focus();
      }
    });

    // Handle any rename requests
    rename_requested.connect((pos) => {
      if( pos == item.position ) {
        var row = (TreeListRow)item.get_item();
        var nb  = (BaseNotebook)row.get_item();
        entry.text = nb.name;
        stack.visible_child_name = "rename";
      }
    });

    save_search_requested.connect((pos) => {
      if( pos == item.position ) {
        entry.text = "";
        stack.visible_child_name = "rename";
      }
    });

	}

	private void bind_tree( Object obj ) {

		var item     = (ListItem)obj;
		var expander = (TreeExpander)item.child;
    var stack    = (Stack)expander.child;
		var box      = (Box)stack.get_child_by_name( "display" );
		var label    = (Label)Utils.get_child_at_index( box, 0 );
		var count    = (Label)Utils.get_child_at_index( box, 1 );
		var row      = (TreeListRow)item.get_item();
		var nb       = (BaseNotebook)row.get_item();

    if( nb == _selected_notebook ) {
      _list_view.model.select_item( row.get_position(), true );
    }

		if( (nb as LabelNotebook) != null ) {
			item.selectable   = false;
			item.activatable  = false;
			item.focusable    = false;
			label.label       = Utils.make_title( nb.name );
			label.use_markup  = true;
			label.margin_start = 5;
			count.visible     = false;
			box.margin_top    = 10;
			box.margin_bottom = 10;
    } else if( ((nb as HiddenNotebook) != null) || ((nb as HiddenSmartNotebook) != null) ) {
      item.selectable  = false;
      item.activatable = false;
      item.focusable = false;
      stack.visible_child_name = "rename";
      stack.visible = false;
		} else {
		  expander.set_list_row( row );
		  label.label = nb.name;
		  count.label = nb.count().to_string();
		  if( nb.count() == 0 ) {
		  	expander.margin_top = 6;
		  	expander.margin_bottom = 6;
		  	count.visible = false;
		  }
      var node = (nb as NotebookTree.Node);
      if( node != null ) {
        if( node.size() == 0 ) {
          expander.hide_expander = true;
        } else {
          row.expanded = node.expanded;
        }
      }
		}

    row.notify["expanded"].connect(() => {
      if( row.expandable ) {
        var node = (nb as NotebookTree.Node);
        if( node != null ) {
          node.expanded = row.expanded;
        }
      }
    });

	}

  //-------------------------------------------------------------
	// Create expander tree
	public ListModel? add_tree_node( Object obj ) {
		if( (obj != null) && ((obj as NotebookTree.Node) != null) ) {
  		var node  = (NotebookTree.Node)obj;
      var store = new GLib.ListStore( typeof( BaseNotebook ) );
      if( node.size() > 0 ) {
   	  	for( int i=0; i<node.size(); i++ ) {
    	  	store.append( node.get_node( i ) );
	      }
      }
      var new_notebook = new HiddenNotebook();
      store.append( new_notebook );
      _adding = false;
	    return( (store.get_n_items() == 0) ? null : store );
		}
  	return( null );
	}

  //-------------------------------------------------------------
  // Returns true if the given note is currently in the trash.
  private bool note_in_trash( Note note ) {
    return( note.notebook == _win.notebooks.trash );
  }

  //-------------------------------------------------------------
  // Called whenever we need to move a note to another notebook.
  // If the notebook we are moving to is the trash, remove the note's
  // tags from the full tags list and remove the note from the smart
  // notebooks.  If we are moving a note from the trash, add the note's
  // tags to the full list of tags and add the note to any smartbooks.
  private void move_note_to_notebook( Note note, Notebook notebook ) {
    if( note.notebook == _win.notebooks.trash ) {
      _win.full_tags.add_note_tags( note );
      _win.smart_notebooks.handle_note( note );
    } else if( notebook == _win.notebooks.trash ) {
      _win.full_tags.delete_note_tags( note );
      _win.smart_notebooks.remove_note( note );
    }
    if( (note.notebook == _win.notebooks.templates) && (notebook != _win.notebooks.trash) ) {
      var new_note = new Note.copy( notebook, note );
      notebook.add_note( new_note );
      _win.undo.add_item( new UndoNoteAdd( new_note ) );
    } else {
      _win.undo.add_item( new UndoNoteMove( note ) );
      notebook.move_note( note );
    }
  }

  //-------------------------------------------------------------
  // Adjusts the UI to allow the user to create a new notebook.
  private void action_add_new_notebook() {
    add_requested( _notebook_add_pos );
  }

  //-------------------------------------------------------------
  // Adjusts the UI to allow the user to create a new smart notebook.
  private void action_add_new_smart_notebook() {
    add_requested( _smart_add_pos );
  }

  //-------------------------------------------------------------
  // Adds a new sub-notebook to the currently selected notebook.
  private void action_add_sub_notebook( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      _adding = true;
      var pos = variant.get_int32();
      var row = _model.get_row( pos );
      row.expanded = true;
      row = _model.get_row( pos );
      var children = row.children;
      add_requested( (int)(pos + children.get_n_items()) );
    }
  }

  //-------------------------------------------------------------
  // Renames the selected notebook.
  private void action_rename_notebook( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var pos = variant.get_int32();
      rename_requested( pos );
    }
  }

  //-------------------------------------------------------------
  // Deletes the notebook with at the given row.
  private void delete_notebook( Object? obj ) {
    var row = (TreeListRow)obj;
    var nb  = (BaseNotebook)row.get_item();
    if( nb_is_node( nb ) ) {
      row = row.get_parent();
      var notebook = ((NotebookTree.Node)nb).get_notebook();
      _win.full_tags.delete_notebook_tags( notebook );
      _win.notebooks.trash.add_notebook( notebook );
      if( row == null ) {
        _win.notebooks.remove_notebook( notebook );
      } else {
        var parent = (NotebookTree.Node)row.get_item();
        parent.remove_notebook( notebook );
      }
    } else if( nb_is_smart( nb, SmartNotebookType.USER ) ) {
      _win.smart_notebooks.remove_notebook( (SmartNotebook)nb );
    }
  }

  //-------------------------------------------------------------
  // Action to delete the notebook at the given listbox position.
  private void action_delete_notebook( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var pos = variant.get_int32();
      var row = _model.get_row( pos );
      var nb  = (BaseNotebook)row.get_item();
      if( nb_is_node( nb ) ) {
        Utils.show_confirmation( _win, _( "Delete Notebook?" ), _( "This action cannot be reversed" ), row, delete_notebook );
      } else if( nb_is_smart( nb, SmartNotebookType.USER ) ) {
        Utils.show_confirmation( _win, _( "Delete Smart Notebook?" ), _( "This action cannot be reversed" ), row, delete_notebook );
      }
    }
  }

  //-------------------------------------------------------------
  // Saves the search as a user-created smart notebook.
  private void action_save_search( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var pos = variant.get_int32();
      save_search_requested( pos );
    }
  }

  //-------------------------------------------------------------
  // Causes the smartnotebook search criteria to be re-editable
  // by the user, displaying the search UI after setup is complete.
  private void action_edit_search( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var pos = variant.get_int32();
      var row = _model.get_row( pos );
      var nb  = (SmartNotebook)row.get_item();
      _win.note.search.notebook = nb;
      _win.note.show_search( nb.extra );
    }
  }

  //-------------------------------------------------------------
  // Empties the trash notebook.
  private void empty_trash( Object? obj ) {
    _win.notebooks.trash.delete_all_notes();
  }

  //-------------------------------------------------------------
  // Empties the note within the trash.
  private void action_empty_trash() {
    Utils.show_confirmation( _win, _( "Empty Trash?" ), _( "This action is not reversable" ), null, empty_trash );
  }

  //-------------------------------------------------------------
  // Clears the current selection.
  public void clear_selection() {
    var selection = (SingleSelection)_list_view.model;
    selection.unselect_item( selection.selected );
  }

  //-------------------------------------------------------------
  // Selects the given notebook.
  public void select_notebook( BaseNotebook nb ) {
    var selection = (SingleSelection)_list_view.model;
    uint pos;
    var found = _store.find_with_equal_func( nb, (a, b) => {
      if( (b as Notebook) != null ) {
        return( ((a as NotebookTree.Node) != null) && (((NotebookTree.Node)a).get_notebook() == b) );
      } else {
        return( a == b );
      }
    }, out pos );
    if( found ) {
      // TODO - Make sure that the notebook is within view
      selection.select_item( pos, true );
    }
  }

}
