$(document).ready(function(){
	if ("geolocation" in navigator) {
		console.log("geolocation is available")
	} else {
		console.log("geolocation IS NOT available")
	}

	// function prompt(window, pref, message, callback) {
	// 	let branch = Components.classes["@mozilla.org/preferences-service;1"]
	// 	.getService(Components.interfaces.nsIPrefBranch);

	// 	if (branch.getPrefType(pref) === branch.PREF_STRING) {
	// 		switch (branch.getCharPref(pref)) {
	// 			case "always":
	// 			return callback(true);
	// 			case "never":
	// 			return callback(false);
	// 		}
	// 	}

	// 	let done = false;

	// 	function remember(value, result) {
	// 		return function() {
	// 			done = true;
	// 			branch.setCharPref(pref, value);
	// 			callback(result);
	// 		}
	// 	}

	// 	let self = window.PopupNotifications.show(
	// 		window.gBrowser.selectedBrowser,
	// 		"geolocation",
	// 		message,
	// 		"geo-notification-icon",
	// 		{
	// 			label: "Share Location",
	// 			accessKey: "S",
	// 			callback: function(notification) {
	// 				done = true;
	// 				callback(true);
	// 			}
	// 		}, [
	// 		{
	// 			label: "Always Share",
	// 			accessKey: "A",
	// 			callback: remember("always", true)
	// 		},
	// 		{
	// 			label: "Never Share",
	// 			accessKey: "N",
	// 			callback: remember("never", false)
	// 		}
	// 		], {
	// 			eventCallback: function(event) {
	// 				if (event === "dismissed") {
	// 					if (!done) callback(false);
	// 					done = true;
	// 					window.PopupNotifications.remove(self);
	// 				}
	// 			},
	// 			persistWhileVisible: true
	// 		});
	// }

	// prompt(window,
	// 	"extensions.foo-addon.allowGeolocation",
	// 	"Foo Add-on wants to know your location.",
	// 	function callback(allowed) { alert(allowed); });

	$('.geo').on('click', function(e) {
		var output = document.getElementById("out");
		e.preventDefault();
		if (!navigator.geolocation){
			output.innerHTML = "<p>Geolocation is not supported by your browser. Please input your address below.</p>";
			return;
		}

		function success(position) {
			var latitude  = position.coords.latitude;
			var longitude = position.coords.longitude;
			var latlng = latitude + ',' + longitude;
			initialize();
			codeLatLng(latitude, longitude, latlng);
		};

		function error() {
			output.innerHTML = "Unable to retrieve your location. Please input your address.";
		};
		navigator.geolocation.getCurrentPosition(success, error);
	});

	var geocoder;
	var map;
	var infowindow = new google.maps.InfoWindow();
	var marker;

	function initialize() {
		geocoder = new google.maps.Geocoder();

	}

	function codeLatLng(lat, lng, latlng) {
		var latlng = new google.maps.LatLng(lat, lng);
		geocoder.geocode({'latLng': latlng}, function(results, status) {
			if (status == google.maps.GeocoderStatus.OK) {
				var elem = document.getElementById("address");
				elem.value = results[0].formatted_address;
			} else {
				alert("Geocoder failed due to: " + status);
			}
		});
	}


	$('.location').on('click', function() {
		if ($('#address').val().length==0) {
			$('.error.address').show();
			return false;
		}
	});

	$($('.toggle').next()).hide();


	$('.toggle').click(function() {
		$($(this).next()).slideToggle("slow", function(){
		});
	});

});



	// $('form.start').on('submit', function (e) {
	// 	// e.preventDefault();
	// 	$('body').css("background-color","blue");
	// });