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

GRADLE?=$(CURDIR)/nouveau/gradlew

.PHONY: release
# target: release - Create an Erlang release including CouchDB!
release: nouveau
	@echo "Installing CouchDB into rel/couchdb/ ..."
	@rm -rf rel/couchdb

	@mkdir -p rel/couchdb/nouveau
	@cd nouveau && $(GRADLE) installDist
	@cp -R nouveau/build/install/nouveau rel/couchdb

	@echo "... done"
	@echo
	@echo "    You can now copy the rel/couchdb directory anywhere on your system."
	@echo "    Start CouchDB with ./bin/couchdb from within that directory."
	@echo

################################################################################
# Nouveau
################################################################################

.PHONY: nouveau
# target: nouveau - Build nouveau
nouveau:
	@cd nouveau && $(GRADLE) spotlessApply
	@cd nouveau && $(GRADLE) build -x test
