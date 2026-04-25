/* 41°23'16.6"N 2°06'34.9"E, y=41.38794 | x=2.109694; 
   41°23'17.2"N 2°06'55.1"E; y=41.38811 | x=2.115305;*/
const limit = {
    LowY: 41.387359790855136,
    HighY: 41.39062968119511,
    LowX: 2.109694,
    HighX: 2.115305
};

const guess = document.getElementById("guess");
const forfeit = document.getElementById("forfeit");
const proceed = document.getElementById("Proceed");
const npcd = document.getElementById("Npcd")
const nprd = document.getElementById("Nprd")

const search = document.getElementById("search")

const warngss = document.getElementById("warngss");
const warnff = document.getElementById("warnff")

const results = document.getElementById("Result");
const error = document.getElementById("errbox");
const broke = document.getElementById("brokebox")

const takeph = document.getElementById("Takeph");
const takeph2 = document.getElementById("Takeph2");
const takeph3 = document.getElementById("Takeph3");
const inputCamara = document.getElementById("inputCamara");
const inputCamara2 = document.getElementById("inputCamara2");
const inputCamara3 = document.getElementById("inputCamara3");

let Amcredits = 10;

let targetUbi = { lat: 0, lon: 0 };

function EstimateDistance(lat1, lon1, lat2, lon2) {
	const R = 6371e3; 											// Earth radius
	const phi1 = lat1 * Math.PI / 180;
	const phi2 = lat2 * Math.PI / 180;
	const deltaPhi = (lat2 - lat1) * Math.PI / 180;
	const deltaLambda = (lon2 - lon1) * Math.PI / 180;
	const a = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) + Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c; 												// distance in meters
}

function GainPoints(distance) {
	if (distance <= 1) return 1000;
	if (distance <= 2) return 947;
	if (distance <= 3) return 632;
	if (distance <= 4) return 425;
	if (distance <= 5) return 173;
	return 0;
}
let lastPosition = null;
const CheckUbi = function(ActIfInside) {
	navigator.geolocation.getCurrentPosition((position) => {
	    const { latitude: Y, longitude: X } = position.coords;

	    const Inside = 
	        Y >= limit.LowY && 
	        Y <= limit.HighY &&
	        X >= limit.LowX && 
	        X <= limit.HighX;

		if (!Inside) {
			console.log("Y, X", {Y, X});
			error.classList.remove("hidden")
			setTimeout(() => {
	  	    	error.classList.add("hidden");
	   		}, 2000);
		}
		else {
            lastPosition = position.coords;
			ActIfInside();
		}
	});
}
if (document.getElementById("Pl")) {
	search.onclick = function() {
		CheckUbi(() => {
			window.location.href = "/search";
		});
	};
}

if (document.getElementById("Se")) {

	fetch("/api/globo/random")
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                console.error("Error de API:", data.error);
            } else {
                const imgElement = document.querySelector('.igm');
                if (imgElement) {
                    imgElement.src = data.image_path;
                }
                targetUbi.lat = data.lat;
                targetUbi.lon = data.lon;
            }
        })
        .catch(err => console.error("Error loading image:", err));

	guess.onclick = function() {
		warngss.classList.remove("hidden");
	}

	forfeit.onclick = function() {
		warnff.classList.remove("hidden")
	}

	proceed.onclick = function() {
		navigator.geolocation.getCurrentPosition((position) => {
			const userLat = position.coords.latitude;
			const userLong = position.coords.longitude;
			const distance = EstimateDistance(userLat, userLong, targetUbi.lat, targetUbi.lon);
			const points = GainPoints(distance);
			warngss.classList.add("hidden");
			results.classList.remove("hidden");
			const txtdis = document.querySelector('#txtdis');
			const txtpnt = document.querySelector('#txtpnt');
			txtdis.innerText = `You are ${distance.toFixed(2)} meters away` ;
			txtpnt.innerText = `Points: ${points}`;
		});
	}
	npcd.onclick = function() {
		warngss.classList.add("hidden")
	}
	nprd.onclick = function() {
		warnff.classList.add("hidden")
	}
}

if (document.getElementById("Ch")) {
    const slots = [
        { btn: document.getElementById("Takeph"), input: document.getElementById("inputCamara"), cost: 2 },
        { btn: document.getElementById("Takeph2"), input: document.getElementById("inputCamara2"), cost: 4 },
        { btn: document.getElementById("Takeph3"), input: document.getElementById("inputCamara3"), cost: 7 }
    ];

    function setupPhotoHandler(buttonEl, inputEl, cost) {
        buttonEl.onclick = function() {
            if (Amcredits >= cost) {
                CheckUbi(() => inputEl.click());
            } else {
                broke.classList.remove("hidden");
                setTimeout(() => broke.classList.add("hidden"), 3000);
            }
        };

        inputEl.onchange = function(e) {
            const photo = e.target.files[0];
            CheckUbi(() => {
            console.log("cualquier cosa")
            if (photo && lastPosition) {
                const form = new FormData();
                form.append("image", photo);
                form.append("lat", lastPosition.latitude);
                form.append("lon", lastPosition.longitude);

                fetch("/api/globo/upload", {
                    method: "POST",
                    credentials: "include",
                    body: form
                })

                .then(response => response.json())
                .then(data => {
                    if (data.error) return console.error(data.error);

                    const reader = new FileReader();
                    reader.onload = (event) => {
                        buttonEl.src = event.target.result;
                        const creditLabel = buttonEl.parentElement.querySelector('h1');
                        if (creditLabel) creditLabel.style.visibility = 'hidden';

                        const durationSeconds = 7200;
                        const endTime = Date.now() + (durationSeconds * 1000);
                        
                        startUnixTimer(buttonEl.parentElement, creditLabel, endTime, buttonEl, data.rating);
                    };
                    reader.readAsDataURL(photo);
                    Amcredits -= cost;
                });
            }
        });
    };
	}
    function startUnixTimer(container, creditLabel, endTime, imageEl, score) {
        const oldInfo = container.querySelector('.slot-info');
        if (oldInfo) oldInfo.remove();

        const infoDiv = document.createElement('div');
        infoDiv.className = 'slot-info';
        
        const starPercentage = (parseFloat(score) / 5) * 100;

        infoDiv.innerHTML = `
            <div class="timer" style="color: white; font-family: monospace; font-size: 1.1rem;">Time left: --:--:--</div>
            <div class="stars-outer">
                <div class="stars-inner" style="width: ${starPercentage}%"></div>
            </div>
            <div style="font-size: 0.8rem; color: white; margin-top: 2px;">Rating: ${score}</div>
        `;
        container.appendChild(infoDiv);

        const timerDisplay = infoDiv.querySelector('.timer');

        const interval = setInterval(() => {
            const now = Date.now();
            const timeLeftMs = endTime - now;

            if (timeLeftMs <= 0) {
                clearInterval(interval);
                timerDisplay.innerText = "Time left: 00:00:00";
                setTimeout(() => {
                    infoDiv.remove();
                    imageEl.src = "add.png";
                    creditLabel.style.visibility = 'visible';
                }, 1000);
            } else {
                const totalSeconds = Math.floor(timeLeftMs / 1000);
                const hrs = Math.floor(totalSeconds / 3600).toString().padStart(2, '0');
                const mins = Math.floor((totalSeconds % 3600) / 60).toString().padStart(2, '0');
                const secs = (totalSeconds % 60).toString().padStart(2, '0');
                timerDisplay.innerText = `Time left: ${hrs}:${mins}:${secs}`;
            }
        }, 500);
    }

    slots.forEach(slot => setupPhotoHandler(slot.btn, slot.input, slot.cost));
}
