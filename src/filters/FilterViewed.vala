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

public class FilterViewed : SmartDateFilter {

  //-------------------------------------------------------------
  // Default constructor
  public FilterViewed() {
    base();
  }

  //-------------------------------------------------------------
  // Constructor for absolute dates
  public FilterViewed.absolute( DateMatchType match_type, DateTime first, DateTime? second = null ) {
    base.absolute( match_type, first, second );
  }

  //-------------------------------------------------------------
  // Constructor for relative dates
  public FilterViewed.relative( DateMatchType match_type, int num, TimeType time_type ) {
    base.relative( match_type, num, time_type );
  }

  //-------------------------------------------------------------
  // Constructor from XML
  public FilterViewed.from_xml( Xml.Node* node ) {
    base.from_xml( node );
  }

  //-------------------------------------------------------------
  // Creates and returns a copy of this filter.
  public override SmartFilter copy() {
    var filter = new FilterViewed();
    copy_to( filter );
    return( filter );
  }

  //-------------------------------------------------------------
  // Returns true if this note matches this filter's criteria.
  public override bool check_note( Note note ) {
    return( check_date( note.viewed ) );
  }

  //-------------------------------------------------------------
  // Returns the contents of this filter as a string.
  public override string to_string() {
    return( "viewed:" + base.to_string() );
  }

  //-------------------------------------------------------------
  // Saves the contents of this filter as XML
  public override Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "viewed" );
    save_to_node( node );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of this filter from XML
  public override void load( Xml.Node* node ) {
    load_from_node( node );
  }

}