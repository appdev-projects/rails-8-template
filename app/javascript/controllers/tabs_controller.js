import { Controller } from "@hotwired/stimulus"

// Tabs Controller for Stimulus
//
// Switches between tab panels. Replaces Bootstrap's
// data-bs-toggle="tab" behavior.
//
// Expected HTML Structure:
// ------------------------
// <div data-controller="tabs">
//   <ul class="nav nav-underline" role="tablist">
//     <li><button class="nav-link active" data-tabs-target="tab"
//                 data-action="click->tabs#select"
//                 aria-controls="posts-pane" aria-selected="true">Posts</button></li>
//     <li><button class="nav-link" data-tabs-target="tab"
//                 data-action="click->tabs#select"
//                 aria-controls="likes-pane" aria-selected="false">Likes</button></li>
//   </ul>
//
//   <div id="posts-pane" class="tab-pane active" data-tabs-target="panel">...</div>
//   <div id="likes-pane" class="tab-pane" data-tabs-target="panel">...</div>
// </div>
//
// Each tab button's aria-controls names the id of the panel it reveals.
// Panels are hidden by CSS by default (a `.tab-pane` rule or a `hidden`
// utility class); the active one gets the `active` class. Hiding is
// class-based (not the HTML `hidden` attribute) on purpose: it keeps
// panel content reachable in CSS-less contexts, mirroring how
// Bootstrap's tabs behaved.
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const selectedTab = event.currentTarget
    const panelId = selectedTab.getAttribute("aria-controls")

    this.tabTargets.forEach((tab) => {
      const active = tab === selectedTab
      tab.classList.toggle("active", active)
      tab.setAttribute("aria-selected", active)
    })

    this.panelTargets.forEach((panel) => {
      const active = panel.id === panelId
      panel.classList.toggle("active", active)
      panel.classList.toggle("hidden", !active)
    })
  }
}
