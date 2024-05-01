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

	private Notebook _nb;
	private ListBox  _list;
  private Button   _add;

	public signal void note_selected( Note note );

	// Default constructor
	public NotesPanel() {

		Object( orientation: Orientation.VERTICAL, spacing: 5, margin_top: 5, margin_bottom: 5, margin_start: 5, margin_end: 5 );

		_list = new ListBox() {
			valign = Align.FILL,
			selection_mode = SelectionMode.BROWSE
		};

		_list.row_selected.connect((row) => {
			if( row != null ) {
        stdout.printf( "Calling note_selected, index: %d\n", row.get_index() );
  			note_selected( _nb.get_note( row.get_index() ) );
  		}
  	});

		_add = new Button.from_icon_name( "list-add-symbolic" ) {
      has_frame = false,
			tooltip_text = _( "Add new note" ),
      sensitive = false
		};

		_add.clicked.connect(() => {
			var note = new Note( _nb );
			_nb.add_note( note );
      populate();
		});

		var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
			valign = Align.END,
			vexpand = true
		};

		bbox.append( _add );

		append( _list );
		append( bbox );

	}

	// Populates the notes list from the given notebook
  public void populate_with_notebook( Notebook? nb ) {
  	_nb = nb;
    if( _nb != null ) {
      _nb.changed.connect(() => {
        populate();
      });
      populate();
    }
  }

  private void populate() {

  	// _list.remove_all();
    Utils.clear_listbox( _list );

    if( _nb != null ) {
  	  for( int i=0; i<_nb.size(); i++ ) {
  		  _list.append( create_note( _nb.get_note( i ) ) );
  	  }
      _add.sensitive = true;
    } else {
      _add.sensitive = false;
    }

    // Select the first row
    // _list.select_row( _list.get_row_at_index( 0 ) );

  }	

  // Adds the given note
  private Box create_note( Note note ) {

  	var title = new Label( Utils.make_title( note.title ) ) {
      use_markup = true,
      xalign = 0
    };

    var preview = new Label( note.created.to_string() ) {
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