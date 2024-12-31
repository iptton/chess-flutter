#!/bin/bash

# Define the output file names
merged_file="merged_dart_files.dart"
output_pdf="output.pdf"

# Create or clear the merged file
> $merged_file

# Find all Dart files in the lib directory
for file in $(find lib -name "*.dart"); do
  # Add the file path and name before the content
  echo "File: $file"
  echo "File: $file" >> $merged_file
  cat "$file" >> $merged_file
  echo -e "\n" >> $merged_file
done

# Convert the merged Dart file to PDF using pandoc
pandoc $merged_file -o $output_pdf

# Clean up the temporary merged file
rm $merged_file

echo "All Dart files in the lib directory have been merged and converted to $output_pdf"