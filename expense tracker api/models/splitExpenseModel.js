const mongoose = require('mongoose');

const splitParticipantSchema = new mongoose.Schema({
  uid: { type: String, required: true },
  email: { type: String, required: true },
  displayName: { type: String, required: true },
  amount: { type: Number, required: true },
  isPaid: { type: Boolean, default: false },
});

const splitExpenseSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },
    totalAmount: { type: Number, required: true },
    category: { type: String, required: true },
    paidByUid: { type: String, required: true },
    paidByEmail: { type: String, required: true },
    paidByName: { type: String, required: true },
    participants: { type: [splitParticipantSchema], required: true },
    date: { type: Date, required: true },
    note: { type: String },
    isSettled: { type: Boolean, default: false },
    involvedUids: { type: [String], required: true },
  },
  { timestamps: true },
);

const SplitExpense = mongoose.model('splitExpense', splitExpenseSchema);

module.exports = { SplitExpense };