Parse.Cloud.define('getAverageRating', function(request, response) {
	var RatingObject = Parse.Object.extend('GroupReviews');
	var query = new Parse.Query(RatingObject);
	
	query.equalTo('group', request.params.group);
	query.limit(200);
	query.find({
		success: function(results) {
			if (results.length > 0) {
				var sum = 0;
				for (var i = 0; i < results.length; ++i) {
					sum += results[i].get("rating");
				}				
				response.success(sum / results.length);
			}
			else {
				response.error("Average not available");
			} 
    	},
    	error: function(error) {
      		response.error('Oops something went wrong!');
    	}
	});
});
