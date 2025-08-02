const toggleSwitch = document.querySelector("[role='switch']")

const THEMES = {
    "theme-light": "Tema claro",
    "theme-dark": "Tema escuro"
}

function setThemeLocalstorage(themeName) {
    localStorage.setItem("theme", themeName)
}

function getThemeLocalstorage() {
    const theme = localStorage.getItem("theme")
    return theme ?? "theme-light"
}

function setThemeLabel(themeName) {
    const toggleLabel = THEMES[themeName]
    const toggleWrapper = toggleSwitch.closest("label")
    toggleWrapper.ariaLabel = toggleLabel
}

toggleSwitch.addEventListener("click", ({ target }) => {
    const isToggled = target.checked
    const toggleClass = isToggled ? "theme-light" : "theme-dark"

    const currentClass = document.documentElement.className
    const hasTheme = Array.from(document.documentElement.classList).filter((classNames) =>
        Object.keys(THEMES).includes(classNames)
    ).length

    setThemeLabel(toggleClass)
    if (hasTheme) {
        document.documentElement.classList.replace(currentClass, toggleClass)
    } else {
        document.documentElement.classList.add(toggleClass)
    }

    toggleSwitch.checked = toggleClass === "theme-light"

    setThemeLocalstorage(toggleClass)
})

toggleSwitch.addEventListener("focus", (event) => {
    event.currentTarget.parentNode.classList.add("switch--focus")
})

toggleSwitch.addEventListener("blur", (event) => {
    event.currentTarget.parentNode.classList.remove("switch--focus")
})

window.addEventListener("DOMContentLoaded", () => {
    const theme = getThemeLocalstorage()
    setThemeLabel(theme)
    toggleSwitch.checked = theme === "theme-light"
})

function enableBeta() {
    const queryParams = new URLSearchParams(window.location.search.substring(1))
    if (queryParams.get("beta") === "true") {
        showBeta()
        changeBetaLink()
    }
}

function showBeta() {
    const betaElements = document.getElementsByClassName("beta")
    for (const betaElement of betaElements) {
        betaElement.setAttribute("data-beta", "true")
    }
}

function changeBetaLink() {
    const betaElements = document.getElementsByClassName("beta-link")
    for (const betaElement of betaElements) {
        if (
            betaElement.hasAttribute("href") &&
            betaElement.getAttribute("data-beta-applied") != "beta-applied"
        ) {
            betaElement.setAttribute("data-beta-applied", "beta-applied")
            betaElement.href += window.location.search
        }
    }
}

enableBeta()
