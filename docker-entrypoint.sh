#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

set -e

# first arg is the bare word `clouseau`
if [ "$1" = 'clouseau' ]; then
    export CLASS_PATH=$(ls -t *.jar | tr '\n' ':'):test-classes
    set -- scala -classpath "$CLASS_PATH" com.cloudant.clouseau.Main
fi

if [ "$1" = 'scala' ]; then
    epmd -daemon

    chown -R clouseau:clouseau /opt/clouseau
    chmod -R 0770 /opt/clouseau/data
    chmod 664 /opt/clouseau/*.ini

    exec gosu clouseau "$@"
fi

exec "$@"
