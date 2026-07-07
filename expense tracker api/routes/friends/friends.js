const express = require('express');
const {
  sendFriendRequest,
  listFriendRequests,
  listIncomingRequests,
  listOutgoingRequests,
  acceptFriendRequest,
  rejectFriendRequest,
  listFriends,
} = require('../../controllers/friendsController');
const { restrictToLoggedInUsersOnly } = require('../../middleware/auth');

const router = express.Router();

router.use(restrictToLoggedInUsersOnly);

router.post('/requests', sendFriendRequest);
router.get('/requests', listFriendRequests);
router.get('/requests/incoming', listIncomingRequests);
router.get('/requests/outgoing', listOutgoingRequests);
router.post('/requests/:id/accept', acceptFriendRequest);
router.post('/requests/:id/reject', rejectFriendRequest);
router.get('/list', listFriends);

module.exports = router;
