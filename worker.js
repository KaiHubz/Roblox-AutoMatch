export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname === "/") {
      return Response.json({
        name: "KaiHubz AutoMatch",
        version: "V12 Clean",
        status: "online"
      });
    }

    if (url.pathname === "/version") {
      return Response.json({
        latest: "V12 Clean",
        version: 12
      });
    }

    return new Response("Not Found", { status: 404 });
  }
};
