// Initialize database and collections in MongoDB

db = db.getSiblingDB("neeqcrawler");
result = db.createUser({user: "crawler", pwd: "ca$hc0w", roles: ["readWrite"]});
db.auth("crawler", "ca$hc0w");
db.schemaversion.insert({version: 1});
