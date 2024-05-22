async function citation2clipboard(title, slug) {
    try {
        await navigator.clipboard.writeText(`[${title}]({% post_url ${slug} %})`)
        console.log("citação copiada")
    } catch (e) {
        console.log("erro ocorreu")
    }
}

{
    const citationCopier = document.getElementById("citationCopier");

    function enableOrDisableCitationCopier() {
        const localStorageCite = localStorage.getItem("computaria-cite");
        if (citationCopier) {
            const styleDisplay = localStorageCite === "true"? "block": "none";
            citationCopier.style.display = styleDisplay
        }
    }

    enableOrDisableCitationCopier();
    // para detecção multi-aba: mudança em uma aba implica mudança na local
    window.addEventListener("storage", event => {
        if (event.key == "computaria-cite" || !event.key) {
            enableOrDisableCitationCopier();
        }
    });
}