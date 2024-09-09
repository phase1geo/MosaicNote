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

using GLib;

public class UndoItemAssetsAdd : UndoItem {

  private NoteItemPaneAssets _pane;
  private NoteItemAssets     _item;
  private int                _index;
  private NoteItemAsset      _asset;

  //-------------------------------------------------------------
  // Default constructor
  public UndoItemAssetsAdd( NoteItemPaneAssets pane, NoteItemAssets item, int index ) {
    base( _( "Add Asset" ) );
    _pane  = pane;
    _item  = item;
    _index = index;
    _asset = item.get_asset( index );
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo( MainWindow win ) {
    _item.remove_asset( _index );
    _pane.remove_asset( _index );
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo( MainWindow win ) {
    _item.insert_existing_asset( _index, _asset );
    _pane.add_asset( _asset.orig_path, false, _index );
  }

}
