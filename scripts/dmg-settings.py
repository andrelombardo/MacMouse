from pathlib import Path

root = Path.cwd()  # package.sh always runs from the repository root.
files = [str(root / "build/MacMouse.app")]
symlinks = {"Applications": "/Applications"}
format = "UDZO"
filesystem = "HFS+"
background = str(root / "build/dmg-background.png")
window_rect = ((200, 180), (560, 420))
icon_locations = {"MacMouse.app": (140, 130), "Applications": (420, 130)}
icon_size = 96
text_size = 13
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
default_view = "icon-view"
include_icon_view_settings = True
include_list_view_settings = False
arrange_by = None
hide_extensions = ["MacMouse.app"]
