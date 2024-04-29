/*
* Copyright (c) 2024 (https://github.com/phase1geo/MosaicNote)
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

public class FullTag {

	public string name  { get; private set; default = ""; }
	public int    count { get; private set; default = 0; }

	// Default constructor
	public FullTag( string tag_name ) {
    name = tag_name;
    count++; 
	}

	// Constructor from XML format
	public FullTag.from_xml( Xml.Node* node ) {
		load( node );
	}

	// Comparison function for searching
	public static int compare( FullTag a, FullTag b ) {
		return( strcmp( a.name, b.name ) );
	}

	// Adjusts the tag count by the given number
	public void adjust_count( int num ) {
		count += num;
	}

	// Saves the contents of this tag in XML format
	public Xml.Node* save() {
		Xml.Node* node = new Xml.Node( null, "tag" );
		node->set_prop( "name", name );
		node->set_prop( "count", count.to_string() );
		return( node );
	}

	// Loads the contents of this tag from XML format
	public void load( Xml.Node* node ) {
	  var n = node->get_prop( "name" );
	  if( n != null ) {
	  	name = n;
	  }	
	  var c = node->get_prop( "count" );
	  if( c != null ) {
	  	count = int.parse( c );
	  }
	}

}