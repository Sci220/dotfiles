# In ~/.config/fish/functions/bak.fish
function bak
    if test -z "$argv[1]"
        echo "Usage: bak <filename>"
        return 1
    end

    set -l filename $argv[1]
    # Create a timestamp in YYYY-MM-DD_HH-MM-SS format
    set -l timestamp (date +%Y-%m-%d_%H-%M-%S)
    cp $filename $filename.$timestamp.bak
    echo "Backup created: $filename.$timestamp.bak"
end
