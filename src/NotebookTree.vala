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

	public class Node : BaseNotebook {

		private Node?       _parent;
		private int         _id;
		private Notebook?   _notebook;
		private Array<Node> _children;
		private bool        _expanded = true;
		private bool        _modified = false;

		public int id {
			get {
				return( _id );
			}
		}

		public bool expanded {
			get {
				return( _expanded );
			}
			set {
				if( _expanded != value ) {
					_expanded = value;
					_modified = true;
				}
			}
		}

		public bool modified {
			get {
				if( !_modified ) {
					for( int i=0; i<_children.length; i++ ) {
						if( _children.index( i ).modified ) {
							return( true );
						}
					}
				}
				return( _modified );
			}
		}

    public ulong handler_id { set; get; default = 0; }

		// Default constructor
		public Node( Node? parent, Notebook nb ) {
			base( nb.name );
			_parent   = parent;
			_id       = nb.id;
			_notebook = nb;
			_children = new Array<Node>();
			_modified = true;
			changed();
		}

		// Constructor from XML format
		public Node.from_xml( Xml.Node* node, Node? parent ) {
			base( "" );
			_children = new Array<Node>();
			load( node, parent );
		}

		private void node_changed() {
			changed();
		}

		// Adds the given notebook to the list of children
		public void add_notebook( Notebook nb ) {
			var node = new Node( this, nb );
			node.changed.connect( node_changed );
			_children.append_val( node );
			_modified = true;
			changed();
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
					node.changed.disconnect( node_changed );
					_children.remove_index( i );
				  _modified = true;
				  changed();
					break;
				}
			}
		}

		// Returns the number of child notebooks
		public int size() {
			return( (int)_children.length );
		}

		// Returns the number of notes stored in this notebook
		public override int count() {
		  return( get_notebook().count() );
		}

		// Returns the notes model associated with the notebook
		public override ListModel? get_model() {
			return( get_notebook().get_model() );
		}

		// Returns the child at the given position
		public Node get_node( int pos ) {
			return( _children.index( pos ) );
		}

		// Returns the node at the given position in the tree
		public Node? get_node_at_position( ref int pos ) {
			if( pos-- == 0 ) {
				return( this );
			} else {
  			for( int i=0; i<_children.length; i++ ) {
          var node = _children.index( i ).get_node_at_position( ref pos );
          if( node != null ) {
          	return( node );
          }
  			}
  		}
      return( null );
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
				_notebook = new Notebook.from_xml( id );
			}
			return( _notebook );
		}

		// Searches for a notebook with the given ID.  If it is found, return it; otherwise, returns null.
		public Notebook? find_notebook( int id ) {
			if( get_notebook().id == id ) {
				return( get_notebook() );
			}
			for( int i=0; i<_children.length; i++ ) {
				var nb = _children.index( i ).find_notebook( id );
				if( nb != null ) {
					return( nb );
				}
			}
			return( null );
		}

		// Searches for a note with the given ID.  If it is found, return it; otherwise, returns null.
		public Note? find_note( int id ) {
			var note = get_notebook().find_note( id );
			if( note != null ) {
				return( note );
			}
			for( int i=0; i<_children.length; i++ ) {
				note = _children.index( i ).find_note( id );
				if( note != null ) {
					return( note );
				}
			}
			return( null );
		}

		// Populates the given list of notes that contain the given tag.
		public void get_notes_with_tag( string tag, Array<Note> notes ) {
			get_notebook().get_notes_with_tag( tag, notes );
			for( int i=0; i<_children.length; i++ ) {
				_children.index( i ).get_notes_with_tag( tag, notes );
			}
		}

		/* Saves this notebook node in XML format */
		public Xml.Node* save() {
			Xml.Node* node = new Xml.Node( null, "node" );
			node->set_prop( "id",   _id.to_string() );
			base_save( node );
			for( int i=0; i<_children.length; i++ ) {
				node->add_child( _children.index( i ).save() );
			}
			_modified = false;
			return( node );
		}

    /* Saves all of the modified notebooks */
    public void save_notebooks() {
      var nb = get_notebook();
      nb.save();
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).save_notebooks();
      }
    }

		/* Loads the notebook node from XML format */
		private void load( Xml.Node* node, Node? parent ) {
			var id = node->get_prop( "id" );
			if( id != null ) {
        _id = int.parse( id );
			}
			base_load( node );
			_parent   = parent;
			_notebook = null;
			for( Xml.Node* it = node->children; it != null; it = it->next ) {
				if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
					var n = new Node.from_xml( it, this );
					_children.append_val( n );
				}
			}
		}

	}  // class Node

	private Array<Node> _nodes;
	private bool        _modified = false;

	public signal void changed();

	// Default constructor
	public NotebookTree() {
		_nodes = new Array<Node>();
		load();
	}

	private void set_modified() {
		_modified = true;
		changed();
	}

	// Adds the given notebook to the end of the list
	public void add_notebook( Notebook nb ) {
		var node = new Node( null, nb );
		node.changed.connect( set_modified );
		_nodes.append_val( node );
		_modified = true;
		changed();
	}

	// Removes the notebook at the specified position
	public void remove_notebook( int pos ) {
		_nodes.index( pos ).changed.disconnect( set_modified );
		_nodes.remove_index( pos );
		_modified = true;
		changed();
	}

	// Returns the number of notebooks at the top-most level
	public int size() {
		return( (int)_nodes.length );
	}

	// Returns the node at the given top-level position
	public Node? get_node( int pos ) {
		return( _nodes.index( pos ) );
	}

	public Node? get_node_at_position( int pos ) {
		for( int i=0; i<_nodes.length; i++ ) {
  		var node = _nodes.index( i ).get_node_at_position( ref pos );
			if( node != null ) {
				return( node );
			}
		}
		return( null );
	}

	// Searches the notebooks for one that matches the given ID
	public Notebook? find_notebook( int id ) {
		for( int i=0; i<_nodes.length; i++ ) {
			var nb = _nodes.index( i ).find_notebook( id );
			if( nb != null ) {
				return( nb );
			}
		}
		return( null );
	}

	// Searches the notebooks for a note that matches the given ID
	public Note? find_note( int id ) {
		for( int i=0; i<_nodes.length; i++ ) {
			var note = _nodes.index( i ).find_note( id );
			if( note != null ) {
				return( note );
			}
		}
		return( null );
	}

	// Searches the tree of notebooks for notes that contain the given tag
  public void get_notes_with_tag( string tag, Array<Note> notes ) {
  	for( int i=0; i<_nodes.length; i++ ) {
  		_nodes.index( i ).get_notes_with_tag( tag, notes );
  	}
  }

	private string xml_file() {
		return( Utils.user_location( "notebooks.xml" ) );
	}

	// Saves the current notebook tree in XML format
	public void save() {

		if( !_modified ) return;

	  Xml.Doc*  doc  = new Xml.Doc( "1.0" );
	  Xml.Node* root = new Xml.Node( null, "notebooks" );

	  root->set_prop( "version", MosaicNote.current_version );
	  root->set_prop( "notebook-id", Notebook.current_id.to_string() );
	  root->set_prop( "note-id", Note.current_id.to_string() );
	  root->set_prop( "note-item-id", NoteItem.current_id.to_string() );

	  for( int i=0; i<_nodes.length; i++ ) {
	  	root->add_child( _nodes.index( i ).save() );
	  }
	
	  doc->set_root_element( root );
	  doc->save_format_file( xml_file(), 1 );
	
	  delete doc;

	  _modified = false;

  }

  /* Saves all of the modified notebooks */
  public void save_notebooks() {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).save_notebooks();
    }
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

    var ni_id = root->get_prop( "note-item-id" );
    if( ni_id != null ) {
    	NoteItem.current_id = int.parse( ni_id );
    }

    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
      	var node = new Node.from_xml( it, null );
      	node.changed.connect( set_modified );
      	_nodes.append_val( node );
      }
    }
    
    delete doc;

  }

  private void check_version( string version ) {

  	// Nothing to do yet

  }

}