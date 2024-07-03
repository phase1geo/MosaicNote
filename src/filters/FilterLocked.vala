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

public class FilterLocked : SmartFilter {

  private bool _locked = true;

  //-------------------------------------------------------------
  // Default constructor
  public FilterLocked( bool locked ) {
    base();
    _locked = locked;
  }

  //-------------------------------------------------------------
  // Constructo from XML
  public FilterLocked.from_xml( Xml.Node* node ) {
    base.from_xml( node );
    load( node );
  }

  //-------------------------------------------------------------
  // Creates and returns a copy of this filter.
  public override SmartFilter copy() {
    var filter = new FilterLocked( _locked );
    return( filter );
  }

  //-------------------------------------------------------------
  // Checks the note to see if it matches or does not match the
  // stored tag value.
  public override bool check_note( Note note ) {
    return( note.locked == _locked );
  }

  //-------------------------------------------------------------
  // Returns the contents of this filter as a string.
  public override string to_string() {
    return( (_locked ? "" : "!") + "locked" );
  }

  //-------------------------------------------------------------
  // Saves the contents of this filter as XML
  public override Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "locked" );
    node->set_prop( "value", _locked.to_string() );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of this filter from XML
  public override void load( Xml.Node* node ) {
    var v = node->get_prop( "value" );
    if( v != null ) {
      _locked = bool.parse( v );
    }
  }

}