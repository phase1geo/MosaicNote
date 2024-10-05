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

public class GalleryItemCode : GalleryItem {

  private NoteItemCode code_item {
    get {
      return( (NoteItemCode)item );
    }
  }

  //-------------------------------------------------------------
  // Default constructor
  public GalleryItemCode( MainWindow win, NoteItem item ) {
    base( win, item );
  }

  //-------------------------------------------------------------
  // Returns the number of panes that will be displayed
  protected override int panes() {
    return( 1 );
  }

  //-------------------------------------------------------------
  // Returns the 
  protected override string pane_label( int pane_index ) {
    return( _( "Code Snippet" ) );
  }

  //-------------------------------------------------------------
  // Generates the header that will be displayed above the pane.
  protected override Widget create_header() {

    var label = new Label( Utils.make_title( code_item.description ) ) {
      halign = Align.FILL,
      use_markup = true
    };

    highlight_match.connect((pattern) => {
      highlight_label( label, code_item.description, pattern );
    });

    return( label );

  }

  //-------------------------------------------------------------
  // Generates the main pain displaying the content.
  protected override Widget? create_pane( int pane ) {

    var text = create_text_pane( code_item.content, code_item.lang );
    text.add_css_class( "code-text" );

    return( text );

  }

  //-------------------------------------------------------------
  // Copies the given pane content to the clipboard.
  protected override void copy_pane_to_clipboard( int pane_index ) {
    copy_text_to_clipboard( code_item.content );
  }

}