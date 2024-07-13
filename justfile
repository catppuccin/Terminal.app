_default:
  @just --list

build:
  for file in `find iterm/colors/ -type f`; do ./convert.swift $file; done
