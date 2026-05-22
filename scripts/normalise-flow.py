#!/usr/bin/env python3
"""
Normalise a Flow XML file for diffing:
  - Strip <locationX> and <locationY> (canvas positions, cosmetic)
  - Strip <status> (runtime activation state, not source)
  - Strip <styleProperties> (cosmetic layout, not logic)
  - Sort top-level named elements by tag+name for stable ordering
"""
import sys
import re
from xml.etree import ElementTree as ET

STRIP_TAGS = {"locationX", "locationY", "status", "styleProperties"}

SORTABLE_TAGS = {
    "actionCalls", "assignments", "choices", "collectionProcessors",
    "constants", "customErrors", "decisions", "dynamicChoiceSets",
    "loops", "orchestratedStages", "recordCreates", "recordDeletes",
    "recordLookups", "recordUpdates", "screens", "subflows",
    "transforms", "variables", "waits",
}

NS = "http://soap.sforce.com/2006/04/metadata"


def local(tag):
    """Strip namespace prefix from a tag."""
    return tag.replace(f"{{{NS}}}", "")


def element_sort_key(el):
    name_el = el.find(f"{{{NS}}}name")
    name = name_el.text if name_el is not None else ""
    return (local(el.tag), name)


def strip_and_sort(el):
    # Remove direct children whose local tag is in STRIP_TAGS
    to_remove = [c for c in list(el) if local(c.tag) in STRIP_TAGS]
    for child in to_remove:
        el.remove(child)

    # Recurse into remaining children
    for child in list(el):
        strip_and_sort(child)

    # Sort sortable direct children by tag+name
    sortable = [c for c in list(el) if local(c.tag) in SORTABLE_TAGS]
    if sortable:
        non_sortable = [c for c in list(el) if local(c.tag) not in SORTABLE_TAGS]
        el[:] = non_sortable + sorted(sortable, key=element_sort_key)


def normalise(path):
    ET.register_namespace("", NS)
    tree = ET.parse(path)
    root = tree.getroot()
    strip_and_sort(root)
    ET.indent(tree, space="    ")
    ET.dump(root)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <flow-meta.xml>", file=sys.stderr)
        sys.exit(1)
    normalise(sys.argv[1])
