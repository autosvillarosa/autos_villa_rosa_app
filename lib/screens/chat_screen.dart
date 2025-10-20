import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String cocheUuid;
  final String marca;
  final String matricula;
  final String modelo;

  const ChatScreen({
    super.key,
    required this.cocheUuid,
    required this.marca,
    required this.matricula,
    required this.modelo,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<dynamic> _messages = [];
  List<dynamic> _filteredMessages = [];
  bool _isLoading = false;
  RealtimeChannel? _subscription;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUsername;

  static const Map<String, String> _userIdToUsername = {
    'e35bf66c-7396-4f00-801d-7c9a381f05e3': 'Mohamed',
    'b332ae8a-faac-475a-803e-9bd3c8c4f174': 'Ricardo',
    '5ad95f34-22df-4656-8648-e879697ad28c': 'Osvaldo',
    'd80f7c0a-5531-4275-8eaf-af0cdb99bacd': 'Daniel',
    'f3e05718-1ead-4741-b9de-796ffe64fe21': 'Lucia',
    '80e56284-d5ed-44ef-ada9-80fa5404b3c0': 'Ursula',
    '5df29426-11c6-4386-b0c8-58926c5f6e38': 'Alejandro',
    'b6812b4d-6f6f-45ee-bb34-1a88cd7b323a': 'Luisjavier',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _currentUserEmail =
        Supabase.instance.client.auth.currentUser?.email ?? 'Desconocido';
    _currentUsername = _currentUserEmail != 'Desconocido'
        ? _currentUserEmail!.split('@')[0]
        : 'Desconocido';
    _fetchMessages();
    _setupRealtimeSubscription();
    _searchController.addListener(_filterMessages);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _searchController.removeListener(_filterMessages);
    _searchController.dispose();
    _scrollController.dispose();
    _subscription?.unsubscribe();
    super.dispose();
  }

  // 👇 Este método detecta cuando aparece o desaparece el teclado
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = View.of(context).viewInsets.bottom;
    if (bottomInset > 0) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  Future<void> _fetchMessages() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('mensajes')
          .select('id, coche_uuid, user_id, mensaje, fecha')
          .eq('coche_uuid', widget.cocheUuid)
          .order('fecha', ascending: true);

      final messages = response.map((msg) {
        final displayName = msg['user_id'] == _currentUserId
            ? _currentUsername
            : _userIdToUsername[msg['user_id']] ?? 'Desconocido';
        final fecha = DateTime.parse(msg['fecha']).toLocal();
        final formattedFecha = DateFormat('dd/MM/yyyy HH:mm').format(fecha);
        return {
          ...msg,
          'formattedFecha': formattedFecha,
          'email': displayName,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _messages = messages;
          _filterMessages();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar mensajes: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    });
  }

  void _setupRealtimeSubscription() {
    _subscription = Supabase.instance.client
        .channel('mensajes:coche_uuid=eq.${widget.cocheUuid}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'coche_uuid',
            value: widget.cocheUuid,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            final displayName = newMessage['user_id'] == _currentUserId
                ? _currentUsername
                : _userIdToUsername[newMessage['user_id']] ?? 'Desconocido';
            final fecha = DateTime.parse(newMessage['fecha']).toLocal();
            final formattedFecha = DateFormat('dd/MM/yyyy HH:mm').format(fecha);

            if (mounted) {
              setState(() {
                _messages.add({
                  ...newMessage,
                  'formattedFecha': formattedFecha,
                  'email': displayName,
                });
                _filterMessages();
              });
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  void _filterMessages() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredMessages = List.from(_messages));
    } else {
      setState(() {
        _filteredMessages = _messages.where((msg) {
          final mensaje = msg['mensaje']?.toLowerCase() ?? '';
          final email = msg['email']?.toLowerCase() ?? '';
          return mensaje.contains(query) || email.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();
    FocusScope.of(context).unfocus();

    final optimisticMessage = {
      'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
      'coche_uuid': widget.cocheUuid,
      'user_id': _currentUserId,
      'mensaje': messageText,
      'fecha': DateTime.now().toIso8601String(),
      'formattedFecha':
          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now().toLocal()),
      'email': _currentUsername,
    };

    setState(() {
      _messages.add(optimisticMessage);
      _filterMessages();
    });
    _scrollToBottom();

    try {
      await Supabase.instance.client.from('mensajes').insert({
        'coche_uuid': widget.cocheUuid,
        'user_id': _currentUserId,
        'mensaje': messageText,
        'fecha': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg['id'] == optimisticMessage['id']);
          _filterMessages();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar mensaje: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Observaciones', style: TextStyle(fontSize: 20.0)),
            Text(
              '${widget.matricula} ${widget.marca} ${widget.modelo}',
              style: const TextStyle(fontSize: 14.0),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/fondo.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar mensajes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading && _messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredMessages.isEmpty
                        ? const Center(child: Text('No hay mensajes'))
                        : ListView.builder(
                            controller: _scrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.all(8.0),
                            itemCount: _filteredMessages.length,
                            itemBuilder: (context, index) {
                              final message = _filteredMessages[index];
                              final isMe = message['user_id'] == _currentUserId;
                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.blue.shade100
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message['email'],
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        message['mensaje'],
                                        style: const TextStyle(fontSize: 16.0),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        message['formattedFecha'],
                                        style: TextStyle(
                                          fontSize: 10.0,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    IconButton(
                      icon: _isLoading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Icon(Icons.send),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
