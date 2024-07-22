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

public class NotesPanel : Box {

  private MainWindow    _win;
	private BaseNotebook? _bn = null;
	private ListBox       _list;
  private ListModel     _model;
  private Button        _add;
  private bool          _ignore = false;

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

		var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
			valign = Align.END
		};

		bbox.append( _add );

		append( _list );
		append( bbox );

	}

  //-------------------------------------------------------------
  // Returns true if the stored base notebook is from the notebook tree.
  private bool bn_is_node() {
    return( (_bn != null) && ((_bn as NotebookTree.Node) != null) );
  }

  //-------------------------------------------------------------
  // Returns true if the stored based notebook is a smart notebook.
  private bool bn_is_smart() {
    return( (_bn != null) && ((_bn as SmartNotebook) != null) );
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
      _ignore = true;
      _model.items_changed( pos, 1, 1 );
      _ignore = true;
      _list.select_row( _list.get_row_at_index( pos ) );
    }
  }

  //-------------------------------------------------------------
	// Populates the notes list from the given notebook
  public void populate_with_notebook( BaseNotebook? bn ) {
    _bn = bn;
    if( bn != null ) {
      _model = bn.get_model();
      _list.bind_model( _model, create_note );
      _add.sensitive = bn_is_node() || (bn_is_notebook() && (_win.notebooks.inbox == (Notebook)_bn));
    } else {
      _model = null;
      _list.bind_model( null, create_note );
      _add.sensitive = false;
    }
  }

  //-------------------------------------------------------------
  // Selects the row at the given index.
  public void select_row( int index ) {
    var row = _list.get_row_at_index( index );
    if( row != null ) {
      _list.select_row( row );
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

}