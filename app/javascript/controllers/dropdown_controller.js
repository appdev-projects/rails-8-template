import { Controller } from "@hotwired/stimulus"

// Dropdown Controller for Stimulus
//
// Toggles a dropdown menu open and closed. Replaces Bootstrap's
// data-bs-toggle="dropdown" behavior.
//
// Expected HTML Structure:
// ------------------------
// <div class="dropdown" data-controller="dropdown">
//   <button data-action="click->dropdown#toggle" aria-expanded="false">Open menu</button>
//
//   <ul class="dropdown-menu" data-dropdown-target="menu">
//     <li>...menu items...</li>
//   </ul>
// </div>
//
// The menu needs no markup to start closed: the stylesheet's
// `.dropdown-menu` rule is `display: none`, and the controller adds the
// `show` class to reveal it. The menu also closes when clicking anywhere
// else on the page or pressing the Escape key.
//
// Hiding is class-based (never the HTML `hidden` attribute) on purpose:
// it keeps menu items present in the DOM for tests and for CSS-less
// contexts, mirroring how Bootstrap's dropdowns behaved.
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this._open = false
    // Bound versions of the handlers so we can remove the exact same
    // listeners later
    this._boundClickOutside = this._clickOutside.bind(this)
    this._boundKeydown = this._keydown.bind(this)
  }

  toggle(event) {
    event.preventDefault()

    if (this._open) {
      this.close()
    } else {
      this.open(event.currentTarget)
    }
  }

  open(button) {
    this._open = true
    this.menuTarget.classList.add("show")
    this.menuTarget.classList.remove("hidden")
    button?.setAttribute("aria-expanded", "true")

    // Close when clicking outside the dropdown or pressing Escape
    document.addEventListener("click", this._boundClickOutside)
    document.addEventListener("keydown", this._boundKeydown)
  }

  close() {
    this._open = false
    this.menuTarget.classList.remove("show")
    this.menuTarget.classList.add("hidden")
    this.element.querySelector("[aria-expanded]")?.setAttribute("aria-expanded", "false")

    document.removeEventListener("click", this._boundClickOutside)
    document.removeEventListener("keydown", this._boundKeydown)
  }

  _clickOutside(e) {
    if (!this.element.contains(e.target)) this.close()
  }

  _keydown(e) {
    if (e.key === "Escape") this.close()
  }

  disconnect() {
    document.removeEventListener("click", this._boundClickOutside)
    document.removeEventListener("keydown", this._boundKeydown)
  }
}
