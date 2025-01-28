repo_root=$(git rev-parse --show-toplevel)

if git rev-parse --verify HEAD~1 &>/dev/null; then
    commit_range="HEAD~1..HEAD"
else
    commit_range="$(git rev-list --max-parents=0 HEAD)..HEAD"
fi

branch_name=$(git rev-parse --abbrev-ref HEAD)

compress_json() {
    local file="$1"
    if jq -c . "$file" > tmp.json; then
        mv tmp.json "$file"
        echo "Compressed: $file"
    else
        echo "Failed to compress: $file"
    fi
}

find_and_compress_git_diff_files() {
    local base_commit="$1"
    local head_commit="$2"

    local changed_files
    changed_files=$(git diff --name-only $base_commit $head_commit | grep '^Frontend/android-native/[^/]*/src/[^/]*/[^/]*/res/raw/.*\.json$')
    # changed_files=$(git diff --name-only "$commit_range" | grep '^Frontend/android-native/[^/]*/src/[^/]*/res/drawable/.*\.png$')

    if [[ -z "$changed_files" ]]; then
        echo "No JSON files found to compress in the latest commit."
        return
    fi

    echo "$changed_files" | while read -r json_file; do    
        echo "Checking file: '$json_file'"
        full_path="$repo_root/$json_file"
        if [[ -f "$full_path" ]]; then
            compress_json "$full_path"
        else
            echo "File not found: $full_path"
        fi
    done

    git config --local user.email "github-actions[bot]@users.noreply.github.com"
    git config --local user.name "github-actions[bot]"
    git add .
    git diff --quiet && git diff --staged --quiet || git commit -m "[GITHUB-ACTION] Compressed Lotties"
    git push origin "$branch_name"
}

base_commit=$1
head_commit=$2

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not inside a Git repository."
    exit 1
fi

if [[ -z "$commit_range" ]]; then
    echo "Error: Commit range not specified."
    exit 1
fi

find_and_compress_git_diff_files "$base_commit" "$head_commit"
