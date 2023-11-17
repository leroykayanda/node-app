const express = require('express');
const app = express();
const routes = require('./routes');

//middleware that allows express to parse JSON request bodies
app.use(express.json());

//define routes in sepatrate file to make code neater
app.use(routes)

//get port from env variable. If env is undefined, use 3000 as the default
const PORT = process.env.APPLICATION_PORT || 3000;
app.listen(PORT, () => console.log(`App available on http://localhost:${PORT}`))