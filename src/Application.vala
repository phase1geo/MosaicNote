/*
* Copyright (c) 2023 (https://github.com/phase1geo/Journaler)
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
using GLib;
using Gee;

public class MosaicNote : Gtk.Application {

  private const string INTERFACE_SCHEMA = "org.gnome.desktop.interface";

  private static bool show_version = false;
  public  static GLib.Settings settings;
  public  static string        current_version = "1.0.0";

  private MainWindow appwin;

  //-------------------------------------------------------------
  // Default constructor.
  public MosaicNote () {

    Object( application_id: "com.github.phase1geo.mosaic-note", flags: ApplicationFlags.HANDLES_OPEN );

    Intl.setlocale( LocaleCategory.ALL, "" );
    Intl.bindtextdomain( GETTEXT_PACKAGE, LOCALEDIR );
    Intl.bind_textdomain_codeset( GETTEXT_PACKAGE, "UTF-8" );
    Intl.textdomain( GETTEXT_PACKAGE );

    startup.connect( start_application );
    activate.connect( on_activate );
    open.connect( open_files );

  }

  //-------------------------------------------------------------
  // First method called in the startup process
  private void start_application() {

    /* Initialize the settings */
    settings = new GLib.Settings( "com.github.phase1geo.mosaic-note" );

    /* Add the application-specific icons */
    weak IconTheme default_theme = IconTheme.get_for_display( Display.get_default() );
    default_theme.add_resource_path( "/com/github/phase1geo/mosaic-note" );

    /* Make sure that the user data directory exists */
    var app_dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "mosaic-note" );
    Utils.create_dir( app_dir );

    /* Create the main window */
    appwin = new MainWindow( this, settings );

    var granite_settings = Granite.Settings.get_default();
    var gtk_settings = Gtk.Settings.get_default();

    /* Handle dark mode changes */
    gtk_settings.gtk_application_prefer_dark_theme = (
      granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
    );
    appwin.themes.dark_mode = gtk_settings.gtk_application_prefer_dark_theme;

    granite_settings.notify["prefers-color-scheme"].connect (() => {
      gtk_settings.gtk_application_prefer_dark_theme = (
        granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
      );
      appwin.themes.dark_mode = gtk_settings.gtk_application_prefer_dark_theme;
    });

  }

  //-------------------------------------------------------------
  // Called if we have no files to open
  private void on_activate() {
  }

  //-------------------------------------------------------------
  // Attempts to show the note with the given query information.
  // The query must be "id=N" where N is the note ID to display.
  private void show_note( string? uri_query ) {

    if( uri_query != null ) {
      var query_items = uri_query.split( "=" );
      if( (query_items[0] != "id") || !appwin.show_note( int.parse( query_items[1] ) ) ) {
        appwin.notification( "MosaicNote", "Linked note could not be found\n" );
      }
    }

  }

  //-------------------------------------------------------------
  // Opens files from the command-line.  The only "file" that we will
  // handle is the URI scheme (mosaicnote://*).
  private void open_files( File[] files, string hint ) {
    if( files.length == 1 ) {
      try {
        var uri = Uri.parse( files[0].get_uri(), UriFlags.NONE );
        if( uri.get_scheme() == "mosaicnote" ) {
          switch( uri.get_host() ) {
            case "show-note" :  show_note( uri.get_query() );  break;
            default          :  return;
          }
        }
        /*
        stdout.printf( "Parsed URI\n" );
        stdout.printf( "  auth_params: %s\n", uri.get_auth_params() ?? "NA" );
        stdout.printf( "  flags:       %s\n", uri.get_flags().to_string() );
        stdout.printf( "  fragment:    %s\n", uri.get_fragment() ?? "NA" );
        stdout.printf( "  host:        %s\n", uri.get_host() ?? "NA" );
        stdout.printf( "  path:        %s\n", uri.get_path() );
        stdout.printf( "  port:        %d\n", uri.get_port() );
        stdout.printf( "  query:       %s\n", uri.get_query() ?? "NA" );
        stdout.printf( "  scheme:      %s\n", uri.get_scheme() );
        stdout.printf( "  user:        %s\n", uri.get_user() ?? "NA" );
        stdout.printf( "  userinfo:    %s\n", uri.get_userinfo() ?? "NA" );
        */
      } catch( UriError e ) {
        stdout.printf( "URI parsing error: %s\n", e.message );
      }
    }
  }

  //-------------------------------------------------------------
  // Parse the command-line arguments
  private void parse_arguments( ref unowned string[] args ) {

    var context = new OptionContext( "- MosaicNote Options" );
    var options = new OptionEntry[2];

    /* Create the command-line options */
    options[0] = {"version", 0, 0, OptionArg.NONE, ref show_version, _( "Display version number" ), null};
    options[1] = {null};

    /* Parse the arguments */
    try {
      context.set_help_enabled( true );
      context.add_main_entries( options, null );
      context.parse( ref args );
    } catch( OptionError e ) {
      stdout.printf( _( "ERROR: %s\n" ), e.message );
      stdout.printf( _( "Run '%s --help' to see valid options\n" ), args[0] );
      Process.exit( 1 );
    }

    /* If the version was specified, output it and then exit */
    if( show_version ) {
      stdout.printf( current_version + "\n" );
      Process.exit( 0 );
    }

  }

  //-------------------------------------------------------------
  // Main routine which gets everything started
  public static int main( string[] args ) {

    // Make sure that we initialize the GtkSource library
    GtkSource.init();

    var app = new MosaicNote();
    app.parse_arguments( ref args );

    return( app.run( args ) );

  }

}

