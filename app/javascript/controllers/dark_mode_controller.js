import { Controller } from "@hotwired/stimulus"

// Dark Mode Controller for Stimulus
//
// Toggles the site between light and dark themes by stamping
// data-theme="dark" (or "light") on the <html> element. Our stylesheet's
// design tokens and Tailwind's dark: utilities both key off that
// attribute. The choice is remembered in localStorage; first-time
// visitors get their operating system's preference.
//
// Usage — attach to the toggle button itself:
//   <button data-controller="dark-mode" data-action="click->dark-mode#toggle"></button>
export default class extends Controller {
  connect() {
    const saved = localStorage.getItem("theme")
    const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches
    const initial = saved || (systemPrefersDark ? "dark" : "light")
    this.setTheme(initial)
  }

  toggle(event) {
    event.preventDefault()
    const current = document.documentElement.getAttribute("data-theme")
    const next = current === "dark" ? "light" : "dark"
    this.setTheme(next)
  }

  setTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme)
    localStorage.setItem("theme", theme)
    this.updateButton(theme)
  }

  updateButton(theme) {
    if (this.element.tagName !== "BUTTON") return
    this.element.textContent = theme === "dark" ? "☀️ Light" : "🌙 Dark"
  }
}
