#!/bin/bash

# Set the umbrella chart directory containing Chart.yaml
UMBRELLA_DIR="./charts/app"

# Get the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/temp"

# Set the output path for values-current.yaml
VALUES_CURRENT_PATH="$SCRIPT_DIR/values-current.yaml"

# Set the output path for values-new.yaml
VALUES_NEW_PATH="$SCRIPT_DIR/values-new.yaml"

# Change to the umbrella chart directory
cd "$UMBRELLA_DIR"

# Step 1: Add helm repos according to dependencies in Chart.yaml
dependency_count=$(yq e '.dependencies | length' Chart.yaml)

for ((i=0; i<$dependency_count; i++)); do
  repo_name=$(yq e ".dependencies[$i].name" Chart.yaml)
  repo_url=$(yq e ".dependencies[$i].repository" Chart.yaml)
  
  helm repo add "$repo_name" "$repo_url" || echo "Repository $repo_name already added."
done


# Step 2: Run helm repo update and download current dependencies
helm repo update
echo "Downloading current version chart"
helm dependency update > /dev/null 2>&1

# Step 3: Untar and copy the current chart's dependencies values file contents
# Saving to values-current.yaml in the script's temp directory

# Ensure the temp directory exists
mkdir -p "$SCRIPT_DIR"

# Esure a clean file values-current.yaml
if [[ -f "$VALUES_CURRENT_PATH" ]]; then
    rm "$VALUES_CURRENT_PATH"
fi
touch "$VALUES_CURRENT_PATH"

for FILE_PATH in charts/*.tgz; do
  # Extract the dependency name from the file name
  DEP="${FILE_PATH##*/}"  # Remove the path prefix
  DEP="${DEP%%-*}"  # Remove the version suffix

  # Untar the upstream chart
  echo "Untaring $FILE_PATH"
  tar -zxvf "$FILE_PATH" -C "charts/" > /dev/null 2>&1

  # Indent the dependency's values.yaml file content
  sed 's/^/  /' "charts/$DEP/values.yaml" > temp_values.yaml

  # Ensure the dependency block exists in values.yaml, then merge the contents
  echo "$DEP:" >> "$VALUES_CURRENT_PATH"
  cat temp_values.yaml >> "$VALUES_CURRENT_PATH"
  echo "" >> "$VALUES_CURRENT_PATH"  # Optional: Add a blank line between sections for readability

  # Remove the  untarred dependency folders
  rm -rf "charts/$DEP"

done


# Step 4: Search helm repos for the latest versions for the dependencies from Chart.yaml

# Get the number of dependencies
dependency_count=$(yq e '.dependencies | length' Chart.yaml)
echo "Number of dependencies: $dependency_count"

for ((i=0; i<$dependency_count; i++)); do
  dep_name=$(yq e ".dependencies[$i].name" Chart.yaml)
  echo "Processing dependency: $dep_name"
  
  current_version=$(yq e ".dependencies[$i].version" Chart.yaml | head -1)  # Only take the first line
  echo "Current version of $dep_name: $current_version"
  
  # Searching for the latest version
  echo "Searching for latest version of $dep_name using helm..."
  latest_version=$(helm search repo "$dep_name" | awk -v name="$dep_name/" '$1 ~ name {print $2}' | head -1)
  echo "Latest version found: $latest_version"
  
  if [[ "$current_version" != "$latest_version" && -n "$latest_version" ]]; then
    echo "Updating $dep_name in Chart.yaml from $current_version to $latest_version"
    yq e ".dependencies[$i].version = \"$latest_version\"" -i Chart.yaml
  fi
done


# Step 5: Run helm dependency upgrade
echo "Downloading latest version(s) of the chart"
helm dependency update > /dev/null 2>&1

# Step 6: Similar logic to Step 3, but save values-new.yaml to compare it with the current version

# Esure a clean file values-new.yaml
if [[ -f "$VALUES_NEW_PATH" ]]; then
    rm "$VALUES_NEW_PATH"
fi
touch "$VALUES_NEW_PATH"

for FILE_PATH in charts/*.tgz; do
  # Extract the dependency name from the file name
  DEP="${FILE_PATH##*/}"  # Remove the path prefix
  DEP="${DEP%%-*}"  # Remove the version suffix
  

  # Untar the updated upstream chart
  echo "Untaring $FILE_PATH"
  tar -zxvf "$FILE_PATH" -C "charts/" > /dev/null 2>&1

  # Indent the dependency's values.yaml file content
  sed 's/^/  /' "charts/$DEP/values.yaml" > temp_values.yaml

  # Ensure the dependency block exists in values-new.yaml, then merge the contents
  echo "$DEP:" >> "$VALUES_NEW_PATH"
  cat temp_values.yaml >> "$VALUES_NEW_PATH"
  echo "" >> "$VALUES_NEW_PATH"  # Optional: Add a blank line between sections for readability

  # Remove the  untarred dependency folders
  rm -rf "charts/$DEP"

done

# Optionally, clean up temporary files:
rm temp_values.yaml


# Step 7: Diff the generated values files
diff_output=$(diff $VALUES_CURRENT_PATH $VALUES_NEW_PATH)
if [[ "$diff_output" != "" ]]; then

  echo "-----------------------------------------------------------------------------------------"
  echo "WARNING!!: Differences detected between values-current.yaml and values-new.yaml!"
  echo ""
  echo "run vimdiff $VALUES_CURRENT_PATH $VALUES_NEW_PATH to check for possible breaking changes"
  echo ""  
  echo "-----------------------------------------------------------------------------------------"
  # echo "$diff_output"

fi


# Optionally, clean up temporary files:
echo "To cleanup temp files run rm -rf ./temp " 
