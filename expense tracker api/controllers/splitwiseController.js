const { SplitExpense } = require('../models/splitExpenseModel');

async function createSplitExpense(req, res) {
  try {
    const payload = req.body;
    const userId = req.user._id;

    if (!payload || !payload.title || !payload.participants) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    const involvedUids = payload.involvedUids || [payload.paidByUid, ...payload.participants.map((p) => p.uid)];

    const expense = await SplitExpense.create({
      ...payload,
      involvedUids,
    });

    return res.status(201).json({ success: true, message: 'Split expense created', data: expense });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Failed to create split expense' });
  }
}

async function listSplitExpenses(req, res) {
  try {
    const expenses = await SplitExpense.find({ involvedUids: req.user._id }).sort({ date: -1 });
    return res.status(200).json({ success: true, data: expenses });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Failed to fetch split expenses' });
  }
}

async function markParticipantPaid(req, res) {
  try {
    const { id, participantUid } = req.params;
    const expense = await SplitExpense.findOne({ _id: id, involvedUids: req.user._id });
    if (!expense) {
      return res.status(404).json({ success: false, message: 'Expense not found' });
    }

    const participant = expense.participants.find((p) => p.uid === participantUid);
    if (!participant) {
      return res.status(404).json({ success: false, message: 'Participant not found' });
    }

    participant.isPaid = true;
    expense.isSettled = expense.participants.every((p) => p.isPaid);

    await expense.save();

    return res.status(200).json({ success: true, message: 'Participant marked paid', data: expense });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Failed to update participant payment' });
  }
}

async function settleExpense(req, res) {
  try {
    const { id } = req.params;
    const expense = await SplitExpense.findOneAndUpdate(
      { _id: id, involvedUids: req.user._id },
      { isSettled: true },
      { new: true },
    );

    if (!expense) {
      return res.status(404).json({ success: false, message: 'Expense not found' });
    }

    return res.status(200).json({ success: true, message: 'Expense settled', data: expense });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Failed to settle expense' });
  }
}

async function deleteSplitExpense(req, res) {
  try {
    const { id } = req.params;
    const expense = await SplitExpense.findOneAndDelete({ _id: id, involvedUids: req.user._id });

    if (!expense) {
      return res.status(404).json({ success: false, message: 'Expense not found' });
    }

    return res.status(200).json({ success: true, message: 'Expense deleted' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Failed to delete expense' });
  }
}

module.exports = {
  createSplitExpense,
  listSplitExpenses,
  markParticipantPaid,
  settleExpense,
  deleteSplitExpense,
};