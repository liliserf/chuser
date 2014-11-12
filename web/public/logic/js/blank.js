$(document).ready(function(){
	if ("geolocation" in navigator) {
		console.log("geolocation is available")
	} else {
		console.log("geolocation IS NOT available")
	}

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