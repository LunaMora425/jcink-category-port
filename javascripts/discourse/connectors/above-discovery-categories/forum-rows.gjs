/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { classNames } from "@ember-decorators/component";
import { and, or } from "discourse/truth-helpers";
import ForumRowsGroups from "../../components/forum-rows-groups";

@classNames("above-discovery-categories-outlet", "custom-forum-rows")
export default class ForumRowsConnector extends Component {
  <template>
    {{#if
      (or
        this.site.desktopView (and settings.show_on_mobile this.site.mobileView)
      )
    }}
      <ForumRowsGroups @categories={{this.outletArgs.categories}} />
    {{/if}}
  </template>
}
