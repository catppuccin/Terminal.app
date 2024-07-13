_default:
  @just --list

build:
  for file in `find iterm/colors/ -type f`; do swift convert.swift $file; done
