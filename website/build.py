"""Build the two localized Pages routes with only the Python standard library."""
import argparse
import html
import json
from pathlib import Path
import re
import shutil
from urllib.parse import urlsplit, urlunsplit

ROOT = Path(__file__).resolve().parent
REPOSITORY = ROOT.parent
TOKEN = re.compile(r"\{\{([a-z0-9_]+)\}\}")


def build(destination, base_url):
    parts = urlsplit(base_url)
    if parts.scheme not in {"http", "https"} or not parts.netloc or parts.query or parts.fragment:
        raise ValueError("base URL must be an HTTP(S) site URL without query or fragment")
    # The existing Pages domain serves HTTPS; canonical links use that secure URL.
    base_url = urlunsplit(("https", parts.netloc, parts.path.rstrip("/"), "", ""))
    metadata = (REPOSITORY / "metadata.lua").read_text()
    version = re.search(r'PLUGIN.version = "([0-9.]+)"', metadata).group(1)
    min_version = re.search(r'PLUGIN.minRuntimeVersion = "([0-9.]+)"', metadata).group(1)
    utils = (REPOSITORY / "lib/utils.lua").read_text()
    supported = re.search(r"local windows_luabinaries_versions = \{([^}]+)\}", utils).group(1)
    windows_versions = ", ".join(re.findall(r'"([0-9.]+)"', supported))
    template = (ROOT / "template.html").read_text()
    keys = set(TOKEN.findall(template))
    destination.mkdir(parents=True, exist_ok=True)
    shutil.copytree(ROOT / "assets", destination / "assets", dirs_exist_ok=True)
    locales = []
    for locale, route, language in [("zh", "", "zh-CN"), ("en", "en/", "en")]:
        messages = json.loads((ROOT / "locales" / f"{locale}.json").read_text())
        locales.append(set(messages))
        messages = {key: value.format(min_version=min_version, windows_versions=windows_versions)
                    for key, value in messages.items()}
        messages.update(lang=language, version=version, asset_prefix="../" if route else "",
                        language_href="../" if route else "en/", language_lang="zh-CN" if route else "en", canonical=base_url + "/" + route,
                        site_url=base_url, copy_data=json.dumps({key: messages[key] for key in
                        ("copy", "copied", "copy_error")}, ensure_ascii=False))
        messages.pop("copied")
        messages.pop("copy_error")
        if set(messages) != keys:
            raise ValueError(f"{locale}: missing {keys - set(messages)}, unused {set(messages) - keys}")
        rendered = TOKEN.sub(lambda match: html.escape(messages[match[1]], quote=True), template)
        output = destination / route
        output.mkdir(parents=True, exist_ok=True)
        (output / "index.html").write_text(rendered)
    if locales[0] != locales[1]:
        raise ValueError("Chinese and English translation keys differ")
    (destination / ".nojekyll").touch()
    (destination / "robots.txt").write_text(f"User-agent: *\nAllow: /\nSitemap: {base_url}/sitemap.xml\n")
    (destination / "sitemap.xml").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
        "".join(f"<url><loc>{html.escape(base_url + '/' + route)}</loc></url>\n" for route in ("", "en/")) +
        "</urlset>\n")
    print(f"Built Chinese and English pages for plugin {version}: {destination}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=REPOSITORY / "_site")
    parser.add_argument("--base-url", default="https://shansan.top/vfox-lua")
    arguments = parser.parse_args()
    build(arguments.output, arguments.base_url)
