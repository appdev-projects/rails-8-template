import { Controller } from "@hotwired/stimulus"

// Dismiss Controller for Stimulus
//
// Removes an element from the page (e.g. a dismissible flash alert).
// Replaces Bootstrap's data-bs-dismiss="alert" behavior.
//
// Expected HTML Structure:
// ------------------------
// <div class="alert alert-success alert-dismissible" data-controller="dismiss">
//   A message!
//   <button class="btn-close" data-action="click->dismiss#remove" aria-label="Close"></button>
// </div>
export default class extends Controller {
  remove() {
    this.element.remove()
  }
}
