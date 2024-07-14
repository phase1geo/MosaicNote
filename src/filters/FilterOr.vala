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

public class FilterOr : SmartLogicFilter {

  //-------------------------------------------------------------
  // Default constructor
  public FilterOr() {
    base( LogicOperator.OR );
  }

  //-------------------------------------------------------------
  // Constructor from XML
  public FilterOr.from_xml( Xml.Node* node ) {
    base.from_xml( node, LogicOperator.OR );
  }

  //-------------------------------------------------------------
  // Creates a FilterOr filter and populates it with a copy
  // of this filter.
  public override SmartFilter copy() {
    var filter = new FilterOr();
    copy_to( filter );
    return( filter );
  }

  //-------------------------------------------------------------
  // Checks the given note to see if it matches all of the smart
  // filters stored in this filter.
  public override bool check_note( Note note ) {
    for( int i=0; i<filters.length; i++ ) {
      if( filters.index( i ).check_note( note ) ) {
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns this filter as a string.
  public override string to_string() {
    return( to_string_with_connector( "|" ) );
  }

  //-------------------------------------------------------------
  // Saves the contents of this filter in XML format.
  public override Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "logic-or" );
    save_to_node( node );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of this filter from XML mode.
  public override void load( Xml.Node* node ) {
    load_from_node( node );
  }

}