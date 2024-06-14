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

public class FilterItemText : SmartTextFilter {

  public NoteItemType item_type { get; set; default = NoteItemType.MARKDOWN; }

  //-------------------------------------------------------------
  // Default constructor
  public FilterItemText( NoteItemType item_type, TextMatchType match_type, string pattern ) {
    base( match_type, pattern );
    this.item_type = item_type;
  }

  //-------------------------------------------------------------
  // Constructor from XML
  public FilterItemText.from_xml( Xml.Node* node ) {
    base.from_xml( node );
    load( node );
  }

  //-------------------------------------------------------------
  // Checks the note to see if it matches the title text.
  public override bool check_note( Note note ) {
    for( int i=0; i<note.size(); i++ ) {
      var item = note.get_item( i );
      if( (item.item_type == item_type) && check_text( item.content ) ) {
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns the contents of this filter as a string
  public override string to_string() {
    return( "content[%s]:%s".printf( item_type.to_string(), base.to_string() ) );
  }

  //-------------------------------------------------------------
  // Saves this filter to XML format
  public override Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "item-text" );
    node->set_prop( "type", item_type.to_string() );
    save_to_node( node );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads this filter from XML format
  public override void load( Xml.Node* node ) {
    var t = node->get_prop( "type" );
    if( t != null ) {
      item_type = NoteItemType.parse( t );
    }
    load_from_node( node );
  }

}