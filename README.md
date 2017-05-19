# Gspöt - a stateful GUI lib for LÖVE

## What it does
- range of one-line GUI elements, with default functionality and utility functions
- callbacks for a wide variety of events
- element grouping and relative positioning
- cascading element styles
- timed element-level update functions
- richtext support (add images to your text, change colors and fonts per character)
- typetexter
- render to canvas to avoid performance loss

## Aims
- easily implemented GUI elements for games and menus
- flexibility
- visual consistency
- easily enhanceable, add new widgets and override functions

## Files
- lib\richtext.lua : required by Gspot
- lib\Gspot.lua : the lib's only required file for your project
- main.lua : commented demo
- conf.lua : LÖVE config for demo
- img.png : example image

## Cloning
usage:
> git clone git@github.com:SiENcE/Gspot.git --recurse-submodules

## Start the Sample
- checkout https://github.com/SiENcE/richtext and put into the lib/ folder to start the sample

## Notes
- Documentation is currently out of date, but demo code is commented, and should provide enough detail to get by. Wiki will be updates asap.

## Supported LOVE2D versions
- 0.8.0
- 0.9.2
- 0.10.+ needs smaller changes to textinput and other stuff

## license
Copyright (c) 2012 trubblegum

Bugfixed an enhanced with richtext library by (c) 2017 Florian Fischer


Gspot is free to use under the Zlib/libpng license.

Fragments attributed to vrld's Quickie : https://github.com/vrld/Quickie
