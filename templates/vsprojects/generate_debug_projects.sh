#!/bin/sh

# Copyright 2015, Google Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# To properly use this, you'll need to add:
#
#    "debug": true
#
# to build.json

# workflow is: run generate_projects once to get grpc.sln rebuilt with new test projects
# then grep grpc.sln for the new projects and create tempaltes for them
# then re-run generate_projects to create projects from the new templates

cd `dirname $0`/../..

./tools/buildgen/generate_projects.sh

echo    #generate_projects doesn't finish with a newline

line_number=0

cat ./vsprojects/grpc.sln |
grep -A2 Project\(\"{ |       #find 'Project("{' , plus 2 additional lines to capture the "libs = ". there will also be 1 line of "--" (grep output)
while read p ; do
  line_number=$((line_number + 1))
  if [ "$line_number" -gt "4" ]; then
    line_number=1;
  fi
  if [ "$line_number" -eq "1" ]; then
    project_name=$(echo "$p" | cut -d\" -f 4)          #cut with delimiter " and select only field 4
  fi
  if [ "$line_number" -eq "3" ]; then
    lib_setting=$(echo "$p" | cut -d\" -f 2)          #cut with delimiter " and select only field 2
    if [ -e ./templates/vsprojects/$project_name/$project_name.vcxproj.template ]; then
      echo "skipping template creation for $project_name: template already exists"
    else
      if [ "$lib_setting" = "True" ]; then
        echo "creating template for $project_name as library"
        mkdir -p ./templates/vsprojects/$project_name
        echo '<%namespace file="../vcxproj_defs.include" import="gen_project"/>${gen_project("'$project_name'", libs)}' > ./templates/vsprojects/$project_name/$project_name.vcxproj.template
      else
        if [ "$lib_setting" = "False" ]; then
          echo "creating template for $project_name as target"
          mkdir -p templates/vsprojects/$project_name
          echo '<%namespace file="../vcxproj_defs.include" import="gen_project"/>${gen_project("'$project_name'", targets)}' > ./templates/vsprojects/$project_name/$project_name.vcxproj.template
        else
          echo "skipping template creation for $project_name: could not determine lib/target setting"
        fi
      fi
    fi
  fi
 # sleep .5     #for testing
done

./tools/buildgen/generate_projects.sh
