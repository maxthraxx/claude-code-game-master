#!/bin/bash
# dm-reset.sh - Reset world state for a fresh campaign start
# Archives current world, then cleans for new beginning

# Source common utilities
source "$(dirname "$0")/common.sh"

echo "🔄 Campaign Reset Tool"
echo "======================"
echo ""

# Show which campaign we're working with
ACTIVE_CAMPAIGN=$(get_active_campaign)
if [ -n "$ACTIVE_CAMPAIGN" ]; then
    echo "Active campaign: $ACTIVE_CAMPAIGN"
    echo "Campaign path: $WORLD_STATE_DIR"
else
    echo "No active campaign set. Use 'dm-campaign.sh list' and 'dm-campaign.sh switch <name>' first."
    exit 1
fi
echo ""

ACTION="${1:-}"

show_usage() {
    echo "Usage: dm-reset.sh <action>"
    echo ""
    echo "Actions:"
    echo "  preview     - Show what would be reset (safe)"
    echo "  archive     - Archive current world to git branch, then reset"
    echo "  hard        - Delete everything and start fresh (destructive!)"
    echo ""
    echo "Examples:"
    echo "  dm-reset.sh preview              # See what exists"
    echo "  dm-reset.sh archive              # Safe reset with backup"
    echo "  dm-reset.sh hard                 # Nuclear option"
    echo ""
    echo "Note: This resets the ACTIVE CAMPAIGN only."
    echo "Use 'dm-campaign.sh switch <name>' to change campaigns first."
}

preview_world() {
    require_active_campaign
    echo "📊 Current World State:"
    echo ""
    $PYTHON_CMD "$LIB_DIR/world_stats.py" counts
    echo ""
    echo "📁 Files that would be reset:"
    echo "  • $WORLD_STATE_DIR/npcs.json"
    echo "  • $WORLD_STATE_DIR/locations.json"
    echo "  • $WORLD_STATE_DIR/facts.json"
    echo "  • $WORLD_STATE_DIR/consequences.json"
    echo "  • $WORLD_STATE_DIR/campaign-overview.json"
    echo "  • $WORLD_STATE_DIR/session-log.md"
    # Check for new format (character.json) vs legacy (characters/)
    if [ -f "$WORLD_STATE_DIR/character.json" ]; then
        echo "  • $WORLD_STATE_DIR/character.json"
    elif [ -d "$WORLD_STATE_DIR/characters" ]; then
        echo "  • $WORLD_STATE_DIR/characters/*.json"
    fi
}

reset_world() {
    require_active_campaign
    echo "🧹 Resetting world state..."
    echo ""

    # Reset NPCs
    echo '{}' > "$NPCS_FILE"
    echo "  ✓ NPCs cleared"

    # Reset Locations
    echo '{}' > "$LOCATIONS_FILE"
    echo "  ✓ Locations cleared"

    # Reset Facts
    echo '{}' > "$FACTS_FILE"
    echo "  ✓ Facts cleared"

    # Reset Consequences
    echo '{"active": [], "resolved": []}' > "$CONSEQUENCES_FILE"
    echo "  ✓ Consequences cleared"

    # Reset Campaign Overview
    cat > "$CAMPAIGN_OVERVIEW" << 'EOF'
{
  "campaign_name": "New Campaign",
  "genre": "Fantasy",
  "tone": {
    "horror": 30,
    "comedy": 30,
    "drama": 40
  },
  "current_date": "1st of the First Month, Year 1",
  "time_of_day": "Morning",
  "player_position": {
    "current_location": null,
    "previous_location": null
  },
  "current_character": null,
  "session_count": 0
}
EOF
    echo "  ✓ Campaign overview reset"

    # Reset Session Log
    cat > "$SESSION_LOG" << 'EOF'
# Campaign Session Log

*A new adventure begins...*

---

EOF
    echo "  ✓ Session log cleared"

    # Remove character file (new format) or characters directory (legacy)
    if [ -f "$CHARACTER_FILE" ]; then
        rm -f "$CHARACTER_FILE"
        echo "  ✓ Character removed"
    elif [ -d "$CHARACTERS_DIR" ]; then
        rm -f "$CHARACTERS_DIR"/*.json 2>/dev/null
        echo "  ✓ Characters removed"
    fi

    echo ""
    echo "✅ World state reset to blank slate"
}

case "$ACTION" in
    preview)
        preview_world
        echo ""
        echo "💡 Run 'dm-reset.sh archive' to safely reset with backup"
        ;;

    archive)
        echo "📦 Archiving current campaign..."
        echo ""

        if ! git rev-parse --git-dir > /dev/null 2>&1; then
            echo "❌ Not a git repository - cannot archive"
            echo "   Use 'dm-reset.sh hard' for destructive reset"
            exit 1
        fi

        # Get campaign name for branch
        CAMPAIGN_NAME=$($PYTHON_CMD "$LIB_DIR/json_ops.py" get "$CAMPAIGN_OVERVIEW" --key campaign_name 2>/dev/null | tr -d '"' | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
        [ -z "$CAMPAIGN_NAME" ] && CAMPAIGN_NAME="unknown"

        ARCHIVE_BRANCH="archive/${CAMPAIGN_NAME}-$(date +%Y%m%d-%H%M%S)"

        # Commit any pending changes
        cd "$PROJECT_ROOT"
        git add world-state/
        git commit -m "Final state before reset: $CAMPAIGN_NAME" --quiet 2>/dev/null || true

        # Create archive branch
        CURRENT_BRANCH=$(git branch --show-current)
        git branch "$ARCHIVE_BRANCH"

        echo "  ✓ Archived to branch: $ARCHIVE_BRANCH"
        echo ""

        preview_world
        echo ""

        read -p "⚠️  Reset this world? Archive saved to '$ARCHIVE_BRANCH' (y/N) " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            reset_world

            # Commit the reset
            git add world-state/
            git commit -m "Fresh start: World reset for new campaign" --quiet

            echo ""
            echo "📜 To restore archived campaign:"
            echo "   git checkout $ARCHIVE_BRANCH -- world-state/"
        else
            echo "Reset cancelled. World unchanged."
        fi
        ;;

    hard)
        echo "⚠️  HARD RESET - No backup will be created!"
        echo ""
        preview_world
        echo ""

        read -p "💀 This is DESTRUCTIVE. Type 'DELETE' to confirm: " CONFIRM

        if [ "$CONFIRM" = "DELETE" ]; then
            reset_world
            echo ""
            echo "💀 World obliterated. Starting fresh."
        else
            echo "Reset cancelled. World unchanged."
        fi
        ;;

    *)
        show_usage
        exit 1
        ;;
esac
