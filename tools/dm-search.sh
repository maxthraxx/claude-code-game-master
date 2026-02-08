#!/bin/bash
# dm-search.sh - Unified search across world state and RAG vectors

source "$(dirname "$0")/common.sh"

show_usage() {
    cat << EOF
Search Tool - Query world state and source material

Usage:
  dm-search.sh <query> [options]

Options:
  --rag              Include RAG vector results (default if vectors exist)
  --world-only       Search world state only, skip RAG
  --rag-only         Search RAG vectors only, skip world state
  -n <count>         Number of RAG results (default: 10)
  --tag-location <t> Search NPCs by location tag
  --tag-quest <t>    Search NPCs by quest tag

Examples:
  dm-search.sh "dragon"                   # Search both world + RAG
  dm-search.sh "dragon" --world-only      # World state only
  dm-search.sh "dragon" --rag-only -n 20  # RAG only, 20 results
  dm-search.sh --tag-location "Thornhaven"

Searches across: NPCs, locations, facts, consequences, plots, and source material.
EOF
}

# Parse arguments
QUERY=""
RAG_ONLY=false
WORLD_ONLY=false
RAG_COUNT=10
TAG_SEARCH=false
TAG_TYPE=""
TAG_VALUE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rag)
            shift
            ;;
        --world-only)
            WORLD_ONLY=true
            shift
            ;;
        --rag-only)
            RAG_ONLY=true
            shift
            ;;
        -n)
            RAG_COUNT="$2"
            shift 2
            ;;
        --tag-location)
            TAG_SEARCH=true
            TAG_TYPE="--tag-location"
            TAG_VALUE="$2"
            shift 2
            ;;
        --tag-quest)
            TAG_SEARCH=true
            TAG_TYPE="--tag-quest"
            TAG_VALUE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            if [ -z "$QUERY" ]; then
                QUERY="$1"
            fi
            shift
            ;;
    esac
done

require_active_campaign

# Validate input
if [ -z "$QUERY" ] && [ "$TAG_SEARCH" = false ]; then
    show_usage
    exit 1
fi

# Handle tag searches (world-only by nature)
if [ "$TAG_SEARCH" = true ]; then
    echo "Searching World State"
    echo "====================="
    $PYTHON_CMD "$LIB_DIR/search.py" "$TAG_TYPE" "$TAG_VALUE"
    exit 0
fi

# Get campaign directory
CAMPAIGN_DIR=$(bash "$TOOLS_DIR/dm-campaign.sh" path 2>/dev/null)

# Search world state (unless RAG-only)
if [ "$RAG_ONLY" = false ]; then
    echo "Searching World State"
    echo "====================="
    $PYTHON_CMD "$LIB_DIR/search.py" "$QUERY"
fi

# Search RAG (unless world-only)
if [ "$WORLD_ONLY" = false ]; then
    if [ -d "$CAMPAIGN_DIR/vectors" ]; then
        echo ""
        echo "Source Material Matches"
        echo "======================="
        $PYTHON_CMD "$LIB_DIR/entity_enhancer.py" search "$QUERY" -n "$RAG_COUNT"
    elif [ "$RAG_ONLY" = true ]; then
        echo "No vector store found for this campaign."
        echo "Import a document with /import to enable RAG search."
        exit 1
    fi
fi
