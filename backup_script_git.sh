#!/bin/bash

# This will be a script to backup my i-cloud data to my s3 bucket in aws.
# $HOME = Users/amielterry40

working_dir="$HOME/desktop/Downloads/tbs"

mv $working_dir/*.md $working_dir/markdown
mv $working_dir/*.pdf $working_dir/pdf
mv $working_dir/*.txt $working_dir/txt
mv $working_dir/*.png $working_dir/media
mv $working_dir/*.mp4 $working_dir/media
mv $working_dir/*.mp3 $working_dir/media
mv $working_dir/*.webp $working_dir/media
mv $working_dir/*.MOV $working_dir/media
mv $working_dir/*.mov $working_dir/media
mv $working_dir/*.* $working_dir/unsorted

aws s3 sync $working_dir s3://amiels-aws-bucket/cloud_backups --delete