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

public class FilterAnd : SmartLogicFilter {

  //-------------------------------------------------------------
  // Default constructor
  public FilterAnd() {
    base();
  }

  //-------------------------------------------------------------
  // Constructor from XML
  public FilterAnd.from_xml( Xml.Node* node ) {
    base.from_xml( node );
  }

  //-------------------------------------------------------------
  // Checks the given note to see if it matches all of the smart
  // filters stored in this filter.
  public override bool check_note( Note note ) {
    for( int i=0; i<filters.length; i++ ) {
      var result = filters.index( i ).check_note( note );
      stdout.printf( "  In FilterAnd.check_note, i: %d, result: %s\n", i, result.to_string() );
      if( !result ) {
        return( false );
      }
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Returns this filter as a string.
  public override string to_string() {
    return( "&" + to_string_with_connector( "&" ) );
  }

  //-------------------------------------------------------------
  // Saves the contents of this filter in XML format.
  public override Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "logic-and" );
    save_to_node( node );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of this filter from XML mode.
  public override void load( Xml.Node* node ) {
    load_from_node( node );
  }

}