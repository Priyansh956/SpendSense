const express = require('express');
const { restrictToLoggedInUsersOnly } = require('../../middleware/auth');
const {
  createSplitExpense,
  listSplitExpenses,
  markParticipantPaid,
  settleExpense,
  deleteSplitExpense,
} = require('../../controllers/splitwiseController');

const router = express.Router();
router.use(restrictToLoggedInUsersOnly);

router.post('/expenses', createSplitExpense);
router.get('/expenses', listSplitExpenses);
router.patch('/expenses/:id/participants/:participantUid/paid', markParticipantPaid);
router.patch('/expenses/:id/settle', settleExpense);
router.delete('/expenses/:id', deleteSplitExpense);

module.exports = router;