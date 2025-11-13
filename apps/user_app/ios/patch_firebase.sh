#!/bin/bash
# Patch Firebase Messaging header to fix modular header issue
FIREBASE_HEADER="$HOME/.pub-cache/hosted/pub.dev/firebase_messaging-14.7.10/ios/Classes/FLTFirebaseMessagingPlugin.h"

if [ -f "$FIREBASE_HEADER" ]; then
  # Backup original
  cp "$FIREBASE_HEADER" "$FIREBASE_HEADER.bak"
  
  # Replace #import with @import
  sed -i '' 's/#import <Firebase\/Firebase\.h>/@import Firebase;/g' "$FIREBASE_HEADER"
  
  echo "✅ Patched Firebase Messaging header file"
else
  echo "⚠️  Firebase header not found at: $FIREBASE_HEADER"
fi
