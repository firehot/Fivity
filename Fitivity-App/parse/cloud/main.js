Parse.Cloud.define('getAverageRating', function(request, response) {
	var RatingObject = Parse.Object.extend('GroupReviews');
	var query = new Parse.Query(RatingObject);
	
	var GroupObject = Parse.Object.extend('Group');
	var groupQuery = new Parse.Query(GroupObject);
	var groupRef = Parse.Object.extend('Group');
	
	groupQuery.get(request.params.groupID {
		success: function(group) {
			groupRef = group;
		},
		error: function(error) {
			response.error('Couldn\'t get group reference');
		}
	});
	
	query.equalTo('group', groupRef);
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
