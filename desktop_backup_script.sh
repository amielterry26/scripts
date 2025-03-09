#!/bin/bash

# This will be a script that backs up my /desktop/downloads/tbs directory on my local machine up to my s3 bucket.

working_dir="$HOME/desktop/Downloads/tbs"
s3bucket="s3://amiels-aws-bucket-dev"

aws s3 sync $working_dir $s3bucket/cloud_backups --delete