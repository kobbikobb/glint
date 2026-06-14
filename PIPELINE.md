# Glint — CI/CD & Deployment

## Prerequisites

- Apple Developer Program ($99/yr)
- GitHub repository (`glint/glint`)
- GitHub repository (`glint/homebrew-tap`)

## Apple certificates & secrets

| Secret | What it is | How to get |
|---|---|---|
| `MACOS_CERTIFICATE` | Developer ID Application cert (.p12, base64) | Keychain Access → Export |
| `MACOS_CERTIFICATE_PWD` | Password for the .p12 | Created during export |
| `NOTARY_API_KEY` | App Store Connect API key (.p8, base64) | Apple Developer Portal → Keys |
| `NOTARY_API_KEY_ID` | Key ID (10 chars) | Same page |
| `NOTARY_API_ISSUER_ID` | Issuer UUID | Same page |
| `GH_PAT` | GitHub PAT with `repo` scope | GitHub Settings → Tokens |

## Pipeline overview

```
git tag v1.0.0  ──►  GitHub Actions  ──►  signed + notarized .app.zip
       │                                         │
       │                                         ▼
       │                               GitHub Release (draft)
       │                                         │
       │                                         ▼
       │                               homebrew-tap formula updated
       │                                         │
       │                                         ▼
       │                               Release published
       │
       ▼
  brew update && brew upgrade glint
```

## GitHub Actions workflow

```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags:
      - 'v*'

jobs:
  build-macos:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app

      - name: Import signing certificate
        env:
          CERT_B64: ${{ secrets.MACOS_CERTIFICATE }}
          CERT_PWD: ${{ secrets.MACOS_CERTIFICATE_PWD }}
        run: |
          echo "$CERT_B64" | base64 --decode > /tmp/cert.p12
          security create-keychain -p temp /tmp/build.keychain
          security unlock-keychain -p temp /tmp/build.keychain
          security import /tmp/cert.p12 -k /tmp/build.keychain \
            -P "$CERT_PWD" -T /usr/bin/codesign
          security set-key-partition-list \
            -S apple-tool:,apple:,codesign: -s -k temp /tmp/build.keychain

      - name: Build and archive
        run: |
          xcodebuild archive \
            -scheme Glint \
            -configuration Release \
            -archivePath /tmp/Glint.xcarchive \
            -derivedDataPath /tmp/derived

      - name: Export .app
        run: |
          xcodebuild -exportArchive \
            -archivePath /tmp/Glint.xcarchive \
            -exportPath /tmp/export \
            -exportOptionsPlist export.plist

      - name: Sign (should already be signed — verify)
        run: codesign -dv --verbose=4 /tmp/export/Glint.app

      - name: Notarize
        env:
          KEY_B64: ${{ secrets.NOTARY_API_KEY }}
          KEY_ID: ${{ secrets.NOTARY_API_KEY_ID }}
          ISSUER: ${{ secrets.NOTARY_API_ISSUER_ID }}
        run: |
          echo "$KEY_B64" | base64 --decode > /tmp/authkey.p8
          xcrun notarytool submit /tmp/export/Glint.app \
            --apple-id "$ISSUER" \
            --team-id "$KEY_ID" \
            --key /tmp/authkey.p8 \
            --wait
          xcrun stapler staple /tmp/export/Glint.app

      - name: Package
        run: |
          ditto -c -k --keepParent /tmp/export/Glint.app /tmp/Glint.zip
          shasum -a 256 /tmp/Glint.zip | cut -d' ' -f1 > /tmp/checksum.txt

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ github.ref_name }}
          name: Glint ${{ github.ref_name }}
          draft: true
          generate_release_notes: true
          files: |
            /tmp/Glint.zip

      - name: Update Homebrew tap
        env:
          GH_PAT: ${{ secrets.GH_PAT }}
          VERSION: ${{ github.ref_name }}
        run: |
          SHA=$(cat /tmp/checksum.txt)
          git clone https://x-access-token:$GH_PAT@github.com/glint/homebrew-tap.git
          cd homebrew-tap
          sed -i '' "s/version \".*\"/version \"${VERSION#v}\"/" Formula/glint.rb
          sed -i '' "s/sha256 \".*\"/sha256 \"$SHA\"/" Formula/glint.rb
          git config user.name "github-actions"
          git config user.email "github-actions@github.com"
          git add Formula/glint.rb
          git commit -m "Glint ${VERSION#v}"
          git push
```

## export.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>teamID</key>
  <string>YOUR_TEAM_ID</string>
  <key>signingStyle</key>
  <string>manual</string>
</dict>
</plist>
```

## Homebrew tap repository

Separate repo: `github.com/glint/homebrew-tap`

```
homebrew-tap/
├── Formula/
│   └── glint.rb
└── README.md
```

### glint.rb

```ruby
class Glint < Formula
  desc "Your morning glint — daily summary from calendar, email, and social"
  homepage "https://github.com/glint/glint"
  version "1.0.0"
  license "MIT"

  on_macos do
    url "https://github.com/glint/glint/releases/download/v1.0.0/Glint.zip"
    sha256 "abc123..."

    depends_on :macos => :ventura
  end

  def install
    app.install "Glint.app"
  end

  def caveats
    <<~EOS
      Glint runs as a menu bar app. Launch it from Applications.
    EOS
  end

  test do
    assert_predicate "/Applications/Glint.app", :exist?
  end
end
```

## Installation for users

```bash
brew tap glint/tap
brew install glint
# Or once it's in homebrew-core:
brew install glint
```

## Manual release checklist (for debugging)

```bash
# Local build + sign
xcodebuild archive -scheme Glint -configuration Release -archivePath /tmp/G.xcarchive
xcodebuild -exportArchive -archivePath /tmp/G.xcarchive -exportPath /tmp/out -exportOptionsPlist export.plist

# Notarize
xcrun notarytool submit /tmp/out/Glint.app --key ~/AuthKey.p8 --key-id XXXX --issuer YYYY --wait
xcrun stapler staple /tmp/out/Glint.app

# Package
ditto -c -k --keepParent /tmp/out/Glint.app /tmp/Glint.zip
shasum -a 256 /tmp/Glint.zip
```
