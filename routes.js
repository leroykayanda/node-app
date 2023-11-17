const express = require('express')
const router = express.Router()
const http = require('http');
const register = require('./prometheus/prometheus');
const db = require('./db')
const redis = require('./redis')

router.get('/', (req, res) => {
    //app index page
    res.send(`This is a simple node app`);
});

router.get('/status', async (req, res) => {
    //this route returns the application's current status

    //check if app is healthy

    //GET request to localhost
    const serverUrl = 'http://localhost:3000/';

    http.get(serverUrl, (resp) => {
        const statusCode = resp.statusCode;
        let status = '';

        if (statusCode === 200) {
            status = 'HEALTHY';
        } else {
            status = `UNHEALTHY  - (${statusCode})`;
        }

        const msg = `App Status: ${status}`
        console.log(msg)
        res.send(msg);
    }).on('error', (err) => {
        console.error('Error:', err.message);
    });

});

router.post('/data', (req, res) => {
    //this route is used to retrieve a JSON POST parameter containing product details and stores it in the database

    const product = req.body
    id = product.id
    name = product.name
    price = product.price

    //add product to DB

    //first check if product exists

    let sql = 'SELECT COUNT(*) AS productCount FROM Products WHERE id = ?';
    db.query(sql, [id], (error, results) => {
        if (error) {
            console.error('Error executing query: ' + error.stack);
            return res.status(500).send('Error executing query: ' + error.stack);
        }
        const productCount = results[0].productCount;

        if (productCount > 0) {
            const msg = `A product with ID ${id} already exists`
            console.error(msg);
            return res.status(400).send(msg);
        }

        //the product does not exist, add it to the db
        sql = 'INSERT INTO Products (id, name, price) VALUES (?, ?, ?)';
        db.query(sql, [id, name, price], (error, results) => {
            if (error) {
                console.error('Error executing query: ' + error.stack);
                return res.status(500).send('Error executing query: ' + error.stack);
            }
            const msg = `Product with iD ${id} has been added`
            console.log(msg)
            res.send(msg)
        });

    });

});

router.get('/product/:id', async (req, res) => {
    //this route is used to retrieve a product given its ID

    //get ID from parameter
    const id = req.params.id

    //try to get product from redis
    let product = ''
    product = await redis.get(id);

    if (product !== null) {
        //cache hit - get product from redis

        console.log(`Product with ID ${id} found in Redis`);
        product = JSON.parse(product)
        res.send(product)
        return
    }

    //cache miss
    //get product from DB

    //first check if product exists

    let sql = 'SELECT COUNT(*) AS productCount FROM Products WHERE id = ?';
    db.query(sql, [id], (error, results) => {
        if (error) {
            console.error('Error executing query: ' + error.stack);
            return res.status(500).send('Error executing query: ' + error.stack);
        }
        const productCount = results[0].productCount;

        if (productCount == 0) {
            const msg = `A product with an ID of ${id} does not exist`
            console.error(msg);
            return res.status(400).send(msg);
        }

        //product exists, fetch it

        sql = 'SELECT * FROM Products WHERE id = ?';
        db.query(sql, [id], (error, results) => {
            if (error) {
                console.error('Error executing query: ' + error.stack);
                return res.status(500).send('Error executing query: ' + error.stack);
            }
            const result = results[0];
            let id = result.id;
            let name = result.name;
            let price = result.price;

            product = {
                "id": id,
                "name": name,
                "price": price
            }

            //write product to redis with a TTL of 1h
            // Convert JSON object to string before storing in Redis
            redis.set(id.toString(), JSON.stringify(product));
            redis.expire(id.toString(), 3600)
            console.log(`Product with ID ${id} has been stored in Redis`)

            //convert response to JSON
            const msg = `Product with ID ${id} has been retrieved from the DB`
            console.log(msg)
            res.json(product)
        });

    });

});

//this route will be scraped by the prometheus server every 5s for default Node metrics
router.get('/metrics', async (req, res) => {
    res.setHeader('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
});


module.exports = router