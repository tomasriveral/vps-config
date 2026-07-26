import os
import time
import sqlite3
import requests
import subprocess

from urllib.parse import urlparse

def load_env_file(path=".env"):
    if not os.path.exists(path):
        return

    with open(path) as f:
        for line in f:
            line = line.strip()

            # ignore empty lines and comments
            if not line or line.startswith("#"):
                continue

            key, value = line.split("=", 1)
            os.environ.setdefault(key, value)


load_env_file()

FRESHRSS_DB = os.environ["FRESHRSS_DB"]
ARCHIVE_INDEX = os.environ["ARCHIVE_INDEX"]

METUBE_URL = os.environ["METUBE_URL"]
METUBE_USER = os.environ["METUBE_USER"]
METUBE_PASS = os.environ["METUBE_PASS"]

NTFY_URL = os.environ["NTFY_URL"]
NTFY_TOKEN = os.environ["NTFY_TOKEN"]

DOCKER_COMPOSE_DIR = os.environ["DOCKER_COMPOSE_DIR"]

VIDEO_HOSTS = {
    "youtube.com",
    "www.youtube.com",
    "youtu.be",
    "vimeo.com",
    "www.vimeo.com",
    "dailymotion.com",
    "www.dailymotion.com",
}

print("=== FreshRSS archiver starting ===")
print("Working directory:", os.getcwd())
print("Python:", os.sys.executable)
print("FreshRSS DB:", FRESHRSS_DB)
print("Archive index:", ARCHIVE_INDEX)

def get_favorites():
    conn = sqlite3.connect(FRESHRSS_DB)
    conn.row_factory = sqlite3.Row

    cur = conn.cursor()
    cur.execute("""
        SELECT title, link
        FROM entry
        WHERE is_favorite = 1
        ORDER BY date DESC
    """)

    result = [
        {
            "title": row["title"],
            "link": row["link"]
        }
        for row in cur.fetchall()
    ]

    conn.close()
    return result


def load_index():
    if not os.path.exists(ARCHIVE_INDEX):
        return set()

    with open(ARCHIVE_INDEX, "r") as f:
        return set(line.strip() for line in f if line.strip())


def save_to_index(url):
    with open(ARCHIVE_INDEX, "a") as f:
        f.write(url + "\n")


def is_video_url(url):
    host = urlparse(url).netloc.lower()
    return any(host.endswith(site) for site in VIDEO_HOSTS)


def send_to_metube(url):
    """
    MeTube API endpoint:
    POST /add
    """
    try:
        r = requests.post(
            f"{METUBE_URL}/add",
            json={
                "url": url
            },
            auth=(METUBE_USER, METUBE_PASS),
            timeout=30
        )

        return r.status_code in range(200, 300)

    except Exception as e:
        print("MeTube error:", e)
        return False

def send_to_archivebox(url):
    try:
        r = subprocess.run(
            [
                "docker",
                "compose",
                "-f",
                f"{DOCKER_COMPOSE_DIR}/compose.yml",
                "run",
                "-T",
                "archivebox",
                "archivebox",
                "add",
                url,
            ],
            capture_output=True,
            text=True,
            timeout=300
        )

        if r.returncode != 0:
            print("ArchiveBox error:")
            print(r.stderr)
            return False

        print(r.stdout)
        return True

    except Exception as e:
        print("ArchiveBox error:", e)
        return False

def notify_failure(url):
    try:
        requests.post(
            NTFY_URL + "/Alerts",
            data=f"Failed to archive {url}",
            auth=("", NTFY_TOKEN),
            timeout=10
        )
    except Exception as e:
        print("ntfy error:", e)


def process():
    indexed = load_index()
    favorites = get_favorites()

    for article in favorites:
        url = article["link"]

        if url in indexed:
            continue

        print("Archiving:", url)

        if is_video_url(url):
            success = send_to_metube(url)
        else:
            success = send_to_archivebox(url)

        if success:
            print("Success")
            save_to_index(url)
        else:
            print("Failed")
            notify_failure(url)

        # avoid hammering services
        time.sleep(60)


if __name__ == "__main__":
    process()
