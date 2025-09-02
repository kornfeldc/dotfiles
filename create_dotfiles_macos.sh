#!/bin/bash

# macOS dotfiles symlink creation script with interactive options

homedir="$HOME"
dotfiles="$homedir/RiderProjects/dotfiles"

# Function to handle each file
handle_file() {
    local source_path="$1"
    local target_path="$2"
    local filename=$(basename "$source_path")
    
    # Check if source file exists
    if [[ ! -e "$source_path" ]]; then
        echo "File $filename does not exist at $source_path, skipping..."
        return
    fi
    
    echo ""
    echo "Processing: $filename"
    echo "Source: $source_path"
    echo "Target: $target_path"
    echo ""
    echo "What would you like to do?"
    echo "1) Delete original file and create symlink"
    echo "2) Move original file to dotfiles and create symlink"
    echo "3) Skip this file"
    echo ""
    
    while true; do
        read -p "Enter your choice (1/2/3): " choice
        case $choice in
            1)
                echo "Deleting original file and creating symlink..."
                rm -f "$source_path"
                ln -sf "$target_path" "$source_path"
                echo "Created symlink: $source_path -> $target_path"
                break
                ;;
            2)
                echo "Moving original file and creating symlink..."
                # Create target directory if it doesn't exist
                mkdir -p "$(dirname "$target_path")"
                mv "$source_path" "$target_path"
                ln -sf "$target_path" "$source_path"
                echo "Moved file to: $target_path"
                echo "Created symlink: $source_path -> $target_path"
                break
                ;;
            3)
                echo "Skipping $filename"
                break
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done
}

echo "Starting dotfiles symlink setup..."
echo "Dotfiles directory: $dotfiles"

# Process .ideavimrc
handle_file "$homedir/.ideavimrc" "$dotfiles/ideavim/.ideavimrc"
# Process AutoHotkey file (keeping for reference, though not common on macOS)
handle_file "$homedir/Documents/AutoHotkey/Untitled.ahk" "$dotfiles/ahk/Untitled.ahk"
# Process Hammerspoon toml 
handle_file "$homedir/.hammerspoon/Spoons/Hammerflow.spoon/sample.toml" "$dotfiles/hammerflow/sample.toml"
# Process Obsidian vimrc 
handle_file "$homedir/Obsidian/Christian/.obsidian.vimrc" "$dotfiles/obsidian/.obsidian.vimrc"

echo ""
echo "Dotfiles setup completed!"