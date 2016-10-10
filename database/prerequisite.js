// Prerequisite of the database setup for MongoDB v3.2
// Check if the login user has 'userAdminAnyDatabase' role
// If not, add it to the user.

conn = new Mongo();
username = db.runCommand({connectionStatus: 1}).authInfo.authenticatedUsers[0].user;
user = db.getUser(username);
cur_roles = [];
need_role = true;
for(i = 0; i < user.roles.length; i++) {
	if(user.roles[i].role == "userAdminAnyDatabase") {
		print(username + " has userAdminAnyDatabase role, skip the role setup");
		need_role = false;
		break;
	}else{
		cur_roles.push(user.roles[i].role);
	}
}
if(need_role) {
	print("Updating " + username + " with new roles");
	cur_roles.push("userAdminAnyDatabase");
	db.updateUser(username, {roles: cur_roles});
}