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

  private MainWindow  _win;
  private SearchEntry _search;
  private FlowBox     _flowbox;

  public signal void show_note( Note note );

  //-------------------------------------------------------------
  // Default constructor
  public GalleryView( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 5 );

    _win = win;

    _search = new SearchEntry() {
      halign  = Align.CENTER,
      hexpand = true,
      width_chars = 50,
      placeholder_text = _( "Search Gallery" ),
      margin_top = 5
    };

    _search.search_changed.connect( do_search );

    _flowbox = new FlowBox() {
      valign                = Align.START,
      vexpand               = true,
      homogeneous           = true,
      row_spacing           = 10,
      column_spacing        = 10,
      max_children_per_line = 2,
      selection_mode        = SelectionMode.NONE
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

    append( _search );
    append( sw );

  }

  //-------------------------------------------------------------
  // Creates a pane to display the given note item within.
  private GalleryItem? make_pane( NoteItem item ) {

    GalleryItem pane;
    switch( item.item_type ) {
      case NoteItemType.CODE  :  pane = new GalleryItemCode( _win, item );   break;
      case NoteItemType.IMAGE :  pane = new GalleryItemImage( _win, item );  break;
      case NoteItemType.UML   :  pane = new GalleryItemUML( _win, item );    break;
      case NoteItemType.MATH  :  pane = new GalleryItemMath( _win, item );   break;
      default                 :  return( null );
    }

    pane.show_note.connect((note) => {
      show_note( note );
    });

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

  //-------------------------------------------------------------
  // Perform search.
  private void do_search() {

    /* If the search field is empty, show all of the icons by category again */
    if( _search.text == "" ) {
      _flowbox.invalidate_filter();
    
    /* Otherwise, show only the currently matching icons */
    } else {
      _flowbox.set_filter_func((item) => {
        var gallery_item = (GalleryItem)item.child;
        if( (_search.text == "") || gallery_item.item.search( _search.text ) ) {
          gallery_item.highlight_match( _search.text );
          return( true );
        }
        return( false );
      });
    }

  }

}