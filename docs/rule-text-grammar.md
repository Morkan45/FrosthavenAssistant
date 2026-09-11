# Rule-text grammar supported by the Frosthaven renderer

The renderer accepts plain text interleaved with `%token%` ability markers.
`[r]`/`[/r]`, `[s]`/`[/s]`, `[c]`, `[newLine]`, and `^`/`^^` prefixes are
layout markers used by Frosthaven card data. Markers may be incomplete in
external or legacy data: conversion treats missing neighbours as plain layout
input and must not throw.

`test/resource/line_builder/rule_text_corpus_test.dart` validates every string
in packaged JSON data through the conversion path. Its diagnostics include the
source JSON file and failing value. This is a grammar/robustness validator; it
does not assert visual line breaks or replace the legacy renderer yet.
