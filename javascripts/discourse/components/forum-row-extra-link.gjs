import Component from "@glimmer/component";
import CookText from "discourse/components/cook-text";
import borderColor from "discourse/helpers/border-color";
import dIcon from "discourse/helpers/d-icon";

// Renders a "lite" row for extra links — no stats or last-post column,
// just icon + title + description. These are not real Discourse categories,
// so they have none of the category model's computed properties.

export default class ForumRowExtraLink extends Component {
  get colorForHelper() {
    // borderColor helper expects a hex string WITHOUT the leading #
    const c = this.args.link.color || "000000";
    return c.startsWith("#") ? c.slice(1) : c;
  }

  <template>
    <li
      style={{borderColor this.colorForHelper}}
      class="forum__row forum__row--extra-link extra-link-{{@link.id}}"
    >
      <div class="forum__row-inner">
        <div class="forum__row-header">
          {{#if @link.icon}}
            <span class="forum__row-icon">
              {{dIcon @link.icon}}
            </span>
          {{/if}}
          <div class="forum__row-name">
            <a href={{@link.url}}>{{@link.title}}</a>
          </div>
        </div>

        {{#if @link.description}}
          <div class="forum__row-desc">
            <CookText @rawText={{@link.description}} />
          </div>
        {{/if}}
      </div>
    </li>
  </template>
}
