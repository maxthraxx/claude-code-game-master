# DM Claude

**Step inside your favorite books and live the story.**

Import any novel, adventure module, or world guide — DM Claude extracts the characters, locations, plots, and lore, then lets you explore that world as a living, breathing participant. Your choices matter. NPCs remember you. The story adapts.

---

## What Is This?

DM Claude is an AI Dungeon Master built on [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Drop in a PDF of your favorite fantasy novel, a homebrew campaign setting, or a classic adventure module, and the system extracts everything — characters, locations, items, plot threads — into a persistent world you can explore using D&D 5e rules.

The magic happens through **RAG (Retrieval-Augmented Generation)**: when you encounter a character or location, the AI pulls relevant passages from your source material to stay faithful to the original while improvising around your choices.

**Why D&D 5e rules?** Not because this is a game — because stories need stakes. The dice mechanics provide:
- **Consequences** - Failed persuasion attempts have real outcomes
- **Uncertainty** - You don't know if you'll succeed
- **Fairness** - The AI can't just decide you win or lose arbitrarily
- **Grounding** - Combat, skills, and abilities follow consistent logic

You don't need to know D&D. Just describe what you want to do. The AI handles all the mechanics.

---

## Getting Started

**Prerequisites:** [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and Python 3.11+

```bash
git clone https://github.com/sstobo/dm-claude.git && cd dm-claude && claude
```

Claude auto-detects first-time setup and handles installation, world creation, and character building. Just follow the prompts.

To import source material, add PDFs, EPUBs, or text files to the `source-material/` folder before running `/import`. The [Internet Archive](https://archive.org/) is a great free source.

---

## Commands

### Slash Commands

| Command | What it does |
|---------|--------------|
| `/dm` | Start or continue your story |
| `/dm save` | Save your progress |
| `/dm character` | View your character sheet |
| `/dm overview` | See the world state |
| `/dm status` | Quick campaign status |
| `/dm end` | End current session |
| `/new-game` | Create a world from scratch |
| `/create-character` | Build your character (interactive wizard) |
| `/import` | Import a PDF/document as a new campaign |
| `/enhance` | Enrich entities with source material via RAG |
| `/world-check` | Validate campaign consistency |
| `/reset` | Clear campaign state (with backup options) |
| `/setup` | Verify/fix installation |
| `/help` | Full command reference |

---

## How It Works

### 1. Import Your Source Material

```
/import "source-material/my-book.pdf" "my-campaign"
```

The extraction system parses your document using concurrent specialist agents and identifies:
- **NPCs** — Characters with descriptions, roles, and relationships
- **Locations** — Places with geography and atmosphere
- **Items** — Objects, artifacts, treasures
- **Plots** — Story threads, quests, mysteries

All extracted content is vectorized for RAG retrieval during gameplay.

### 2. Create Your Character

```
/create-character
```

An interactive wizard walks you through race, class, background, abilities, and (for casters) spell selection — all powered by the official D&D 5e API.

### 3. Live the Story

```
/dm
```

Describe what you do. The AI narrates the world's response, drawing on your source material to stay authentic while adapting to your choices. Combat, social encounters, exploration, and skill checks all follow D&D 5e rules with real dice rolls.

---

## The Persistent World

Everything you do is remembered:

| What's Tracked | How |
|----------------|-----|
| **NPC Relationships** | Attitudes shift based on your interactions |
| **Location States** | Places change as events unfold |
| **Consequences** | Actions trigger future events on timers |
| **Plot Progress** | Quest threads track milestones and completion |
| **Time & Calendar** | In-game time advances with travel and rest |
| **Character Growth** | XP, level-ups, inventory, conditions, gold |
| **Session History** | Full log of what happened each session |

Save points let you checkpoint and restore at any time.

---

## Architecture

```
dm-claude/
├── source-material/        # Your PDFs, books, documents
├── world-state/             # Persistent campaign data
│   ├── active-campaign.txt  # Currently active campaign
│   └── campaigns/           # One folder per world
│       └── <campaign>/
│           ├── campaign-overview.json   # Metadata, location, time, rules
│           ├── character.json           # Player character sheet
│           ├── npcs.json                # NPCs, attitudes, events, tags
│           ├── locations.json           # Places and connections
│           ├── facts.json               # Categorized world facts
│           ├── consequences.json        # Pending and resolved events
│           ├── plots.json               # Quests and story threads
│           ├── items.json               # Items and treasures
│           ├── session-log.md           # Session history
│           ├── saves/                   # Named save snapshots
│           ├── chunks/                  # Text chunks from imports
│           └── vectors/                 # ChromaDB embeddings for RAG
├── tools/                   # Bash CLI wrappers
├── lib/                     # Python modules
│   └── rag/                 # RAG pipeline (embedder, vector store, chunker)
├── features/                # D&D 5e API integrations
│   ├── character-creation/  # Race, class, spell selection APIs
│   ├── dnd-api/             # Monster stats and encounters
│   ├── gear/                # Equipment and magic items
│   ├── loot/                # Loot tables by rarity
│   ├── spells/              # Spell lookup and listing
│   └── rules/               # Rules, skills, conditions
├── .claude/
│   ├── commands/            # Slash command definitions
│   └── agents/              # Specialist agent prompts
├── docs/                    # Technical documentation
└── CLAUDE.md                # Complete DM ruleset
```

---

## Tools Reference

DM Claude uses a suite of bash tools that delegate to Python modules. These run behind the scenes during gameplay, but can also be called directly.

All tools follow the pattern: `bash tools/dm-<tool>.sh <command> [arguments]`

### Campaign & Session Management

| Tool | Commands | Purpose |
|------|----------|---------|
| `dm-campaign.sh` | `list`, `create`, `switch`, `delete`, `info`, `active`, `path` | Multi-campaign management |
| `dm-session.sh` | `start`, `end`, `move`, `status`, `context`, `save`, `restore`, `list-saves`, `delete-save`, `history` | Session lifecycle, party movement, save/restore system |
| `dm-overview.sh` | `--detailed` | Quick world state summary |
| `dm-time.sh` | `<time> <date>` | Advance in-game time |

### Character & Party

| Tool | Commands | Purpose |
|------|----------|---------|
| `dm-player.sh` | `show`, `get`, `set`, `xp`, `hp`, `gold`, `inventory`, `loot`, `condition`, `level-check` | Player character stats, inventory, progression |
| `dm-condition.sh` | `add`, `remove`, `check` | Player condition tracking (poisoned, stunned, etc.) |
| `dm-npc.sh` | `create`, `update`, `status`, `enhance`, `list`, `promote`, `demote`, `party`, `hp`, `xp`, `set`, `equip`, `unequip`, `condition`, `feature`, `tag-location`, `tag-quest`, `tags` | NPC management and party member control |

### World Building

| Tool | Commands | Purpose |
|------|----------|---------|
| `dm-location.sh` | `add`, `connect`, `describe`, `get`, `list`, `connections` | Location creation and connections |
| `dm-note.sh` | `<category> <fact>`, `categories` | Record world facts by category |
| `dm-consequence.sh` | `add`, `check`, `resolve`, `list-resolved` | Track future events with triggers |
| `dm-plot.sh` | `list`, `show`, `search`, `update`, `complete`, `fail`, `threads`, `counts` | Quest and storyline management |

### Content & Search

| Tool | Commands | Purpose |
|------|----------|---------|
| `dm-search.sh` | `<query>`, `--world-only`, `--rag-only`, `--tag-location`, `--tag-quest` | Unified search across world state and source material |
| `dm-enhance.sh` | `find`, `query`, `apply`, `summary`, `list`, `scene`, `batch`, `dungeon-check` | RAG-powered entity enhancement |
| `dm-extract.sh` | `prepare`, `merge`, `save`, `review`, `list`, `clean`, `archive`, `validate` | Document import and extraction pipeline |

---

## Specialist Agents

The AI spawns focused agents automatically when context demands it:

| Agent | Specialty | Triggered By |
|-------|-----------|--------------|
| `monster-manual` | Official D&D 5e creature stats (334+ monsters) | Combat encounters |
| `spell-caster` | Spell mechanics, magic schools, conditions | Casting spells |
| `rules-master` | Rule clarifications and edge cases | Mechanical questions |
| `gear-master` | Equipment, weapons, magic items (237+ items, 362+ magic items) | Shopping, identifying gear |
| `loot-dropper` | Context-appropriate treasure generation | Victory, treasure discovery |
| `npc-builder` | NPC backstory, motivations, personality depth | Meeting new NPCs |
| `world-builder` | Iterative location and world expansion | Exploring new areas |
| `dungeon-architect` | Dungeon room generation with exits, monsters, features | Entering dungeons |
| `create-character` | Interactive character creation wizard | New characters |

**Document extraction agents** (run during `/import`):
| Agent | Extracts |
|-------|----------|
| `extractor-npcs` | Characters and people |
| `extractor-locations` | Places and settings |
| `extractor-items` | Objects, props, treasures |
| `extractor-plots` | Quests, scenes, story elements |

---

## Python Library Modules

The `lib/` directory contains the core Python modules:

| Module | Purpose |
|--------|---------|
| `entity_manager.py` | Base class providing CRUD operations for all managers |
| `campaign_manager.py` | Multi-campaign creation, switching, metadata |
| `player_manager.py` | Character stats, XP, HP, gold, inventory, conditions |
| `npc_manager.py` | NPC creation, tagging, party member promotion and stats |
| `location_manager.py` | Location creation, bidirectional connections |
| `plot_manager.py` | Quest tracking, progress events, completion |
| `session_manager.py` | Session lifecycle, party movement, save/restore snapshots |
| `consequence_manager.py` | Future event scheduling and resolution |
| `note_manager.py` | Categorized fact recording |
| `time_manager.py` | In-game time tracking |
| `search.py` | World state search across all entity types |
| `entity_enhancer.py` | RAG-powered entity enrichment |
| `dice.py` | Dice roller supporting standard, advantage, and disadvantage notation |
| `validators.py` | Input validation for names, attitudes, dice notation, conditions |
| `json_ops.py` | Atomic JSON read/write operations |
| `world.py` | Unified entry point providing lazy access to all managers |
| `world_stats.py` | Campaign statistics and overview generation |
| `content_extractor.py` | Document text extraction |
| `agent_extractor.py` | Concurrent agent-based document processing |
| `schemas.py` | Data structure definitions |
| `extraction_schemas.py` | Extraction output schemas |

### RAG Pipeline (`lib/rag/`)

| Module | Purpose |
|--------|---------|
| `semantic_chunker.py` | Split documents into meaningful chunks |
| `embedder.py` | Generate embeddings for text chunks |
| `vector_store.py` | ChromaDB vector storage and similarity search |
| `rag_extractor.py` | Extract entities using RAG context |
| `quote_extractor.py` | Pull relevant quotes from source material |
| `extraction_queries.py` | Pre-built queries for entity extraction |

### D&D 5e API Features (`features/`)

| Module | Purpose |
|--------|---------|
| `dnd-api/monsters/` | Monster stat blocks, encounter generation, CR filtering |
| `gear/` | Equipment lookup, magic items, weapon properties |
| `spells/` | Spell details, magic schools, damage types, conditions |
| `rules/` | Combat rules, skills, abilities, conditions reference |
| `character-creation/` | Race, class, spell, and trait APIs for character building |
| `loot/` | Pre-built loot tables organized by rarity tier |

---

## Key Concepts

### The Core Loop

Every interaction follows: **Context > Decide > Execute > Persist > Narrate**

The golden rule: **save all state changes before describing them to the player.**

### Dice Rolling

All dice use `lib/dice.py` with standard notation:
- `1d20+5` — Standard roll
- `2d20kh1+5` — Advantage (keep highest)
- `2d20kl1+5` — Disadvantage (keep lowest)
- `3d6` — Multiple dice

### RAG Enhancement

When you `/import` a document, the system:
1. Extracts text and splits it into semantic chunks
2. Generates vector embeddings stored in ChromaDB
3. During gameplay, retrieves relevant passages to ground narration in source material
4. `/enhance` enriches specific entities with additional context from the source

### Multi-Campaign Support

Run multiple campaigns simultaneously. Each campaign has isolated state in its own directory. Switch between them with `dm-campaign.sh switch`.

### Save System

Create named checkpoints at any time. Saves capture a complete snapshot of all world state (campaign overview, NPCs, locations, character, plots, consequences, facts). Restore to any save point to rewind.

---

## Documentation

| Document | Contents |
|----------|----------|
| `CLAUDE.md` | Complete DM operational ruleset (the AI reads this) |
| `docs/schema-reference.md` | JSON data structure reference |
| `docs/import-guide.md` | Import and RAG system documentation |
| `docs/import-system-deep-dive.md` | Detailed extraction pipeline docs |
| `docs/python-modules-api.md` | Python module API reference |

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

*Your story awaits. Run `/dm` to begin.*
