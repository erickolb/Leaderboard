"""Generate a SideStore/AltStore Classic source from public iOS release IPAs."""
import io
import json
import os
from pathlib import Path
import plistlib
import re
import time
import urllib.request
import zipfile

REPO = "erickolb/Leaderboard"
SITE = "https://erickolb.github.io/Leaderboard"
BUNDLE = "me.erickolb.Leaderboard"
TAG = re.compile(r"leaderboard-v(\d+(?:\.\d+)+)-build([1-9]\d*)")


def download(url):
    headers = {"User-Agent": "Leaderboard-SideStore-source"}
    if url.startswith("https://api.github.com/") and os.environ.get("GH_TOKEN"):
        headers["Authorization"] = "Bearer " + os.environ["GH_TOKEN"]
    for attempt in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=45) as response:
                return response.read()
        except OSError:
            if attempt == 3:
                raise
            time.sleep(5)


def releases():
    result = []
    page = 1
    while True:
        batch = json.loads(download(f"https://api.github.com/repos/{REPO}/releases?per_page=100&page={page}"))
        result.extend(batch)
        if len(batch) < 100:
            return result
        page += 1


def make_source(items, fetch=download):
    candidates = []
    for release in items:
        match = TAG.fullmatch(release["tag_name"])
        if match and not release["draft"]:
            candidates.append((tuple(map(int, match[1].split("."))) + (int(match[2]),), release))
    candidates.sort(key=lambda item: item[0], reverse=True)
    versions, privacy, seen = [], {}, set()
    for numbers, release in candidates:
        version = ".".join(map(str, numbers[:-1]))
        # Classic sources use marketing versions. Keep the newest build of each.
        if version in seen:
            continue
        assets = [a for a in release["assets"] if a["name"] == "Leaderboard.ipa"]
        if len(assets) != 1:
            raise ValueError(f"{release['tag_name']}: expected one Leaderboard.ipa; publish after uploading assets")
        asset = assets[0]
        data = fetch(asset["browser_download_url"])
        if len(data) != asset["size"] or not data:
            raise ValueError("IPA size does not match release metadata")
        with zipfile.ZipFile(io.BytesIO(data)) as ipa:
            paths = [p for p in ipa.namelist() if re.fullmatch(r"Payload/[^/]+\.app/Info.plist", p)]
            if len(paths) != 1:
                raise ValueError("Expected one main app")
            info = plistlib.loads(ipa.read(paths[0]))
            for path in ipa.namelist():
                if path.endswith('.appex/Info.plist'):
                    extension = plistlib.loads(ipa.read(path))
                    if not extension['CFBundleIdentifier'].startswith(BUNDLE + '.'):
                        raise ValueError('Unexpected extension identity')
                    if (extension['CFBundleShortVersionString'], str(extension['CFBundleVersion'])) != (version, str(numbers[-1])):
                        raise ValueError('Extension version differs from app')
                    privacy.update({k: v for k, v in extension.items() if k.startswith('NS') and k.endswith('UsageDescription')})
        if (info["CFBundleIdentifier"], info["CFBundleShortVersionString"], str(info["CFBundleVersion"])) != (BUNDLE, version, str(numbers[-1])):
            raise ValueError(f"{release['tag_name']}: IPA identity/version differs from release tag")
        privacy.update({k: v for k, v in info.items() if k.startswith("NS") and k.endswith("UsageDescription")})
        versions.append({
            "version": version, "buildVersion": str(numbers[-1]),
            "date": release["published_at"],
            "localizedDescription": release.get("body") or release["name"],
            "downloadURL": asset["browser_download_url"],
            "size": len(data),
            "minOSVersion": info["MinimumOSVersion"],
        })
        seen.add(version)
    if not versions:
        raise ValueError("No published stable iOS IPAs found")
    app = {
        "name": "Leaderboard", "bundleIdentifier": BUNDLE,
        "developerName": "Chateau Lore", "subtitle": "Rank and share your favorite things",
        "localizedDescription": "Create ranked lists, reorder items, and share rankings. Includes an Amazon Music share extension.",
        "iconURL": SITE + "/assets/icon.png", "tintColor": "673B61",
        "versions": versions,
        "appPermissions": {"entitlements": ["com.apple.security.application-groups"], "privacy": privacy},
    }
    # Compatibility with older source readers.
    latest = versions[0]
    app.update({"version": latest["version"], "versionDate": latest["date"],
                "versionDescription": latest["localizedDescription"],
                "downloadURL": latest["downloadURL"], "size": latest["size"]})
    return {"name": "Leaderboard · Chateau Lore", "identifier": "me.erickolb.Leaderboard.source",
            "sourceURL": SITE + "/apps.json", "website": SITE + "/",
            "iconURL": SITE + "/assets/icon.png", "tintColor": "673B61",
            "apps": [app], "news": []}


if __name__ == "__main__":
    source = make_source(releases())
    target = Path(__file__).resolve().parents[1] / "docs" / "apps.json"
    target.write_text(json.dumps(source, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    latest = source['apps'][0]['versions'][0]
    page = target.with_name('index.html')
    template = Path(__file__).with_name('index.template.html').read_text(encoding='utf-8')
    page.write_text(template.replace('{{VERSION}}', latest['version']).replace('{{BUILD}}', latest['buildVersion']).replace('{{DOWNLOAD}}', latest['downloadURL']), encoding='utf-8')
    print(f"Generated {target.name}: {len(source['apps'][0]['versions'])} iOS versions, latest {source['apps'][0]['version']}")
