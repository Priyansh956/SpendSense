const { User } = require('../models/userModel');
const { FriendRequest } = require('../models/friendRequestModel');

const normalizeEmail = (email) => email.trim().toLowerCase();

const getUserSummary = (user) => ({
  id: user._id.toString(),
  email: user.email,
});

const sendFriendRequest = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Email is required' });
    }

    const targetEmail = normalizeEmail(email);
    if (targetEmail === normalizeEmail(req.user.email)) {
      return res.status(400).json({ success: false, message: 'You cannot add yourself' });
    }

    const targetUser = await User.findOne({ email: targetEmail });
    if (!targetUser) {
      return res.status(404).json({ success: false, message: 'No user found with that email' });
    }

    const existingRequest = await FriendRequest.findOne({
      $or: [
        { fromUser: req.user._id, toUser: targetUser._id, status: 'pending' },
        { fromUser: targetUser._id, toUser: req.user._id, status: 'pending' },
      ],
    });

    if (existingRequest) {
      return res.status(409).json({ success: false, message: 'Friend request already exists' });
    }

    const request = await FriendRequest.create({
      fromUser: req.user._id,
      toUser: targetUser._id,
      status: 'pending',
    });

    return res.status(201).json({
      success: true,
      message: 'Friend request sent',
      data: {
        id: request._id.toString(),
        fromUser: getUserSummary(req.user),
        toUser: getUserSummary(targetUser),
        status: request.status,
        createdAt: request.createdAt,
      },
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ success: false, message: 'Failed to send friend request' });
  }
};

const listFriendRequests = async (req, res) => {
  try {
    const requests = await FriendRequest.find({
      $or: [{ fromUser: req.user._id }, { toUser: req.user._id }],
    })
      .populate('fromUser', 'email')
      .populate('toUser', 'email')
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: requests.map((request) => ({
        id: request._id.toString(),
        fromUser: getUserSummary(request.fromUser),
        toUser: getUserSummary(request.toUser),
        status: request.status,
        createdAt: request.createdAt,
      })),
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ success: false, message: 'Failed to fetch friend requests' });
  }
};

const listIncomingRequests = async (req, res) => {
  try {
    const requests = await FriendRequest.find({ toUser: req.user._id, status: 'pending' })
      .populate('fromUser', 'email')
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: requests.map((request) => ({
        id: request._id.toString(),
        fromUser: getUserSummary(request.fromUser),
        toUser: getUserSummary(req.user),
        status: request.status,
        createdAt: request.createdAt,
      })),
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ success: false, message: 'Failed to fetch incoming requests' });
  }
};

const listOutgoingRequests = async (req, res) => {
  try {
    const requests = await FriendRequest.find({ fromUser: req.user._id, status: 'pending' })
      .populate('toUser', 'email')
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: requests.map((request) => ({
        id: request._id.toString(),
        fromUser: getUserSummary(req.user),
        toUser: getUserSummary(request.toUser),
        status: request.status,
        createdAt: request.createdAt,
      })),
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ success: false, message: 'Failed to fetch outgoing requests' });
  }
};

const acceptFriendRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const request = await FriendRequest.findOne({ _id: id, toUser: req.user._id, status: 'pending' });

    if (!request) {
      return res.status(404).json({ success: false, message: 'Request not found' });
    }

    request.status = 'accepted';
    await request.save();

    return res.status(200).json({
      success: true,
      message: 'Friend request accepted',
      data: {
        id: request._id.toString(),
        status: request.status,
      },
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ success: false, message: 'Failed to accept request' });
  }
};

const rejectFriendRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const request = await FriendRequest.findOne({ _id: id, toUser: req.user._id, status: 'pending' });

    if (!request) {
      return res.status(404).json({ success: false, message: 'Request not found' });
    }

    request.status = 'rejected';
    await request.save();

    return res.status(200).json({
      success: true,
      message: 'Friend request rejected',
      data: {
        id: request._id.toString(),
        status: request.status,
      },
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ success: false, message: 'Failed to reject request' });
  }
};

const removeFriend = async (req, res) => {
  try {
    const { friendUid } = req.params;

    const result = await FriendRequest.deleteMany({
      status: 'accepted',
      $or: [
        { fromUser: req.user._id, toUser: friendUid },
        { fromUser: friendUid, toUser: req.user._id },
      ],
    });

    if (!result.deletedCount) {
      return res.status(404).json({ success: false, message: 'Friend relationship not found' });
    }

    return res.status(200).json({ success: true, message: 'Friend removed' });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ success: false, message: 'Failed to remove friend' });
  }
};

const listFriends = async (req, res) => {
  try {
    const acceptedRequests = await FriendRequest.find({
      status: 'accepted',
      $or: [{ fromUser: req.user._id }, { toUser: req.user._id }],
    }).populate('fromUser', 'email').populate('toUser', 'email');

    const friends = acceptedRequests.flatMap((request) => {
      const otherUser = request.fromUser._id.toString() === req.user._id.toString()
        ? request.toUser
        : request.fromUser;

      return [{
        id: otherUser._id.toString(),
        email: otherUser.email,
      }];
    });

    return res.status(200).json({ success: true, data: friends });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ success: false, message: 'Failed to fetch friends' });
  }
};

module.exports = {
  sendFriendRequest,
  listFriendRequests,
  listIncomingRequests,
  listOutgoingRequests,
  acceptFriendRequest,
  rejectFriendRequest,
  removeFriend,
  listFriends,
};
