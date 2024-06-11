/*
* Copyright (c) 2024 (https://github.com/phase1geo/MosaicNote)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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

public class ToolbarItem : Box {

  private GtkSource.View? _text = null;

  public NoteItemType item_type { get; private set; default = NoteItemType.NUM; }

  public GtkSource.View? text {
    get {
      return( _text );
    }
    set {
      _text = value;
      text_updated();
    }
  }

  // Constructor
  public ToolbarItem( NoteItemType? type = null ) {

    Object( orientation: Orientation.HORIZONTAL, spacing: 5, halign: Align.FILL, hexpand: true );

    if( type != null ) {
      item_type = type;
    }

  }

  // Called whenever the text changes
  protected virtual void text_updated() {}

}