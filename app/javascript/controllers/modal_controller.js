import { Controller } from "@hotwired/stimulus"

// Modal Controller for Stimulus
// 
// This controller manages modal dialogs using the native HTML <dialog> element
// combined with Pico CSS framework's modal styling classes.
//
// Expected HTML Structure:
// ------------------------
// <div data-controller="modal">
//   <!-- Button to open the modal -->
//   <button data-action="click->modal#open">Open Modal</button>
//   
//   <!-- The modal dialog itself -->
//   <dialog data-modal-target="dialog">
//     <article>
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
//     </article>
//   </dialog>
// </div>

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
    
    // Add Pico CSS framework classes to the <html> element:
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
    // - "click": to detect clicks on the backdrop (outside the modal content)
    d.addEventListener("cancel", this._boundHandleCancel)
    d.addEventListener("click", this._boundHandleBackdrop)
    
    // Use the native HTML dialog showModal() method
    // This creates a modal with a backdrop and makes the rest of the page inert
    d.showModal()
    
    // Remove the opening animation class after the animation completes (400ms)
    // This matches Pico CSS's animation duration
    setTimeout(() => {
      document.documentElement.classList.remove("modal-is-opening")
    }, 400)
    
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
    
    // Add closing animation class to trigger Pico CSS closing animation
    document.documentElement.classList.add("modal-is-closing")

    // Wait for closing animation to complete (400ms), then:
    setTimeout(() => {
      // Remove all modal-related classes from <html>
      document.documentElement.classList.remove("modal-is-closing", "modal-is-open")
      
      // Use native dialog close() method
      d.close()
      
      // Clean up event listeners to prevent memory leaks
      this._removeEventListeners()
      
      // Return focus to the element that opened the modal (accessibility)
      this._lastFocused?.focus()
    }, 400)
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

  // Private method: Handles clicks on the modal backdrop
  _handleBackdrop(e) {
    // The <dialog> element covers the entire viewport when modal
    // The <article> inside it is the actual modal content
    // If the click target is NOT inside the article, it's on the backdrop
    const article = this.dialogTarget.querySelector("article")
    
    // Only close if:
    // 1. Click was outside the article (on the backdrop)
    // 2. closeOnBackdrop setting is true
    if (!article.contains(e.target) && this.closeOnBackdropValue) {
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
    d.removeEventListener("click", this._boundHandleBackdrop)
  }
  
  // Called when the controller is disconnected from the DOM
  disconnect() {
    // Clean up any remaining event listeners
    this._removeEventListeners()
  }
}
