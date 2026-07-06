const {transaction} = require('../models/transactionsModel');
const {asyncWrapper} = require('../services/asyncWrapper');
const {NotFoundError} = require('../services/errorHandlers');

// Add expense
const addExpense = asyncWrapper(async(req, res, next) => {
    const {expenditureCategory, amount, category, date, note} = req.body;

    if(!expenditureCategory) return res.status(400).json({
        "message": "Choose the expenditure type",
        "success": false,
    });
    
    if(!amount) return res.status(400).json({
        "message": "Enter the amount",
        "success": false,
    });

    if(!category) return res.status(400).json({
        "message": "Choose the category",
        "success": false,
    });

    if(!date) return res.status(400).json({
        "message": "Enter the date",
        "success": false,
    });

    const new_transaction = await transaction.create({
        userId: req.user._id,
        expenditureCategory,
        amount,
        category,
        date,
        note,
    });

    return res.status(201).json({
        "message": "Transaction logged successfully",
        "data": new_transaction,
        "success": true,
    });
})

// Edit expense
const editExpense = asyncWrapper(async(req, res, next) => {
    const {id} = req.params;
    const {expenditureCategory, amount, category, date, note} = req.body;

    const updated_transaction = await transaction.findOneAndUpdate(
        { _id: id, userId: req.user._id },
        { expenditureCategory, amount, category, date, note },
        { new: true, runValidators: true }
    );

    if (!updated_transaction) {
        return res.status(404).json({ message: "Transaction not found", success: false });
    }

    return res.status(200).json({
        "message": "Transaction updated successfully",
        "data": updated_transaction,
        "success": true,
    });
    
})

// Delete expense
const deleteExpense = asyncWrapper(async(req, res, next)=> {
    const {id} = req.params;
    const deletedTransaction = await transaction.findOneAndDelete({ _id: id, userId: req.user._id});

    return res.status(200).json({
        "message": "Transaction delete successfully",
        "data": deletedTransaction,
        "success": true,
    });
})

// Get all expenses (pagination implemented)
const getAllTransactions = asyncWrapper(async (req, res, next) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    
    const skip = (page - 1) * limit;

    const {category} = req.query;
    const filter = {userId: req.user._id};
    
    if(category) filter.category = category;

    const [transactions, total] = await Promise.all([
        transaction.find(filter)
            .sort({ date: -1 }) // Sort descending so newest expenses appear on Page 1
            .skip(skip)
            .limit(limit),
        transaction.countDocuments(filter)
    ]);

    return res.status(200).json({
        message: "Transactions fetched",
        success: true,
        data: transactions,
        meta: {
            currentPage: page,
            limit: limit,
            totalItems: total,
            totalPages: Math.ceil(total / limit) 
        }
    });
});

// Get particular expense
const getTransactionsById = asyncWrapper(async (req, res, next) => {
    const {id} = req.params;    

    const transactionFetched = await transaction.findOne({
        userId: req.user._id,
        _id: id,
    });

    if (!transactionFetched) {
        throw new NotFoundError("Transaction"); 
    }
    
    return res.status(200).json({
        "message": "Transactions fetched",
        "success": true,
        "data": transactionFetched  ,
    });
});

// Get expenses of a particular category
// const getAllTransactionsByCategory = asyncWrapper(async (req, res, next) => {
//     const {category} = req.query;

//     const query = {
//         userId: req.user._id,
//         category: category,
//     }

//     const categoricalTransactions = await transaction.find(query); 

//     return res.status(200).json({
//         "message": "Expenses fetched categorically",
//         "success": true,
//         "data": categoricalTransactions,
//     })
// });

module.exports = {
    addExpense,
    editExpense,
    deleteExpense,
    getAllTransactions,
    getTransactionsById,
};