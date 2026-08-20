# datastar-docs-mirror

Local *.md mirror of [data-star.dev](https://data-star.dev)'s `guide`,
`reference`, `examples`, and `how_tos` content, for offline/greppable
reference.

## Why

[data-star.dev](https://data-star.dev) publishes an aggregated export at https://data-star.dev/docs.md
for LLMs to consume. It's incomplete (checked 2026-08-20): covers `guide/`
fully, only 2 of 6 `reference/` pages, no `examples/` or `how_tos/` at all.
Might improve later, but until then, scrape it yourself.

## Requirements

### Nix users

```bash
direnv allow   # or: nix develop
```

### Non-Nix users

Need Python 3 and [`uv`](https://docs.astral.sh/uv/) installed.

```bash
uv venv
source .venv/bin/activate
uv pip install trafilatura
```

## Run

```bash
./mirror-datastar-docs.sh [output-dir]
```

Example:

```bash
./mirror-datastar-docs.sh
Fetching sitemap...
Found 58 URLs. Converting to Markdown in ./data-star-docs ...
[1/58] https://data-star.dev/guide/getting_started
[2/58] https://data-star.dev/guide/reactive_signals
[3/58] https://data-star.dev/guide/datastar_expressions
[4/58] https://data-star.dev/guide/backend_requests
[5/58] https://data-star.dev/guide/the_tao_of_datastar
[6/58] https://data-star.dev/reference/attributes
...
[56/58] https://data-star.dev/examples/rocket_qr_code
[57/58] https://data-star.dev/examples/rocket_starfield
[58/58] https://data-star.dev/examples/rocket_virtual_scroll
Done. 58 markdown files written to ./data-star-docs (0 failed)
```

## How [`mirror-datastar-docs.sh`](./mirror-datastar-docs.sh) works

Sitemap → filter to `guide/reference/examples/how_tos` → per URL: `curl` the
page, extract via trafilatura's `extract()` API (not the CLI — its stdout
silently no-ops when redirected to a file; `-i` is documented as "batch
processing," no `--output-file` flag, only `--output-dir`), write
`<output-dir>/<url-path>.md`.

`trafilatura`'s own downloader (`-u`) fails against this site for unclear
reasons; plain `curl` never does — hence curl-then-extract instead of
letting trafilatura fetch.

## License

[MIT](./LICENSE)
