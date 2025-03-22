#!/usr/bin/env sh

# thx to Alex (norse-dreki) - https://answers.launchpad.net/launchpad/+question/709634
if [ -n "${LAUNCHPAD_INSTANCE+1}" ]; then
  https_proxy_host=$(echo $https_proxy | cut -d'/' -f3 | cut -d':' -f1)
  https_proxy_port=$(echo $https_proxy | cut -d'/' -f3 | cut -d':' -f2)
  export GRADLE_OPTS="-Dhttp.proxyHost=$https_proxy_host -Dhttp.proxyPort=$https_proxy_port -Dhttps.proxyHost=$https_proxy_host -Dhttps.proxyPort=$https_proxy_port"
fi
