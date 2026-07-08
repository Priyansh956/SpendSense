const express = require('express');
const {addExpense, editExpense, deleteExpense, getAllTransactions, getTransactionsById} = require('../../controllers/transactionsController');
const { restrictToLoggedInUsersOnly } = require('../../middleware/auth');

const router = express.Router();

router.use(restrictToLoggedInUsersOnly);

router.post('/expenditure', addExpense);
router.patch('/expenditure/:id', editExpense);
router.delete('/expenditure/:id', deleteExpense);
router.get('/expenditure', getAllTransactions);
router.get('/expenditure/:id', getTransactionsById);

module.exports = router;