#!/bin/bash

# Changelog Generator
# Automatically updates CHANGELOG.md based on conventional commit messages

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CHANGELOG_FILE="CHANGELOG.md"
TEMP_FILE=$(mktemp)

echo -e "${BLUE}📝 Updating CHANGELOG.md based on recent commits...${NC}"

# Get the last tag or use the beginning of the repository
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LAST_TAG" ]; then
    RANGE="--all"
    echo -e "${YELLOW}⚠️  No tags found, processing all commits${NC}"
else
    RANGE="$LAST_TAG..HEAD"
    echo -e "${GREEN}📌 Processing commits since $LAST_TAG${NC}"
fi

# Arrays to store categorized commits
declare -a ADDED_COMMITS=()
declare -a CHANGED_COMMITS=()
declare -a REMOVED_COMMITS=()
declare -a FIXED_COMMITS=()
declare -a SECURITY_COMMITS=()

# Process commits and categorize them
while IFS= read -r commit; do
    if [[ -z "$commit" ]]; then
        continue
    fi
    
    # Extract emoji, type, scope, and message
    if [[ $commit =~ ^([🎨🐛⚡🔥💄✨🚚📝🚀✅♻️➕➖🔧⬇️⬆️📌👷📈🐳🔀💚👕🚨🍻💬🗃️🔊🔇👥🚸📱⚗️🏷️🌱🚩💫🗑️]+)\ ([a-z]+)(\([a-z0-9-]+\))?!?:\ (.+)$ ]]; then
        emoji="${BASH_REMATCH[1]}"
        type="${BASH_REMATCH[2]}"
        scope="${BASH_REMATCH[3]}"
        message="${BASH_REMATCH[4]}"
        
        formatted_commit="- $emoji $type$scope: $message"
        
        case $type in
            feat)
                ADDED_COMMITS+=("$formatted_commit")
                ;;
            fix)
                FIXED_COMMITS+=("$formatted_commit")
                ;;
            docs|style|refactor|perf|chore|build|ci)
                CHANGED_COMMITS+=("$formatted_commit")
                ;;
            remove|delete)
                REMOVED_COMMITS+=("$formatted_commit")
                ;;
            security)
                SECURITY_COMMITS+=("$formatted_commit")
                ;;
        esac
    fi
done < <(git log $RANGE --pretty=format:"%s" --no-merges --reverse)

# Read existing changelog
if [[ -f "$CHANGELOG_FILE" ]]; then
    cp "$CHANGELOG_FILE" "$TEMP_FILE"
else
    cat > "$TEMP_FILE" << 'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

EOF
fi

# Function to add section to changelog
add_section() {
    local section_name="$1"
    shift
    local commits=("$@")
    
    if [[ ${#commits[@]} -gt 0 ]]; then
        echo -e "\n### $section_name"
        printf '%s\n' "${commits[@]}"
    fi
}

# Generate new unreleased section
{
    echo "# Changelog"
    echo ""
    echo "All notable changes to this project will be documented in this file."
    echo ""
    echo "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),"
    echo "and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."
    echo ""
    echo "## [Unreleased]"
    
    add_section "Added" "${ADDED_COMMITS[@]}"
    add_section "Changed" "${CHANGED_COMMITS[@]}"
    add_section "Removed" "${REMOVED_COMMITS[@]}"
    add_section "Fixed" "${FIXED_COMMITS[@]}"
    add_section "Security" "${SECURITY_COMMITS[@]}"
    
    echo ""
    
    # Add existing content (skip the header and unreleased section)
    sed -n '/^## \[.*\] - /,$p' "$TEMP_FILE" 2>/dev/null || echo ""
    
} > "$CHANGELOG_FILE"

# Clean up
rm "$TEMP_FILE"

echo -e "${GREEN}✅ CHANGELOG.md updated successfully${NC}"

# Show summary
total_commits=$((${#ADDED_COMMITS[@]} + ${#CHANGED_COMMITS[@]} + ${#REMOVED_COMMITS[@]} + ${#FIXED_COMMITS[@]} + ${#SECURITY_COMMITS[@]}))
echo -e "${GREEN}📊 Summary:${NC}"
echo "  Added: ${#ADDED_COMMITS[@]} commits"
echo "  Changed: ${#CHANGED_COMMITS[@]} commits" 
echo "  Removed: ${#REMOVED_COMMITS[@]} commits"
echo "  Fixed: ${#FIXED_COMMITS[@]} commits"
echo "  Security: ${#SECURITY_COMMITS[@]} commits"
echo "  Total: $total_commits commits processed"
