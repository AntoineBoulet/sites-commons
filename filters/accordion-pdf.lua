--[[
accordion-pdf.lua

PROBLÈME RÉSOLU
----------------
Les "Custom Listings" de Quarto (listing: + template: *.ejs.html + contents: *.yml)
ne sont traités QUE pour les sorties HTML/site web. Pandoc/Quarto n'exécute jamais
le moteur EJS pour les formats PDF/LaTeX : le div d'ancrage du listing
(ex. ::: {#research-highlights}) reste donc vide dans le PDF.

Ce filtre détecte ces divs d'ancrage (via leur id) en sortie PDF/LaTeX et les
remplace par du contenu Pandoc généré directement depuis le(s) même(s)
fichier(s) YAML, avec une logique de rendu équivalente à celle du template
accordion.ejs.html (champs multilingues {en, fr}, gras/italique simples,
paragraphes).

En HTML, ce filtre ne fait RIEN : le système de listing natif de Quarto
continue de fonctionner normalement.

CONFIGURATION (dans le YAML de la page, ou dans _quarto.yml)
--------------------------------------------------------------
accordion-pdf:
  - id: research-highlights        # id du div d'ancrage du listing (cf. ::: {#research-highlights})
    yaml: data/research/highlights.yml   # chemin relatif au fichier .qmd
    lang: fr                       # langue à utiliser (en/fr), défaut "en"

Vous pouvez répertorier ici toutes vos pages utilisant ce pattern de listing
(3 à 10 pages dans votre cas) ; chaque entrée est traitée indépendamment.

ACTIVATION
----------
Dans le qmd ou _quarto.yml :

filters:
  - accordion-pdf

--]]

-- ============================================================
-- Helpers
-- ============================================================

-- Résout un chemin relatif au fichier .qmd en cours de rendu (et non au
-- répertoire d'exécution de Quarto), pour être cohérent avec la façon dont
-- `contents:` est résolu dans un listing classique.
local function resolve_path(path)
    if pandoc.path.is_absolute(path) then
        return path
    end
    local input_file = quarto.doc.input_file
    if not input_file then
        return path
    end
    local dir = pandoc.path.directory(input_file)
    return pandoc.path.join({ dir, path })
end

-- Lit un fichier YAML "à la main" en passant par pandoc.read, qui sait déjà
-- parser le YAML (c'est ce qu'il fait pour les en-têtes de document).
-- On enveloppe le contenu du fichier dans un bloc de métadonnées markdown
-- factice, puis on récupère le Meta résultant.
local function read_yaml_file(path)
    local resolved = resolve_path(path)
    local fh = io.open(resolved, "r")
    if not fh then
        quarto.log.output("accordion-pdf: impossible d'ouvrir " .. resolved)
        return nil
    end
    local content = fh:read("*a")
    fh:close()

    -- Le fichier highlights.yml est une LISTE au premier niveau (- id: ...),
    -- alors qu'un bloc de métadonnées Pandoc attend une MAP au premier niveau.
    -- On l'enveloppe donc sous une clé "items", en ajoutant une indentation
    -- fixe de 2 espaces à CHAQUE ligne (y compris les lignes vides, qu'on
    -- NE DOIT PAS supprimer : elles séparent les paragraphes à l'intérieur
    -- des blocs scalaires `body: |`).
    --
    -- IMPORTANT : on ne réindente jamais le contenu existant, on se contente
    -- d'ajouter un préfixe constant devant chaque ligne. L'indentation
    -- relative du fichier d'origine (cruciale pour les listes imbriquées
    -- sous une entrée de référence, ex. "  - **Langue :** ...") doit rester
    -- inchangée, sinon YAML perd la structure de liste.
    local indented_lines = {}
    -- On découpe sur \n en conservant les lignes vides (gmatch("[^\n]*")
    -- saute les lignes vides ; on utilise donc une boucle manuelle).
    local pos = 1
    local len = #content
    while pos <= len do
        local nl = content:find("\n", pos)
        local line
        if nl then
            line = content:sub(pos, nl - 1)
            pos = nl + 1
        else
            line = content:sub(pos)
            pos = len + 1
        end
        table.insert(indented_lines, "  " .. line)
    end

    local wrapped = "---\nitems:\n" .. table.concat(indented_lines, "\n") .. "\n---\n"

    local doc = pandoc.read(wrapped, "markdown")
    return doc.meta.items
end

-- Vos fichiers de données n'ont PAS de structure multilingue {en, fr} :
-- header et body sont des champs plats (header: "texte", body: "texte").
-- On garde quand même la résolution de langue par sécurité (si jamais
-- certains fichiers ont {en, fr} et d'autres non), mais le cas simple
-- (un seul champ texte) est maintenant le chemin principal.
local function resolve_lang(meta_value, lang)
    if meta_value == nil then return nil end

    -- Cas {en, fr} : seulement si meta_value est une MetaMap qui a CES clés
    -- (et pas, par exemple, un Inlines qui contiendrait accidentellement
    -- un champ nommé pareil après parsing markdown).
    if pandoc.utils.type(meta_value) == "table" and (meta_value.en ~= nil or meta_value.fr ~= nil) then
        return meta_value[lang] or meta_value.en or meta_value.fr
    end

    -- Cas plat (le vôtre) : on renvoie directement le champ déjà parsé.
    return meta_value
end

-- Convertit un MetaValue (MetaInlines/MetaBlocks/MetaString) déjà parsé par
-- Pandoc en une liste de Blocks utilisables dans le corps du document.
-- - MetaBlocks (plusieurs paragraphes séparés par une ligne vide dans le
--   YAML) -> renvoyé tel quel.
-- - MetaInlines (une seule "ligne" de markdown, le cas le plus fréquent
--   pour un champ "header" ou un "body" court) -> enveloppé dans un Para.
local function meta_to_blocks(meta_value)
    if meta_value == nil then return {} end

    -- MetaBlocks : déjà une liste de blocks (Para, etc.)
    if pandoc.utils.type(meta_value) == "Blocks" then
        return meta_value
    end

    -- MetaInlines : une liste d'inlines -> un seul paragraphe
    if pandoc.utils.type(meta_value) == "Inlines" then
        return { pandoc.Para(meta_value) }
    end

    -- Repli : on stringifie (perd le formatage, mais ne casse jamais le build)
    return { pandoc.Para({ pandoc.Str(pandoc.utils.stringify(meta_value)) }) }
end

-- Extrait les Inlines d'un MetaValue déjà parsé, pour les cas où l'on veut
-- les insérer dans un Para existant (ex: le header en gras).
local function meta_to_inlines(meta_value)
    if meta_value == nil then return {} end

    if pandoc.utils.type(meta_value) == "Inlines" then
        return meta_value
    end

    if pandoc.utils.type(meta_value) == "Blocks" then
        return pandoc.utils.blocks_to_inlines(meta_value)
    end

    return { pandoc.Str(pandoc.utils.stringify(meta_value)) }
end

-- ============================================================
-- Construction du contenu de remplacement pour un item d'accordéon
-- ============================================================

local function build_item_blocks(item, lang)
    local blocks = {}

    local header_meta = resolve_lang(item.header, lang)
    local body_meta = resolve_lang(item.body, lang)

    if header_meta then
        -- En PDF il n'y a pas de notion d'accordéon interactif : on rend
        -- chaque entrée comme un sous-titre en gras suivi de son contenu,
        -- ce qui correspond à l'esprit du rendu "header" + "body" de l'EJS.
        -- On enveloppe les inlines déjà parsés (donc *italique* à l'intérieur
        -- du header reste correctement *italique*, en plus du gras global).
        table.insert(blocks, pandoc.Para({ pandoc.Strong(meta_to_inlines(header_meta)) }))
    end

    if body_meta then
        local body_blocks = meta_to_blocks(body_meta)
        for _, b in ipairs(body_blocks) do
            table.insert(blocks, b)
        end
    end

    return blocks
end

-- ============================================================
-- Filtre principal : ne s'applique qu'en sortie PDF/LaTeX
-- ============================================================

local function get_fallback_config()
    local meta_value = quarto.metadata.get("accordion-pdf")
    if meta_value == nil then return {} end

    local config = {}
    for _, entry in ipairs(meta_value) do
        table.insert(config, {
            id = pandoc.utils.stringify(entry.id),
            yaml = pandoc.utils.stringify(entry.yaml),
            lang = entry.lang and pandoc.utils.stringify(entry.lang) or "en",
        })
    end
    return config
end

function Pandoc(doc)
    quarto.log.output("[accordion-pdf] format pdf? " .. tostring(quarto.doc.is_format("pdf")))

    -- On laisse le HTML/le site web intact : le moteur de listing natif
    -- s'en occupe très bien.
    if not quarto.doc.is_format("pdf") then
        return doc
    end

    local config = get_fallback_config()
    quarto.log.output("[accordion-pdf] nombre d'entrées de config trouvées: " .. tostring(#config))
    for _, entry in ipairs(config) do
        quarto.log.output("[accordion-pdf]   - id=" ..
            entry.id .. " yaml=" .. entry.yaml .. " lang=" .. entry.lang)
    end

    if #config == 0 then
        quarto.log.output(
            "[accordion-pdf] AUCUNE config 'accordion-pdf' trouvée dans les métadonnées. Vérifiez le frontmatter du .qmd.")
        return doc
    end

    -- Index des configs par id de div pour un accès rapide.
    local config_by_id = {}
    for _, entry in ipairs(config) do
        config_by_id[entry.id] = entry
    end

    local divs_seen = {}
    local divs_matched = 0

    doc.blocks = doc.blocks:walk({
        Div = function(div)
            table.insert(divs_seen, div.identifier ~= "" and div.identifier or "(sans id)")

            local entry = config_by_id[div.identifier]
            if not entry then return nil end

            divs_matched = divs_matched + 1
            quarto.log.output("[accordion-pdf] div trouvée et matchée: id=" .. div.identifier)

            local resolved_path = resolve_path(entry.yaml)
            quarto.log.output("[accordion-pdf] chemin yaml résolu: " .. resolved_path)

            local items_meta = read_yaml_file(entry.yaml)
            if not items_meta then
                quarto.log.output(
                    "[accordion-pdf] ERREUR: YAML introuvable ou vide pour l'id '" ..
                    entry.id .. "' (chemin résolu: " .. resolved_path .. ")"
                )
                return nil
            end

            quarto.log.output("[accordion-pdf] nombre d'items lus dans le yaml: " .. tostring(#items_meta))

            local new_blocks = pandoc.List({})
            for _, item in ipairs(items_meta) do
                local item_blocks = build_item_blocks(item, entry.lang)
                for _, b in ipairs(item_blocks) do
                    new_blocks:insert(b)
                end
                -- Petit séparateur visuel entre deux entrées du "accordéon" PDF.
                new_blocks:insert(pandoc.HorizontalRule())
            end

            -- On retire la dernière ligne de séparation superflue.
            if #new_blocks > 0 and new_blocks[#new_blocks].t == "HorizontalRule" then
                new_blocks:remove(#new_blocks)
            end

            quarto.log.output("[accordion-pdf] nombre de blocks générés: " .. tostring(#new_blocks))

            div.content = new_blocks
            return div
        end
    })

    quarto.log.output("[accordion-pdf] divs vues dans le document: " .. table.concat(divs_seen, ", "))
    quarto.log.output("[accordion-pdf] divs matchées par la config: " .. tostring(divs_matched))

    return doc
end
