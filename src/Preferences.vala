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
using Gee;

public class Preferences : Gtk.Dialog {

  private MainWindow                 _win;
  private HashMap<string,MenuButton> _menus;

  private const GLib.ActionEntry action_entries[] = {
    { "action_spell_menu", action_spell_menu, "s" },
  };

  public signal void update_theme( string theme_id );

  private delegate string ValidateEntryCallback( Entry entry, string text, int position );

  /* Default constructor */
  public Preferences( MainWindow win ) {

    Object(
      resizable: false,
      title: _("Preferences"),
      transient_for: win,
      modal: true
    );

    _win      = win;
    _menus    = new HashMap<string,MenuButton>();

    var stack = new Stack() {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 24,
      margin_bottom = 18,
      hhomogeneous  = true,
      vhomogeneous  = true
    };
    stack.add_titled( create_general(), "general",  _( "General" ) );
    stack.add_titled( create_editor(),  "editor",   _( "Editor" ) );

    var switcher = new StackSwitcher() {
      halign = Align.CENTER
    };
    switcher.set_stack( stack );

    var box = new Box( Orientation.VERTICAL, 0 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    box.append( switcher );
    box.append( stack );

    get_content_area().append( box );

    /* Add the menu actions */
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "prefs", actions );

  }

  // -----------------------------------------------------------------
  // GENERAL PANEL
  // -----------------------------------------------------------------

  /* Creates the general panel */
  private Grid create_general() {

    var grid = new Grid() {
      row_spacing = 5,
      column_spacing = 5,
      halign = Align.CENTER,
      row_homogeneous = true
    };

    var row = 0;

    grid.attach( make_label( _( "Enable spell checker" ) ), 0, row );
    grid.attach( make_switch( "enable-spellchecker" ), 1, row );
    row++;

    grid.attach( make_label( _( "Spell checker language" ) ), 0, row );
    grid.attach( make_menu( "spellchecker-language", spell_lang_label(), create_spell_lang_menu() ), 1, row, 2 );
    row++;

    grid.attach( make_label( _( "Show Tags section in sidebar" ) ), 0, row );
    grid.attach( make_switch( "sidebar-show-tags" ), 1, row );
    row++;

    return( grid );

  }

  /* Create the spell checker language menu */
  private GLib.Menu create_spell_lang_menu() {

    var menu  = new GLib.Menu();
    var langs = new Gee.ArrayList<string>();
    var spell = new SpellChecker();

    spell.get_language_list( langs );

    var sys_menu = new GLib.Menu();
    sys_menu.append( _( "Use System Language" ), "prefs.action_spell_menu('system')" );

    var other_menu = new GLib.Menu();
    langs.foreach((lang) => {
      other_menu.append( lang, "prefs.action_spell_menu('%s')".printf( lang ) );
      return( true );
    });

    menu.append_section( null, sys_menu );
    menu.append_section( null, other_menu );

    return( menu );

  }

  /* Get the currently specified spell checker language value from settings */
  private string spell_lang_label() {

    var lang = MosaicNote.settings.get_string( "spellchecker-language" );

    if( lang == "system" ) {
      return( _( "Use System Language" ) );
    } else {
      return( lang );
    }

  }

  /* Handles changes to the spell checker language menu */
  private void action_spell_menu( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var lang = variant.get_string();
      if( lang == "system" ) {
        lang = _( "Use System Language" );
      }
      _menus.get( "spellchecker-language" ).label = lang;
      MosaicNote.settings.set_string( "spellchecker-language", lang );
    }
  }

  // -----------------------------------------------------------------
  // EDITOR PANEL
  // -----------------------------------------------------------------

  /* Creates the editor panel */
  private Grid create_editor() {

    var grid = new Grid() {
      row_spacing = 5,
      column_spacing = 5,
      halign = Align.CENTER,
      row_homogeneous = true
    };

    var row = 0;

    grid.attach( make_label( _( "Default Theme" ) ), 0, row );
    grid.attach( make_themes(), 1, row, 2 );
    row++;

    grid.attach( make_label( _( "Font Size" ) ), 0, row );
    grid.attach( make_spinner( "editor-font-size", 8, 24, 1 ), 1, row );
    row++;

    grid.attach( make_label( _( "Line Spacing" ) ), 0, row );
    grid.attach( make_spinner( "editor-line-spacing", 2, 20, 1 ), 1, row );
    row++;

    grid.attach( make_label( _( "Enable Vim Mode" ) ), 0, row );
    grid.attach( make_switch( "editor-vim-mode" ), 1, row );

    return( grid );

  }
  
  // -----------------------------------------------------------------

  /* Creates visual spacer */
  private Label make_spacer() {
    var w = new Label( "" );
    return( w );
  }

  /* Creates label */
  private Label make_label( string label ) {
    var w = new Label( Utils.make_title( label ) ) {
      use_markup = true,
      halign = Align.END
    };
    return( w );
  }

  /* Creates switch */
  private Switch make_switch( string setting ) {
    var w = new Switch() {
      halign = Align.START,
      valign = Align.CENTER
    };
    MosaicNote.settings.bind( setting, w, "active", SettingsBindFlags.DEFAULT );
    return( w );
  }

  /* Creates spinner */
  private SpinButton make_spinner( string setting, int min_value, int max_value, int step ) {
    var w = new SpinButton.with_range( min_value, max_value, step );
    MosaicNote.settings.bind( setting, w, "value", SettingsBindFlags.DEFAULT );
    return( w );
  }

  /* Creates an entry */
  private Entry make_entry( string setting, string placeholder, int max_length = 30, ValidateEntryCallback? cb = null ) {
    var w = new Entry() {
      placeholder_text        = placeholder,
      max_length              = max_length,
      enable_emoji_completion = false
    };
    if( cb != null ) {
      w.insert_text.connect((new_text, new_text_length, ref position) => {
        var cleaned = cb( w, new_text, position );
        if( cleaned != new_text ) {
          handle_text_insertion( w, cleaned, ref position );
        }
      });
    }
    MosaicNote.settings.bind( setting, w, "text", SettingsBindFlags.DEFAULT );
    return( w );
  }

  /* Helper function for the make_entry method */
  private void handle_text_insertion( Entry entry, string cleaned, ref int position ) {
    var void_entry = (void*)entry;
    SignalHandler.block_by_func( void_entry, (void*)handle_text_insertion, this );
    entry.insert_text( cleaned, cleaned.length, ref position );
    SignalHandler.unblock_by_func( void_entry, (void*)handle_text_insertion, this );
    Signal.stop_emission_by_name( entry, "insert_text" );
  }

  /* Creates a menubutton with the given menu */
  private MenuButton make_menu( string setting, string label, GLib.Menu menu ) {
    var w = new MenuButton() {
      label      = label,
      menu_model = menu
    };
    _menus.set( setting, w );
    return( w );
  }

  /* Creates an information image */
  private Image make_info( string detail ) {
    var w = new Image.from_icon_name( "dialog-information-symbolic" ) {
      halign       = Align.START,
      tooltip_text = detail
    };
    return( w );
  }

  /* Creates the theme menu button */
  private DropDown make_themes() {

    var mgr    = GtkSource.StyleSchemeManager.get_default();
    var ids    = mgr.get_scheme_ids();
    var themes = new DropDown.from_strings( mgr.get_scheme_ids() );

    themes.notify["selected"].connect(() => {
      var id = ids[themes.selected];
      MosaicNote.settings.set_string( "default-theme", id );
      update_theme( id );
    });

    return( themes );

  }

}
