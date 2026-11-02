const OWNER = "KaiHubz";
const REPO = "Roblox-AutoMatch";
const BRANCH = "main";
const FILE = "KaiHubz.lua";

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === "/release") {
      return Response.json({
        name: "KaiHubz AutoMatch",
        latest: "V12 Clean Test",
        version: 12,
        channel: "stable",
        status: "online"
      });
    }

    if (url.pathname === "/script") {
      const response = await fetch(
        `https://api.github.com/repos/${OWNER}/${REPO}/contents/${FILE}?ref=${BRANCH}`,
        {
          headers: {
            Authorization: `Bearer ${env.GITHUB_TOKEN}`,
            Accept: "application/vnd.github.raw+json",
            "User-Agent": "KaiHubz-AutoMatch"
          }
        }
      );

      if (!response.ok) {
        return new Response("GitHub file unavailable", {
          status: response.status
        });
      }

      return new Response(await response.text(), {
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "no-store"
        }
      });
    }

    return new Response("Not Found", { status: 404 });
  }
};
