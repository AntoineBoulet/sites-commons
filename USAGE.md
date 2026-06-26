# site-commons — Guide d'utilisation

Submodule partagé entre tous les repos de l'écosystème.
À inclure comme submodule Git sous `system/` dans chaque repo consommateur.

Voir `batch/submodule-system/`.

---

## Composition par type de repo

### Site personnel (en + fr)

Deux `_quarto.yml` séparés, un par langue.

```yaml
# _quarto.yml (version EN)
metadata-files:
  - system/fragments/default.yml
  - system/fragments/portfolio.yml
  - system/fragments/lang-en.yml
```

```yaml
# _quarto.yml (version FR)
metadata-files:
  - system/fragments/default.yml
  - system/fragments/portfolio.yml
  - system/fragments/lang-fr.yml
```

---

### Blog de recherche (en)

```yaml
metadata-files:
  - system/fragments/default.yml
  - system/fragments/notebook.yml
  - system/fragments/lang-en.yml

format:
  html:
    css:
      - system/styles/listing.css
```

---

### Blog pédagogique (fr)

```yaml
metadata-files:
  - system/fragments/default.yml
  - system/fragments/notebook.yml
  - system/fragments/lang-fr.yml

format:
  html:
    css:
      - system/styles/listing.css
```

---

### Site de cours (website)

```yaml
metadata-files:
  - system/fragments/default.yml
  - system/fragments/lang-fr.yml
  - system/fragments/pages.yml
```

---

### Book de cours (pdf + html)

```yaml
metadata-files:
  - system/fragments/default.yml
  - system/fragments/lang-fr.yml
  - system/fragments/notes.yml
  - system/fragments/latex-book.yml  # pour la sortie PDF uniquement
```

---

## Référence des fragments

| Fragment | Rôle |
|---|---|
| `default.yml` | Base commune (thème, MathJax, filtres) — toujours inclus |
| `lang-en.yml` | Langue EN, navbar EN, format de date |
| `lang-fr.yml` | Langue FR, navbar FR, format de date |
| `notebook.yml` | Style pour notebooks de recherche (STIX serif + titre sans-serif) |
| `notes.yml` | Style pour books de cours (STIX serif, sidebar dockée, Hypothesis) |
| `pages.yml` | Style pour pages statiques (identique à notes, sidebar dockée) |
| `latex-article.yml` | Format PDF article (LuaLaTeX, STIX, 11pt) |
| `latex-book.yml` | Format PDF book (LuaLaTeX, STIX, TOC) |
| `portfolio.yml` | Style pour le portfolio (MathJax Fira) |

## Référence des styles

| Fichier | Utilisé par |
|---|---|
| `base.css` | Importé automatiquement par notebook/notes/pages — ne pas inclure directement |
| `common-custom-theme.css` | Inclus via `default.yml` — toujours actif |
| `notebook.css` | Via `notebook.yml` |
| `notes.css` | Via `notes.yml` |
| `pages.css` | Via `pages.yml` |
| `listing.css` | À inclure manuellement dans les blogs |
| `about.css` | À inclure manuellement sur la page about |
| `404.css` | À inclure manuellement sur la page 404 |

## Référence des filtres

Inclus automatiquement via `default.yml` :

| Filtre | Rôle |
|---|---|
| `hint.lua` | Transforme `.indication` en bloc `<details>/<summary>` |
| `margin-html-figure.lua` | Figures SVG light/dark en marge, PDF en inline |

## Ordre des filtres

L'ordre dans `default.yml` est significatif — ne pas modifier :

```yaml
filters:
  - system/filters/margin-html-figure.lua
  - system/filters/hint.lua
```

---

## Mise à jour du submodule

Voir `batch/submodule-system/`.