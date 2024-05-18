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

public class SmartFilter {

  // Default constructor
  public SmartFilter() {}

  // Constructor from XML format
  public SmartFilter.from_xml( Xml.Node* node ) {}

  // Returns true if the note matches the filter.
  public virtual bool check_note( Note note ) {
    return( false );
  }

  // Saves the filter setup in XML format
  public virtual Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "smart-filter" );
    return( node );
  }

  // Loads the filter content from XML format
  public virtual void load( Xml.Node* node ) {}

}