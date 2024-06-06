public class Export {

  public static bool export_html( string filename, Note note ) {

    var file_parts  = filename.split( "." );
    var md_filename = string.joinv( ".", file_parts[0:file_parts.length-1] ) + ".md";

    // Write the note contents to a file
    var md = note.to_markdown();
    try {
      FileUtils.set_contents( md_filename, md );
    } catch( FileError e ) {
      stdout.printf( "ERROR:  %s\n", e.message );
      return( false );
    }

    // TODO - Get the list of all languages that need to be supported and taken from the pandoc-langs
    // directory.

    // Call pandoc (use async method) to generate the documentation
    try {
      string[] command = {};
      command += "pandoc";
      command += "--syntax-definition /usr/share/mosaic-note/pandoc-langs/vala.xml";
      command += "-s";
      command += "-o";
      command += filename;
      command += md_filename;
      Process.spawn_command_line_async( string.joinv( " ", command ) );
    } catch( SpawnError e ) {
      stdout.printf( "ERROR:  %s\n", e.message );
      return( false );
    }

    return( true );

  }

}