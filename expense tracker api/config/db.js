const dns = require('dns');
dns.setServers(['8.8.8.8', '8.8.4.4']);

const mongoose = require("mongoose");
mongoose.connect(process.env.MONGODB_URI).then( () => console.log("Connected to database!")).catch(err => console.log(`MongoDb error,${err}`));
