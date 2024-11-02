#!/bin/sh

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

echo "Starting nouveau (java)"
echo "java path : ${JAVA_PATH}"
echo "java opts : ${_JAVA_OPTS}"
echo "jar       : ${COUCHDB_NOUVEAU_JAR}"
echo "cfg       : ${COUCHDB_NOUVEAU_CFG}"

export JAVA_OPTS="-server -Djava.awt.headless=true -Xmx2g"

exec ${JAVA_PATH} ${JAVA_OPTS} -jar ${COUCHDB_NOUVEAU_JAR} server ${COUCHDB_NOUVEAU_CFG}
