const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user',
        required: true,
    },
    title: {
        type: String,
        required: true,
    },
    expenditureCategory:{
        type: String,
        required: true,
    },
    amount:{
        type: Number,
        required: true,
    },
    category:{
        type: String,
        required: true,
    },
    date:{
        type: Date,
        required: true,
    },
    note:{
        type: String,
    },
});

const transaction = mongoose.model('expenses', transactionSchema);

module.exports = {transaction};