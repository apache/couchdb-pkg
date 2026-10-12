# check=skip=InvalidDefaultArgInFrom
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

# Build CouchDB packages for an {os,arch} combo inside the matching couchdb-ci image.
# Run from build.sh as:
#
#   docker buildx build --platform linux/<arch> --output type=local,dest=pkgs/couch ...
#
# The reuslt is the built package(s). Then the local exporter saves
# them into pkgs/couch/$dist on the host. The build itself run on
# whatever node of the current builder supports combo (possibly
# remote).

# IMAGE always passed in by build.sh. No good default for it, so added
# lint in line 1 so it stops complaining about.
ARG IMAGE
FROM ${IMAGE} AS build
ARG TARGET
ARG COUCHTARBALL
USER root
WORKDIR /home/jenkins/couchdb-pkg
COPY . .
RUN make copy-couch ${TARGET} COUCHTARBALL=${COUCHTARBALL}

FROM scratch
COPY --from=build /home/jenkins/couchdb-pkg/pkgs/couch/ /
