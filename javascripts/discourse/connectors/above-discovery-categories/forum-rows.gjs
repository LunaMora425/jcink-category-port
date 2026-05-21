/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { classNames } from "@ember-decorators/component";
import { and, or } from "discourse/truth-helpers";
import ForumRowsGroups from "../../components/forum-rows-groups";

// This connector injects our custom category layout above the default
// Discourse category list. The default list is hidden via CSS in common.scss.
// Using a classic component here (same pattern as discourse-category-groups-component)
// because Discourse's connector system passes outletArgs as a direct property
// on classic components.

@classNames("above-discovery-categories-outlet", "custom-forum-rows")
export default class ForumRowsConnector extends Component {
  <template>
    {{#if
      (or
        this.site.desktopView
        (and settings.show_on_mobile this.site.mobileView)
      )
    }}
      <ForumRowsGroups @categories={{this.outletArgs.categories}} />
    {{/if}}
  </template>
}
