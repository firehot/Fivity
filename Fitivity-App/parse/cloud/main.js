Parse.Cloud.define('getAverageRating', function(request, response) {
  	var ReviewObject = Parse.Object.extend('GroupReviews');
  	var query = new Parse.Query(ReviewObject);
	
	var GroupObject = Parse.Object.extend("Groups");
	var query2 = new Parse.Query(GroupObject);
	
	query2.get(request.params.groupID, {
		success: function(group) {
			query.equalTo('group', group);
 			query.limit(200);
			query.find({
  				success: function(results) {
     				if (results.length > 0) {
       	 				var sum = 0;
        				for (var i = 0; i < results.length; i++) {
         	 				sum += results[i].get('rating');
        				}
        				response.success(sum / results.length);
     	 			} else {
        				response.error('Average not available');
      				}
    			},
    			error: function(error) {
      				response.error('Oups something went wrong');
    			}
  			});
		},
		error: function(object, error) {
			response.error('Could not find the group');
		}
	});
});
