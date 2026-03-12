function updateStatus() {
    fetch('/status')
        .then(response => response.text())
        .then(text => {
            document.getElementById('status-text').innerText = text;
        })
        .catch(error => console.error('Error fetching status:', error));
}
updateStatus(); // Load initial status
setInterval(updateStatus, 10000);
