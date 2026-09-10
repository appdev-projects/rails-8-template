import { Controller } from "@hotwired/stimulus"

// Modal Controller for Stimulus
//
// This controller manages modal dialogs using the native HTML <dialog> element
// combined with the modal styling in tailwind.appdev.css.
//
// Expected HTML Structure:
// ------------------------
// <div data-controller="modal">
//   <!-- Button to open the modal -->
//   <button data-action="click->modal#open">Open Modal</button>
//
//   <!-- The modal dialog itself -->
//   <dialog data-modal-target="dialog">
//     <div class="card">
//       <header>
//         <!-- Close button (X) in the header -->
//         <button aria-label="Close" rel="prev" data-action="click->modal#close"></button>
//         <h3>Modal Title</h3>
//       </header>
//
//       <!-- Modal content goes here -->
//       <p>Your content...</p>
//
//       <footer>
//         <!-- Cancel and confirm buttons -->
//         <button type="button" data-action="click->modal#close">Cancel</button>
//         <button type="submit" data-action="click->modal#confirm">Confirm</button>
//       </footer>
//     </div>
//   </dialog>
// </div>
//
// The card inside the dialog can be written either way — <div class="card">
// or <article> — because the stylesheet styles both spellings.

export default class extends Controller {
  // Stimulus targets - defines which elements this controller can access
  // In the HTML, use data-modal-target="dialog" on the <dialog> element
  static targets = ["dialog"]
  
  // Stimulus values - configurable options for the controller
  // closeOnBackdrop: whether clicking outside the modal closes it (default: true)
  // Can be set in HTML with data-modal-close-on-backdrop-value="false"
  static values = { closeOnBackdrop: { type: Boolean, default: true } }
  
  // Called when the controller is connected to the DOM
  connect() {
    // Create bound versions of event handlers to maintain the correct 'this' context
    // This ensures we can properly remove these exact listeners later
    this._boundHandleBackdrop = this._handleBackdrop.bind(this)
    this._boundHandleCancel = this._handleCancel.bind(this)
    this._boundHandlePointerdown = this._handlePointerdown.bind(this)
  }

  // Opens the modal - triggered by data-action="click->modal#open"
  open(event) {
    // Prevent default action (e.g., form submission or link navigation)
    event?.preventDefault()
    
    // Store the currently focused element so we can return focus after closing
    // This is important for accessibility
    this._lastFocused = document.activeElement

    // Clear any leftover closing animation class from previous modal interactions
    // This prevents animation conflicts
    document.documentElement.classList.remove("modal-is-closing")
    
    // Add the stylesheet's modal classes to the <html> element:
    // - modal-is-open: locks scrolling on the page behind the modal
    // - modal-is-opening: triggers the opening animation
    document.documentElement.classList.add("modal-is-open", "modal-is-opening")

    // Get the dialog element using Stimulus targets
    const d = this.dialogTarget
    
    // Clean up any existing event listeners before adding new ones
    // This prevents duplicate listeners if the modal is opened multiple times
    this._removeEventListeners()
    
    // Add event listeners:
    // - "cancel": fired when user presses ESC key
    // - "pointerdown": to record where a press started (see _handleBackdrop)
    // - "click": to detect clicks on the backdrop (outside the modal content)
    d.addEventListener("cancel", this._boundHandleCancel)
    d.addEventListener("pointerdown", this._boundHandlePointerdown)
    d.addEventListener("click", this._boundHandleBackdrop)
    
    // Use the native HTML dialog showModal() method
    // This creates a modal with a backdrop and makes the rest of the page inert
    d.showModal()
    
    // Remove the opening animation class after the animation completes (200ms)
    // This matches our stylesheet's animation duration
    setTimeout(() => {
      document.documentElement.classList.remove("modal-is-opening")
    }, 200)
    
    // Focus management for accessibility:
    // First try to focus an element with [autofocus] attribute
    // If none exists, focus the first interactive element
    const focusable = d.querySelector("[autofocus]") || 
                     d.querySelector("button, [href], input, select, textarea, [tabindex]:not([tabindex='-1'])")
    focusable?.focus()
  }

  // Closes the modal - triggered by data-action="click->modal#close"
  close(event) {
    // Prevent default action
    event?.preventDefault()
    
    // Safety check: don't try to close if already closed
    if (!this.dialogTarget.open) return
    
    const d = this.dialogTarget
    
    // Add closing animation class to trigger the closing animation
    document.documentElement.classList.add("modal-is-closing")

    // Wait for closing animation to complete (200ms), then:
    setTimeout(() => {
      // Remove all modal-related classes from <html>
      document.documentElement.classList.remove("modal-is-closing", "modal-is-open")
      
      // Use native dialog close() method
      d.close()
      
      // Clean up event listeners to prevent memory leaks
      this._removeEventListeners()
      
      // Return focus to the element that opened the modal (accessibility)
      this._lastFocused?.focus()
    }, 200)
  }

  // Handles the confirm action - triggered by data-action="click->modal#confirm"
  // This is useful for forms or confirmation dialogs
  confirm(event) {
    event?.preventDefault()
    
    // Close the modal
    this.close()
    
    // Dispatch a custom 'confirm' event that other parts of your app can listen for
    // Example: document.querySelector('[data-controller="modal"]').addEventListener('modal:confirm', (e) => {...})
    this.dispatch("confirm")
  }

  // Private method: Finds the card that holds the modal's content
  // The <dialog> covers the whole viewport when modal, so anything outside
  // this element counts as the backdrop. Both spellings of a card are
  // accepted, and we fall back to the dialog's first child so a modal built
  // from some other markup still gets working backdrop clicks.
  _content() {
    return this.dialogTarget.querySelector("article, .card") ||
           this.dialogTarget.firstElementChild
  }

  // Private method: Records where a press (mousedown/touch) started
  // A "click" fires on release, so selecting text inside the modal and
  // releasing the mouse outside it would otherwise count as a backdrop
  // click and close the modal by mistake. We only treat a click as a
  // backdrop click if the press also STARTED on the backdrop.
  _handlePointerdown(e) {
    const content = this._content()
    this._pressStartedOnBackdrop = !content?.contains(e.target)
  }

  // Private method: Handles clicks on the modal backdrop
  _handleBackdrop(e) {
    // If the click target is NOT inside the card, it landed on the backdrop
    const content = this._content()

    // Only close if:
    // 1. Click was released outside the card (on the backdrop)
    // 2. The press also started on the backdrop (not a text-selection drag)
    // 3. closeOnBackdrop setting is true
    if (!content?.contains(e.target) && this._pressStartedOnBackdrop && this.closeOnBackdropValue) {
      this.close()
    }
  }

  // Private method: Handles the ESC key press (cancel event)
  _handleCancel(e) {
    // Prevent the default dialog closing behavior
    // We want to use our own close() method to handle animations
    e.preventDefault()
    this.close()
  }

  // Private method: Removes event listeners to prevent memory leaks
  _removeEventListeners() {
    const d = this.dialogTarget
    // Remove the bound listeners (must use the same references created in connect())
    d.removeEventListener("cancel", this._boundHandleCancel)
    d.removeEventListener("pointerdown", this._boundHandlePointerdown)
    d.removeEventListener("click", this._boundHandleBackdrop)
  }
  
  // Called when the controller is disconnected from the DOM
  disconnect() {
    // Clean up any remaining event listeners
    this._removeEventListeners()
  }
}
