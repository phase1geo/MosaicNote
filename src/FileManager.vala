/*
* Copyright (c) 2026 (https://github.com/phase1geo/MosaicNote)
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

using Gee;

public class FileInstance {

  public string  path { get; private set; default = ""; }
  public string? etag { get; set; default = null; }

  //-------------------------------------------------------------
  // Constructor
  public FileInstance( string path, string? etag ) {
    this.path = path;
    this.etag = etag;
  }

  //-------------------------------------------------------------
  // Returns the name of the backup file for this instance.
  public string backup_filepath() {
    return( path + ".bak" );
  }

}

public class FileManager {

  private HashMap<string, FileInstance> _instances;

  //-------------------------------------------------------------
  // Constructor
  public FileManager() {
    _instances = new HashMap<string, FileInstance>();
  }

  //-------------------------------------------------------------
  // Create a new file instance and add it to the list of instances.
  private void make_instance( string inst_name ) {
    var inst = new FileInstance( Utils.user_location( inst_name ), null );
    _instances.set( inst_name, inst );
  }

  //-------------------------------------------------------------
  // Returns the etag value associated with the given file.
  private string? get_etag( File file ) {
    try {
      var info = file.query_info( FileAttribute.ETAG_VALUE, FileQueryInfoFlags.NONE );
      return info.get_etag();
    } catch( Error e ) {
      return null;
    }
  }

  //-------------------------------------------------------------
  // Returns true if a backup file exists for the given instance name.
  public bool backup_exists( string inst_name ) {
    if( !_instances.has_key( inst_name ) ) {
      make_instance( inst_name );
    }
    var inst = _instances.get( inst_name );
    return( FileUtils.test( inst.backup_filepath(), FileTest.EXISTS ) );
  }

  //-------------------------------------------------------------
  // Called to replace the original file with the backup file, if
  // one exists.
  public bool use_backup( string inst_name ) {
    if( backup_exists( inst_name ) ) {
      // TBD
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Reads the given XML document from a file.
  public Xml.Doc* read_xml( string inst_name ) {

    if( !_instances.has_key( inst_name ) ) {
      make_instance( inst_name );
    }

    var inst = _instances.get( inst_name );
    var file = File.new_for_path( inst.path );

    if( !file.query_exists() ) {
      inst.etag = null;
      return( null );
    }

    uint8[] contents;
    string? read_etag = null;

    try {
      if( !file.load_contents( null, out contents, out read_etag ) ) {
        return( null );
      }
    } catch( Error e ) {
      return( null );
    }

    var doc = Xml.Parser.read_memory(
      (string)contents,
      contents.length,
      file.get_uri(),
      null,
      (Xml.ParserOption.NONET | Xml.ParserOption.HUGE | Xml.ParserOption.NOWARNING)
    );

    if( doc != null ) {
      inst.etag = read_etag;
    }

    return( doc );

  }

  //-------------------------------------------------------------
  // Writes the given XML document to a file.
  public bool write_xml( Xml.Doc* doc, string inst_name ) {

    if( !_instances.has_key( inst_name ) ) {
      make_instance( inst_name );
    }

    var inst = _instances.get( inst_name );

    // 1. Dump memory from document to string.
    string contents;
    doc->dump_memory_format( out contents );

    // 2. Keep the previous version as <name>.bak (only if it exists).
    var file = File.new_for_path( inst.path );
    if( file.query_exists() ) {
      var bak = File.new_for_path( inst.backup_filepath() );
      try {
        file.copy( bak, FileCopyFlags.OVERWRITE );
      } catch( Error e ) {
        return( false );
      }
    }

    // 3. Atomic replace: GIO writes to a temp file in the same directory,
    //    then renames it over the original.
    try {
      string new_etag;
      file.replace_contents(
        contents.data,
        inst.etag,                         // etag: don't check
        false,                             // make_backup: handled in step 2
        FileCreateFlags.REPLACE_DESTINATION,
        out new_etag,
        null                               // cancellable
      );
      inst.etag = new_etag;
    } catch( Error e ) {
      return( false );
    }

    return( true );

  }

}
