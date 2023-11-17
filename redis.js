const dotenv = require('dotenv');
dotenv.config();
const redis = require('redis');

const client = redis.createClient({
    url: process.env.REDIS_URL
});

client.on('error', (err) => {
    console.log(`Error ${err}`);
});

client.connect().then(() => {
    console.log('Connected to Redis');
}).catch(err => {
    console.log('Failed to connect to Redis', err);
});

module.exports = client;
