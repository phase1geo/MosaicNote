/*
* Copyright (c) 2024 (https://github.com/phase1geo/MosaicNote)
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

public class GalleryView : Box {

  private MainWindow _win;
  private FlowBox    _flowbox;

  //-------------------------------------------------------------
  // Default constructor
  public GalleryView( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 5 );

    _win = win;

    _flowbox = new FlowBox() {
      homogeneous    = true,
      row_spacing    = 10,
      column_spacing = 10,
      max_children_per_line = 2
    };

    var box = new Box( Orientation.VERTICAL, 0 ) {
      vexpand = true
    };
    box.append( _flowbox );

    var sw = new ScrolledWindow() {
      vscrollbar_policy = PolicyType.AUTOMATIC,
      hscrollbar_policy = PolicyType.NEVER,
      child             = box,
      halign            = Align.FILL,
      valign            = Align.FILL,
      hexpand           = true,
      vexpand           = true
    };

    append( sw );

  }

  //-------------------------------------------------------------
  // Creates a pane to display the given note item within.
  private NoteItemPane? make_pane( NoteItem item ) {

    NoteItemPane pane;
    switch( item.item_type ) {
      case NoteItemType.CODE  :  pane = new NoteItemPaneCode( _win, item, null );   break;
      case NoteItemType.IMAGE :  pane = new NoteItemPaneImage( _win, item, null );  break;
      case NoteItemType.UML   :  pane = new NoteItemPaneUML( _win, item, null );    break;
      case NoteItemType.MATH  :  pane = new NoteItemPaneMath( _win, item, null );   break;
      default                 :  return( null );
    }

    pane.set_size_request( -1, 400 );

    return( pane );

  }

  //-------------------------------------------------------------
  // Populates the current gallery view with a list of panes for
  // each stored note item.
  public void populate( Gallery gallery ) {

    var items = new Array<NoteItem>();
    gallery.get_note_items( items );

    _flowbox.remove_all();

    for( int i=0; i<items.length; i++ ) {
      var item = make_pane( items.index( i ) );
      if( item != null ) {
        _flowbox.append( item );
      }
    }

  }

}