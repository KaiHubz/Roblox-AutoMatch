const RELEASE = {
  name: "KaiHubz AutoMatch",
  version: 12,
  latest: "V12 Clean Test",
  status: "online",
  channel: "stable"
};

export default {
  async fetch(request) {
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
      return Response.json({
        name: RELEASE.name,
        latest: RELEASE.latest,
        version: RELEASE.version,
        channel: RELEASE.channel,
        status: RELEASE.status
      });
    }

    if (url.pathname === "/health") {
      return Response.json({ status: "online" });
    }

    return new Response("Not Found", { status: 404 });
  }
};


