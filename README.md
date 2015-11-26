# alfred2-workflow-safari-bookmark

Alfred 2 Workflow to manage safari bookmark (delete / edit)

# Installation

You may need to install the gem (sorry...)
Right-click on the worflow, show in finder.
In Terminal, drag and drop the folder to `cd` to it.
`gem install CFPropertyList`

# Usage

find a bookmark, go to file action, select `Rename Bookmark` or `Delete Bookmark`

# How it's done?

A bit sloppyly...

Couldn't find a good doc to do it via iCloud directly. (and didn't really search for it).

Alfred App find bookmark by because of their cache version in the user folder: ~/Library/Caches/Metadata/Safari/Bookmarks

Each file is name with a unique id.

Editing / deleting this file is not enough, it's just a cache.. Bookmark will reappear or be re-edited by Safari.

Another file maintain a more permanent version of the bookmarks: ~/Library/Safari/Bookmarks.plist

Steps:
  - find the bookmark uuid (the cache file name, passed by alfred)
  - find the matching entry in the plist and edit it / delete it (also add entry for iCloud -- see code)
  - repeat the action on the cache file
  

