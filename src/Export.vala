public class Export {

  public static bool export( string filename, Note note ) {

    var file_parts  = filename.split( "." );
    var extension   = file_parts[file_parts.length];
    var md_filename = string.joinv( ".", file_parts[0:file_parts.length-1] ) + ".md";
    var lang_dir    = "";

    foreach( var data_dir in Environment.get_system_data_dirs() ) {
      lang_dir = GLib.Path.build_filename( data_dir, "mosaic-note", "pandoc-langs" );
      if( FileUtils.test( lang_dir, FileTest.EXISTS ) ) {
        break;
      }
    }

    // Write the note contents to a file
    var md = note.to_markdown( extension != "md" );
    try {
      FileUtils.set_contents( md_filename, md );
    } catch( FileError e ) {
      stdout.printf( "ERROR:  %s\n", e.message );
      return( false );
    }

    // If we don't need to run pandoc, return immediately
    if( extension == "md" ) {
      return( true );
    }

    // Get the list of all languages that need to be supported and taken from the pandoc-langs directory.
    var langs = new Gee.HashSet<string>();
    note.get_needed_languages( langs );

    // Call pandoc (use async method) to generate the documentation
    try {

      string[] command = {};
      command += "pandoc";

      // Figure out which languages we need to add to Pandoc
      if( lang_dir != "" ) {
        langs.foreach((lang) => {
          var lang_file = Path.build_filename( lang_dir, lang + ".xml" );
          if( FileUtils.test( lang_file, FileTest.EXISTS ) ) {
            command += "--syntax-definition";
            command += lang_file;
          }    
          return( true );
        });
      }

      command += "--self-contained";
      command += "-o";
      command += filename;
      command += md_filename;

      Process.spawn_command_line_async( string.joinv( " ", command ) );

    } catch( SpawnError e ) {
      stdout.printf( "ERROR:  %s\n", e.message );
      FileUtils.remove( md_filename );
      return( false );
    }

    return( true );

  }

}