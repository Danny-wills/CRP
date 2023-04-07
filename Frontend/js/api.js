window.addEventListener("load", (event) => { fetch("https://cdnuzoe5r4.execute-api.us-east-1.amazonaws.com/prod/count")
    .then((response) => response.json())
    .then((data) => rendercount(data))
    .catch(()=> renderError());
});
function rendercount(data) {
    const visits = document.getElementById("visits");    
    counter.innerHTML = data.visits;    
}
function renderError() {
    const error = document.getElementById('error');    
    error.innerHTML = "Whoops, something went wrong. Please try again later!!";
    error.innerHTML = "";

}