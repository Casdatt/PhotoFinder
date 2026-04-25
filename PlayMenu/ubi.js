/* y=41.387359790855136 | x=2.109694; 
   y=41.3906296811951 | x=2.115305;*/
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
const challenge = document.getElementById("challenge")


const warngss = document.getElementById("warngss");
const warnff = document.getElementById("warnff")

const results = document.getElementById("Result");
const error = document.getElementById("errbox");
const broke = document.getElementById("brokebox")

const takeph = document.getElementById("Takeph");
const inputCamara = document.getElementById("inputCamara");

const Amcredits = 1;
let Credits = credits(Amcredits);

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
			ActIfInside();
		}
	});
}
if (document.getElementById("Pl")) {
	search.onclick = function() {
		CheckUbi(() => {
			window.location.href = "Search.html";
		});
	};
	challenge.onclick = function() {
		CheckUbi(() => {
			window.location.href = "challenge.html";
		});
	};
}

if (document.getElementById("Se")) {
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

function credits(Amcredits) {
	if (Amcredits > 0) {
		return true;
	}
	return false;
}

if (document.getElementById("Ch")) {
	takeph.onclick = function() {
		console.log({Credits, Amcredits})
		if (Credits) {
			CheckUbi(() => {
				inputCamara.click();
			});
		}
		else {
			broke.classList.remove("hidden")
			setTimeout(() => {
				broke.classList.add("hidden")
			}, 3000);
		}
	}

	inputCamara.onchange = function(e) {
		const photo = e.target.files[0]
		if (photo) {
			const reader = new FileReader();
			reader.onload = (event) => {
			};
			reader.readAsDataURL(photo);
		}
	};
}
