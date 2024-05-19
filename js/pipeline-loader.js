---
# frontmatter vazio para fazer o parse do liquid
---
;

const pipeline = document.getElementById("pipeline")
const queryParams = new URLSearchParams(window.location.search.substring(1));

if (queryParams.get("status") === "true") {
    const pipelineIFrame = document.createElement("iframe")

    pipelineIFrame.loading = "lazy"
    pipelineIFrame.src = "{{ '/assets/pipeline-badge.html' | prepend: site.baseurl }}"
    pipelineIFrame.style["border-width"] = "0px"
    pipelineIFrame.height = "20px"
    pipelineIFrame.width = "116px"
    
    pipeline.style.display = "block";
    pipeline.appendChild(pipelineIFrame)

    let intervalId;

    function stopPipelineLoad() {
        clearInterval(intervalId);
        intervalId = null;
        document.getElementById("stopReload").style.display = "none";
        document.getElementById("playReload").style.display = "block";
    }

    function startPipelineLoad() {
        intervalId = setInterval(() => pipelineIFrame.contentWindow.location.reload()), 3000)

        document.getElementById("stopReload").style.display = "block";
        document.getElementById("playReload").style.display = "none";
    }

    startPipelineLoad()
    console.log("visivel")
} else {
    pipeline.remove();
    console.log("removido")
}