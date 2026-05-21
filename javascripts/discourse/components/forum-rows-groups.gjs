import Component from "@glimmer/component";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import borderColor from "discourse/helpers/border-color";
import dIcon from "discourse/helpers/d-icon";
import lazyHash from "discourse/helpers/lazy-hash";
import PluginOutlet from "discourse/components/plugin-outlet";
import { slugify } from "discourse/lib/utilities";
import { i18n } from "discourse-i18n";
import ForumRowExtraLink from "./forum-row-extra-link";

// ---------------------------------------------------------------------------
// Module-level helpers — usable directly in <template> in GJS format
// ---------------------------------------------------------------------------

function parseSettings(settingsStr) {
  return settingsStr.split("|").map((i) => {
    const [categoryGroup, categories] = i.split(":").map((s) => s.trim());
    return { categoryGroup, categories: categories || "" };
  });
}

class ExtraLink {
  isExtraLink = true;
  constructor(args) {
    this.id = args.id;
    this.url = args.url;
    this.color = args.color;
    this.title = args.title;
    this.description = args.description;
    this.icon = args.icon;
  }
}

// Returns true when the category has topics the user hasn't read yet.
function hasNewActivity(category) {
  return (category.unreadTopics > 0) || (category.newTopics > 0);
}

// Returns the first featured topic for a category (the most recently active).
function getLastTopic(category) {
  return category.featuredTopics?.[0] ?? null;
}

// Returns the username of the last poster on a topic.
// Handles both camelCase (JS model) and snake_case (raw API object) property names.
function getLastPosterUsername(topic) {
  if (!topic) return "";
  return topic.lastPosterUsername ?? topic.last_poster_username ?? "";
}

// Returns a human-readable relative date string (e.g. "3h ago", "2d ago").
function getLastPostDate(topic) {
  if (!topic) return "";
  const raw = topic.bumpedAt ?? topic.bumped_at;
  if (!raw) return "";

  const d = new Date(raw);
  const diffMs = Date.now() - d;
  const mins = Math.floor(diffMs / 60_000);
  const hours = Math.floor(mins / 60);
  const days = Math.floor(hours / 24);

  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  if (hours < 24) return `${hours}h ago`;
  if (days < 30) return `${days}d ago`;
  return d.toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

// ---------------------------------------------------------------------------
// Main component
// ---------------------------------------------------------------------------

export default class ForumRowsGroups extends Component {
  @service router;
  @service siteSettings;

  // Only render on the main categories page when a "boxes" style is active.
  // Both "boxes_with_subcategories" and "boxes_with_featured_topics" satisfy this.
  get shouldShow() {
    return (
      this.router.currentRouteName === "discovery.categories" &&
      this.siteSettings.desktop_category_page_style.includes("boxes")
    );
  }

  // Builds the ordered list of groups from the component settings.
  // Logic is preserved from discourse-category-groups-component for compatibility.
  get categoryGroupList() {
    const parsedSettings = parseSettings(settings.category_groups);
    const extraLinks = JSON.parse(settings.extra_links || "[]");
    const foundCategorySlugs = [];

    const findExtraLink = (id) => extraLinks.find((l) => l.id === id);

    const groups = parsedSettings.reduce((acc, { categoryGroup, categories }) => {
      if (!categories) return acc;
      const items = [];

      categories.split(",").map((s) => s.trim()).forEach((slugOrId) => {
        const cat = this.args.categories.find(
          (c) => c.slug === slugOrId && !c.hasMuted
        );
        if (cat) {
          items.push(cat);
          foundCategorySlugs.push(cat.slug);
        } else {
          const link = findExtraLink(slugOrId);
          if (link) items.push(new ExtraLink(link));
        }
      });

      if (items.length > 0) acc.push({ name: categoryGroup, items });
      return acc;
    }, []);

    // Categories not assigned to any group
    if (settings.show_ungrouped) {
      const ungrouped = this.args.categories.filter(
        (c) =>
          !foundCategorySlugs.includes(c.slug) &&
          c.notification_level !== 0
      );
      if (ungrouped.length > 0) {
        groups.push({
          name: i18n(themePrefix("ungrouped_categories_title")),
          items: ungrouped,
        });
      }
    }

    // Muted categories (collapsed by default via localStorage)
    const mutedCategories = settings.hide_muted_subcategories
      ? this.args.categories.filter((c) => c.notification_level === 0)
      : this.args.categories.filter((c) => c.hasMuted);

    if (mutedCategories.length > 0) {
      groups.push({
        name: i18n(themePrefix("muted_categories_title")),
        items: mutedCategories,
      });
    }

    return groups;
  }

  // Restore collapsed/expanded state from localStorage on first render.
  @action
  initializeLocalStorage() {
    if (!localStorage.getItem("categoryGroups")) {
      // Mute group starts collapsed by default
      localStorage.setItem(
        "categoryGroups",
        JSON.stringify([
          `.custom-category-group-${slugify(i18n(themePrefix("muted_categories_title")))}`,
        ])
      );
    }
    const collapsed = JSON.parse(localStorage.getItem("categoryGroups")) || [];
    collapsed.forEach((selector) => {
      document.querySelector(selector)?.classList.remove("is-expanded");
    });
  }

  // Toggle a group's collapsed state and persist to localStorage.
  @action
  toggleGroup(name, event) {
    event.preventDefault();
    const selector = `.custom-category-group-${slugify(name)}`;
    const collapsed = JSON.parse(localStorage.getItem("categoryGroups")) || [];
    const idx = collapsed.indexOf(selector);
    const el = document.querySelector(selector);

    if (idx > -1) {
      collapsed.splice(idx, 1);
      el?.classList.add("is-expanded");
    } else {
      collapsed.push(selector);
      el?.classList.remove("is-expanded");
    }

    localStorage.setItem("categoryGroups", JSON.stringify(collapsed));
  }

  slugId(str) {
    return slugify(str);
  }

  <template>
    {{#if this.shouldShow}}
      <div
        class="custom-categories-groups"
        {{didInsert this.initializeLocalStorage}}
      >
        {{#each this.categoryGroupList as |group|}}
          <div
            class="custom-category-group-{{this.slugId group.name}} is-expanded"
          >
            {{! Ribbon-style group toggle header — styled by the main theme's
                .custom-category-group-toggle rules }}
            <a
              href="#{{this.slugId group.name}}"
              id={{this.slugId group.name}}
              class="custom-category-group-toggle"
              {{on "click" (fn this.toggleGroup group.name)}}
            >
              <h2>{{group.name}}</h2>
              {{dIcon "angle-right"}}
            </a>

            <ul class="custom-category-group forum-rows-list">
              {{#each group.items as |c|}}

                {{! ── Extra link (not a real category) ── }}
                {{#if c.isExtraLink}}
                  <ForumRowExtraLink @link={{c}} />

                {{! ── Real Discourse category ── }}
                {{else}}
                  <li
                    id="fr-{{c.id}}"
                    class="forum__row category-{{c.slug}}
                      {{if c.isMuted 'muted'}}"
                    data-category-id={{c.id}}
                    data-notification-level={{c.notificationLevelString}}
                    style={{borderColor c.color}}
                  >
                    <div class="forum__row-inner">

                      {{! Header row: stats left, new-activity indicator right }}
                      <div class="forum__row-header">
                        <div class="forum__row-stats">
                          <span class="stat-count">{{c.topicCount}}</span>
                          {{" "}}topics &amp;{{" "}}
                          <span class="stat-count">{{c.postCount}}</span>
                          {{" "}}posts
                        </div>
                        <div class="forum__row-indicator">
                          {{#if (hasNewActivity c)}}
                            <span
                              class="activity-dot activity-dot--new"
                              title="New or unread topics"
                            ></span>
                          {{else}}
                            <span
                              class="activity-dot activity-dot--read"
                              title="No new posts"
                            ></span>
                          {{/if}}
                        </div>
                      </div>

                      {{! Category title }}
                      <div class="forum__row-name">
                        <a href={{c.url}}>{{c.name}}</a>
                      </div>

                      {{! Description }}
                      {{#if c.description_excerpt}}
                        <div class="forum__row-desc">
                          {{htmlSafe c.description_excerpt}}
                        </div>
                      {{/if}}

                      {{! Last post info }}
                      {{#let (getLastTopic c) as |topic|}}
                        {{#if topic}}
                          <a href={{topic.url}} class="forum__row-lastpost">
                            {{topic.title}}
                          </a>
                          <div class="forum__row-lastposter">
                            By:
                            <a
                              href="/u/{{getLastPosterUsername topic}}"
                              class="lastposter-username"
                            >{{getLastPosterUsername topic}}</a>
                            <span class="post-time">
                              {{getLastPostDate topic}}
                            </span>
                          </div>
                        {{/if}}
                      {{/let}}

                    </div>

                    {{! Subcategory pills — rendered outside forum__row-inner
                        so they sit in their own bottom strip }}
                    {{#if c.subcategories.length}}
                      <div class="forum__row-subforums">
                        {{#each c.subcategories as |sc|}}
                          <a href={{sc.url}} class="subforum-link">
                            {{sc.name}}
                          </a>
                        {{/each}}
                      </div>
                    {{/if}}

                    {{! Plugin outlet for other components to hook into }}
                    <PluginOutlet
                      @name="forum-row-below-category"
                      @outletArgs={{lazyHash category=c}}
                    />

                  </li>
                {{/if}}

              {{/each}}
            </ul>
          </div>
        {{/each}}
      </div>
    {{/if}}
  </template>
}
