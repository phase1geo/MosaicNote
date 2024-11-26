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

using Gtk;
using Gdk;
using Cairo;

public class Utils {

  public delegate void ConfirmationCallback( Object? obj );

  //-------------------------------------------------------------
  // Returns the location of the local default library.
  public static string default_library_location() {
    return( GLib.Path.build_filename( Environment.get_user_data_dir(), "mosaic-note" ) );
  }

  //-------------------------------------------------------------
  // Returns the location of the given subdirectory path within
  // the user storage directory
  public static string user_location( string path ) {
    var location = MosaicNote.settings.get_string( "library-location" );
    return( GLib.Path.build_filename( ((location == "default") ? default_library_location() : location), path ) );
  }

  //-------------------------------------------------------------
  // Creates the given directory (and all parent directories) with
  // appropriate permissions
  public static bool create_dir( string path ) {
    return( DirUtils.create_with_parents( path, 0755 ) == 0 );
  }

  //-------------------------------------------------------------
  // Displays the given message to standard output if we are
  // development mode
  public static void debug_output( string msg ) {
    if( MosaicNote.settings.get_boolean( "developer-mode" ) ) {
      stdout.printf( "%s\n", msg );
    }
  }

  //-------------------------------------------------------------
  // Returns the extension for the given filename
  public static string get_extension( string filename ) {
    var parts = filename.split( "." );
    return( parts[parts.length - 1] );
  }

  //-------------------------------------------------------------
  // Checks to see if the given URI image extension is supported
  public static bool is_uri_supported_image( string uri ) {
    var uri_ext = get_extension( uri ).down();
    foreach( var format in Pixbuf.get_formats() ) {
      foreach( var ext in format.get_extensions() ) {
        if( ext == uri_ext ) {
          return( true );
        }
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns a regular expression useful for parsing clickable URLs.
  public static string url_re() {
    string[] res = {
      "mailto:.+@[a-z0-9-]+\\.[a-z0-9.-]+",
      "[a-zA-Z0-9]+://[a-z0-9-]+\\.[a-z0-9.-]+(?:/|(?:/[][a-zA-Z0-9!#$%&'*+,.:;=?@_~-]+)*)",
      "file:///([^,\\/:*\\?\\<>\"\\|]+(/|\\\\){0,1})+"
    };
    return( "(" + string.joinv( "|",res ) + ")" );
  }

  //-------------------------------------------------------------
  // Returns the rootname of the given filename
  public static string rootname( string filename ) {
    var basename = GLib.Path.get_basename( filename );
    var parts    = basename.split( "." );
    if( parts.length > 2 ) {
      return( string.joinv( ".", parts[0:parts.length-1] ) );
    } else {
      return( parts[0] );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the given coordinates are within the specified
  // bounds.
  public static bool is_within_bounds( double x, double y, double bx, double by, double bw, double bh ) {
    return( (bx < x) && (x < (bx + bw)) && (by < y) && (y < (by + bh)) );
  }

  //-------------------------------------------------------------
  // Returns a string that is suitable to use as an inspector title
  public static string make_title( string str ) {
    return( "<b>" + str + "</b>" );
  }

  //-------------------------------------------------------------
  // Returns an italicized version of this text.
  public static string make_italicized( string str ) {
    return( "<i>" + str + "</i>" );
  }

  //-------------------------------------------------------------
  // Returns a string that is used to display a tooltip with displayed accelerator
  public static string tooltip_with_accel( string tooltip, string accel ) {
    string[] accels = {accel};
    return( Granite.markup_accel_tooltip( accels, tooltip ) );
  }

  //-------------------------------------------------------------
  // Opens the given URL in the proper external default application
  public static void open_url( string url ) {
    if( (url.substring( 0, 7 ) == "file://") || (url.get_char( 0 ) == '/') ) {
      var app = AppInfo.get_default_for_type( "inode/directory", true );
      var uris = new List<string>();
      uris.append( url );
      try {
        app.launch_uris( uris, null );
      } catch( GLib.Error e ) {
        stdout.printf( _( "error: %s\n" ), e.message );
      }
    } else {
      try {
        AppInfo.launch_default_for_uri( url, null );
      } catch( GLib.Error e ) {
        stdout.printf( _( "error: %s\n" ), e.message );
      }
    }
  }

  //-------------------------------------------------------------
  // Prepares the given note string for use in a markup tooltip
  /*
  public static string prepare_note_markup( string note ) {
    var str = markdown_to_html( note );  // .replace( "<", "&lt;" ).replace( ">", "&gt;" ) );
    // stdout.printf( "---------------\n%s--------------\n", str );
    try {
      MatchInfo match_info;
      var re    = new Regex( "</?(\\w+)[^>]*>" );
      var start = 0;
      var list  = new Queue<int>();
      while( re.match_full( str, -1, start, 0, out match_info ) ) {
        int tag_start, tag_end;
        int name_start, name_end;
        match_info.fetch_pos( 0, out tag_start, out tag_end );
        match_info.fetch_pos( 1, out name_start, out name_end );
        var old_tag = str.slice( tag_start, tag_end );
        var new_tag = old_tag;
        var name    = str.slice( name_start, name_end );
        var end_tag = (str.substring( (name_start - 1), 1 ) == "/");
        switch( name ) {
          case "h1"     :  new_tag = end_tag ? "</span>" : "<span weight=\"bold\" size=\"xx-large\">";  break;
          case "h2"     :  new_tag = end_tag ? "</span>" : "<span weight=\"bold\" size=\"x-large\">";   break;
          case "h3"     :  new_tag = end_tag ? "</span>" : "<span weight=\"bold\" size=\"large\">";     break;
          case "h4"     :
          case "h5"     :
          case "h6"     :  new_tag = end_tag ? "</span>" : "<span weight=\"bold\" size=\"medium\">";    break;
          case "strong" :  new_tag = end_tag ? "</b>" : "<b>";  break;
          case "em"     :  new_tag = end_tag ? "</i>" : "<i>";  break;
          case "code"   :  new_tag = end_tag ? "</tt>" : "<tt>";  break;
          case "blockquote" :  new_tag = end_tag ? "</i>" : "<i>";  break;
          case "hr"     :  new_tag = end_tag ? "" : "---";  break;
          case "p"      :  new_tag = "";  break;
          case "br"     :  new_tag = "";  break;
          case "ul"     :
          case "ol"     :
            new_tag = ""; 
            if( end_tag ) {
              list.pop_tail();
            } else {
              list.push_tail( (name == "ul") ? 1000000 : 1 );
            }
            break;
          case "li"     :
            if( end_tag ) {
              new_tag = "";
            } else {
              var val    = list.pop_tail();
              var prefix = string.nfill( list.get_length(), ' ' );
              if( val >= 1000000 ) {
                new_tag = "%s* ".printf( prefix );
              } else {
                new_tag = "%s%d. ".printf( prefix, val );
              }
              list.push_tail( val + 1 );
            }
            break;
        }
        str   = str.splice( tag_start, tag_end, new_tag );
        start = tag_end + (new_tag.length - old_tag.length);
      }
    } catch( RegexError e ) {
      return( note.replace( "<", "&lt;" ) );
    }
    return( str.replace( "\n\n\n", "\n\n" ) );
  }

  //-------------------------------------------------------------
  // Converts the given Markdown into HTML
  public static string markdown_to_html( string md, string? tag = null ) {
    string html;
    // var    flags = 0x57607000;
    var    flags = 0x47607004;
    var    mkd = new Markdown.Document.gfm_format( md.data, flags );
    mkd.compile( flags );
    mkd.get_document( out html );
    if( tag == null ) {
      return( html );
    } else {
      return( "<" + tag + ">" + html + "</" + tag + ">" );
    }
  }
  */

  //-------------------------------------------------------------
  // Returns the line height of the first line of the given pango layout
  public static double get_line_height( Pango.Layout layout ) {
    int height;
    var line = layout.get_line_readonly( 0 );
    if( line == null ) {
      int width;
      layout.get_size( out width, out height );
    } else {
      Pango.Rectangle ink_rect, log_rect;
      line.get_extents( out ink_rect, out log_rect );
      height = log_rect.height;
    }
    return( height / Pango.SCALE );
  }

  //-------------------------------------------------------------
  // Searches for the beginning or ending word
  public static int find_word( string str, int cursor, bool wordstart ) {
    try {
      MatchInfo match_info;
      var substr = wordstart ? str.substring( 0, cursor ) : str.substring( cursor );
      var re = new Regex( wordstart ? ".*(\\W\\w|[\\w\\s][^\\w\\s])" : "(\\w\\W|[^\\w\\s][\\w\\s])" );
      if( re.match( substr, 0, out match_info ) ) {
        int start_pos, end_pos;
        match_info.fetch_pos( 1, out start_pos, out end_pos );
        return( wordstart ? (start_pos + 1) : (cursor + start_pos + 1) );
      }
    } catch( RegexError e ) {}
    return( -1 );
  }
 
  //-------------------------------------------------------------
  // Returns true if the given string is a valid URL
  public static bool is_url( string str ) {
    return( Regex.match_simple( url_re(), str ) );
  }

  /* Returns true if the given file is read-only */
  /*
  public static bool is_read_only( string fname ) {
    var file = File.new_for_path( fname );
    var src  = new Gtk.SourceFile();
    src.set_location( file );
    src.check_file_on_disk();
    return( src.is_readonly() );
  }
  */

  //-------------------------------------------------------------
  // Show the specified popover
  public static void show_popover( Popover popover ) {
    popover.popup();
  }

  //-------------------------------------------------------------
  // Hide the specified popover
  public static void hide_popover( Popover popover ) {
    popover.popdown();
  }

  /*
  public static void set_chooser_folder( FileDialog chooser ) {
    var dir = MosaicNote.settings.get_string( "last-directory" );
    if( dir != "" ) {
      var fdir = File.new_for_path( dir );
      chooser.set_initial_folder( fdir );
    }
  }
  */

  public static void store_chooser_folder( string file, bool is_dir ) {
    var dir = is_dir ? file : GLib.Path.get_dirname( file );
    MosaicNote.settings.set_string( "last-directory", dir );
  }

  /* Creates a snippet that can be inserted into a GtkSource.Buffer */
  public static GtkSource.Snippet? make_snippet( string text ) {

    Xml.Doc*  doc       = new Xml.Doc( "1.0" );
    Xml.Node* root      = new Xml.Node( null, "snippet" );
    Xml.Node* text_node = new Xml.Node( null, "text" );

    var snippet_text = "";

    root->set_prop( "_name", "" );
    root->set_prop( "trigger", "" );
    root->set_prop( "_description", "" );

    text_node->add_child( doc->new_cdata_block( text, text.length ) );

    root->add_child( text_node );

    doc->set_root_element( root );
    doc->dump_memory_format( out snippet_text );

    delete doc;

    /*
    try {
      var snippet = new GtkSource.Snippet.parsed( snippet_text );
      return( snippet );
    } catch( Error e ) {
      stderr.printf( "ERROR: %s\n", e.message );
    }
    */

    return( null );

  }

  //-------------------------------------------------------------
  // Creates a file chooser dialog and returns it to the code
  public static Gtk.FileDialog make_file_chooser( string user_title, string user_accept_label ) {

    var gtk_settings = Gtk.Settings.get_default();

    var use_header = gtk_settings.gtk_dialogs_use_header;
    gtk_settings.gtk_dialogs_use_header = true;

    var dialog = new FileDialog() {
      title = user_title,
      accept_label = user_accept_label
    };
    gtk_settings.gtk_dialogs_use_header = use_header;

    return( dialog );

  }

  //-------------------------------------------------------------
  // Displays a confirmation dialog.
  public static void show_confirmation( MainWindow win, string question, string detail_msg, Object? obj, ConfirmationCallback callback ) {
    var dialog = new AlertDialog( question ) {
      buttons = { _( "Yes" ), _( "No" ) },
      modal = true,
      default_button = 1,
      cancel_button = 1,
      detail = detail_msg
    };
    dialog.choose.begin( win, null, (obj, res) => {
      try {
        var result = dialog.choose.end( res );
        if( result == 0 ) {
          callback( obj );
        }
      } catch( Error e ) {}
    });
  }

  //-------------------------------------------------------------
  // Clears the given box widget
  public static void clear_box( Box box ) {
    while( box.get_first_child() != null ) {
      box.remove( box.get_first_child() );
    } 
  }

  //-------------------------------------------------------------
  // Clears the given listbox widget
  public static void clear_listbox( ListBox box ) {
    box.remove_all();
  }

  //-------------------------------------------------------------
  // Returns the child widget at the given index of the parent widget (or null if one does not exist)
  public static Widget? get_child_at_index( Widget parent, int index ) {
    var child = (index < 0) ? null : parent.get_first_child();
    while( (child != null) && (index-- > 0) ) {
      child = child.get_next_sibling();
    }
    return( child );
  } 

  //-------------------------------------------------------------
  // Returns the index of the given child within the parent
  public static int get_child_index( Widget parent, Widget child ) {
    var index = 0;
    var current_child = parent.get_first_child();
    while( (current_child != null) && (child != current_child) ) {
      current_child = current_child.get_next_sibling();
      index++;
    }
    return( (current_child == null) ? -1 : index );
  }

  //-------------------------------------------------------------
  // Returns the pixel width of the given image
  public static int image_width( string pathname ) {
    int width, height;
    Pixbuf.get_file_info( pathname, out width, out height );
    return( width );
  }

  //-------------------------------------------------------------
  // Creates a temporary file and returns the path.
  public static string? create_temp_filename( string ext ) {
    try {
      string filename = "";
      var fd = FileUtils.open_tmp( "mnXXXXXX.%s".printf( ext ), out filename );
      FileUtils.close( fd );
      return( filename );
    } catch( FileError e ) {}
    return( null );
  }

  //-------------------------------------------------------------
  // Writes the contents to the given file.
  public static bool write_to_filename( string? filename, string contents ) {
    if( filename != null ) {
      try {
        FileUtils.set_contents( filename, contents );
        return( true );
      } catch( FileError e ) {}
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Writes the given file contents to a temporary file.
  public static bool write_to_tmp( string ext, string contents ) {
    return( write_to_filename( create_temp_filename( ext ), contents ) );
  }

}
