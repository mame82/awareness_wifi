#!/bin/bash
zipalign -v -p 4 app-release-unsigned.apk app-release-unsigned-aligned.apk
apksigner sign --ks release.keystore --ks-pass pass:MaMe82pass --key-pass pass:MaMe82pass --out app-release-signed-aligned.apk --in app-release-unsigned-aligned.apk
