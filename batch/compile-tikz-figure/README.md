# TikZ Figure Compilation (Light/Dark, Colorblind-Safe)

Compiles a bare TikZ figure into three deliverables — a light SVG, a dark SVG,
and a PDF — using two fixed preambles that apply a colorblind-safe palette
(Okabe-Ito), adapted separately for light and dark backgrounds.

## Project structure

```
project-root/
├── compile-tikz-figure.bat
├── system/
│   └── latex/
│       ├── tikz-light.tex      <- preamble + light palette
│       └── tikz-dark.tex       <- preamble + dark palette
└── any-subfolder/
    └── your-figure.tex         <- bare tikzpicture, no preamble
```

Figures can live in any subfolder, at any depth, relative to the project
root. The preambles are always read from `system\latex\`, regardless of
where the figure is located.

## Usage

Run from the project root:

```cmd
.\compile-tikz-figure.bat path\to\figure.tex
```

Example:

```cmd
.\compile-tikz-figure.bat figures\chapter2\diagram.tex
```

This produces, next to the source file:

| File                  | Content                                   |
|-----------------------|--------------------------------------------|
| `diagram-light.svg`   | Light-mode SVG (colorblind-safe palette)    |
| `diagram-dark.svg`    | Dark-mode SVG (colorblind-safe palette)     |
| `diagram.pdf`         | PDF, light variant                         |

All intermediate files (`_tmp-*.tex`, `.aux`, `.log`, intermediate `.pdf`)
are cleaned up automatically.

## Writing a figure file

The `.tex` file must contain **only** a `tikzpicture` environment — no
`\documentclass`, no `\begin{document}`. The script wraps it automatically
with the right preamble at compile time.

```latex
\begin{tikzpicture}
  \draw[thick, ->] (0,0) -- (2,0) node[right] {$x$};
  \draw[thick, ->] (0,0) -- (0,2) node[above] {$y$};
\end{tikzpicture}
```

## Color palette

Both preambles define the same semantic color names; only the underlying
values differ between light and dark mode. Use the semantic names in your
figures — never the raw `ok*` colors directly — so a figure automatically
looks correct in both modes:

| Semantic name | Role                  | Light value (RGB)   | Dark value (RGB)     |
|---------------|------------------------|----------------------|------------------------|
| `figDefault`  | Default strokes/text  | black (0,0,0)        | white (255,255,255)   |
| `figA`        | Accent — orange        | 230,159,0            | 255,176,46            |
| `figB`        | Accent — sky blue       | 86,180,233           | 120,200,245           |
| `figC`        | Accent — green          | 0,158,115            | 49,196,150            |
| `figD`        | Accent — vermillion     | 213,94,0             | 255,140,80            |

These are based on the Okabe-Ito colorblind-safe palette. The dark-mode
values are not a mechanical inversion of the light ones — they are chosen
by hand to stay distinguishable and well-contrasted against a dark
background while preserving the same color-blindness safety.

Example with color:

```latex
\begin{tikzpicture}
  \draw[thick, ->, color=figA] (0,0) -- (2,0) node[right] {$x$};
  \draw[thick, ->, color=figB] (0,0) -- (0,2) node[above] {$y$};
  \fill[figC] (1,1) circle (0.3);
\end{tikzpicture}
```

## Displaying the right SVG in Quarto

Quarto does not know about light/dark figure variants on its own. To switch
between `*-light.svg` and `*-dark.svg` automatically based on the active
site theme, add a small JavaScript snippet that swaps each image's `src`
depending on whether `<body>` has the `quarto-light` or `quarto-dark`
class, and include it via `include-after-body` in `_quarto.yml`.

## Requirements

- [TeX Live](https://www.tug.org/texlive/) (or equivalent) with `lualatex`
  available on the `PATH`
- `pdftocairo` (part of Poppler) available on the `PATH`
- The `STIX Two Text` / `STIX Two Math` fonts installed, or edit
  `system\latex\tikz-light.tex` / `tikz-dark.tex` to use different fonts

## Notes

- Run the script from the project root; the path you pass is relative to
  the root, e.g. `figures\fig1.tex`.
- The PDF output (`<name>.pdf`) is always generated from the **light**
  variant.
- If you add new semantic colors, define them identically (same names) in
  both `tikz-light.tex` and `tikz-dark.tex`, with appropriate values for
  each background.
