$(document).ready(function(){
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