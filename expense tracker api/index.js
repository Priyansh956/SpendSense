// Importing modules
require('dotenv').config();
require('./config/db'); 
const express = require('express');
const cors = require('cors');
const authRouter = require('./routes/auth/user');
const transactionRouter = require('./routes/transactions/transactions');
const friendsRouter = require('./routes/friends/friends');
const splitwiseRouter = require('./routes/splitwise/splitwise');
const { errorHandler } = require('./middleware/errorHandler');

const app = express();

// Middleware
app.use(cors());
app.use(express.urlencoded({extended: false}));
app.use(express.json());

// Mounting routers
app.use('/auth', authRouter);
app.use('/transactions', transactionRouter);
app.use('/friends', friendsRouter);
app.use('/splitwise', splitwiseRouter);

app.use(errorHandler);

const port = parseInt(process.env.PORT) || 8000;
app.listen(port, () => {
    console.log(`Served successfully started at PORT number: ${port}`);
});
