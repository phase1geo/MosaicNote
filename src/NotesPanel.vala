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

  private MainWindow         _win;
	private NotebookTree.Node? _node = null;
	private ListBox            _list;
  private ListModel          _model;
  private Button             _add;
  private bool               _ignore = false;

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

		_list.row_selected.connect((row) => {
      if( _ignore ) {
        _ignore = false;
      } else {
  			if( row == null ) {
          note_selected( null );
        } else {
    			note_selected( (Note)_model.get_item( row.get_index() ) );
        }
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
      var nb   = _node.get_notebook();
			var note = new Note( nb );
			nb.add_note( note );
      populate_with_notebook( _node );
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
  public void populate_with_notebook( BaseNotebook? nb ) {
    _node = (nb as NotebookTree.Node);
    if( nb != null ) {
      _model = nb.get_model();
      _list.bind_model( _model, create_note );
    } else {
      _model = null;
      _list.bind_model( null, create_note );
    }
    _add.sensitive = (_node != null);
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

  // Adds the given note
  private Box create_note( Object obj ) {

    var note = (Note)obj;

  	var title = new Label( Utils.make_title( note.title ) ) {
      use_markup = true,
      xalign = 0
    };

    var preview = new Label( "<small>" + note.created.format( "%b%e, %Y") + "</small>" ) {
      use_markup = true,
      xalign = 0
    };

    var box = new Box( Orientation.VERTICAL, 5 ) {
    	margin_top = 5,
    	margin_bottom = 5,
    	margin_start = 5,
    	margin_end = 5
    };
    box.append( title );
    box.append( preview );

    return( box );

  }

}