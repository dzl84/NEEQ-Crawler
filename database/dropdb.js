// Drop neeqcrawler database and related user

db = db.getSiblingDB("neeqcrawler");
db.dropUser("crawler");
db.dropDatabase();
