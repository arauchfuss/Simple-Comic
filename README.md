# Simple Comic
Simple Comic is a streamlined comic viewer for macOS. This is a fork from the [original version](https://github.com/arauchfuss/Simple-Comic) since the maintainer of that has gone away.

The basic feature drive is to reduce the number of interactions required to browse a comic.

Quick Comic is a bundled quicklook preview and thumbnail generation plugin for cbr and cbz files.

## Live Text support

Simple Comic uses Apple's Optical Character Recognition, on Apple Silicon Macintoshes, to make text in comics selectable for copying and text-to-speech.

* The mouse cursor changes from the Arrow to the I-Beam when over selectable text.
* Click-and-drag to select live text. Recognized words within the dragged out rectangle are selected.
* **Copy**, **Select All**, and **Speak**, on the **Edit** menu work.
* Control-click on selected text for a contextual menu with **Copy** and **Speak**
* ⌘-click-and-drag to add a new selection rectangle to the existing selection.
* Two page spreads, rotations, page ordering, and zooming all work as expected.

## Privacy

We don't collect any user data in the app itself. We know nothing about you and are happy with that.

GitHub collects data when you interact with the project here, but we can't change any of that.

## Build Instructions

For this to build you need to get the submodules. For that you need to run the following commands.

```
git submodule init
git submodule sync --recursive
git submodule update --init --recursive
```
