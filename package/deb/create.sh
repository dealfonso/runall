#!/bin/bash
#
# runall - run a command in all servers (from a list)
# https://github.com/dealfonso/runall
#
# Copyright (C) caralla@upv.es
# Developed by Carlos A. caralla@upv.es
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

SRCFOLDER=$1
if [ "$SRCFOLDER" == "" ]; then
  SRCFOLDER="."
fi

source "$SRCFOLDER/appname"
if [ $? -ne 0 -o "$APPNAME" == "" ]; then
  echo "could not find the name of the application"
  exit 1
fi

source "$SRCFOLDER/version"
if [ $? -ne 0 -o "$VERSION" == "" ]; then
  echo "could not find the version for the package"
  exit 1
fi

REVISION=${VERSION##*-}
VERSION=${VERSION%%-*}

FNAME=build/${APPNAME}_${VERSION}-${REVISION}
rm -rf "${FNAME}"
mkdir -p "${FNAME}/DEBIAN"

${SRCFOLDER}/INSTALL.sh "${SRCFOLDER}" "${FNAME}"

cat > "${FNAME}/DEBIAN/control" << EOF
Package: ${APPNAME}
Version: ${VERSION}-${REVISION}
Section: base
Priority: optional
Architecture: all
Depends: bash, libc-bin, coreutils, grep, openssh-client
Maintainer: Carlos A. <caralla@upv.es>
Description: ${APPNAME}
 run a command in a list of servers. It makes parallel runs
 and other features.
EOF

cat > "${FNAME}/DEBIAN/postinst" <<\EOF
#!/bin/sh
EOF

cat > "${FNAME}/DEBIAN/postrm" <<\EOF
#!/bin/sh
EOF

chmod +x "${FNAME}/DEBIAN/postinst"
chmod +x "${FNAME}/DEBIAN/postrm"

cat > "${FNAME}/DEBIAN/conffiles" <<\EOF
/etc/runall/runall.conf
EOF

cd "${FNAME}"
find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf "%P " | xargs md5sum > "DEBIAN/md5sums"
cd -

fakeroot dpkg-deb --build "${FNAME}"

mv ${FNAME}.deb .