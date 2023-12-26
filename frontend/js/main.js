window.addEventListener('DOMContentLoaded', (event) => {
    getVisitCount();
});

const functionAPI = 'https://ray-resume-function.azurewebsites.net/api/HttpTrigger1?';

const getVisitCount = () => {
    let count = 30;
    fetch(functionAPI)
        .then(response => response.json())
        .then(response => {
            console.log("Website called function API.");
            count = response;
            console.log(count)
            document.getElementById("counter").innerText = count;
        })
        .catch(error => {
            console.log('Error fetching data:', error);
            document.getElementById("counter").innerText = count;
        });
}
