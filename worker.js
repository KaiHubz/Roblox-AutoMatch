
const OWNER = "KaiHubz";
const REPO = "Roblox-AutoMatch";
const BRANCH = "main";
const FILE = "KaiHubz.lua";

const RELEASE = {
  name: "KaiHubz AutoMatch",
  latest: "V12 Clean Test",
  version: 12,
  channel: "stable",
  status: "online"
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method !== "GET") {
      return new Response("Method Not Allowed", { status: 405 });
    }

    if (url.pathname === "/") {
      return Response.json(RELEASE);
    }

    if (url.pathname === "/version") {
      return Response.json({
        latest: RELEASE.latest,
        version: RELEASE.version
      });
    }

    if (url.pathname === "/release") {
      return Response.json(RELEASE);
    }

    if (url.pathname === "/health") {
      return Response.json({ status: "online" });
    }

    if (url.pathname === "/script") {
      if (!env.GITHUB_TOKEN) {
        return new Response("Missing GITHUB_TOKEN secret", {
          status: 500
        });
      }

      const githubUrl =
        `https://api.github.com/repos/${OWNER}/${REPO}/contents/${FILE}?ref=${BRANCH}`;

      try {
        const response = await fetch(githubUrl, {
          headers: {
            Authorization: `Bearer ${env.GITHUB_TOKEN}`,
            Accept: "application/vnd.github.raw+json",
            "User-Agent": "KaiHubz-AutoMatch"
          }
        });

        if (!response.ok) {
          const details = await response.text();

          return new Response(
            `GitHub error: ${response.status}\n${details}`,
            {
              status: 502,
              headers: {
                "Content-Type": "text/plain; charset=utf-8"
              }
            }
          );
        }

        const lua = await response.text();

        return new Response(lua, {
          headers: {
            "Content-Type": "text/plain; charset=utf-8",
            "Cache-Control": "no-store"
          }
        });
      } catch (error) {
        return new Response("Worker error: " + error.message, {
          status: 500
        });
      }
    }

    return new Response("Not Found", { status: 404 });
  }
};
