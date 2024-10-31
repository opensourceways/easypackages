import requests
import datetime

# PyPI JSON API URL to get recent updates
RECENT_UPDATES_URL = "https://pypi.org/rss/updates.xml"


def fetch_recent_updates():
    """Fetch recent package updates from PyPI."""

    response = requests.get(RECENT_UPDATES_URL)
    if response.status_code == 200:
        return response.text
    else:
        print(f"Failed to fetch recent updates."
              f" Status code: {response.status_code}")
        return None


def parse_rss(xml_data):
    """Parse the RSS feed and extract package update information."""

    from xml.etree import ElementTree

    # Parse the XML data
    root = ElementTree.fromstring(xml_data)
    packages = []

    # Iterate over the items in the RSS feed
    for item in root.findall("./channel/item"):
        title = item.find("title").text
        link = item.find("link").text
        pub_date = item.find("pubDate").text

        # Convert pubDate to a datetime object with the corrected format
        pub_date_obj = (datetime.datetime.
                        strptime(pub_date,
                                 "%a, %d %b %Y %H:%M:%S %Z"))

        packages.append({
            "title": title,
            "link": link,
            "pub_date": pub_date_obj
        })

    return packages


def get_top_100_update_packages():
    # Fetch the recent updates XML data
    xml_data = fetch_recent_updates()
    if not xml_data:
        return None

    # Parse the RSS feed and extract package info
    packages = parse_rss(xml_data)
    res = []
    for package in packages:
        parts = package['title'].split()
        # print(f"{parts[0]}")
        res.append(parts[0])
    return res


def main():
    # # Fetch the recent updates XML data
    # xml_data = fetch_recent_updates()
    # if not xml_data:
    #     return

    # # Parse the RSS feed and extract package info
    # packages = parse_rss(xml_data)

    # # Print the recent packages with their published dates
    # print(f"Recent package updates on PyPI:")
    # for package in packages:
    #     print(f"{package['title']} - "
    #           f"{package['pub_date']} - "
    #           f"{package['link']}")
    get_top_100_update_packages()


if __name__ == "__main__":
    main()
