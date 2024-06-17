#!/usr/bin/env bash
while getopts a:n:p:c:u:d: flag
do
    case "${flag}" in
        a) author=${OPTARG};;
        n) name=${OPTARG};;
        p) upper_name=${OPTARG};;
        c) camel_name=${OPTARG};;
        u) urlname=${OPTARG};;
        d) description=${OPTARG};;
    esac
done

echo "Author: $author";
echo "Project Name: $name";
echo "Project Name Upper: $upper_name";
echo "Project Name Camel: $camel_name";
echo "Project URL name: $urlname";
echo "Description: $description";

echo "Renaming project..."

original_author="author_name"
original_name="project_name"
original_upper_name="PROJECT_NAME"
original_camel_name="ProjectName"
original_urlname="project_urlname"
original_description="project_description"
# for filename in $(find . -name "*.*") 
for filename in $(git ls-files) 
do
    sed -i "s/$original_author/$author/g" $filename
    sed -i "s/$original_name/$name/g" $filename
    sed -i "s/$original_upper_name/$upper_name/g" $filename
    sed -i "s/$original_camel_name/$camel_name/g" $filename
    sed -i "s/$original_urlname/$urlname/g" $filename
    sed -i "s/$original_description/$description/g" $filename
    echo "Renamed $filename"
done

cd include
mv project_name $name
cd ..

# This command runs only once on GHA!
rm -rf .github/template.yml
