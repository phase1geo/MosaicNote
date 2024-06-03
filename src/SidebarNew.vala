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

public class SidebarNew : Box {

	private MainWindow     _win;
	private BaseNotebook?  _selected_node = null;
	private GLib.ListStore _store;
  private TreeListModel  _model;
	private ListView       _list_view;
  private Button         _add_nb_btn;
  private bool           _adding = false;

  private const GLib.ActionEntry[] action_entries = {
    { "action_add_notebook",    action_add_notebook, "i" },
    { "action_rename_notebook", action_rename_notebook, "i" },
    { "action_delete_notebook", action_delete_notebook, "i" },
  };

  private signal void add_requested( int pos );
  private signal void rename_requested( int pos );

  public signal void notebook_selected( BaseNotebook nb );

	// Default constructor
	public SidebarNew( MainWindow win ) {

		Object( orientation: Orientation.VERTICAL, spacing: 5 );

		_win = win;
		_win.notebooks.changed.connect( populate_tree );

    var factory = new SignalListItemFactory();
    factory.setup.connect( setup_tree );
    factory.bind.connect( bind_tree );
    
    _store        = new GLib.ListStore( typeof( BaseNotebook ) );
    _model        = new TreeListModel( _store, false, false, add_tree_node );
    var selection = new SingleSelection( _model ) {
      autoselect = false
    };

    selection.selection_changed.connect((pos, num) => {
      var row = _model.get_row( selection.selected );
      var nb  = (BaseNotebook)row.get_item();
      notebook_selected( nb );
    });

		_list_view = new ListView( selection, factory ) {
			single_click_activate = false
		};

		_list_view.activate.connect((pos) => {
			var row = _model.get_row( pos );
			var nb  = (BaseNotebook)row.get_item();
			notebook_selected( nb );
		});

    var sw = new ScrolledWindow() {
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      valign = Align.FILL,
      vexpand = true,
      child = _list_view
    };

    append( sw );

    _add_nb_btn = new Button.from_icon_name( "list-add-symbolic" ) {
  		halign = Align.START,
  		margin_start = 5,
  		margin_top = 5,
  		margin_bottom = 5,
  		has_frame = false
  	};

  	_add_nb_btn.clicked.connect(() => {
  		add_requested( 4 + _win.notebooks.size() + 1 );
		});

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

	// Populates the notebook tree with the updated version of win.notebooks
	private void populate_tree() {

		_store.remove_all();

		var library = new LabelNotebook( _( "Library" ) );
		_store.append( library );

		for( int i=0; i<_win.smart_notebooks.size(); i++ ) {
      var notebook = _win.smart_notebooks.get_notebook( i );
      if( notebook.notebook_type == SmartNotebookType.BUILTIN ) {
      	_store.append( notebook );
      }
		}

		var notebooks = new LabelNotebook( _( "Notebooks" ) );
		_store.append( notebooks );

		for( int i=0; i<_win.notebooks.size(); i++ ) {
			var node = _win.notebooks.get_node( i );
			_store.append( node );
  	}

    var new_notebook = new HiddenNotebook();
    _store.append( new_notebook );

  	var tags = new LabelNotebook( _( "Tags" ) );
  	_store.append( tags );

		for( int i=0; i<_win.full_tags.size(); i++ ) {
			_store.append( _win.full_tags.get_tag( i ) );
		}

	}

	private void setup_tree( Object obj ) {

		var item  = (ListItem)obj;

    var label = new Label( null ) {
    	halign = Align.START
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
    box.add_controller( click );
    box.append( label );
    box.append( count );

    var popover = new PopoverMenu.from_model( null );
    popover.set_parent( box );

    click.pressed.connect((n_press, x, y) => {
      var row = (TreeListRow)item.get_item();
      var nb  = (BaseNotebook)row.get_item();
      if( (nb as NotebookTree.Node) != null ) {
        var top_menu = new GLib.Menu();
        top_menu.append( _( "New Sub-Notebook" ), "sidebar.action_add_notebook(%u)".printf( item.position ) );
        top_menu.append( _( "Rename Notebook" ), "sidebar.action_rename_notebook(%u)".printf( item.position ) );
        var bot_menu = new GLib.Menu();
        bot_menu.append( _( "Delete Notebook" ), "sidebar.action_delete_notebook(%u)".printf( item.position ) );
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
      if( (nb as NotebookTree.Node) != null ) {
        if( entry.text.chomp() != "" ) {
          nb.name = entry.text;
        }
        stack.visible_child_name = "display";
      } else {
        if( entry.text.chomp() != "" ) {
          var new_nb = new Notebook( entry.text );
          stack.visible = false;
          row = row.get_parent();
          if( row == null ) {
            _win.notebooks.add_notebook( new_nb );
          } else {
            var parent = (NotebookTree.Node)row.get_item();
            parent.add_notebook( new_nb );
          }
        }
      }
    });

    key.key_released.connect((keyval, keycode, state) => {
      if( keyval == Gdk.Key.Escape ) {
        stack.visible_child_name = "display";
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
        var row = (TreeListRow)item.get_item();
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

		if( (nb as LabelNotebook) != null ) {
			item.selectable   = false;
			item.activatable  = false;
      // TODO - This option is not available in pre 4.10 versions of Gtk
			// item.focusable    = false;
			label.label       = Utils.make_title( nb.name );
			label.use_markup  = true;
			label.margin_start = 5;
			count.visible     = false;
			box.margin_top    = 10;
			box.margin_bottom = 10;
    } else if( (nb as HiddenNotebook) != null ) {
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
		}

	}

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
      if( _adding ) {
        var new_notebook = new HiddenNotebook();
        store.append( new_notebook );
        _adding = false;
      }
	    return( (store.get_n_items() == 0) ? null : store );
		}
  	return( null );
	}

  private void action_add_notebook( SimpleAction action, Variant? variant ) {
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

  private void action_rename_notebook( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var pos = variant.get_int32();
      rename_requested( pos );
    }
  }

  private void action_delete_notebook( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var pos = variant.get_int32();
      _store.remove( pos );
    }
  }

}