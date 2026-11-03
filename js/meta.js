const toggleSwitch = document.querySelector("[role='switch']")

const toggleChangeListener = [
];

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

function changeTheme(isToggled) {
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
    return toggleClass
}

toggleSwitch.addEventListener("click", ({ target }) => {
    changeToggleSwitchState(target)
})

function changeToggleSwitchState(toggleSwitchComponent) {
    const isToggled = toggleSwitchComponent.checked
    const toggleClass = changeTheme(isToggled)
    for (const listener of toggleChangeListener) {
        listener(toggleClass);
    }
    return toggleClass;
}

toggleSwitch.addEventListener("focus", (event) => {
    event.currentTarget.parentNode.classList.add("switch--focus")
})

toggleSwitch.addEventListener("blur", (event) => {
    event.currentTarget.parentNode.classList.remove("switch--focus")
})

function applyChangeTheme(theme) {
    const isToggled = theme === "theme-light"

    changeTheme(isToggled)
}

window.addEventListener("DOMContentLoaded", () => {
    applyChangeTheme(getThemeLocalstorage())
})

// para detecção multi-aba: mudança em uma aba implica mudança na local
window.addEventListener("storage", event => {
    if (event.key == "theme" || !event.key) {
        applyChangeTheme(event.newValue);
    }
});

function addToggleChangeListener(listener) {
    toggleChangeListener.push(listener);
}

addToggleChangeListener(setThemeLocalstorage)

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
        betaElement.dataset.beta = true
    }
}

function changeBetaLink() {
    const betaElements = document.getElementsByClassName("beta-link")
    for (const betaElement of betaElements) {
        if (
            betaElement.hasAttribute("href") &&
            betaElement.dataset.betaApplied != "beta-applied"
        ) {
            betaElement.dataset.betaApplied = "beta-applied"
            betaElement.href += window.location.search
        }
    }
}

enableBeta()
