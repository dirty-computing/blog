const toggleSwitch = document.querySelector("[role='switch']")

toggleSwitch.addEventListener("click", ({ target }) => {
    const currentClass = document.body.className
    const isToggled = target.checked
    const toggleLabel = isToggled ? "Tema claro" : "Tema escuro"
    const toggleClass = isToggled ? "theme-light" : "theme-dark"

    const togleWrapper = target.closest("label")
    togleWrapper.ariaLabel = toggleLabel
    document.body.classList.replace(currentClass, toggleClass)
})

toggleSwitch.addEventListener("focus", (event) => { 
    event.currentTarget.parentNode.classList.add('switch--focus')
})

toggleSwitch.addEventListener("blur", (event) => {
    event.currentTarget.parentNode.classList.remove('switch--focus')
})

function enableBeta() {
    const queryParams = new URLSearchParams(window.location.search.substring(1))
    if (queryParams.get("beta") === "true") {
        showBeta();
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
        if (betaElement.hasAttribute("href") && betaElement.dataset.betaApplied != "beta-applied") {
            betaElement.dataset.betaApplied = "beta-applied"
            betaElement.href += window.location.search
        }
    }
}

enableBeta()