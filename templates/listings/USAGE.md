# Documentation des templates de listings

Ce document décrit les deux templates EJS utilisés pour les listings Quarto du site,
leur architecture, leurs points d'extension, et les procédures de maintenance courantes.

---

## Vue d'ensemble

| Template | Fichier | Usage principal |
|---|---|---|
| Accordéon simple | `accordion.ejs.html` | Highlights de recherche, FAQ, rubriques textuelles |
| Badges + boutons + accordéon | `badges-buttons-link-accordion.ejs.html` | Publications, thèses, cours, CV, conférences |

Les deux templates partagent la même convention de configuration via `template-params`
dans le front matter Quarto, et le même helper multilingue `t()`.

---

## 1. `accordion.ejs.html` — Accordéon simple

### Rôle

Affiche une liste d'items sous forme d'accordéon Bootstrap minimal.
Chaque item n'a qu'un en-tête (`header`) et un corps (`body`), tous deux multilingues.
Le rendu est volontairement restreint au gras, à l'italique et aux paragraphes.
Pour un rendu plus riche, voir `badges-buttons-link-accordion.ejs.html`.

### Configuration dans le front matter

```yaml
listing:
  - id: research-highlights
    template: ../../system/templates/listings/accordion.ejs.html
    contents: ../../data/research/highlights.yml
    template-params:
      lang: en          # "en" ou "fr"
      id: research-highlights   # optionnel — voir note ci-dessous
```

**Paramètre `id` (template-params)** : si plusieurs listings de ce template
cohabitent sur une même page, chacun doit recevoir un `id` distinct pour éviter
des conflits d'identifiants Bootstrap (`data-bs-parent`, `aria-controls`…).
Par défaut, l'accordéon utilise l'identifiant `"accordion"`.

### Structure YAML attendue

```yaml
# data/research/highlights.yml
- id: mon-item          # requis — sert à construire les id HTML
  header:
    en: "Titre en anglais"
    fr: "Titre en français"
  body:
    en: |
      Paragraphe 1 en anglais.

      Paragraphe 2 (ligne vide = nouveau paragraphe).
    fr: |
      Paragraphe 1 en français.
```

Le champ `id` de chaque item est **obligatoire** : son absence produit des
identifiants HTML de la forme `heading-accordion-undefined`, ce qui casse
le comportement Bootstrap si plusieurs items sont dans cet état.

### Balisage Markdown supporté

Le template implémente un sous-ensemble intentionnellement réduit de Markdown :

| Syntaxe | Rendu |
|---|---|
| `**texte**` | `<strong>texte</strong>` |
| `*texte*` | `<em>texte</em>` |
| Ligne vide entre deux blocs | Nouveau `<p>` |

Les listes, liens, titres et tout autre balisage Markdown **ne sont pas supportés**.
Pour ces besoins, utiliser `badges-buttons-link-accordion.ejs.html` ou un template dédié.

### Helpers internes

| Fonction | Rôle |
|---|---|
| `t(field)` | Résout un champ `{ en, fr }` selon `LANG` |
| `escapeHtml(str)` | Échappe `&`, `<`, `>` avant insertion HTML |
| `mdInline(text)` | Applique gras/italique sur texte déjà échappé |
| `mdBlock(text)` | Découpe en paragraphes et applique `mdInline` |

---

## 2. `badges-buttons-link-accordion.ejs.html` — Badges, boutons, lien, accordéon

### Rôle

Template générique à types multiples. Un seul fichier gère les publications,
thèses, cours, formations, expériences, conférences et séminaires via
un système de **type mappers** : chaque type transforme un item YAML
en un objet normalisé que le rendu HTML consomme de façon uniforme.

### Configuration dans le front matter

```yaml
listing:
  - id: articles
    template: ../../system/templates/listings/badges-buttons-link-accordion.ejs.html
    contents: ../../data/research/articles.yml
    template-params:
      type: article     # voir tableau des types ci-dessous
      lang: en          # "en" ou "fr"
```

Un fichier de contenu YAML = un seul type + une seule langue.
Ces deux valeurs sont déclarées une fois au niveau de la page,
pas dans chaque item.

### Types disponibles

| Valeur de `type` | Alias acceptés | Fichiers de données associés |
|---|---|---|
| `article` | — | `data/research/articles.yml`, `data/research/selected.yml` |
| `thesis` | — | `data/research/thesis.yml` |
| `hpc` | — | `data/research/hpc.yml` |
| `course` | `cours` | `data/teaching/*.yml` |
| `education` | — | `data/cv/education.yml` |
| `experience` | — | `data/cv/experience.yml` |
| `talks` | `conference`, `seminar` | `data/research/conferences.yml`, `data/research/seminars.yml` |

Les alias sont résolus par la table `ALIAS_TYPES` en tête de template.
Pour ajouter un alias : `ALIAS_TYPES["mon-alias"] = "type-existant"`.

### Structure YAML par type

#### `article`

```yaml
- id: Auteur2025a
  title: "Titre de l'article"
  author:
    - A. Auteur
    - B. Co-auteur
  journal: "Nom du journal"
  abbreviation: "Abrév."
  volume: 18
  pages: "001"
  year: 2025
  doi: "10.xxxxx/xxxxxx"
  arxiv: "2402.12345"
  abstract: |
    Texte du résumé.
```

Champs requis : `id`, `title`, `author`, `journal`, `abbreviation`, `volume`,
`pages`, `year`, `doi`, `arxiv`, `abstract`.

#### `thesis`

```yaml
- id: NomPhD2019
  abbreviation: PhD
  title: "Titre de la thèse"
  author:
    - A. Auteur
  school: "Université"
  year: 2019
  nnt: 2019XXXX0000       # identifiant theses.fr
  hal: "tel-00000000"     # identifiant HAL — reconstruit les URLs PDF et HAL
  abstract: |
    Texte du résumé.
```

Les champs `pdf` et `url` présents dans certains fichiers YAML existants
**ne sont pas lus** par ce mapper : les liens sont reconstruits automatiquement
à partir de `hal`.

#### `hpc`

```yaml
- id: mon-code
  title: "Nom du code"
  author:
    - A. Auteur
  language:
    - C
    - Python           # scalaire ou liste
  period:
    start: 2020
    end: present       # ou une année
  links:
    website: https://…
    repository: https://…
    documentation: https://…
  description: |
    Description du code.
```

Les champs `license` et `status` sont présents dans le YAML mais ignorés
par le mapper (aucun affichage associé).

#### `course`

```yaml
- id: MON-COURS
  promotion: "Nom de la promotion"
  course-title:
    en: "Course title"
    fr: "Titre du cours"
  years:
    - 2024
    - 2025
  teaching:
    lecture:
      hours: 21
    tutorials:
      hours: 14
    laboratory:
      hours: 7          # optionnel
    project: true       # optionnel — présence du badge "Projet"
  materials: https://…  # optionnel — génère un bouton "Supports de cours"
  course-description:
    en: |
      Description in English.
    fr: |
      Description en français.
```

Le total d'heures affiché est calculé automatiquement en sommant tous
les `hours` présents dans `teaching`. Le champ `approximate: true`
(présent dans certains fichiers) n'a aucun effet visuel.

#### `education`

```yaml
- id: PhD
  degree:
    en: "PhD in physics"
    fr: "Doctorat en physique"
  focus:                 # optionnel
    en: "nuclear structure"
    fr: "structure nucléaire"
  period:
    start: 2016
    end: 2019
  institution:
    en: "University Name, Country"
    fr: "Nom de l'université, Pays"
  details:               # optionnel — contenu de l'accordéon
    en: "…"
    fr: "…"
```

#### `experience`

```yaml
- id: MON-POSTE
  position:
    en: "Position title"
    fr: "Intitulé du poste"
  period:
    start: 2022
    end: present
  location:
    en: "Institution, Country"
    fr: "Institution, Pays"
  details:               # optionnel — contenu de l'accordéon
    en: "…"
    fr: "…"
```

#### `talks` (alias : `conference`, `seminar`)

```yaml
- id: CONF2024
  title: "Titre de la présentation"
  subtitle: "Sous-titre"   # optionnel — affiché entre parenthèses
  year: 2024
  event: "Nom de l'événement"
  location: "Lieu, Pays"
```

Ce type est intentionnellement minimal : pas de boutons, lien externe,
accordéon ni BibTeX.

---

## Architecture commune

### Objet normalisé retourné par les mappers

Chaque mapper retourne un sous-ensemble des clés suivantes.
Toutes sont optionnelles : le rendu HTML applique des valeurs de repli (`null`, `[]`).

| Clé | Type | Description |
|---|---|---|
| `badges` | `string[]` | Étiquettes affichées dans la colonne de gauche |
| `prebadge` | `string` | Texte avant les badges |
| `postbadge` | `string` | Texte après les badges (ex. année) |
| `pretitle` | `string` | Texte avant le titre |
| `title` | `string` | Titre principal (gras) |
| `posttitle` | `string` | Ligne de méta-données sous le titre |
| `buttons` | `{text, icon, link}[]` | Boutons d'action |
| `external` | `{link, pretext, text}` | Lien externe (DOI, NNT…) |
| `information` | `string` | Texte informatif (promotion pour les cours) |
| `description` | `{title, content}` | Contenu de l'accordéon |
| `bibtex` | `string` | Entrée BibTeX (article et thèse uniquement) |
| `tags` | `string` | Réservé, non utilisé actuellement |

### Helpers partagés

| Fonction | Rôle |
|---|---|
| `t(field)` | Résout `{ en, fr }` selon `LANG` |
| `toArray(v)` | Garantit un tableau (enveloppe un scalaire) |
| `toAuthorArray(a)` | Normalise auteurs liste YAML ou chaîne `"A, B and C"` |
| `displayAuthors(a)` | Rendu `"A, B and C"` |
| `bibtexAuthors(a)` | Rendu `"A and B and C"` pour le champ BibTeX `author` |
| `makeBibtex(type, id, fields)` | Construit une entrée BibTeX |
| `formatRange(input)` | Formate une plage `start–end` ou un tableau d'années |
| `simplifyUrl(url)` | Supprime le protocole (`https://`) pour affichage compact |
| `makePreview(html, maxLen)` | Tronque un extrait HTML pour l'aperçu d'accordéon |

### Presets de boutons (`BTN`)

Les factories centralisées dans l'objet `BTN` contrôlent icônes et URLs.
Pour modifier une icône ou une base d'URL, **un seul endroit à éditer**.

| Clé | Icône | URL construite |
|---|---|---|
| `BTN.pdf(arxiv)` | `bi-file-earmark-pdf` | `https://arxiv.org/pdf/{arxiv}` |
| `BTN.arxiv(arxiv)` | `ai-arxiv` | `https://arxiv.org/abs/{arxiv}` |
| `BTN.hal(hal)` | `bi-file-earmark-pdf` | `https://theses.hal.science/{hal}/document` |
| `BTN.halAbs(hal)` | `ai-hal` | `https://theses.hal.science/{hal}` |
| `BTN.url(href)` | `bi-box-arrow-up-right` | `href` |
| `BTN.code(link)` | `bi-code-slash` | `link` |
| `BTN.book(text, link)` | `bi-book-half` | `link` |

### Chaînes d'interface (`STRINGS`)

Tous les libellés UI (badges de type de cours, labels de boutons, textes de copie…)
sont regroupés dans l'objet `STRINGS` en tête du template.
Pour ajouter une langue, ajouter un bloc `xx: { … }` en reproduisant
la même structure que `en` ou `fr`.

---

## Procédures de maintenance

### Ajouter un nouveau type

1. Créer un fichier YAML de données dans le dossier approprié (`data/…`).
2. Définir un nouveau mapper dans `TYPE_MAPPERS` :
   ```js
   montype(item) {
     return {
       badges:    […],
       title:     item.title,
       posttitle: …,
       // autres clés selon besoin
     };
   }
   ```
3. Si le type est un alias d'un mapper existant, l'ajouter dans `ALIAS_TYPES` :
   ```js
   const ALIAS_TYPES = {
     …
     "mon-alias": "type-existant",
   };
   ```
4. Déclarer `type: montype` dans `template-params` du listing Quarto.

### Ajouter une langue

Dans `badges-buttons-link-accordion.ejs.html`, dupliquer le bloc `en` de `STRINGS`
avec le nouveau code de langue et traduire les valeurs.
Le helper `t()` supporte immédiatement tout nouveau code de langue
dès lors qu'il est renseigné dans les champs YAML `{ en, fr, xx }`.

### Ajouter un bouton preset

Dans l'objet `BTN`, ajouter une factory :
```js
monbouton: (param) => ({ text: "label", icon: "bi bi-…", link: `https://…${param}` }),
```
Puis l'appeler dans le mapper concerné : `BTN.monbouton(item.monchamp)`.

### Modifier une URL de base (arXiv, HAL…)

Éditer uniquement la factory correspondante dans `BTN`.
Tous les items de tous les types utilisant ce bouton sont mis à jour automatiquement.

### Fichiers de données dupliqués

Certains fichiers (`data/research/selected.yml`, `data/teaching/selected.yml`)
sont des **sous-ensembles copiés manuellement** d'un autre fichier.
Toute correction (faute de frappe, champ manquant…) doit être répercutée
dans les deux fichiers. Ces fichiers ne sont pas filtrés automatiquement
depuis la source principale.

---

## Points de vigilance

- **Champ `id` obligatoire dans chaque item** : son absence produit des identifiants
  HTML dupliqués ou `undefined`, ce qui casse les comportements Bootstrap
  (accordéon, ARIA). Toujours renseigner `id` dans le YAML.

- **Plusieurs listings du même template sur une page** : utiliser `template-params.id`
  pour donner à chaque accordéon un identifiant de groupe distinct
  (`data-bs-parent`).

- **Script BibTeX idempotent** : le bloc `<script>` de copie BibTeX est injecté
  une fois par listing. Il utilise `dataset.bound` pour éviter les handlers
  dupliqués quand plusieurs listings cohabitent sur la même page.

- **Champ `teaching.project`** dans les cours : c'est un booléen (`true`/`false`),
  pas un objet avec `hours`. Le badge "Projet" est affiché si `project` est truthy,
  mais il ne contribue pas au total d'heures (pas de champ `hours` à sommer).

- **`makePreview` dans l'accordéon** : la longueur de troncature par défaut est
  140 caractères visibles (hors balises). Pour ajuster globalement : modifier
  la valeur par défaut du paramètre `maxLen` dans la définition de la fonction.