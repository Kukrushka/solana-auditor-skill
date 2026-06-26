#!/bin/bash

# solana-auditor-skill — Installer
# Installs the Solana security auditor skill for Claude Code

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/skill"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
SKILL_PATH="$SKILLS_DIR/solana-auditor"

print_banner() {
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}                                                              ${RED}║${NC}"
    echo -e "${RED}║${NC}   ${WHITE}solana-auditor-skill${NC}                                      ${RED}║${NC}"
    echo -e "${RED}║${NC}   ${CYAN}Full-lifecycle Solana security auditor for Claude Code${NC}    ${RED}║${NC}"
    echo -e "${RED}║${NC}                                                              ${RED}║${NC}"
    echo -e "${RED}║${NC}   ${YELLOW}Powered by Superteam Brasil${NC}                               ${RED}║${NC}"
    echo -e "${RED}║${NC}                                                              ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_help() {
    echo "solana-auditor-skill installer"
    echo ""
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -y, --yes              Skip confirmation prompt"
    echo "  --skills-dir DIR       Install to DIR instead of ~/.claude/skills/"
    echo "  -h, --help             Show this help"
    echo ""
}

SKIP_CONFIRM=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes) SKIP_CONFIRM=true; shift ;;
        --skills-dir) SKILLS_DIR="$2"; SKILL_PATH="$SKILLS_DIR/solana-auditor"; shift 2 ;;
        -h|--help) print_help; exit 0 ;;
        *) echo "Unknown option: $1"; print_help; exit 1 ;;
    esac
done

print_banner

echo -e "  ${WHITE}This will install:${NC}"
echo -e "  ${BLUE}•${NC} solana-auditor skill → ${CYAN}$SKILL_PATH${NC}"
echo ""

if [ "$SKIP_CONFIRM" = false ]; then
    read -p "  Proceed? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "  ${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi
fi

echo ""
mkdir -p "$SKILLS_DIR"

echo -e "  ${CYAN}[1/2]${NC} Installing skill files..."
if [ -d "$SKILL_PATH" ]; then
    echo -e "        ${YELLOW}→${NC} Removing previous installation"
    rm -rf "$SKILL_PATH"
fi
mkdir -p "$SKILL_PATH"
cp -r "$SOURCE_DIR/"* "$SKILL_PATH/"
echo -e "        ${GREEN}✓${NC} Installed to $SKILL_PATH"

echo -e "  ${CYAN}[2/2]${NC} Installing agents and commands..."
if [ -d "$SCRIPT_DIR/agents" ]; then
    mkdir -p "$SKILL_PATH/../solana-auditor-agents"
    cp -r "$SCRIPT_DIR/agents" "$HOME/.claude/agents/" 2>/dev/null || \
        echo -e "        ${YELLOW}→${NC} agents/ directory: copy manually to ~/.claude/agents/"
fi
if [ -d "$SCRIPT_DIR/commands" ]; then
    mkdir -p "$HOME/.claude/commands"
    cp "$SCRIPT_DIR/commands/"*.md "$HOME/.claude/commands/" 2>/dev/null && \
        echo -e "        ${GREEN}✓${NC} Commands installed to ~/.claude/commands/" || \
        echo -e "        ${YELLOW}→${NC} commands/ directory: copy manually to ~/.claude/commands/"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ${WHITE}Installation complete!${NC}                                      ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${WHITE}Try asking Claude Code:${NC}"
echo -e "  ${BLUE}•${NC} ${CYAN}/audit-quick programs/my_program/${NC}"
echo -e "  ${BLUE}•${NC} ${CYAN}/audit-full programs/lending/${NC}"
echo -e "  ${BLUE}•${NC} ${CYAN}/gen-report${NC}"
echo -e "  ${BLUE}•${NC} \"Audit this Anchor instruction for missing signer checks\""
echo -e "  ${BLUE}•${NC} \"Set up Trident fuzzing for my vault program\""
echo ""
