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

public class NoteItemUML : NoteItem {

	private string _description = "";

	public string description {
		get {
			return( _description );
		}
		set {
			if( _description != value ) {
				_description = value;
				modified = true;
				changed();
			}
		}
	}

	public signal void diagram_updated( string? filename );

	// Default constructor
	public NoteItemUML( Note note ) {
		base( note, NoteItemType.UML );
		changed.connect( update_diagram );
	}

	public NoteItemUML.from_xml( Note note, Xml.Node* node ) {
		base( note, NoteItemType.UML );
		load( node );
		changed.connect( update_diagram );
	}

	// Returns the Markdown version of this item
	public override string to_markdown( bool pandoc ) {
		var filename = Utils.user_location( "test.png" );
	  return( format_for_width( "![diagram](file://%s)".printf( filename ), filename, pandoc ) );
	}

  // Returns the resource filename
  public override string get_resource_filename() {
    return( get_resource_path( "png" ) );
  }

	// Updates the UML diagram
	public void update_diagram() {

		if( content != "" ) {

      Utils.create_dir( get_resource_dir() );

		  var input  = get_resource_path( "txt" );
		  var output = get_resource_path( "png" );

		  FileUtils.remove( output );

			// Save the current content to a file
			try {
				FileUtils.set_contents( input, content );
			} catch( FileError e ) {
				stdout.printf( "Error saving UML diagram contents to file %s: %s\n", input, e.message );
				diagram_updated( null );
				return;
			}

			var loop = new MainLoop();

			try {
	    	string[] spawn_args = { "plantuml", "-tpng", "-o", get_resource_dir(), input };
    		string[] spawn_env  = Environ.get();
    		Pid child_pid;

		    Process.spawn_async( "/",
    			spawn_args,
		    	spawn_env,
    			SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
		    	null,
    			out child_pid
    		);

    		ChildWatch.add( child_pid, (pid, status) => {
			    Process.close_pid( pid );
			    loop.quit();
     	    if( FileUtils.test( output, FileTest.EXISTS ) ) {
	   		    diagram_updated( output );
   		    } else {
  		    	diagram_updated( null );
   		    }
		    });

    		loop.run();
    		return;
    	} catch (SpawnError e) {
		    print ("Error: %s\n", e.message);
	    }

	  }

    diagram_updated( null );

	}

  //-------------------------------------------------------------
  // Saves the content in XML format
  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "description", description );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the content from XML format
  protected override void load( Xml.Node* node ) {
    var d = node->get_prop( "description" );
    if( d != null ) {
      _description = d;
    }
  }

}