import { apiInitializer } from "discourse/lib/api";

// The card graphics themselves are THEME-owned (each theme defines
// --bm-gfx-* vars in its color_definitions.scss; see THEME-ARCHITECTURE.md
// rule 5). This initializer only builds the link markup — the image arrives
// via CSS background-image in common.scss, which falls back to this
// component's bundled assets when a theme doesn't define the vars.
export default apiInitializer((api) => {
  const redirectRowsData = [
    {
      id: "extra-link-literary-roleplay",
      altText: "Link to A Guide to Literary Roleplay",
    },
    {
      id: "extra-link-spare-room",
      altText: "Link to Spare Room RP Help Series on YouTube",
    },
    {
      id: "extra-link-internet-safety",
      altText: "Link to Internet Safety Carrd",
    },
    {
      id: "extra-link-talk-show",
      altText: "Link to Spotify Podcast",
    },
    {
      id: "extra-link-roleplay-index",
      altText: "Link to Roleplay Index",
    },
    {
      id: "extra-link-ad-guide",
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
          // Already swapped on a previous page change — re-running would
          // re-query the (now gone) original link and stomp the href.
          if (redirectRow.querySelector(".redirect-image")) {
            return;
          }
          // The extra-link rows are rendered by forum-row-extra-link.gjs,
          // which puts the outbound URL on .forum__row-name a
          // (a.parent-box-link only exists in core's category-boxes markup).
          const parentLink = redirectRow.querySelector(
            ".forum__row-name a, a.parent-box-link"
          );
          const hrefLink = parentLink?.getAttribute("href") || "#";
          redirectRow.innerHTML = `
            <div class="redirect-image">
              <a href="${hrefLink}" target="_blank" title="${rowData.altText}" aria-label="${rowData.altText}"></a>
            </div>
          `;
        }
      });
    }
  });
});
