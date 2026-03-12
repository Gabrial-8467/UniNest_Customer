import 'package:flutter/material.dart';

class LiveChatScreen extends StatefulWidget {
  final bool showBackButton;

  const LiveChatScreen({super.key, this.showBackButton = true});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    // _addInitialMessages(); // Removed to start with empty chat
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (!_isConnected) _buildConnectionBanner(),
          _buildChatHeader(),
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Live Chat',
            style: TextStyle(
              color: Color(0xFF2D3436),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      leading: widget.showBackButton
          ? IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3436)),
            )
          : null,
      automaticallyImplyLeading: widget.showBackButton,
      actions: [
        IconButton(
          onPressed: _showChatInfo,
          icon: const Icon(Icons.info_outline, color: Color(0xFF2D3436)),
        ),
      ],
    );
  }

  Widget _buildConnectionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          const Text(
            'Reconnecting to chat...',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFF6B6B),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Support Agent',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                Text(
                  'Usually responds instantly',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Online',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFF6B6B),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFFFF6B6B)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: message.isUser
                        ? null
                        : Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : const Color(0xFF2D3436),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          _buildQuickReplies(),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _showAttachmentOptions,
                icon: Icon(Icons.attach_file, color: Colors.grey[600]),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _messageController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _messageController.clear();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty && !_isTyping) {
                      _sendMessage(value);
                      setState(() {
                        _isTyping = true;
                      });
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            _isTyping = false;
                          });
                        }
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _sendMessage(_messageController.text),
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    final quickReplies = [
      '📍 Track my order',
      '💳 Payment issue',
      '🚚 Delivery time',
      '🍽 Menu options',
      '📞 Call support',
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quickReplies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendMessage(quickReplies[index]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                quickReplies[index],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text.trim(), isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = false;
    });

    _messageController.clear();
    _scrollToBottom();
    _simulateAgentResponse(text);
  }

  void _simulateAgentResponse(String userMessage) {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _isTyping = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        String response = _generateAgentResponse(userMessage);

        setState(() {
          _messages.add(
            ChatMessage(
              text: response,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isTyping = false;
        });
        _scrollToBottom();
      });
    });
  }

  String _generateAgentResponse(String userMessage) {
    final lowerCaseMessage = userMessage.toLowerCase().trim();

    if (lowerCaseMessage.contains('track') ||
        lowerCaseMessage.contains('order') &&
            (lowerCaseMessage.contains('status') ||
                lowerCaseMessage.contains('where'))) {
      return '🔍 **Order Tracking Help**\n\nI can help you track your order instantly! Please provide:\n\n📋 **Order ID** (e.g., ORD12345)\n📱 **Registered phone number**\n\nYou can also:\n• Go to **Profile** → **Order History**\n• Tap **"Track Order"** on any order\n\nI\'ll show you real-time status from kitchen to delivery! 📍';
    }

    if (lowerCaseMessage.contains('cancel') ||
        lowerCaseMessage.contains('stop')) {
      return '⚠️ **Order Cancellation**\n\nI can help with cancellation:\n\n✅ **Free cancellation** if order hasn\'t started preparation\n• ⏰ **Within 5 minutes** of placing order\n• 💰 **Full refund** to original payment method\n\n📞 **For immediate help**:\n• Call: +1 800-CAMPUS-EATS\n• Live chat with me here\n\nWhat\'s your order ID? I\'ll check the status right away!';
    }

    if (lowerCaseMessage.contains('refund') ||
        lowerCaseMessage.contains('money back')) {
      return '💰 **Refund Information**\n\nRefund timeline and process:\n\n⏱ **5-7 business days** for standard refunds\n• 🚀 **24-48 hours** for digital payments\n• 📧 **3-5 days** for bank transfers\n\n📋 **Required information**:\n• Order ID\n• Reason for refund\n• Bank account details (if applicable)\n\nNeed immediate help? I can connect you to a human agent right away! 📞';
    }

    if (lowerCaseMessage.contains('payment') ||
        lowerCaseMessage.contains('pay') ||
        lowerCaseMessage.contains('card') ||
        lowerCaseMessage.contains('upi')) {
      return '💳 **Payment Support**\n\n**Accepted Payment Methods:**\n\n🎫 **Credit/Debit Cards** (Visa, Mastercard, Rupay)\n📱 **UPI** (Google Pay, PhonePe, Paytm)\n🏦 **Net Banking** (All major banks)\n💵 **Cash on Delivery**\n\n**Troubleshooting:**\n\n• 🔍 **Check card details** - expiry, CVV, billing address\n• 📱 **Verify UPI PIN** and bank balance\n• 🌐 **Check internet connection** for online payments\n• 📞 **Call bank** if card is blocked\n\n**Still facing issues?** I can process payment manually or connect you to payment specialist! 🛠️';
    }

    if (lowerCaseMessage.contains('delivery') ||
        lowerCaseMessage.contains('deliver') ||
        lowerCaseMessage.contains('when') ||
        lowerCaseMessage.contains('time')) {
      return '🚚 **Delivery Information**\n\n**Delivery Timelines:**\n\n⚡ **Express**: 25-30 minutes\n• 🍔 **Standard**: 30-45 minutes\n• ⏰ **Scheduled**: Choose your preferred time\n\n📍 **Real-time Tracking** available in app!\n\n**Delivery Areas:**\n• 🏫 All campus buildings\n• 🏠 Student dormitories\n• 📚 Library and study areas\n\n📱 **Driver Contact**: Available 10 minutes before arrival\n\nNeed to change delivery address? I can help update it! 📝';
    }

    if (lowerCaseMessage.contains('menu') ||
        lowerCaseMessage.contains('food') ||
        lowerCaseMessage.contains('item') ||
        lowerCaseMessage.contains('available')) {
      return '🍽 **Menu & Food Information**\n\n**Popular Categories:**\n\n🍔 **Main Dishes**\n• Burgers, Pizza, Sandwiches\n• 🍗 **Sides**: Fries, Salads, Soups\n• 🥤 **Beverages**: Soft drinks, Shakes, Coffee\n• 🍰 **Desserts**: Ice cream, Brownies, Cakes\n• 🥗 **Healthy Options**: Salads, Fruit bowls, Smoothies\n\n**Dietary Options:**\n• 🌱 **Vegetarian** options available\n• 🍗 **Vegan** choices marked\n• 🔴 **Halal** certified canteens\n\n🕐 **Operating Hours:**\n• Mon-Fri: 11:00 AM - 10:00 PM\n• Sat-Sun: 10:00 AM - 11:00 PM\n\nCraving something specific? Let me know and I\'ll check availability! 🍕';
    }

    if (lowerCaseMessage.contains('account') ||
        lowerCaseMessage.contains('profile') ||
        lowerCaseMessage.contains('login') ||
        lowerCaseMessage.contains('password')) {
      return '👤 **Account & Profile Help**\n\n**Common Issues & Solutions:**\n\n🔐 **Forgot Password**\n• Use "Forgot Password" link on login screen\n• Reset link sent to registered email\n• Create new strong password\n\n📧 **Update Profile**\n• Go to Profile → Edit Profile\n• Add/Update phone number\n• Upload profile picture\n\n🏫 **Campus Verification**\n• Student ID required for campus delivery\n• Verify your campus email address\n• One-time verification process\n\n🔒 **Security Tips:**\n• Use unique password for campus apps\n• Enable two-factor authentication\n• Log out from shared devices\n\nNeed help with specific account issue? I\'m here to assist! 🔧';
    }

    if (lowerCaseMessage.contains('hello') ||
        lowerCaseMessage.contains('hi') ||
        lowerCaseMessage.contains('help') ||
        lowerCaseMessage.length < 10) {
      final greetings = [
        'Hello! 👋 How can I make your campus dining experience better today?',
        'Hi there! 🍕 I\'m your Campus Eats assistant. What can I help you with?',
        'Welcome! 🎓 I\'m here to help with orders, payments, delivery, and more!',
      ];

      final helps = [
        'I can help you:\n📦 Track orders in real-time\n💳 Resolve payment issues\n🍽 Find menu items and dietary options\n🚚 Check delivery status\n📞 Connect to human support if needed',
        'Popular topics:\n• Order tracking and cancellation\n• Payment method problems\n• Delivery time questions\n• Menu and dietary restrictions\n• Account and profile issues',
        'I\'m equipped to help with:\n🔍 Order status and tracking\n💰 Refunds and payment issues\n🍕 Menu recommendations\n🚚 Delivery scheduling\n📞 Technical support\n\nJust let me know what you need!',
      ];

      return '${greetings[DateTime.now().millisecond % greetings.length]}\n\n${helps[DateTime.now().millisecond % helps.length]}';
    }

    return '🤖 **AI Assistant Ready**\n\nI\'m here to help with all aspects of Campus Eats! Here\'s what I can do:\n\n📋 **Order Management:**\n• Track real-time order status\n• Modify or cancel orders\n• Order history and receipts\n\n💳 **Payment Support:**\n• Multiple payment methods\n• Refund processing\n• Payment failure troubleshooting\n\n🚚 **Delivery Services:**\n• Live delivery tracking\n• Delivery time estimates\n• Special delivery instructions\n\n🍽 **Food & Menu:**\n• Dietary restrictions (vegan, halal)\n• Allergen information\n• Popular recommendations\n\n👤 **Account Help:**\n• Profile management\n• Campus verification\n• Password reset assistance\n\n📞 **24/7 Support:**\n• Human agent connection\n• Emergency support\n• Technical troubleshooting\n\n**Quick Commands:**\n• "Track order [ID]" - Check status\n• "Cancel order [ID]" - Cancel order\n• "Payment help" - Payment issues\n• "Menu [canteen]" - Check menu\n\nType your specific question or use a quick command above! 🚀';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Camera feature coming soon!'),
                    backgroundColor: Color(0xFFFF6B6B),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gallery feature coming soon!'),
                    backgroundColor: Color(0xFFFF6B6B),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Send Document'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Document sharing coming soon!'),
                    backgroundColor: Color(0xFFFF6B6B),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat ID: CHAT${DateTime.now().millisecondsSinceEpoch}'),
            SizedBox(height: 8),
            Text('Agent: Support Team'),
            SizedBox(height: 8),
            Text('Average response time: Instant'),
            SizedBox(height: 8),
            Text(
              'Chat transcript will be saved to your account for future reference.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
