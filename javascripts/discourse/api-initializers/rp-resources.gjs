import { apiInitializer } from "discourse/lib/api";

export default apiInitializer((api) => {
  const redirectRowsData = [
    {
      id: "extra-link-literary-roleplay",
      imgSrc: settings.theme_uploads.literaryRPGuide,
      altText: "Link to A Guide to Literary Roleplay",
    },
    {
      id: "extra-link-spare-room",
      imgSrc: settings.theme_uploads.spareRoomHelp,
      altText: "Link to Spare Room RP Help Series on YouTube",
    },
    {
      id: "extra-link-internet-safety",
      imgSrc: settings.theme_uploads.internetSafety,
      altText: "Link to Internet Safety Carrd",
    },
    {
      id: "extra-link-talk-show",
      imgSrc: settings.theme_uploads.bmTalkShow,
      altText: "Link to Spotify Podcast",
    },
    {
      id: "extra-link-roleplay-index",
      imgSrc: settings.theme_uploads.roleplayIndex,
      altText: "Link to Roleplay Index",
    },
    {
      id: "extra-link-ad-guide",
      imgSrc: settings.theme_uploads.roleplayAdGuide,
      altText: "Link to Roleplay Ad Guide",
    },
  ];

  api.onPageChange(() => {
    const body = document.body;
    if (
      body?.classList.contains("navigation-categories") ||
      body?.classList.contains("categories-list")
    ) {
      const redirectRows = document.querySelectorAll(
        ".custom-category-group-rp-resources .custom-category-group li"
      );

      redirectRows.forEach((redirectRow) => {
        const rowData = redirectRowsData.find((data) =>
          redirectRow.classList.contains(data.id)
        );

        if (rowData) {
          const parentLink = redirectRow.querySelector("a.parent-box-link");
          const hrefLink = parentLink?.getAttribute("href") || "#";
          redirectRow.innerHTML = `
            <div class="redirect-image">
              <a href="${hrefLink}" target="_blank" title="${rowData.altText}">
                <img src="${rowData.imgSrc}" alt="${rowData.altText}" />
              </a>
            </div>
          `;
        }
      });
    }
  });
});