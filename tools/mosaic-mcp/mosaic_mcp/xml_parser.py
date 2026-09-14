"""
Read-only parsing layer for MosaicNote's on-disk XML data.

Layout (as of MosaicNote's current format):

    ~/.local/share/mosaic-note/
        notebooks.xml                  <- top-level notebook index
        notebooks/
            notebook-<id>/
                notebook.xml            <- all notes for that notebook
                resources/              <- files referenced by asset blocks

notebooks.xml carries three "special" notebooks by convention
(inbox-id, trash-id, templates-id) that are not listed as explicit
<node> children but always exist on disk. Every other notebook is a
<node id="..." name="..."/> element. The notebook's directory name on
disk is "notebook-" followed by its numeric id (confirmed: the Inbox
notebook has id="0" and lives at notebooks/notebook-0/notebook.xml,
matching inbox-id="0" in notebooks.xml).

This module has no MCP dependency so it can be tested/used standalone.
"""

from __future__ import annotations

import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


class MosaicNoteError(Exception):
    """Raised for problems reading or parsing MosaicNote data."""


@dataclass
class Notebook:
    id: str
    name: str
    special: Optional[str] = None  # "inbox" | "trash" | "templates" | None


@dataclass
class Block:
    """One content block inside a row (markdown, table, math, etc.)."""

    type: str
    id: Optional[str] = None
    presentable: bool = True
    description: Optional[str] = None
    text: Optional[str] = None  # primary text content, meaning depends on type
    extra: dict = field(default_factory=dict)  # type-specific structured data


@dataclass
class Row:
    expanded: bool
    blocks: list[Block] = field(default_factory=list)


@dataclass
class Note:
    id: str
    title: str
    created: str
    updated: str
    viewed: str
    locked: bool
    favorite: bool
    referred: str
    tags: list[str] = field(default_factory=list)
    rows: list[Row] = field(default_factory=list)


def _bool(val: Optional[str]) -> bool:
    return (val or "").strip().lower() == "true"


class MosaicNoteStore:
    """Read-only access to a MosaicNote data directory."""

    def __init__(self, data_dir: str | Path):
        self.data_dir = Path(data_dir).expanduser()
        self.notebooks_xml = self.data_dir / "notebooks.xml"
        self.notebooks_dir = self.data_dir / "notebooks"
        if not self.notebooks_xml.exists():
            raise MosaicNoteError(
                f"notebooks.xml not found at {self.notebooks_xml}. "
                "Is MOSAIC_NOTE_DATA_DIR pointing at the right directory?"
            )

    # -- notebooks -----------------------------------------------------

    def list_notebooks(self) -> list[Notebook]:
        root = self._parse(self.notebooks_xml)

        special_map = {
            root.get("inbox-id"): "inbox",
            root.get("trash-id"): "trash",
            root.get("templates-id"): "templates",
        }
        special_names = {"inbox": "Inbox", "trash": "Trash", "templates": "Templates"}

        notebooks: dict[str, Notebook] = {}

        # Special notebooks are implicit: they always exist on disk even
        # though notebooks.xml doesn't list them as <node> elements.
        for nb_id, kind in special_map.items():
            if nb_id is None:
                continue
            notebooks[nb_id] = Notebook(id=nb_id, name=special_names[kind], special=kind)

        for node in root.findall("node"):
            nb_id = node.get("id")
            if nb_id is None:
                continue
            notebooks[nb_id] = Notebook(id=nb_id, name=node.get("name", ""), special=None)

        # Prefer a stable order: special notebooks first, then the rest by id.
        def sort_key(nb: Notebook):
            return (0 if nb.special else 1, int(nb.id) if nb.id.isdigit() else nb.id)

        return sorted(notebooks.values(), key=sort_key)

    def get_notebook(self, notebook_id: str) -> Notebook:
        for nb in self.list_notebooks():
            if nb.id == str(notebook_id):
                return nb
        raise MosaicNoteError(f"No notebook with id '{notebook_id}'")

    # -- notes -----------------------------------------------------------

    def _notebook_xml_path(self, notebook_id: str) -> Path:
        return self.notebooks_dir / f"notebook-{notebook_id}" / "notebook.xml"

    def list_notes(self, notebook_id: str) -> list[Note]:
        path = self._notebook_xml_path(notebook_id)
        if not path.exists():
            raise MosaicNoteError(f"notebook.xml not found for notebook '{notebook_id}' at {path}")
        root = self._parse(path)
        return [self._parse_note(note_el) for note_el in root.findall("note")]

    def get_note(self, notebook_id: str, note_id: str) -> Note:
        for note in self.list_notes(notebook_id):
            if note.id == str(note_id):
                return note
        raise MosaicNoteError(f"No note with id '{note_id}' in notebook '{notebook_id}'")

    def search_notes(self, query: str, notebook_id: Optional[str] = None) -> list[tuple[Notebook, Note]]:
        """Case-insensitive substring search over title, tags, and block text."""
        query_lower = query.lower()
        results: list[tuple[Notebook, Note]] = []

        notebooks = [self.get_notebook(notebook_id)] if notebook_id else self.list_notebooks()

        for nb in notebooks:
            path = self._notebook_xml_path(nb.id)
            if not path.exists():
                continue
            try:
                root = self._parse(path)
            except MosaicNoteError:
                continue
            for note_el in root.findall("note"):
                note = self._parse_note(note_el)
                if self._note_matches(note, query_lower):
                    results.append((nb, note))

        return results

    # -- internals ---------------------------------------------------------

    @staticmethod
    def _parse(path: Path) -> ET.Element:
        try:
            return ET.parse(path).getroot()
        except ET.ParseError as e:
            raise MosaicNoteError(f"Failed to parse XML at {path}: {e}") from e

    def _parse_note(self, note_el: ET.Element) -> Note:
        tags_el = note_el.find("tags")
        tags = []
        if tags_el is not None:
            for tag_el in tags_el:
                tag_text = (tag_el.get("name") or tag_el.text or "").strip()
                if tag_text:
                    tags.append(tag_text)

        rows: list[Row] = []
        rows_el = note_el.find("rows")
        if rows_el is not None:
            for row_el in rows_el.findall("row"):
                blocks = [self._parse_block(b) for b in list(row_el)]
                rows.append(Row(expanded=_bool(row_el.get("expanded")), blocks=blocks))

        return Note(
            id=note_el.get("id", ""),
            title=note_el.get("title", "") or "",
            created=note_el.get("created", ""),
            updated=note_el.get("updated", ""),
            viewed=note_el.get("viewed", ""),
            locked=_bool(note_el.get("locked")),
            favorite=_bool(note_el.get("favorite")),
            referred=note_el.get("referred", ""),
            tags=tags,
            rows=rows,
        )

    def _parse_block(self, el: ET.Element) -> Block:
        tag = el.tag
        block = Block(
            type=tag,
            id=el.get("id"),
            presentable=_bool(el.get("presentable", "true")),
            description=el.get("description"),
        )

        if tag == "markdown":
            block.text = (el.text or "").strip() or None

        elif tag == "math":
            block.text = (el.text or "").strip() or None

        elif tag == "uml":
            block.text = (el.text or "").strip() or None

        elif tag == "image":
            block.extra["uri"] = el.get("uri")

        elif tag == "assets":
            block.extra["assets"] = [
                {"id": a.get("id"), "path": a.get("path")} for a in el.findall("asset")
            ]

        elif tag == "flash":
            card = el.find("card")
            if card is not None:
                side1 = card.find("side1")
                side2 = card.find("side2")
                block.extra["side1"] = (side1.text or "").strip() if side1 is not None else None
                block.extra["side2"] = (side2.text or "").strip() if side2 is not None else None

        elif tag == "table":
            columns_el = el.find("columns")
            rows_el = el.find("rows")
            columns = []
            if columns_el is not None:
                columns = [
                    {"header": c.get("header"), "type": c.get("type"), "justify": c.get("justify")}
                    for c in columns_el.findall("column")
                ]
            table_rows = []
            if rows_el is not None:
                for r in rows_el.findall("row"):
                    table_rows.append([(c.text or "").strip() for c in r.findall("cell")])
            block.extra["columns"] = columns
            block.extra["rows"] = table_rows

        else:
            # Unknown/future block type: keep raw text so nothing is silently lost.
            block.text = (el.text or "").strip() or None

        return block

    @staticmethod
    def _note_matches(note: Note, query_lower: str) -> bool:
        if query_lower in (note.title or "").lower():
            return True
        if any(query_lower in tag.lower() for tag in note.tags):
            return True
        for row in note.rows:
            for block in row.blocks:
                if block.text and query_lower in block.text.lower():
                    return True
                if block.description and query_lower in block.description.lower():
                    return True
                if block.type == "flash":
                    for key in ("side1", "side2"):
                        val = block.extra.get(key)
                        if val and query_lower in val.lower():
                            return True
                if block.type == "table":
                    for row_cells in block.extra.get("rows", []):
                        if any(query_lower in (cell or "").lower() for cell in row_cells):
                            return True
                if block.type == "assets":
                    for asset in block.extra.get("assets", []):
                        if asset.get("path") and query_lower in asset["path"].lower():
                            return True
        return False
