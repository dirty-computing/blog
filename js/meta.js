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
        betaElement.setAttribute("data-beta", "true")
    }
}

function changeBetaLink() {
    const betaElements = document.getElementsByClassName("beta-link")
    for (const betaElement of betaElements) {
        if (betaElement.hasAttribute("href") && betaElement.getAttribute("data-beta-applied") != "beta-applied") {
            betaElement.setAttribute("data-beta-applied", "beta-applied")
            betaElement.href += window.location.search
        }
    }
}

enableBeta()