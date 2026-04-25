/* 41°23'16.6"N 2°06'34.9"E, y=41.38794 | x=2.109694; 
   41°23'17.2"N 2°06'55.1"E; y=41.38811 | x=2.115305;*/
const limit = {
    LowY: 41.38794,
    HighY: 41.38811,
    LowX: 2.109694,
    HighX: 2.115305
};
const warngss = document.querySelector('#warngss');
const proceed = document.querySelector('#Proceed');
const results = document.querySelector('#Result');

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
	if (distance <= 4) return 1000;
	if (distance <= 5) return 947;
	if (distance <= 6) return 832;
	if (distance <= 7) return 625;
	if (distance <= 8) return 373;
	if (distance <= 9) return 250;
	if (distance <= 12) return 100;
	return 0;
}

const CheckUbi = function(ActIfInside){
	navigator.geolocation.getCurrentPosition((position) => {
	    const { latitude: Y, longitude: X } = position.coords;

	    const Inside = 
	        Y >= limit.LowY && 
	        Y <= limit.HighY &&
	        X >= limit.LowX && 
	        X <= limit.HighX;

	if (!Inside) {
		error.classList.remove("hidden")
		setTimeout(() => {
	        error.classList.add("hidden");
	    }, 2000);
	}
	else {
		ActionIfInside();
	}
};



guess.onclick = function() {
	warngss.classList.remove("hidden");
}

search.onclick = () => {
	CheckUbi(() => {
		window.location.href = "Search.html";
	});
};

challenge.onclick = () => {
	CheckUbi(() => {
		window.location.href = "challenge.html";
	});
};

proceed.onclick = () => {
	navigator.geolocation.getCurrentPosition((position) => {
		const userLat = position.coords.latitude;
		const userLong = position.coords.longitude;
		const distance = EstimateDistance(userLat, userLong, targetUbi.lat, targetUbi.lon);
		const points = GainPoints(distance);
		warngss.classList.add("hidden");
		results.classList.remove("hidden");
		const txtdis = document.querySelector('#txtdis');
		const txtpnt = document.querySelector('#txtpnt');
		txtdis.innerText = `You are ${distance} meters away` ;
		txtpnt.innerText = `Points: ${points}`;
	});
}
