/*
* Copyright (c) 2026 (https://github.com/phase1geo/MosaicNote)
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

public class ListChooser : Granite.Dialog {

  private ListBox     _list;
  private int         _result    = -1;
  private bool        _completed = false;
  private SourceFunc? _callback  = null;

  //-------------------------------------------------------------
  // Constructor
  public ListChooser( MainWindow parent, string title, Array<string> string_list ) {

    Object(
      transient_for: parent,
      title: title,
      modal: true
    );

    var search = new SearchEntry() {
      placeholder_text = _( "Search for notebook" )
    };

    var list = new ListBox() {
      halign = Align.FILL,
      valign = Align.FILL
    };

    list.row_activated.connect((row) => {
      item_was_selected( (int)row.get_index() );
    });

    search.search_changed.connect(() => {
      var str = search.text;
      for( int i=0; i<string_list.length; i++ ) {
        var row = list.get_row_at_index( i );
        row.child.visible = string_list.index( i ).contains( str );
      }
    });

    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    box.append( search );
    box.append( list );

    get_content_area().append( box );

    for( int i=0; i<string_list.length; i++ ) {
      var lbl = new Label( string_list.index( i ) ) {
        halign = Align.START
      };
      list.append( lbl );
    }

    search.grab_focus();

    close_request.connect (() => {
      finish( -1 );
      return( false );
    });

  }

  //-------------------------------------------------------------
  // Method called that causes the value to be chosen.
  public async int choose() {
    present();
    if( !_completed ) {
      _callback = choose.callback;
      yield;
    }
    return( _result );
  }

  //-------------------------------------------------------------
  // Called when a value is selected
  private void on_selected( int val ) {
    _result = val;
    _completed = true;
    _callback();
    _callback = null;
  }

  //-------------------------------------------------------------
  // Called to complete the operation.
  private void finish( int val ) {
    if( _completed ) {
      return;
    }
    on_selected( val );
  }

  //-------------------------------------------------------------
  // Called if an item was selected.
  private void item_was_selected( int val ) {
    assert( val >= 0 );
    finish( val );
  }

}
