/*
* Copyright (c) 2025-2026 (https://github.com/phase1geo/MosaicNote)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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

public class NoteItemPaneRow : Box {

  private const double control_opacity = 0.1;

  private int         _size = 0;
  private Box         _box;
  private NoteItemRow _row;

  public int size {
    get {
      return( _size );
    }
  }

  //-------------------------------------------------------------
  // Constructor
  public NoteItemPaneRow( NoteItemRow note_row ) {

    Object( orientation: Orientation.HORIZONTAL, spacing : 5 );

    _row = note_row;

    var expand = new Button.with_label( note_row.expanded ? "\u23f7" : "\u23f5" ) {
      has_frame = false,
      halign = Align.START,
      opacity = control_opacity
    };

    var lbox = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    lbox.append( expand );

    var lbox_motion = new EventControllerMotion();
    lbox.add_controller( lbox_motion );

    lbox_motion.enter.connect((x, y) => {
      expand.opacity = 1.0;
    });
    lbox_motion.leave.connect(() => {
      expand.opacity = control_opacity;
    });

    _box = new Gtk.Box( Orientation.HORIZONTAL, 5 ) {
      homogeneous = true
    };

    expand.clicked.connect(() => {
      _row.expanded = !_row.expanded;
      // _box.visible  = _row.expanded;
      // pane.visible  = item.expanded;
      // sep.opacity   = item.expanded ? 1.0 : 0.0;
      // type_label.visible = !item.expanded;
      expand.label  = _row.expanded ? "\u23f7" : "\u23f5";
      // _stack.visible_child_name = item.expanded ? "selected" : "unselected";
    });

    append( lbox );
    append( _box );

  }

  //-------------------------------------------------------------
  // Populates this row with the given note.
  public void add_pane( NoteItemPane pane, int column = -1 ) {
    if( column == -1 ) {
      _box.append( pane );
    } else if( column == 0 ) {
      _box.prepend( pane );
    } else {
      var sibling = get_pane( column - 1 );
      _box.insert_child_after( pane, sibling );
    }
    _size++;
  }

  //-------------------------------------------------------------
  // Deletes the item at the given column.
  public void delete_pane( int column ) {
    var box = get_pane( column );
    if( box != null ) {
      _box.remove( box );
      _size--;
    }
  }

  //-------------------------------------------------------------
  // Move the pane to the new location.
  public void move_pane( int col, bool left ) {
    if( left ) {
      _box.reorder_child_after( get_pane( col ), get_pane( col - 2 ) );
    } else {
      _box.reorder_child_after( get_pane( col ), get_pane( col + 1 ) );
    }
  }

  //-------------------------------------------------------------
  // Returns the item at the given column
  public NoteItemPane? get_pane( int column ) {
    return( (NoteItemPane)Utils.get_child_at_index( _box, column ) );
  }

  //-------------------------------------------------------------
  // Returns the column associated with the given pane in the row.
  public int get_pane_col( Widget pane ) {
    return( Utils.get_child_index( _box, pane ) );
  }

}
