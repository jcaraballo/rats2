#!/bin/bash

cd "$( dirname "$0" )"

source functions.bash

ensure_no_uncommited_changes

cat >assembly-generated.sbt <<EOF
import AssemblyKeys._

assemblySettings

jarName in assembly := { s"\${name.value}-\${version.value}-$(date --utc +%Y%m%d%H%M%S)-$(git rev-parse --short --verify HEAD).jar" }
EOF

sbt clean assembly
