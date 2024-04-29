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

public class NotebookTree {

	public class Node {

		private Node?       _parent;
		private int         _id;
		private string      _name;
		private Notebook?   _notebook;
		private Array<Node> _children;

		public int id {
			get {
				return( _id );
			}
		}

		public string name {
			get {
				return( _name );
			}
			set {
				if( _name != value ) {
					_name = value;
					if( _notebook != null ) {
						_notebook.title = value;
					}
				}
			}
		}

		// Default constructor
		public Node( Node? parent, Notebook nb ) {
			_parent   = parent;
			_id       = nb.id;
			_name     = nb.name;
			_notebook = nb;
			_children = new Array<Node>();
		}

		// Constructor from XML format
		public Node.from_xml( Xml.Node* node ) {
			_children = new Array<Node>();
			load( node );
		}

		// Adds the given notebook to the list of children
		public void add_notebook( Notebook nb ) {
			var node = new Node( this, nb );
			_children.append_val( node );
		}

		// Removes the given notebook from the tree
		public void remove_notebook( Notebook nb ) {
			var node = find_node( nb.id );
			if( node != null ) {
				node._parent.remove_child( node );
			}
		}

		// Removes the given child node from 
		public void remove_child( Node node ) {
			for( int i=0; i<_children.length; i++ ) {
				if( node == _children.index( i ) ) {
					_children.remove_index( i );
					break;
				}
			}
		}

		// Returns the number of children
		public int num_children() {
			return( (int)_children.length );
		}

		// Returns the child at the given position
		public Node get_child( int pos ) {
			return( _children.index( pos ) );
		}

		// Returns a reference to the notebook that matches the given ID
		public Node? find_node( int id ) {
			if( _id == id ) {
				return( this );
			} else {
				for( int i=0; i<_children.length; i++ ) {
					var n = _children.index( i ).find_node( id );
					if( n != null ) {
					  return( n );
					}
				}
				return( null );
			}
		}

		// Returns the notebook associated with this node
		public Notebook get_notebook() {
			if( _notebook == null ) {
				_notebook = new Notebook.load_xml( id );
			}
			return( _notebook );
		}

		/* Saves this notebook node in XML format */
		public Xml.Node* save() {
			Xml.Node* node = new Xml.Node( null, "node" );
			node->set_prop( "id",   _id.to_string() );
			node->set_prop( "name", _name );
			for( int i=0; i<_children.length; i++ ) {
				node->add_child( _nodes.index( i ).save() );
			}
		}

		/* Loads the notebook node from XML format */
		private void load( Xml.Node* node, Node? parent ) {
			var id = node->get_prop( "id" );
			if( id != null ) {
        _id = int.parse( id );
			}
			var n = node->get_prop( "name" );
			if( name != null ) {
				_name = name;
			}
			_parent   = parent;
			_notebook = null;
			for( Xml.Node* it = node->children; it != null; it = it->next ) {
				if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
					var n = new Node.from_xml( it, this );
					_children.append_val( n );
				}
			}
		}

	}

	private Node _root = null;

	// Default constructor
	public NotebookTree() {}

	// Constructor from XML
	public NotebookTree.from_xml() {
		load();
	}

	private string xml_file() {
		return( Utils.user_location( "notebooks.xml" ) );
	}

	// Saves the current notebook tree in XML format
	public void save() {

	  Xml.Doc*  doc  = new Xml.Doc( "1.0" );
	  Xml.Node* root = new Xml.Node( null, "notebooks" );

	  root->set_prop( "version", MosaicNote.version );
	  root->set_prop( "notebook-id", Notebook.current_id.to_string() );
	  root->set_prop( "note-id", Note.current_id.to_string() );

	  if( _root != null ) {
	  	root.add_child( _root.save() );
	  }
	
	  doc->set_root_element( root );
	  doc->save_format_file( xml_file(), 1 );
	
	  delete doc;

  }

  // Loads the contents of this notebook from XML format
  private void load() {

    var doc = Xml.Parser.read_file( xml_file(), null, (Xml.ParserOption.HUGE | Xml.ParserOption.NOWARNING) );
    if( doc == null ) {
      return;
    }

    Xml.Node* root = doc->get_root_element();
    
    var verson = root->get_prop( "version" );
    if( verson != null ) {
      check_version( verson );
    }

    var nb_id = root->get_prop( "notebook-id" );
    if( nb_id != null ) {
    	Notebook.current_id = int.parse( nb_id );
    }

    var nt_id = root->get_prop( "note-id" );
    if( nt_id != null ) {
    	Note.current_id = int.parse( nt_id );
    }

    var n = node->get_prop( "name" );
    if( n != null ) {
    	_name = n;
    }

    var i = node->get_prop( "id" );
    if( i != null ) {
    	_id = int.parse( i );
    }
  
    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "note") ) {
      	var note = new Note.from_xml( it );
      	_notes.append_val( note );
      }
    }
    
    delete doc;

  }

  private void check_version( string version ) {

  	// Nothing to do yet

  }

}